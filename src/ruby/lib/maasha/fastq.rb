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

require 'maasha/seq'
require 'maasha/filesys'

# Error class for all exceptions to do with FASTQ.
class FastqError < StandardError; end

# Class for parsing FASTQ entries from an ios and return as Seq objects.
class Fastq < Filesys
  # Method to get the next FASTQ entry from an ios and return this
  # as a Seq object. If no entry is found or eof then nil is returned.
  def get_entry
    seq_name       = @io.gets.chomp!
    seq            = @io.gets.chomp!
    @io.gets
    qual           = @io.gets.chomp!

    entry          = Seq.new
    entry.seq      = seq
    entry.seq_name = seq_name[1 .. seq_name.length]
    entry.qual     = qual
    entry.type     = nil

    entry
  rescue
    nil
  end
end

# Class for indesing FASTQ entries. The index will be
# a hash with the FASTQ sequence name as key and a 
# FastqElem as value. The latter contains info on
# byte offset and length for each entry.
class FastqIndex
  HEADCHAR = 1
  NEWLINE  = 1

  attr_accessor :ios

  # Method to initialize a FastqIndex object. For reading
  # entries from file an _ios_ object must be supplied.
  def initialize(ios = nil)
    @ios    = ios
    @index  = {}
    @offset = 0
  end

  # Method to add a Fastq entry to a FastqIndex.
  def add(entry, orig_name)
    offset_seq  = @offset + HEADCHAR + entry.seq_name.length + NEWLINE
    offset_qual = @offset + HEADCHAR + entry.seq_name.length + NEWLINE + entry.length + NEWLINE + HEADCHAR + NEWLINE

    @index[entry.seq_name] = FastqElem.new(offset_seq, offset_qual, entry.length, orig_name)

    @offset += HEADCHAR + entry.seq_name.length + NEWLINE + entry.length + NEWLINE + HEADCHAR + NEWLINE + entry.length + NEWLINE
  end

  # Method to read from file a Fastq entry from an indexed position,
  # and return the entry as a Seq object.
  def get(seq_name)
    raise FastqError, "Sequence name: #{seq_name} not found in index." unless @index[seq_name]

    elem = @index[seq_name]
    @ios.sysseek(elem.offset_seq)
    seq = @ios.sysread(elem.length)
    @ios.sysseek(elem.offset_qual)
    qual = @ios.sysread(elem.length)

    Seq.new(seq_name: elem.seq_name, seq: seq, qual: qual)
  end

  private

  # Class for storing index information to be used
  # with disk based index.
  class FastqElem
    attr_reader :offset_seq, :offset_qual, :length, :seq_name

    def initialize(offset_seq, offset_qual, length, seq_name)
      @offset_seq  = offset_seq
      @offset_qual = offset_qual
      @length      = length
      @seq_name    = seq_name
    end
  end
end


__END__
