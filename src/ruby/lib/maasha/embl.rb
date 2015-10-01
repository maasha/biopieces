# Copyright (C) 2007-2011 Martin A. Hansen.

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

require 'maasha/locator'
require 'maasha/seq'
require 'maasha/filesys'
require 'pp'

# Error class for all exceptions to do with EMBL.
class EMBLError < StandardError; end

class EMBL < Filesys
  def initialize(io)
    @io      = io
    @entry   = []
  end

  # Iterator method for parsing EMBL entries.
  def each(hash_keys = nil, hash_feats = nil, hash_quals = nil)
    while @entry = get_entry do
      keys = get_keys(hash_keys)
      seq  = get_seq

      features = EMBLFeatures.new(@entry, hash_feats, hash_quals)

      features.each do |record|
        keys.each_pair { |key,val| record[key] = val }

				loc = Locator.new(record[:LOCATOR], seq)
				record[:SEQ]     = loc.subseq.seq
        record[:SEQ_LEN] = loc.subseq.length
				record[:STRAND]  = loc.strand
				record[:S_BEG]   = loc.s_beg
				record[:S_END]   = loc.s_end

        yield record
      end
    end
  end

  private

  # Method to get the next Genbank entry form an ios and return this.
  def get_entry
    block = @io.gets("//" + $/)
    return nil if block.nil?

    block.chomp!("//" + $/ )

    entry = block.tr("\r", "\n").split $/

    return nil if entry.empty?

    entry
  end

  # Method to get the DNA sequence from an EMBL entry and return
  # this as a Seq object.
  def get_seq
    i = @entry.size
    j = i - 1

    while @entry[j] and @entry[j] !~ /^[A-Z]/
      j -= 1
    end

    seq = @entry[j + 1 .. i].join.delete(" 0123456789")

    Seq.new(seq: seq, type: :dna) if seq
  end

  # Method to get the base keys from EMBL entry and return these
  # in a hash.
  def get_keys(hash_keys)
    keys = {}
    i    = 0
    j    = 0

    while @entry[i]
      key, val = @entry[i].split(/\s+/, 2)
      break if key == "FH"
      unless key == "XX"
        if want_key?(hash_keys, key)
          j = i + 1

          while @entry[j]
            next_key, next_val = @entry[j].split(/\s+/, 2)
            if key == next_key
              val << " " + next_val
              j += 1
            else
              break
            end
          end

          if keys[key.to_sym]
            keys[key.to_sym] << " " + val
          else
            keys[key.to_sym] = val
          end
        end
      end

      j > i ? i = j : i += 1
    end

    keys
  end

  def want_key?(hash_keys, key)
    if hash_keys
      if hash_keys[key.to_sym]
        return true
      else
        return false
      end
    else
      return true
    end
  end
end

class EMBLFeatures
  def initialize(entry, hash_feats, hash_quals)
    @entry      = entry
    @hash_feats = hash_feats
    @hash_quals = hash_quals
  	@i          = 0
  	@j          = 0
  end

  def each
    while @entry[@i] and @entry[@i][0 ... 2] != "SQ"
      if @entry[@i] =~ /^FT\s{3}([53'A-Za-z_-]+)/
        if want_feat? $1
          record = {}

          key, feat, loc = @entry[@i].split(/\s+/, 3)

          @j = @i + 1

          while @entry[@j] and @entry[@j][0 ... 2] == "FT" and @entry[@j] !~ /^FT(\s{19}\/|\s{3}[53'A-Za-z_-])/
            loc << @entry[@j].split(/\s+/, 2).last
            @j += 1
          end

          get_quals.each_pair { |k,v|
            record[k.upcase.to_sym] = v
          }

          record[:FEATURE] = feat
          record[:LOCATOR] = loc

          yield record
        end
      end

      @j > @i ? @i = @j : @i += 1
    end
  end

  private

  def get_quals
    quals = {}
    k     = 0

    while @entry[@j] and @entry[@j][0 ... 2] == "FT" and @entry[@j] !~ /^FT\s{3}[53'A-Za-z_-]/
      if @entry[@j] =~ /^FT\s{19}\/([^=]+)="([^"]+)/
        qual = $1
        val  = $2

        if want_qual? qual
          k = @j + 1

          while @entry[k] and @entry[k][0 ... 2] == "FT" and @entry[k] !~ /^FT(\s{19}\/|\s{3}[53'A-Za-z_-])/
            val << @entry[k].split(/\s+/, 2).last.chomp('"')
            k += 1
          end

          if quals[qual]
            quals[qual] << ";" + val
          else
            quals[qual] = val
          end
        end
      end

      k > @j ? @j = k : @j += 1
    end

    quals
  end

  def want_feat?(feat)
    if @hash_feats
      if @hash_feats[feat.upcase.to_sym]
        return true
      else
        return false
      end
    else
      return true
    end
  end

  def want_qual?(qual)
    if @hash_quals
      if @hash_quals[qual.upcase.to_sym]
        return true
      else
        return false
      end
    else
      return true
    end
  end
end

__END__
