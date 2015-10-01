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
require 'maasha/seq/backtrack'

include BackTrack

# Error class for all exceptions to do with Trim.
class TrimError < StandardError; end

# Module containing methods for end trimming sequences with suboptimal quality
# scores.
module Trim
  # Method to progressively trim a Seq object sequence from the right end until
  # a run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim_right(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    self[0, pos]
  end

  # Method to progressively trim a Seq object sequence from the right end until
  # a run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim_right!(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    self.seq  = self.seq[0, pos]
    self.qual = self.qual[0, pos] if self.qual

    self
  end

  # Method to progressively trim a Seq object sequence from the left end until
  # a run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim_left(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    self[pos .. -1]
  end

  # Method to progressively trim a Seq object sequence from the left end until
  # a run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim_left!(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    self.seq  = self.seq[pos .. -1]
    self.qual = self.qual[pos .. -1] if self.qual

    self
  end

  # Method to progressively trim a Seq object sequence from both ends until a
  # run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos_right = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)
    pos_left  = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    pos_left = pos_right if pos_left > pos_right

    self[pos_left ... pos_right]
  end

  # Method to progressively trim a Seq object sequence from both ends until a
  # run of min_len residues with quality scores above min_qual is encountered.
  def quality_trim!(min_qual, min_len = 1)
    check_trim_args(min_qual)

    pos_right = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)
    pos_left  = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

    pos_left = pos_right if pos_left > pos_right

    self.seq  = self.seq[pos_left ... pos_right]
    self.qual = self.qual[pos_left ... pos_right] if self.qual

    self
  end

  # Method to locate a pattern in a sequence and trim all sequence to the left
  # including the pattern.
  def patmatch_trim_left!(pattern, options = {})
    match = self.patmatch(pattern, options)

    if match
      stop = self.length

      self.seq  = self.seq[match.pos + match.length .. stop]
      self.qual = self.qual[match.pos + match.length .. stop] if self.qual

      return self
    end

    nil
  end

  # Method to locate a pattern in a sequence and trim all sequence to the right
  # including the pattern.
  def patmatch_trim_right!(pattern, options = {})
    match = self.patmatch(pattern, options)

    if match
      self.seq  = self.seq[0 ... match.pos]
      self.qual = self.qual[0 ... match.pos] if self.qual

      return self
    end

    nil
  end

  private

  # Method to check the arguments for trimming and raise on bad sequence, qualities,
  # and min_qual.
  def check_trim_args(min_qual)
    raise TrimError, "no sequence"      if self.seq.nil?
    raise TrimError, "no quality score" if self.qual.nil?
    unless (Seq::SCORE_MIN .. Seq::SCORE_MAX).include? min_qual
      raise TrimError, "minimum quality value: #{min_qual} out of range #{Seq::SCORE_MIN} .. #{Seq::SCORE_MAX}"
    end
  end

  # Inline C functions for speed below.
  inline do |builder|
    # Method for locating the right trim position and return this.
    builder.c %{
      VALUE trim_right_pos_c(
        VALUE _qual,        // quality score string
        VALUE _len,         // length of quality score string
        VALUE _min_qual,    // minimum quality score
        VALUE _min_len,     // minimum quality length
        VALUE _score_base   // score base
      )
      { 
        unsigned char *qual       = StringValuePtr(_qual);
        unsigned int   len        = FIX2UINT(_len);
        unsigned int   min_qual   = FIX2UINT(_min_qual);
        unsigned int   min_len    = FIX2UINT(_min_len);
        unsigned int   score_base = FIX2UINT(_score_base);

        unsigned int i = 0;
        unsigned int c = 0;

        while (i < len)
        {
          c = 0;

          while ((c < min_len) && ((c + i) < len) && (qual[len - (c + i) - 1] - score_base >= min_qual))
            c++;

          if (c == min_len)
            return UINT2NUM(len - i);
          else
            i += c;

          i++;
        }

        return UINT2NUM(0);
      }
    }

    # Method for locating the left trim position and return this.
    builder.c %{
      VALUE trim_left_pos_c(
        VALUE _qual,        // quality score string
        VALUE _len,         // length of quality score string
        VALUE _min_qual,    // minimum quality score
        VALUE _min_len,     // minimum quality length
        VALUE _score_base   // score base
      )
      { 
        unsigned char *qual       = StringValuePtr(_qual);
        unsigned int   len        = FIX2UINT(_len);
        unsigned int   min_qual   = FIX2UINT(_min_qual);
        unsigned int   min_len    = FIX2UINT(_min_len);
        unsigned int   score_base = FIX2UINT(_score_base);

        unsigned int i = 0;
        unsigned int c = 0;

        while (i < len)
        {
          c = 0;

          while ((c < min_len) && ((c + i) < len) && (qual[c + i] - score_base >= min_qual))
            c++;

          if (c == min_len)
            return UINT2NUM(i);
          else
            i += c;

          i++;
        }

        return UINT2NUM(i);
      }
    }
  end
end

__END__
