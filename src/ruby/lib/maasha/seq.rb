# Copyright (C) 2007-2012 Martin A. Hansen.

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

require 'maasha/bits'
require 'maasha/seq/digest'
require 'maasha/seq/trim'
require 'narray'

autoload :BackTrack,   'maasha/seq/backtrack'
autoload :Dynamic,     'maasha/seq/dynamic'
autoload :Homopolymer, 'maasha/seq/homopolymer'
autoload :Hamming,     'maasha/seq/hamming'
autoload :Levenshtein, 'maasha/seq/levenshtein'
autoload :Ambiguity,   'maasha/seq/ambiguity'

# Residue alphabets
DNA     = %w[a t c g]
RNA     = %w[a u c g]
PROTEIN = %w[f l s y c w p h q r i m t n k v a d e g]
INDELS  = %w[. - _ ~]

# Translation table 11
# (http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi?chapter=cgencodes#SG11)
#   AAs  = FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
# Starts = ---M---------------M------------MMMM---------------M------------
# Base1  = TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
# Base2  = TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
# Base3  = TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
TRANS_TAB11_START = {
  "TTG" => "M", "CTG" => "M", "ATT" => "M", "ATC" => "M",
  "ATA" => "M", "ATG" => "M", "GTG" => "M"
}

TRANS_TAB11 = {
  "TTT" => "F", "TCT" => "S", "TAT" => "Y", "TGT" => "C",
  "TTC" => "F", "TCC" => "S", "TAC" => "Y", "TGC" => "C",
  "TTA" => "L", "TCA" => "S", "TAA" => "*", "TGA" => "*",
  "TTG" => "L", "TCG" => "S", "TAG" => "*", "TGG" => "W",
  "CTT" => "L", "CCT" => "P", "CAT" => "H", "CGT" => "R",
  "CTC" => "L", "CCC" => "P", "CAC" => "H", "CGC" => "R",
  "CTA" => "L", "CCA" => "P", "CAA" => "Q", "CGA" => "R",
  "CTG" => "L", "CCG" => "P", "CAG" => "Q", "CGG" => "R",
  "ATT" => "I", "ACT" => "T", "AAT" => "N", "AGT" => "S",
  "ATC" => "I", "ACC" => "T", "AAC" => "N", "AGC" => "S",
  "ATA" => "I", "ACA" => "T", "AAA" => "K", "AGA" => "R",
  "ATG" => "M", "ACG" => "T", "AAG" => "K", "AGG" => "R",
  "GTT" => "V", "GCT" => "A", "GAT" => "D", "GGT" => "G",
  "GTC" => "V", "GCC" => "A", "GAC" => "D", "GGC" => "G",
  "GTA" => "V", "GCA" => "A", "GAA" => "E", "GGA" => "G",
  "GTG" => "V", "GCG" => "A", "GAG" => "E", "GGG" => "G"
}

# Error class for all exceptions to do with Seq.
class SeqError < StandardError; end

class Seq
  # Quality scores bases
  SCORE_BASE = 33
  SCORE_MIN  = 0
  SCORE_MAX  = 40

  include Digest
  include Trim

  attr_accessor :seq_name, :seq, :type, :qual

  # Class method to instantiate a new Sequence object given
  # a Biopiece record.
  def self.new_bp(record)
    seq_name = record[:SEQ_NAME]
    seq      = record[:SEQ]
    type     = record[:SEQ_TYPE].to_sym if record[:SEQ_TYPE]
    qual     = record[:SCORES]

    self.new(seq_name: seq_name, seq: seq, type: type, qual: qual)
  end

  # Class method that generates all possible oligos of a specifed length and type.
  def self.generate_oligos(length, type)
    raise SeqError, "Cannot generate negative oligo length: #{length}" if length <= 0

    case type.downcase
    when :dna     then alph = DNA
    when :rna     then alph = RNA
    when :protein then alph = PROTEIN
    else
      raise SeqError, "Unknown sequence type: #{type}"
    end

    oligos = [""]

    (1 .. length).each do
      list = []

      oligos.each do |oligo|
        alph.each do |char|
          list << oligo + char
        end
      end

      oligos = list
    end

    oligos
  end

  # Initialize a sequence object with the following options:
  # - :seq_name   Name of the sequence.
  # - :seq        The sequence.
  # - :type       The sequence type - DNA, RNA, or protein
  # - :qual       An Illumina type quality scores string.
  def initialize(options = {})
    @seq_name = options[:seq_name]
    @seq      = options[:seq]
    @type     = options[:type]
    @qual     = options[:qual]

    if @seq and @qual and @seq.length != @qual.length
      raise SeqError, "Sequence length and score length mismatch: #{@seq.length} != #{@qual.length}"
    end
  end

  # Method that guesses and returns the sequence type
  # by inspecting the first 100 residues.
  def type_guess
    raise SeqError, "Guess failed: sequence is nil" if self.seq.nil?

    case self.seq[0 ... 100].downcase
    when /[flpqie]/ then return :protein
    when /[u]/      then return :rna
    else                 return :dna
    end
  end

  # Method that guesses and sets the sequence type
  # by inspecting the first 100 residues.
  def type_guess!
    self.type = self.type_guess
    self
  end

  # Returns the length of a sequence.
  def length
    self.seq.nil? ? 0 : self.seq.length
  end

  alias :len :length

  # Return the number indels in a sequence.
  def indels
    regex = Regexp.new(/[#{Regexp.escape(INDELS.join(""))}]/)
    self.seq.scan(regex).size
  end

  # Method to remove indels from seq and qual if qual.
  def indels_remove
    if self.qual.nil?
      self.seq.delete!(Regexp.escape(INDELS.join('')))
    else
      na_seq  = NArray.to_na(self.seq, "byte")
      na_qual = NArray.to_na(self.qual, "byte")
      mask    = NArray.byte(self.length)

      INDELS.each do |c|
        mask += na_seq.eq(c.ord)
      end

      mask = mask.eq(0)

      self.seq  = na_seq[mask].to_s
      self.qual = na_qual[mask].to_s
    end

    self
  end

  # Method that returns true is a given sequence type is DNA.
  def is_dna?
    self.type == :dna
  end

  # Method that returns true is a given sequence type is RNA.
  def is_rna?
    self.type == :rna
  end

  # Method that returns true is a given sequence type is protein.
  def is_protein?
    self.type == :protein
  end

  # Method to transcribe DNA to RNA.
  def to_rna
    raise SeqError, "Cannot transcribe 0 length sequence" if self.length == 0
    raise SeqError, "Cannot transcribe sequence type: #{self.type}" unless self.is_dna?
    self.type = :rna
    self.seq.tr!('Tt','Uu')
  end

  # Method to reverse-transcribe RNA to DNA.
  def to_dna
    raise SeqError, "Cannot reverse-transcribe 0 length sequence" if self.length == 0
    raise SeqError, "Cannot reverse-transcribe sequence type: #{self.type}" unless self.is_rna?
    self.type = :dna
    self.seq.tr!('Uu','Tt')
  end

  # Method to translate a DNA sequence to protein.
  def translate!(trans_tab = 11)
    raise SeqError, "Sequence type must be 'dna' - not #{self.type}" unless self.type == :dna
    raise SeqError, "Sequence length must be a multiplum of 3 - was: #{self.length}" unless (self.length % 3) == 0

    case trans_tab
    when 11
      codon_start_hash = TRANS_TAB11_START
      codon_hash       = TRANS_TAB11
    else
      raise SeqError, "Unknown translation table: #{trans_tab}"
    end

    codon  = self.seq[0 ... 3].upcase

    aa = codon_start_hash[codon]

    raise SeqError, "Unknown start codon: #{codon}" if aa.nil?

    protein = aa

    i = 3

    while i < self.length
      codon = self.seq[i ... i + 3].upcase

      aa = codon_hash[codon]

      raise SeqError, "Unknown codon: #{codon}" if aa.nil?

      protein << aa

      i += 3
    end

    self.seq  = protein
    self.qual = nil
    self.type = :protein

    self
  end

  alias :to_protein! :translate!

  def translate(trans_tab = 11)
    self.dup.translate!(trans_tab)
  end

  alias :to_protein :translate

  # Method that given a Seq entry returns a Biopieces record (a hash).
  def to_bp
    raise SeqError, "Missing seq_name" if self.seq_name.nil?
    raise SeqError, "Missing seq"      if self.seq.nil?

    record             = {}
    record[:SEQ_NAME] = self.seq_name
    record[:SEQ]      = self.seq
    record[:SEQ_LEN]  = self.length
    record[:SCORES]   = self.qual if self.qual
    record
  end

  # Method that given a Seq entry returns a FASTA entry (a string).
  def to_fasta(wrap = nil)
    raise SeqError, "Missing seq_name" if self.seq_name.nil? or self.seq_name == ''
    raise SeqError, "Missing seq"      if self.seq.nil?      or self.seq.empty?

    seq_name = self.seq_name
    seq      = self.seq.dup

    unless wrap.nil?
      seq.gsub!(/(.{#{wrap}})/) do |match|
        match << $/
      end

      seq.chomp!
    end

    ">" + seq_name.to_s + $/ + seq + $/
  end

  # Method that given a Seq entry returns a FASTQ entry (a string).
  def to_fastq
    raise SeqError, "Missing seq_name" if self.seq_name.nil?
    raise SeqError, "Missing seq"      if self.seq.nil?
    raise SeqError, "Missing qual"     if self.qual.nil?

    seq_name = self.seq_name.to_s
    seq      = self.seq.to_s
    qual     = self.qual.to_s

    "@" + seq_name + $/ + seq + $/ + "+" + $/ + qual + $/
  end

  # Method that generates a unique key for a
  # DNA sequence and return this key as a Fixnum.
  def to_key
    key = 0
    
    self.seq.upcase.each_char do |char|
      key <<= 2
      
      case char
      when 'A' then key |= 0
      when 'C' then key |= 1
      when 'G' then key |= 2
      when 'T' then key |= 3
      else raise SeqError, "Bad residue: #{char}"
      end
    end
    
    key
  end

  # Method to reverse the sequence.
  def reverse
    entry = Seq.new(
      seq_name: self.seq_name,
      seq:      self.seq.reverse,
      type:     self.type,
      qual:     (self.qual ? self.qual.reverse : self.qual)
    )

    entry
  end

  # Method to reverse the sequence.
  def reverse!
    self.seq.reverse!
    self.qual.reverse! if self.qual
    self
  end

  # Method that complements sequence including ambiguity codes.
  def complement
    raise SeqError, "Cannot complement 0 length sequence" if self.length == 0

    entry = Seq.new(
      seq_name: self.seq_name,
      type:     self.type,
      qual:     self.qual
    )

    if self.is_dna?
      entry.seq = self.seq.tr('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn', 'TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn')
    elsif self.is_rna?
      entry.seq = self.seq.tr('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn', 'UCGAAYRWSKMDHBVNucgaayrwskmdhbvn')
    else
      raise SeqError, "Cannot complement sequence type: #{self.type}"
    end

    entry
  end

  # Method that complements sequence including ambiguity codes.
  def complement!
    raise SeqError, "Cannot complement 0 length sequence" if self.length == 0

    if self.is_dna?
      self.seq.tr!('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn', 'TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn')
    elsif self.is_rna?
      self.seq.tr!('AGCUTRYWSMKHDVBNagcutrywsmkhdvbn', 'UCGAAYRWSKMDHBVNucgaayrwskmdhbvn')
    else
      raise SeqError, "Cannot complement sequence type: #{self.type}"
    end

    self
  end

  # Method to determine the Hamming Distance between
  # two Sequence objects (case insensitive).
  def hamming_distance(entry, options = nil)
    if options and options[:ambiguity]
      Hamming.distance(self.seq, entry.seq)
    else
      self.seq.upcase.hamming_distance(entry.seq.upcase)
    end
  end

  # Method to determine the Edit Distance between
  # two Sequence objects (case insensitive).
  def edit_distance(entry)
    Levenshtein.distance(self.seq, entry.seq)
  end

  # Method that generates a random sequence of a given length and type.
  def generate(length, type)
    raise SeqError, "Cannot generate sequence length < 1: #{length}" if length <= 0

    case type
    when :dna     then alph = DNA
    when :rna     then alph = RNA
    when :protein then alph = PROTEIN
    else
      raise SeqError, "Unknown sequence type: #{type}"
    end

    seq_new   = Array.new(length) { alph[rand(alph.size)] }.join("")
    self.seq  = seq_new
    self.type = type
    seq_new
  end

  # Method to return a new Seq object with shuffled sequence.
  def shuffle
    Seq.new(
      seq_name: self.seq_name,
      seq:      self.seq.split('').shuffle!.join,
      type:     self.type,
      qual:     self.qual
    )
  end

  # Method to shuffle a sequence randomly inline.
  def shuffle!
    self.seq = self.seq.split('').shuffle!.join
    self
  end

  # Method to add two Seq objects.
  def +(entry)
    new_entry = Seq.new()
    new_entry.seq  = self.seq  + entry.seq
    new_entry.type = self.type              if self.type == entry.type
    new_entry.qual = self.qual + entry.qual if self.qual and entry.qual
    new_entry
  end

  # Method to concatenate sequence entries.
  def <<(entry)
    raise SeqError, "sequences of different types" unless self.type == entry.type
    raise SeqError, "qual is missing in one entry" unless self.qual.class == entry.qual.class

    self.seq  << entry.seq
    self.qual << entry.qual unless entry.qual.nil?

    self
  end

  # Index method for Seq objects.
  def [](*args)
    entry = Seq.new
    entry.seq_name = self.seq_name.dup if self.seq_name
    entry.seq      = self.seq[*args]
    entry.type     = self.type
    entry.qual     = self.qual[*args] unless self.qual.nil?

    entry
  end

  # Index assignment method for Seq objects.
  def []=(*args, entry)
    self.seq[*args]  = entry.seq[*args]
    self.qual[*args] = entry.qual[*args] unless self.qual.nil?

    self
  end

  # Method that returns a subsequence of a given length
  # beginning at a random position.
  def subseq_rand(length)
    if self.length - length + 1 == 0
      start = 0
    else
      start = rand(self.length - length + 1)
    end

    self[start .. start + length]
  end

  # Method that returns the residue compositions of a sequence in
  # a hash where the key is the residue and the value is the residue
  # count.
  def composition
    comp = Hash.new(0);

    self.seq.upcase.each_char do |char|
      comp[char] += 1
    end

    comp
  end

  # Method that returns the percentage of hard masked residues
  # or N's in a sequence.
  def hard_mask
    ((self.seq.upcase.scan("N").size.to_f / (self.len - self.indels).to_f) * 100).round(2)
  end

  # Method that returns the percentage of soft masked residues
  # or lower cased residues in a sequence.
  def soft_mask
    ((self.seq.scan(/[a-z]/).size.to_f / (self.len - self.indels).to_f) * 100).round(2)
  end

  # Hard masks sequence residues where the corresponding quality score
  # is below a given cutoff.
  def mask_seq_hard!(cutoff)
    raise SeqError, "seq is nil"  if self.seq.nil?
    raise SeqError, "qual is nil" if self.qual.nil?
    raise SeqError, "cufoff value: #{cutoff} out of range #{SCORE_MIN} .. #{SCORE_MAX}" unless (SCORE_MIN .. SCORE_MAX).include? cutoff

    na_seq  = NArray.to_na(self.seq, "byte")
    na_qual = NArray.to_na(self.qual, "byte")
    mask    = (na_qual - SCORE_BASE) < cutoff
    mask   *= na_seq.ne("-".ord)

    na_seq[mask] = 'N'.ord

    self.seq = na_seq.to_s

    self
  end

  # Soft masks sequence residues where the corresponding quality score
  # is below a given cutoff.
  def mask_seq_soft!(cutoff)
    raise SeqError, "seq is nil"  if self.seq.nil?
    raise SeqError, "qual is nil" if self.qual.nil?
    raise SeqError, "cufoff value: #{cutoff} out of range #{SCORE_MIN} .. #{SCORE_MAX}" unless (SCORE_MIN .. SCORE_MAX).include? cutoff

    na_seq  = NArray.to_na(self.seq, "byte")
    na_qual = NArray.to_na(self.qual, "byte")
    mask    = (na_qual - SCORE_BASE) < cutoff
    mask   *= na_seq.ne("-".ord)

    na_seq[mask] ^= ' '.ord

    self.seq = na_seq.to_s

    self
  end

  # Method that determines if a quality score string can be
  # absolutely identified as base 33.
  def qual_base33?
    self.qual.match(/[!-:]/) ? true : false
  end
 
  # Method that determines if a quality score string may be base 64.
  def qual_base64?
    self.qual.match(/[K-h]/) ? true : false
  end

  # Method to determine if a quality score is valid accepting only 0-40 range.
  def qual_valid?(encoding)
    raise SeqError, "Missing qual" if self.qual.nil?

    case encoding
    when :base_33 then return true if self.qual.match(/^[!-I]*$/)
    when :base_64 then return true if self.qual.match(/^[@-h]*$/)
    else raise SeqError, "unknown quality score encoding: #{encoding}"
    end

    false
  end

  # Method to coerce quality scores to be within the 0-40 range.
  def qual_coerce!(encoding)
    raise SeqError, "Missing qual" if self.qual.nil?

    case encoding
    when :base_33 then qual_coerce_C(self.qual, self.qual.length, 33, 73)  # !-J
    when :base_64 then qual_coerce_C(self.qual, self.qual.length, 64, 104) # @-h
    else
      raise SeqError, "unknown quality score encoding: #{encoding}"
    end 

    self
  end

  # Method to convert quality scores.
  def qual_convert!(from, to)
    raise SeqError, "unknown quality score encoding: #{from}" unless from == :base_33 or from == :base_64
    raise SeqError, "unknown quality score encoding: #{to}"   unless to   == :base_33 or to   == :base_64

    if from == :base_33 and to == :base_64
      qual_convert_C(self.qual, self.qual.length, 31)    # += 64 - 33
    elsif from == :base_64 and to == :base_33
      qual_coerce_C(self.qual, self.qual.length, 64, 104) # Handle negative Solexa values from -5 to -1 (set these to 0).
      qual_convert_C(self.qual, self.qual.length, -31)    # -= 64 - 33
    end

    self
  end

  # Method to calculate and return the mean quality score.
  def scores_mean
    raise SeqError, "Missing qual in entry" if self.qual.nil?

    na_qual = NArray.to_na(self.qual, "byte")
    na_qual -= SCORE_BASE

    na_qual.mean
  end

  # Method to find open reading frames (ORFs).
  def each_orf(size_min, size_max, start_codons, stop_codons, pick_longest = false)
    orfs    = []
    pos_beg = 0

    regex_start = Regexp.new(start_codons.join('|'), true)
    regex_stop  = Regexp.new(stop_codons.join('|'), true)

    while pos_beg = self.seq.index(regex_start, pos_beg)
      pos_end = pos_beg + 3
       
      while pos_end = self.seq.index(regex_stop, pos_end)
        length = (pos_end - pos_beg) + 3

        if (length % 3) == 0
          if size_min <= length and length <= size_max
            subseq = self[pos_beg ... pos_beg + length]

            orfs << [subseq, pos_beg, pos_end + 3]
          end

          break
        end

        pos_end += 1
      end

      pos_beg += 1
    end

    if pick_longest
      orf_hash = {}

      orfs.each { |orf| orf_hash[orf.last] = orf unless orf_hash[orf.last] }

      orfs = orf_hash.values
    end

    if block_given?
      orfs.each { |orf| yield orf }
    else
      return orfs
    end
  end

  private

  inline do |builder|
    builder.c %{
      VALUE qual_coerce_C(
        VALUE _qual,
        VALUE _qual_len,
        VALUE _min_value,
        VALUE _max_value
      )
      {
        unsigned char *qual      = (unsigned char *) StringValuePtr(_qual);
        unsigned int   qual_len  = FIX2UINT(_qual_len);
        unsigned int   min_value = FIX2UINT(_min_value);
        unsigned int   max_value = FIX2UINT(_max_value);
        unsigned int   i         = 0;

        for (i = 0; i < qual_len; i++)
        {
          if (qual[i] > max_value) {
            qual[i] = max_value;
          } else if (qual[i] < min_value) {
            qual[i] = min_value;
          }
        }

        return Qnil;
      }
    }

    builder.c %{
      VALUE qual_convert_C(
        VALUE _qual,
        VALUE _qual_len,
        VALUE _value
      )
      {
        unsigned char *qual     = (unsigned char *) StringValuePtr(_qual);
        unsigned int   qual_len = FIX2UINT(_qual_len);
        int            value    = FIX2INT(_value);
        unsigned int   i        = 0;

        for (i = 0; i < qual_len; i++)
        {
          qual[i] += value;
        }

        return Qnil;
      }
    }
  end
end

__END__
