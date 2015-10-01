# Copyright (C) 2011 Martin A. Hansen.

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

require 'maasha/base36'
require 'maasha/seq'

# Error class for all exceptions to do with SFF.
class SFFError < StandardError; end

BIT_SHIFT = 12
BIT_MASK  = (1 << BIT_SHIFT) - 1

# Class containing methods to parse SFF files:
# http://www.ncbi.nlm.nih.gov/Traces/trace.cgi?cmd=show&f=formats&m=doc&s=format#sff
class SFF
  include Enumerable

  # Class method for opening SFF files.
  def self.open(*args)
    ios = File.open(*args)

    if block_given?
      begin
        yield self.new(ios)
      ensure
        ios.close
      end
    else
      return self.new(ios)
    end
  end

  # Method to initialize an SFF object along with
  # instance variables pertaining to the SFF header
  # section.
  def initialize(io)
    @io                       = io
    @magic_number             = 0
    @version                  = ""
    @index_offset             = 0
    @index_length             = 0
    @number_of_reads          = 0
    @header_length            = 0
    @key_length               = 0
    @number_of_flows_per_read = 0
    @flowgram_format_code     = 0
    @flow_chars               = ""
    @key_sequence             = ""
    @eight_byte_padding       = 0
    @count                    = 0

    header_parse
  end

  # Method to close ios.
  def close
    @io.close
  end

  # Method to iterate over each SFF entry.
  def each
    while (read = read_parse) do
      yield read
    end

    self   # conventionally
  end

  private

  # Method to parse the SFF file's header section
  # and load the information into the instance variables.
  def header_parse
    template     = "NC4N2NNnnnC"
    bits_in_uint = 32

    data = @io.read(31).unpack(template)
    
    @magic_number             = data[0]
    @version                  = data[1 .. 4].join ""
    @index_offset             = (data[5] << bits_in_uint) | data[6]
    @index_length             = data[7]
    @number_of_reads          = data[8]
    @header_length            = data[9]
    @key_length               = data[10]
    @number_of_flows_per_read = data[11]
    @flowgram_format_code     = data[12]
    @flow_chars               = @io.read(@number_of_flows_per_read).unpack("A*").join ""
    @key_sequence             = @io.read(@key_length).unpack("A*").join ""

    fast_forward

    check_magic_number
    check_version
    check_header_length
  end

  # Method that reads the eight_byte_padding field found at the end of the
  # data section and fast forwards, i.e. move the file read pointer,
  # so that the length of the section is divisible by 8.
  def fast_forward
    eight_byte_padding = 8 - (@io.pos % 8)

    @io.read(eight_byte_padding) unless eight_byte_padding == 8
  end

  # Method to parse a read section of an SFF file.
  def read_parse
    return nil if @number_of_reads == @count

    template = "nnNnnnn"

    read = Read.new()

    data = @io.read(16).unpack(template)

    read.read_header_length  = data[0]
    read.name_length         = data[1]
    read.number_of_bases     = data[2]
    read.clip_qual_left      = data[3]
    read.clip_qual_right     = data[4]
    read.clip_adapter_left   = data[5]
    read.clip_adaptor_right  = data[6]
    read.name                = @io.read(read.name_length).unpack("A*").join ""

    fast_forward

    @io.read(2 * @number_of_flows_per_read) # skip through flowgram_values
    @io.read(read.number_of_bases)          # skip through flow_index_per_base

    # NB! Parsing of flowgram_values and flow_index_per_base is currently disabled since these are not needed.
    # read.flowgram_values     = @io.read(2 * @number_of_flows_per_read).unpack("n*").map { |val| val = sprintf("%.2f", val * 0.01) }
    # flow_index_per_base      = @io.read(read.number_of_bases).unpack("C*")
    # (1 ... flow_index_per_base.length).each { |i| flow_index_per_base[i] += flow_index_per_base[i - 1] }
    # read.flow_index_per_base = flow_index_per_base

    read.bases               = @io.read(read.number_of_bases).unpack("A*").join ""
    read.quality_scores      = @io.read(read.number_of_bases).unpack("C*")

    fast_forward

    @count += 1

    read
  end

  # Method to check the magic number of an SFF file.
  # Raises an error if the magic number don't match.
  def check_magic_number
    raise SFFError, "Badly formatted SFF file." unless @magic_number == 779314790
  end

  # Method to check the version number of an SFF file.
  # Raises an error if the version don't match.
  def check_version
    raise SFFError, "Wrong version: #{@version}" unless @version.to_i == 1
  end

  # Method to check the header length of an SFF file.
  # Raises an error if the header length don't match
  # the file position after reading the header section.
  def check_header_length
    raise SFFError, "Bad header length: #{header_length}" unless @io.pos == @header_length
  end
end

# Class containing data accessor methods for an SFF entry and methods
# for manipulating this entry.
class Read
  attr_accessor :read_header_length, :name_length, :number_of_bases,   
    :clip_qual_left, :clip_qual_right, :clip_adapter_left, :clip_adaptor_right,
    :name, :flowgram_values, :flow_index_per_base, :bases, :quality_scores,
    :x_pos, :y_pos

  # Method that converts a Read object's data to a Biopiece record (a hash).
  def to_bp
    # Simulated SFF files may not have coordinates.
    begin
      coordinates_get
    rescue
    end

    hash = {}

    hash[:SEQ_NAME]           = self.name
    hash[:SEQ]                = self.bases
    hash[:SEQ_LEN]            = self.bases.length
    hash[:CLIP_QUAL_LEFT]     = self.clip_qual_left     - 1
    hash[:CLIP_QUAL_RIGHT]    = self.clip_qual_right    - 1
    hash[:CLIP_ADAPTOR_LEFT]  = self.clip_adapter_left  - 1
    hash[:CLIP_ADAPTOR_RIGHT] = self.clip_adaptor_right - 1
    hash[:SCORES]             = self.quality_scores.map { |i| (i += Seq::SCORE_BASE).chr }.join ""
    hash[:X_POS]              = self.x_pos
    hash[:Y_POS]              = self.y_pos

    hash
  end

  # Method that converts a Read object's data to a Seq object.
  def to_seq
    Seq.new(
      seq_name: self.name,
      seq: self.bases, 
      qual: self.quality_scores.map { |i| (i += Seq::SCORE_BASE).chr }.join("")
    )
  end

  # Method that soft masks the sequence (i.e. lowercases sequence) according to
  # clip_qual_left and clip_qual_right information.
  def mask
    left   = self.bases[0 ... self.clip_qual_left - 1].downcase
    middle = self.bases[self.clip_qual_left - 1 ... self.clip_qual_right]
    right  = self.bases[self.clip_qual_right ... self.bases.length].downcase

    self.bases = left + middle + right

    self
  end

  # Method that clips sequence (i.e. trims) according to
  # clip_qual_left and clip_qual_right information.
  def clip
    self.bases          = self.bases[self.clip_qual_left - 1 ... self.clip_qual_right]
    self.quality_scores = self.quality_scores[self.clip_qual_left - 1 ... self.clip_qual_right]

    self
  end

  private

  # Method that extracts the X/Y coordinates from
  # an SFF read name encoded with base36.
  def coordinates_get
    base36 = self.name[-5, 5]
    num    = Base36.decode(base36)

    self.x_pos = num >> BIT_SHIFT
    self.y_pos = num &  BIT_MASK
  end
end

__END__

