# Copyright (C) 2007-2013 Martin A. Hansen.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# http://www.gnu.org/copyleft/gpl.html

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# This software is part of the Biopieces framework (www.biopieces.org).

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# SAM format version v1.4-r962 - April 17, 2011
#
# http://samtools.sourceforge.net/SAM1.pdf

require 'pp'
require 'maasha/filesys'
require 'maasha/seq'
require 'maasha/cigar'

REGEX_HEADER  = Regexp.new(/^@[A-Za-z][A-Za-z](\t[A-Za-z][A-Za-z0-9]:[ -~]+)+$/)
REGEX_COMMENT = Regexp.new(/^@CO\t.*/)

FLAG_MULTI               = 0x1   # Template having multiple fragments in sequencing
FLAG_ALIGNED             = 0x2   # Each fragment properly aligned according to the aligner
FLAG_UNMAPPED            = 0x4   # Fragment unmapped
FLAG_NEXT_UNMAPPED       = 0x8   # Next fragment in the template unmapped
FLAG_REVCOMP             = 0x10  # SEQ being reverse complemented
FLAG_NEXT_REVCOMP        = 0x20  # SEQ of the next fragment in the template being reversed
FLAG_FIRST               = 0x40  # The first fragment in the template
FLAG_LAST                = 0x80  # The last fragment in the template
FLAG_SECONDARY_ALIGNMENT = 0x100 # Secondary alignment
FLAG_QUALITY_FAIL        = 0x200 # Not passing quality controls
FLAG_DUPLICATES          = 0x400 # PCR or optical duplicate

# Error class for all exceptions to do with Genbank.
class SamError < StandardError; end

# Class to parse and write SAM files.
class Sam < Filesys
  attr_accessor :io, :header

  # Class method to convert a SAM entry
  # to a Biopiece record.
  def self.to_bp(sam)
    bp = {}

    bp[:REC_TYPE] = 'SAM'
    bp[:Q_ID]     = sam[:QNAME]
    bp[:STRAND]   = sam[:FLAG].revcomp? ? '-' : '+'
    bp[:S_ID]     = sam[:RNAME]
    bp[:S_BEG]    = sam[:POS]
    bp[:S_END]    = sam[:POS] + sam[:SEQ].length - 1
    bp[:MAPQ]     = sam[:MAPQ]
    bp[:CIGAR]    = sam[:CIGAR].to_s

    unless sam[:RNEXT] == '*'
      bp[:Q_ID2]  = sam[:RNEXT]
      bp[:S_BEG2] = sam[:PNEXT]
      bp[:TLEN]   = sam[:TLEN]
    end

    bp[:SEQ]      = sam[:SEQ].seq

    unless sam[:SEQ].qual.nil?
      bp[:SCORES] = sam[:SEQ].qual # qual_convert!(:base_64, :base_33).qual
    end

    if sam[:NM] and sam[:NM].to_i > 0
      bp[:NM] = sam[:NM]
      bp[:MD] = sam[:MD]
      #bp[:ALIGN] = self.align_descriptors(sam)
      bp[:ALIGN] = self.align_pair(sam)
    end

    bp
  end

  # Class method to create a new SAM entry from a Biopiece record.
  # FIXME
  def self.new_bp(bp)
    qname = bp[:Q_ID]
    flag  = 0
    rname = bp[:S_ID]
    pos   = bp[:S_BEG]
    mapq  = bp[:MAPQ]
    cigar = bp[:CIGAR]
    rnext = bp[:Q_ID2]  || '*'
    pnext = bp[:S_BEG2] || 0
    tlen  = bp[:TLEN]   || 0
    seq   = bp[:SEQ]
    qual  = bp[:SCORES] || '*'
    nm    = "NM:i:#{bp[:NM]}" if bp[:NM]
    md    = "MD:Z:#{bp[:MD]}" if bp[:MD]

    flag |= FLAG_REVCOMP if bp[:STRAND] == '+'

    if qname && flag && rname && pos && mapq && cigar && rnext && pnext && tlen && seq && qual
      ary = [qname, flag, rname, pos, mapq, cigar, rnext, pnext, tlen, seq, qual]
      ary << nm if nm
      ary << md if md
      
      ary.join("\t")
    end
  end

  # Create alignment descriptors according to the KISS
  # format description:
  # http://code.google.com/p/biopieces/wiki/KissFormat
  def self.align_pair(sam)
    seq1    = sam[:SEQ].seq.dup
    seq2    = seq1.dup
    offset1 = 0
    offset2 = 0

    ins_index = Hash.new(0)

    sam[:CIGAR].each do |len, op|
      case op
      when 'I'
        ins_index[offset1] = len
        seq1[offset1 ... offset1 + len] = '-' * len
        offset1 += len
      when 'D'
        seq2 = seq2[0 ... offset2] + '-' * len + seq2[offset2 .. -1]
        offset2 += len
      when 'M'
        offset1 += len
        offset2 += len
      end
    end

    ins = 0

    (0 .. seq1.length).each do |i|
      ins = ins_index[i] if ins_index[i] > ins

      ins_index[i] = ins
    end

    offset1 = 0
    offset2 = 0

    sam[:MD].scan(/\d+|\^[A-Z]+|[A-Z]+/).each do |m|
      if m =~ /\d+/      # Matches
        offset1 += m.to_i
        offset2 += m.to_i
      elsif m[0] == '^'  # Deletions
        seq1 = seq1[0 ... offset1] + m[1 .. -1] + seq1[offset1 .. -1]

        offset1 += m.length - 1
      else               # Mismatches
        m.each_char do |nt|
          seq1[offset1 + ins_index[offset1]] = nt

          offset1 += 1
          offset2 += 1
        end
      end
    end

    align = []

    (0 ... seq1.length).each do |i|
      if seq1[i] != seq2[i]
        align << [i, "#{seq1[i]}>#{seq2[i]}"]
      end
    end

    align.map { |k, v| "#{k}:#{v}" }.join(",")
  end

  # Method to initialize a Sam object.
  def initialize(io = nil)
    @io     = io
    @header = {}

    parse_header
  end

  def each(encoding = :auto)
    @io.each_line do |line|
      unless line[0] == '@'
        entry = parse_alignment(line.chomp)

        if entry[:SEQ].qual
          if encoding == :auto
            if entry[:SEQ].qual_base33?
              encoding = :base_33
            elsif entry[:SEQ].qual_base64?
              encoding = :base_64
            else
              raise SeqError, "Could not auto-detect quality score encoding"
            end
          end

          entry[:SEQ].qual_convert!(encoding, :base_33)
        end

        yield entry if block_given?
      end
    end
  end

  private

  # Method to parse the header section of a SAM file.
  # Each header line should match:
  # /^@[A-Za-z][A-Za-z](\t[A-Za-z][A-Za-z0-9]:[ -~]+)+$/ or /^@CO\t.*/.
  # Tags containing lowercase letters are reserved for end users.
  def parse_header
    @io.each_line do |line|
      if line =~ /^@([A-Za-z][A-Za-z])/
        line.chomp!

        tag = $1

        case tag
        when 'HD' then subparse_header(line)
        when 'SQ' then subparse_sequence(line)
        when 'RG' then subparse_read_group(line)
        when 'PG' then subparse_program(line)
        when 'CO' then subparse_comment(line)
        else
          raise SamError, "Unknown header tag: #{tag}"
        end
      else
        @io.rewind
        break
      end
    end

    return @header.empty? ? nil : @header
  end

  # Method to subparse header lines.
  def subparse_header(line)
    hash   = {}
    fields = line.split("\t")

    if fields[1] =~ /^VN:([0-9]+\.[0-9]+)$/
      hash[:VN] = $1.to_f
    else
      raise SamError, "Bad version number: #{fields[1]}"
    end

    if fields.size > 2
      if fields[2] =~ /^SO:(unknown|unsorted|queryname|coordinate)$/
        hash[:SO] = $1
      else
        raise SamError, "Bad sort order: #{fields[2]}"
      end
    end

    @header[:HD] = hash
  end

  # Method to subparse sequence lines.
  def subparse_sequence(line)
    @header[:SQ] = Hash.new unless @header[:SQ].is_a? Hash
    hash = {}

    fields = line.split("\t")

    if fields[1] =~ /^SN:([!-)+-<>-~][!-~]*)$/
      seq_name = $1.to_sym
    else
      raise SamError, "Bad sequence name: #{fields[1]}"
    end

    if fields[2] =~ /^LN:(\d+)$/
      hash[:LN] = $1.to_i
    else
      raise SamError, "Bad sequence length: #{fields[2]}"
    end

    (3 ... fields.size).each do |i|
      if fields[i] =~ /^(AS|M5|SP|UR):([ -~]+)$/
        hash[$1.to_sym] = $2
      else
        raise SamError, "Bad sequence tag: #{fields[i]}"
      end
    end

    @header[:SQ][:SN] = Hash.new unless @header[:SQ][:SN].is_a? Hash

    if @header[:SQ][:SN][seq_name]
      raise SamError, "Non-unique sequence name: #{seq_name}"
    else
      @header[:SQ][:SN][seq_name] = hash
    end
  end

  # Method to subparse read group lines.
  def subparse_read_group(line)
    @header[:RG] = Hash.new unless @header[:RG].is_a? Hash
    hash = {}

    fields = line.split("\t")

    if fields[1] =~ /^ID:([ -~]+)$/
      id = $1.to_sym
    else
      raise SamError, "Bad read group identifier: #{fields[1]}"
    end

    (2 ... fields.size).each do |i|
      if fields[i] =~ /^(CN|DS|DT|FO|KS|LB|PG|PI|PL|PU|SM):([ -~]+)$/
        hash[$1.to_sym] = $2
      else
        raise SamError, "Bad read group tag: #{fields[i]}"
      end
    end

    if hash[:FO]
      unless hash[:FO] =~ /^\*|[ACMGRSVTWYHKDBN]+$/
        raise SamError, "Bad flow order: #{hash[:FO]}"
      end
    end

    if hash[:PL]
      unless hash[:PL] =~ /^(CAPILLARY|LS454|ILLUMINA|SOLID|HELICOS|IONTORRENT|PACBIO)$/
        raise SamError, "Bad platform: #{hash[:PL]}"
      end
    end

    @header[:RG][:ID] = Hash.new unless @header[:RG][:ID].is_a? Hash

    if @header[:RG][:ID][id]
      raise SamError, "Non-unique read group identifier: #{id}"
    else
      @header[:RG][:ID][id] = hash
    end
  end

  # Method to subparse program lines.
  def subparse_program(line)
    @header[:PG] = Hash.new unless @header[:PG].is_a? Hash
    hash = {}

    fields = line.split("\t")

    if fields[1] =~ /^ID:([ -~]+)$/
      id = $1.to_sym
    else
      raise SamError, "Bad program record identifier: #{fields[1]}"
    end

    (2 ... fields.size).each do |i|
      if fields[i] =~ /^(PN|CL|PP|VN):([ -~]+)$/
        hash[$1.to_sym] = $2
      else
        raise SamError, "Bad program record tag: #{fields[i]}"
      end
    end

    @header[:PG][:ID] = Hash.new unless @header[:PG][:ID].is_a? Hash

    if @header[:PG][:ID][id]
      raise SamError, "Non-unique program record identifier: #{id}"
    else
      @header[:PG][:ID][id] = hash
    end
  end

  # Method to subparse comment lines.
  def subparse_comment(line)
    @header[:CO] = Array.new unless @header[:CO].is_a? Array

    if line =~ /^@CO\t(.+)/
      @header[:CO] << $1
    else
      raise SamError, "Bad comment line: #{line}"
    end
  end

  # Method to subparse alignment lines.
  def parse_alignment(line)
    fields = line.split("\t")

    raise SamError, "Bad number of fields: #{fields.size} < 11" if fields.size < 11

    qname = fields[0]
    flag  = fields[1].to_i
    rname = fields[2]
    pos   = fields[3].to_i
    mapq  = fields[4].to_i
    cigar = fields[5]
    rnext = fields[6]
    pnext = fields[7].to_i
    tlen  = fields[8].to_i
    seq   = fields[9]
    qual  = fields[10]

    check_qname(qname)
    check_flag(flag)
    check_rname(rname)
    check_pos(pos)
    check_mapq(mapq)
    check_rnext(rnext)
    check_pnext(pnext)
    check_tlen(tlen)
    check_seq(seq)
    check_qual(qual)

    entry = {}
    entry[:QNAME] = qname
    entry[:FLAG]  = Flag.new(flag)
    entry[:RNAME] = rname
    entry[:POS]   = pos
    entry[:MAPQ]  = mapq
    entry[:CIGAR] = Cigar.new(cigar)
    entry[:RNEXT] = rnext
    entry[:PNEXT] = pnext
    entry[:TLEN]  = tlen
    entry[:SEQ]   = (qual == '*') ? Seq.new(seq_name: qname, seq: seq) : Seq.new(seq_name: qname, seq: seq, qual: qual)
    entry[:QUAL]  = qual

    # Optional fields - where some are really important! HATE HATE HATE SAM!!!
    
    fields[11 .. -1].each do |field|
      tag, type, val = field.split(':')

      raise SamError, "Non-unique optional tag: #{tag}" if entry[tag.to_sym]

      # A [!-~] Printable character

      # i [-+]?[0-9]+ Singed 32-bit integer
      if type == 'i'
        raise SamError, "Bad tag in optional field: #{field}" unless val =~ /^[-+]?[0-9]+$/
        val = val.to_i
      end

      # f [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)? Single-precision floating number
      # Z [ !-~]+ Printable string, including space
      # H [0-9A-F]+ Byte array in the Hex format
      # B [cCsSiIf](,[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+ Integer or numeric array

      entry[tag.to_sym] = val
    end

    entry
  end

  # Method to check qname.
  def check_qname(qname)
    raise SamError, "Bad qname: #{qname}" unless qname =~ /^[!-?A-~]{1,255}$/
  end

  # Method to check flag.
  def check_flag(flag)
    raise SamError, "Bad flag: #{flag}" unless (0 .. 2**16 - 1).include? flag
  end

  # Method to check if rname, when not '*' and
  # @SQ header lines are present, is located in
  # the header hash.
  def check_rname(rname)
    raise SamError, "Bad rname: #{rname}" unless rname =~ /^(\*|[!-()+-<>-~][!-~]*)$/

    unless @header.empty? or rname == '*'
      unless @header[:SQ][:SN][rname.to_sym]
        raise SamError, "rname not found in header hash: #{rname}"
      end
    end
  end

  # Method to check pos.
  def check_pos(pos)
    raise SamError, "Bad pos: #{pos}" unless (0 .. 2**29 - 1).include? pos
  end

  # Method to check mapq.
  def check_mapq(mapq)
    raise SamError, "Bad mapq: #{mapq}" unless (0 .. 2**8 - 1).include? mapq
  end

  # Method to check if rnext, when not '*' or '='
  # and @SQ header lines are present, is located
  # in the header hash.
  def check_rnext(rnext)
    raise SamError, "Bad rnext: #{rnext}" unless rnext =~ /^(\*|=|[!-()+-<>-~][!-~]*)$/

    unless @header.empty? or rnext == '*' or rnext == '='
      unless @header[:SQ][:SN][rnext.to_sym]
        raise SamError, "rnext not found in header hash: #{rnext}"
      end
    end
  end

  # Method to check pnext.
  def check_pnext(pnext)
    raise SamError, "Bad pnext: #{pnext}" unless (0 .. 2**29 - 1).include? pnext
  end

  # Method to check tlen.
  def check_tlen(tlen)
    raise SamError, "Bad tlen: #{tlen}" unless (-2**29 + 1 .. 2**29 - 1).include? tlen
  end

  # Method to check seq.
  def check_seq(seq)
    raise SamError, "Bad seq: #{seq}" unless seq  =~ /^(\*|[A-Za-z=.]+)$/
  end

  # Method to check qual.
  def check_qual(qual)
    raise SamError, "Bad qual: #{qual}" unless qual =~ /^[!-~]+$/
  end

  # Method to deconvolute the SAM flag field.
  class Flag
    attr_reader :flag

    # Method to initialize a Flag object.
    def initialize(flag)
      @flag = flag
    end

    # Method to test if template have
    # multiple fragments in sequencing.
    def multi?
      (flag & FLAG_MULTI) == 0
    end

    # Method to test if each fragment
    # properly aligned according to the aligner.
    def aligned?
      (flag & FLAG_ALIGNED) == 0
    end
    
    # Method to test if the fragment was unmapped.
    def unmapped?
      (flag & FLAG_UNMAPPED) == 0
    end

    # Method to test if the next fragment was unmapped.
    def next_unmapped?
      (flag & FLAG_NEXT_UNMAPPED) == 0
    end

    # Method to test if the fragment was reverse complemented.
    def revcomp?
      (flag & FLAG_REVCOMP) == 0
    end

    # Method to test if the next fragment was reverse complemented.
    def next_revcomp?
      (flag & FLAG_NEXT_REVCOMP) == 0
    end

    # Method to test if the fragment was first in the template.
    def first?
      (flag & FLAG_FIRST) == 0
    end

    # Method to test if the fragment was last in the template.
    def last?
      (flag & FLAG_LAST) == 0
    end

    # Method to test for secondary alignment.
    def secondary_alignment?
      (flag & FLAG_SECONDARY_ALIGNMENT) == 0
    end

    # Method to test for quality fail.
    def quality_fail?
      (flag & FLAG_QUALITY_FAIL) == 0
    end

    # Method to test for PCR or optical duplicates.
    def duplicates?
      (flag & FLAG_DUPLICATES) == 0
    end
  end
end


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__

