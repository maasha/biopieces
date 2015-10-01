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

# Error class for all exceptions to do with Digest.
class DigestError < StandardError; end

module Digest
  # Method to get the next digestion product from a sequence.
  def each_digest(pattern, cut_pos)
    pattern = disambiguate(pattern)
    results = []
    offset  = 0

    self.seq.upcase.scan pattern do
      pos = $`.length + cut_pos 

      if pos >= 0 and pos < self.length - 2
        subseq = self[offset .. pos - 1]
        subseq.seq_name = "#{self.seq_name}[#{offset}-#{pos - offset - 1}]"

        block_given? ? (yield subseq) : (results << subseq)
      end

      offset = pos 
    end

    if offset < 0 or offset > self.length
      offset = 0
    end

    subseq = self[offset .. -1]
    subseq.seq_name = "#{self.seq_name}[#{offset}-#{self.length - 1}]"

    block_given? ? (yield subseq) : (results << subseq)

    return results unless block_given?
  end

  private

  # Method that returns a regexp object with a restriction
  # enzyme pattern with ambiguity codes substituted to the
  # appropriate regexp.
  def disambiguate(pattern)
    ambiguity = {
      'A' => "A",
      'T' => "T",
      'U' => "T",
      'C' => "C",
      'G' => "G",
      'M' => "[AC]",
      'R' => "[AG]",
      'W' => "[AT]",
      'S' => "[CG]",
      'Y' => "[CT]",
      'K' => "[GT]",
      'V' => "[ACG]",
      'H' => "[ACT]",
      'D' => "[AGT]",
      'B' => "[CGT]",
      'N' => "[GATC]"
    }

    new_pattern = ""

    pattern.upcase.each_char do |char|
      if ambiguity[char]
        new_pattern << ambiguity[char]
      else
        raise DigestError, "Could not disambiguate residue: #{char}"
      end
    end

    Regexp.new(new_pattern)
  end
end
