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

require 'maasha/align/match'

# Class containing methods for located all non-redundant Maximally Extended Matches (MEMs)
# between two strings.
class Matches
  # Class method to located all non-redudant MEMs bewteen two sequences within a given
  # search space and seeded with kmers of a given size.
  def self.find(q_seq, s_seq, q_min, s_min, q_max, s_max, kmer)
    m = self.new
    m.matches_find(q_seq, s_seq, q_min, s_min, q_max, s_max, kmer)
  end

  # Method that finds all maximally expanded non-redundant matches shared
  # between two sequences inside a given search space.
  def matches_find(q_seq, s_seq, q_min, s_min, q_max, s_max, kmer)
    matches   = []
    redundant = {}

    s_index = index_seq(s_seq, s_min, s_max, kmer)

    q_pos = q_min

    while q_pos <= q_max - kmer + 1
      q_oligo = q_seq[q_pos ... q_pos + kmer]

      s_index[q_oligo].each do |s_pos|
        match = Match.new(q_pos, s_pos, kmer)
        
        unless redundant[match.q_beg * 1_000_000_000 + match.s_beg]
          match.expand(q_seq, s_seq, q_min, s_min, q_max, s_max)
          matches << match

          (0 ... match.length).each do |j|
            redundant[(match.q_beg + j) * 1_000_000_000 + match.s_beg + j] = true
          end
        end
      end

      q_pos += 1
    end

    matches
  end

  # Method that indexes a sequence within a given interval such that the
  # index contains all oligos of a given kmer size and the positions where
  # this oligo was located.
  def index_seq(seq, min, max, kmer, step = 1)
    index_hash = Hash.new { |h, k| h[k] = [] }

    pos = min

    while pos <= max - kmer + 1
      oligo = seq[pos ... pos + kmer]
      index_hash[oligo] << pos

      pos += step
    end

    index_hash
  end
end
