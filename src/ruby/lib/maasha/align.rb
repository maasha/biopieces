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

require 'pp'
require 'open3'
require 'narray'
require 'maasha/align/pair'
require 'maasha/fasta'

class AlignError < StandardError; end;

class Fasta
  def initialize(io)
    @io = io
  end

  def close
    @io.close
  end
end

# Class for aligning sequences.
class Align
  attr_accessor :options
  attr_reader   :entries

  include Enumerable
  include PairAlign

  # Class method to align sequences in a list of Seq objects and
  # return these as a new list of Seq objects.
  def self.muscle(entries, verbose = false)
    result   = []
    index    = {}

    Open3.popen3("muscle", "-quiet") do |stdin, stdout, stderr|
      entries.each do |entry|
        raise AlignError, "Duplicate sequence name: #{entry.seq_name}" if index[entry.seq_name]

        index[entry.seq_name] = entry.dup

        stdin.puts entry.to_fasta
      end

      stdin.close

      stderr.each_line { |line| $stderr.puts line } if verbose

      aligned_entries = Fasta.new(stdout)

      aligned_entries.each do |fa_entry|
        fq_entry = index[fa_entry.seq_name]

        fa_entry.seq.scan(/-+/) do |m|
          fq_entry.seq  = fq_entry.seq[0 ... $`.length]  + ('-' * m.length) + fq_entry.seq[$`.length .. -1]
          fq_entry.qual = fq_entry.qual[0 ... $`.length] + ('@' * m.length) + fq_entry.qual[$`.length .. -1] unless fq_entry.qual.nil?
        end

        result << fq_entry
      end
    end

    self.new(result)
  end
  
  # Class method to create a pairwise alignment of two given Seq objects. The
  # alignment is created by casting a search space the size of the sequences
  # and save the best scoring match between the sequences and recurse into
  # the left and right search spaced around this match. When all search spaces
  # are exhausted the saved matches are used to insert gaps in the sequences.
  def self.pair(q_entry, s_entry)
    AlignPair.align(q_entry, s_entry)

    self.new([q_entry, s_entry])
  end

  # Method to initialize an Align object with a list of aligned Seq objects.
  def initialize(entries, options = {})
    @entries = entries
    @options = options
  end

  # Method that returns the length of the alignment.
  def length
    @entries.first.length
  end

  # Method that returns the number of members or sequences in the alignment.
  def members
    @entries.size
  end

  # Method that returns the identity of an alignment with two members.
  def identity
    if self.members != 2
      raise AlignError "Bad number of members for similarity calculation: #{self.members}"
    end

    na1 = NArray.to_na(@entries[0].seq.upcase, "byte")
    na2 = NArray.to_na(@entries[1].seq.upcase, "byte")

    shared   = (na1 - na2).count_false
    total    = (@entries[0].length < @entries[1].length) ? @entries[0].length : @entries[1].length
    identity = shared.to_f / total

    identity
  end

  # Method for iterating each of the aligned sequences.
  def each
    if block_given?
      @entries.each { |entry| yield entry }
    else
      return @entries
    end
  end

  def to_s
    align = ""

    self.each do |entry|
      align << entry.seq_name  + "\t" + entry.seq + $/
    end

    align << $/

    align
  end
end

__END__
