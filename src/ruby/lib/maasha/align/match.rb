# Copyright (C) 2007-2013 Martin A. Hansen.

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

# Class for describing a match between two sequences q and s.
class Match
  attr_accessor :q_beg, :s_beg, :length, :score

  def initialize(q_beg, s_beg, length)
    @q_beg  = q_beg
    @s_beg  = s_beg
    @length = length
    @score  = 0.0
  end

  def q_end
    @q_beg + @length - 1
  end

  def s_end
    @s_beg + @length - 1
  end

  # Method to expand a match as far as possible to the left and right
  # within a given search space.
  def expand(q_seq, s_seq, q_space_beg, s_space_beg, q_space_end, s_space_end)
    length = expand_left_C(q_seq, s_seq, @q_beg, @s_beg, q_space_beg, s_space_beg)
    @length += length
    @q_beg  -= length
    @s_beg  -= length

    length = expand_right_C(q_seq, s_seq, q_end, s_end, q_space_end, s_space_end)
    @length += length

    self
  end

  def to_s(seq = nil)
    s = "q: #{@q_beg} #{self.q_end} s: #{@s_beg} #{self.s_end} l: #{@length} s: #{@score}"
    s << " #{seq[@q_beg .. q_end]}" if seq

    s
  end

  private

  inline do |builder|
    # Method to expand a match as far as possible to the left within a given
    # search space.
    builder.c %{
      VALUE expand_left_C(
        VALUE _q_seq,
        VALUE _s_seq,
        VALUE _q_beg,
        VALUE _s_beg,
        VALUE _q_space_beg,
        VALUE _s_space_beg
      )
      {
        unsigned char *q_seq       = (unsigned char *) StringValuePtr(_q_seq);
        unsigned char *s_seq       = (unsigned char *) StringValuePtr(_s_seq);
        unsigned int   q_beg       = NUM2UINT(_q_beg);
        unsigned int   s_beg       = NUM2UINT(_s_beg);
        unsigned int   q_space_beg = NUM2UINT(_q_space_beg);
        unsigned int   s_space_beg = NUM2UINT(_s_space_beg);

        unsigned int   len = 0;

        while (q_beg > q_space_beg && s_beg > s_space_beg && q_seq[q_beg - 1] == s_seq[s_beg - 1])
        {
          q_beg--;
          s_beg--;
          len++;
        }

        return UINT2NUM(len);
      }
    }

    builder.c %{
      VALUE expand_right_C(
        VALUE _q_seq,
        VALUE _s_seq,
        VALUE _q_end,
        VALUE _s_end,
        VALUE _q_space_end,
        VALUE _s_space_end
      )
      {
        unsigned char *q_seq       = (unsigned char *) StringValuePtr(_q_seq);
        unsigned char *s_seq       = (unsigned char *) StringValuePtr(_s_seq);
        unsigned int   q_end       = NUM2UINT(_q_end);
        unsigned int   s_end       = NUM2UINT(_s_end);
        unsigned int   q_space_end = NUM2UINT(_q_space_end);
        unsigned int   s_space_end = NUM2UINT(_s_space_end);

        unsigned int   len = 0;
      
        while (q_end + 1 <= q_space_end && s_end + 1 <= s_space_end && q_seq[q_end + 1] == s_seq[s_end + 1])
        {
          q_end++;
          s_end++;
          len++;
        }

        return UINT2NUM(len);
      }
    }
  end
end
