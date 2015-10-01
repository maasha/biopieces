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

require 'maasha/align/matches'
require 'maasha/math_aux'

FACTOR_SCORE_LENGTH =  1.0
FACTOR_SCORE_DIAG   = -1.41
KMER                = 32

# Module with stuff to create a pairwise aligment.
module PairAlign
  # Class for creating a pairwise alignment.
  class AlignPair
    # Class method to create a pairwise alignment of two given Seq objects.
    def self.align(q_entry, s_entry)
      self.new(q_entry, s_entry)
    end

    # Method to inialize a pairwise alignment given two Seq objects.
    def initialize(q_entry, s_entry)
      @q_entry = q_entry
      @s_entry = s_entry
      @matches = []

      @q_entry.seq.downcase!
      @s_entry.seq.downcase!

      space = Space.new(0, 0, @q_entry.length - 1, @s_entry.length - 1)

      align_recurse(@q_entry.seq, @s_entry.seq, space, KMER)
      matches_upcase
      gaps_insert
    end

    private

    # Method that creates an alignment by chaining matches, which are
    # subsequences shared between two sequences. This recursive method
    # functions by considering only matches within a given search space. If no
    # matches are given these will be located and matches will be included
    # depending on a calculated score. New search spaces spanning the spaces
    # between the best scoring matches and the search space boundaries will be
    # cast and recursed into.
    def align_recurse(q_seq, s_seq, space, kmer, matches = [])
      matches = matches_select_by_space(matches, space)
      matches = matches_select_by_score(matches, space)

      while (matches.size == 0 and kmer > 0)
        matches = Matches.find(q_seq, s_seq, space.q_min, space.s_min, space.q_max, space.s_max, kmer)
        #matches = Mem.find(q_seq, s_seq, kmer, space.q_min, space.s_min, space.q_max, space.s_max)

        if @matches.empty?
          matches.sort_by! { |m| m.length }
        else
          matches = matches_select_by_score(matches, space)
        end

        kmer /= 2
      end

      if best_match = matches.pop
        @matches << best_match

        space_left  = Space.new(space.q_min, space.s_min, best_match.q_beg - 1, best_match.s_beg - 1)
        space_right = Space.new(best_match.q_end + 1, best_match.s_end + 1, space.q_max, space.s_max)

        align_recurse(q_seq, s_seq, space_left, kmer, matches)  unless space_left.empty?
        align_recurse(q_seq, s_seq, space_right, kmer, matches) unless space_right.empty?
      end
    end

    # Method to select matches that lies within the search space.
    def matches_select_by_space(matches, space)
      new_matches = matches.select do |match|
        match.q_beg >= space.q_min and
        match.s_beg >= space.s_min and
        match.q_end <= space.q_max and
        match.s_end <= space.s_max
      end

      new_matches
    end

    # Method to select matches based on score.
    def matches_select_by_score(matches, space)
      matches_score(matches, space)

      matches.select { |match| match.score > 0 }
    end

    def matches_score(matches, space)
      matches.each do |match|
        score_length = match_score_length(match)
        score_diag   = match_score_diag(match, space)

        match.score = score_length + score_diag
      end

      matches.sort_by! { |match| match.score }
    end

    def match_score_length(match)
      match.length * FACTOR_SCORE_LENGTH
    end

    def match_score_diag(match, space)
      if space.q_dim > space.s_dim   # s_dim is the narrow end
        dist_beg = Math.dist_point2line(match.q_beg,
                                        match.s_beg,
                                        space.q_min,
                                        space.s_min,
                                        space.q_min + space.s_dim,
                                        space.s_min + space.s_dim)

        dist_end = Math.dist_point2line( match.q_beg,
                                         match.s_beg,
                                         space.q_max - space.s_dim,
                                         space.s_max - space.s_dim,
                                         space.q_max,
                                         space.s_max)
      else
        dist_beg = Math.dist_point2line( match.q_beg,
                                         match.s_beg,
                                         space.q_min,
                                         space.s_min,
                                         space.q_min + space.q_dim,
                                         space.s_min + space.q_dim)

        dist_end = Math.dist_point2line( match.q_beg,
                                         match.s_beg,
                                         space.q_max - space.q_dim,
                                         space.s_max - space.q_dim,
                                         space.q_max,
                                         space.s_max)
      end

      dist_min = dist_beg < dist_end ? dist_beg : dist_end

      dist_min * FACTOR_SCORE_DIAG
    end

    # Method for debugging purposes that upcase matching sequence while non-matches
    # sequence is kept in lower case.
    def matches_upcase
      @matches.each do |match|
        @q_entry.seq[match.q_beg .. match.q_end] = @q_entry.seq[match.q_beg .. match.q_end].upcase
        @s_entry.seq[match.s_beg .. match.s_end] = @s_entry.seq[match.s_beg .. match.s_end].upcase
      end
    end

    # Method that insert gaps in sequences based on a list of matches and thus
    # creating an alignment.
    def gaps_insert
      @matches.sort_by! { |m| m.q_beg }

      q_gaps = 0
      s_gaps = 0

      match = @matches.first
      diff  = (q_gaps + match.q_beg) - (s_gaps + match.s_beg)

      if diff < 0
        @q_entry.seq.insert(0, "-" * diff.abs)
        q_gaps += diff.abs
      elsif diff > 0
        @s_entry.seq.insert(0, "-" * diff.abs)
        s_gaps += diff.abs
      end

      @matches[1 .. -1].each do |m|
        diff = (q_gaps + m.q_beg) - (s_gaps + m.s_beg)

        if diff < 0
          @q_entry.seq.insert(m.q_beg + q_gaps, "-" * diff.abs)
          q_gaps += diff.abs
        elsif diff > 0
          @s_entry.seq.insert(m.s_beg + s_gaps, "-" * diff.abs)
          s_gaps += diff.abs
        end
      end

      diff = @q_entry.length - @s_entry.length

      if diff < 0
        @q_entry.seq << ("-" * diff.abs)
      else
        @s_entry.seq << ("-" * diff.abs)
      end
    end
  end

  # Class for containing a search space between two sequences q and s.
  class Space
    attr_reader :q_min, :s_min, :q_max, :s_max

    def initialize(q_min, s_min, q_max, s_max)
      @q_min = q_min
      @s_min = s_min
      @q_max = q_max
      @s_max = s_max
    end

    def q_dim
      @q_max - @q_min + 1
    end

    def s_dim
      @s_max - @s_min + 1
    end

    def empty?
      if @q_max - @q_min >= 0 and @s_max - @s_min >= 0
        return false
      end

      true
    end
  end
end

