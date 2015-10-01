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

require 'inline'

# Module containing code to locate nucleotide patterns in sequences allowing for
# ambiguity codes and a given maximum edit distance.
# Insertions are nucleotides found in the pattern but not in the sequence.
# Deletions are nucleotides found in the sequence but not in the pattern.
#
# Inspired by the paper by Bruno Woltzenlogel Paleo (page 197):
# http://www.logic.at/people/bruno/Papers/2007-GATE-ESSLLI.pdf
module Dynamic
  # ------------------------------------------------------------------------------
  #   str.patmatch(pattern[, pos[, max_edit_distance]])
  #   -> Match or nil
  #   str.patscan(pattern[, pos[, max_edit_distance]]) { |match|
  #     block
  #   }
  #   -> Match
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence to locate the first pattern match
  # starting from a given position and allowing for a maximum edit distance.
  def patmatch(pattern, pos = 0, max_edit_distance = 0)
    self.patscan(pattern, pos, max_edit_distance) do |m|
      return m
    end
  end

  # ------------------------------------------------------------------------------
  #   str.patscan(pattern[, pos[, max_edit_distance]])
  #   -> Array or nil
  #   str.patscan(pattern[, pos[, max_edit_distance]]) { |match|
  #     block
  #   }
  #   -> Match
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence to locate pattern matches starting from a
  # given position and allowing for a maximum edit distance. Matches found in
  # block context return the Match object. Otherwise matches are returned in an
  # Array.
  def patscan(pattern, pos = 0, max_edit_distance = 0)
    matches = []

    while result = match_C(self.seq, self.length, pattern, pattern.length, pos, max_edit_distance)
      match = Match.new(*result, self.seq[result[0] ... result[0] + result[1]]);

      if block_given?
        yield match
      else
        matches << match
      end

      pos = match.beg + 1
    end

    return matches unless block_given?
  end

  private

  inline do |builder|
    # Macro for matching nucleotides including ambiguity codes.
    builder.prefix %{
      #define MAX_PAT 1024
    }

    builder.prefix %{
      #define MATCH(A,B) ((bitmap[A] & bitmap[B]) != 0)
    }

    builder.prefix %{
      typedef struct 
      {
        unsigned int mis;
        unsigned int ins;
        unsigned int del;
        unsigned int ed;
      } score;
    }

    # Bitmap for matching nucleotides including ambiguity codes.
    # For each value bits are set from the left: bit pos 1 for A,
    # bit pos 2 for T, bit pos 3 for C, and bit pos 4 for G.
    builder.prefix %{
      char bitmap[256] = {
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 1,14, 4,11, 0, 0, 8, 7, 0, 0,10, 0, 5,15, 0,
          0, 0, 9,12, 2, 2,13, 3, 0, 6, 0, 0, 0, 0, 0, 0,
          0, 1,14, 4,11, 0, 0, 8, 7, 0, 0,10, 0, 5,15, 0,
          0, 0, 9,12, 2, 2,13, 3, 0, 6, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      };
    }

    builder.prefix %{
      void vector_init(score *vec, unsigned int vec_len)
      {
        unsigned int i = 0;

        for (i = 1; i < vec_len; i++)
        {
          vec[i].ins = i;
          vec[i].ed  = i;
        }
      }
    }

    builder.prefix %{
      void vector_print(score *vec, unsigned int vec_len)
      {
        unsigned int i = 0;

        for (i = 0; i < vec_len; i++)
        {
          printf("i: %d   mis: %d   ins: %d   del: %d   ed: %d\\n", i, vec[i].mis, vec[i].ins, vec[i].del, vec[i].ed);
        }

        printf("---\\n");
      }
    }

    builder.prefix %{
      int match_found(score *vec, unsigned int pat_len, unsigned int max_ed)
      {
        return (vec[pat_len].ed <= max_ed);
      }
    }

    builder.prefix %{
      void vector_update(score *vec, char *seq, char *pat, unsigned int pat_len, unsigned int pos)
      {
        score diag = vec[0];
        score up   = {0, 0, 0, 0};   // insertion
        score left = vec[1];            // deletion
        score new  = {0, 0, 0, 0};

        unsigned int i = 0;

        for (i = 0; i < pat_len; i++)
        {
          if (MATCH(seq[pos], pat[i]))                        // match
          {
            new = diag;
          }
          else
          {
            if (left.ed <= diag.ed && left.ed <= up.ed)       // deletion
            {
              new = left;
              new.del++;
            }
            else if (diag.ed <= up.ed && diag.ed <= left.ed)   // mismatch
            {
              new = diag;
              new.mis++;
            }
            else if (up.ed <= diag.ed && up.ed <= left.ed)      // insertion
            {
              new = up;
              new.ins++;
            }
            else
            {
              printf("This should not happen\\n");
              exit(1);
            }

            new.ed++;
          }

          diag = vec[i + 1];
          up   = new;
          left = vec[i + 2];

          vec[i + 1] = new;
        }
      }
    }

    builder.c %{
      VALUE match_C(
        VALUE _seq,       // Sequence
        VALUE _seq_len,   // Sequence length
        VALUE _pat,       // Pattern
        VALUE _pat_len,   // Pattern length
        VALUE _pos,       // Offset position
        VALUE _max_ed     // Maximum edit distance
      )
      {
        char         *seq     = (char *) StringValuePtr(_seq);
        char         *pat     = (char *) StringValuePtr(_pat);
        unsigned int  seq_len = FIX2UINT(_seq_len);
        unsigned int  pat_len = FIX2UINT(_pat_len);
        unsigned int  pos     = FIX2UINT(_pos);
        unsigned int  max_ed  = FIX2UINT(_max_ed);
        
        score         vec[MAX_PAT] = {0};
        unsigned int  vec_len      = pat_len + 1;
        unsigned int  match_beg    = 0;
        unsigned int  match_len    = 0;

        VALUE         match_ary;

        vector_init(vec, vec_len);

        while (pos < seq_len)
        {
          vector_update(vec, seq, pat, pat_len, pos);

          if (match_found(vec, pat_len, max_ed))
          {
            match_len = pat_len - vec[pat_len].ins + vec[pat_len].del;
            match_beg = pos - match_len + 1;

            match_ary = rb_ary_new();
            rb_ary_push(match_ary, INT2FIX(match_beg));
            rb_ary_push(match_ary, INT2FIX(match_len));
            rb_ary_push(match_ary, INT2FIX(vec[pat_len].mis));
            rb_ary_push(match_ary, INT2FIX(vec[pat_len].ins));
            rb_ary_push(match_ary, INT2FIX(vec[pat_len].del));

            return match_ary;
          }

          pos++;
        }

        return Qfalse;  // no match
      }
    }
  end

  class Match
    attr_accessor :beg, :length, :mis, :ins, :del, :match

    def initialize(beg, length, mis, ins, del, match)
      @beg    = beg
      @length = length
      @mis    = mis
      @ins    = ins
      @del    = del
      @match  = match
    end
  end
end


__END__
