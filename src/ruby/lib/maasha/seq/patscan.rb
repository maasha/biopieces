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

require 'maasha/filesys'
require 'open3'

# Module containing code to locate nucleotide patterns in sequences allowing for
# ambiguity codes and a given maximum mismatches, insertions, and deletions. The
# pattern match engine is based on scan_for_matches.
module Patscan
  # ------------------------------------------------------------------------------
  #   str.scan(pattern[, max_mismatches [, max_insertions [,max_deletions]]])
  #   -> Array
  #   str.scan(pattern[, max_mismatches [, max_insertions [,max_deletions]]]) { |match|
  #     block
  #   }
  #   -> Match
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence to locate pattern matches starting
  # allowing for a maximum number of mismatches, insertions, and deletions.
  # Matches found in block context return the Match object. Otherwise matches are
  # returned in an Array.
  def scan(pattern, max_mismatches = 0, max_insertions = 0, max_deletions = 0)
    @pattern = pattern + "[#{max_mismatches},#{max_insertions},#{max_deletions}]"
    matches  = []

    pattern_file = Filesys.tmpfile

    File.open(pattern_file, mode = 'w') do |ios|
      ios.puts @pattern
    end

    cmd = "scan_for_matches #{pattern_file}"

    Open3.popen3(cmd) do |stdin, stdout, stderr|
      #raise SeqError, "scan_for_matches failed: #{stderr.gets}" unless stderr.empty?

      stdin << ">dummy\n#{self.seq}\n"

      stdin.close

      while block = stdout.gets($/ + ">")
        if block =~ />dummy:\[(\d+),(\d+)\]\n(.+)/
          start  = $1.to_i
          stop   = $2.to_i
          match  = $3.delete(" ")
          length = stop - start

          if block_given?
            yield Match.new(start, length, match)
          else
            matches << Match.new(start, length, match)
          end
        end
      end
    end

    matches unless block_given?
  end

  class Match
    attr_reader :pos, :length, :match

    def initialize(pos, length, match)
      @pos    = pos
      @length = length
      @match  = match
    end
  end
end

__END__


# Eeeeiiiii - this one is slower than scan_for_matches!


# Module containing code to locate nucleotide patterns in sequences allowing for
# ambiguity codes and a given maximum edit distance. Pattern match engine is based
# on nrgrep.
module Patscan
  # ------------------------------------------------------------------------------
  #   str.scan(pattern[, max_edit_distance])
  #   -> Array
  #   str.scan(pattern[, max_edit_distance]) { |match|
  #     block
  #   }
  #   -> Match
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence to locate pattern matches starting
  # from a given position and allowing for a maximum edit distance.
  # Matches found in block context return the Match object. Otherwise matches are
  # returned in an Array.
  def scan(pattern, edit_distance = 0)
    @pattern = pattern.upcase
    matches  = []

    pattern_disambiguate

    cmd = "nrgrep_coords"
    cmd << " -i"
    cmd << " -k #{edit_distance}s" if edit_distance > 0
    cmd << " #{@pattern}"

    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << self.seq

      stdin.close

      stdout.each_line do |line| 
        if line =~ /\[(\d+), (\d+)\]: (.+)/
          start = $1.to_i
          stop  = $2.to_i
          match = $3
          length = stop - start

          if block_given?
            yield Match.new(start, length, match)
          else
            matches << Match.new(start, length, match)
          end
        end
      end
    end

    matches unless block_given?
  end

  private

  def pattern_disambiguate
    case self.type
    when :protein
      @pattern.gsub!('J', '[IFVLWMAGCY]')
      @pattern.gsub!('O', '[TSHEDQNKR]')
      @pattern.gsub!('B', '[DN]')
      @pattern.gsub!('Z', '[EQ]')
      @pattern.gsub!('X', '.')
    when :dna
      @pattern.gsub!('R', '[AG]')
      @pattern.gsub!('Y', '[CT]')
      @pattern.gsub!('S', '[GC]')
      @pattern.gsub!('W', '[AT]')
      @pattern.gsub!('M', '[AC]')
      @pattern.gsub!('K', '[GT]')
      @pattern.gsub!('V', '[ACG]')
      @pattern.gsub!('H', '[ACT]')
      @pattern.gsub!('D', '[AGT]')
      @pattern.gsub!('B', '[CGT]')
      @pattern.gsub!('N', '.')
    when :rna
    else
      raise SeqError "unknown sequence type: #{self.type}"
    end
  end

  class Match
    attr_reader :pos, :length, :match

    def initialize(pos, length, match)
      @pos    = pos
      @length = length
      @match  = match
    end
  end
end

