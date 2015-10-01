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

require 'inline' # RubyInline
require 'maasha/seq/ambiguity'

# Error class for all exceptions to do with BackTrack.
class BackTrackError < StandardError; end

# Module containing code to locate nucleotide patterns in sequences allowing for
# ambiguity codes and a given maximum mismatches, insertions, and deletions. The
# pattern match engine is based on a backtrack algorithm.
# Insertions are nucleotides found in the pattern but not in the sequence.
# Deletions are nucleotides found in the sequence but not in the pattern.
# Algorithm based on code kindly provided by j_random_hacker @ Stackoverflow:
# http://stackoverflow.com/questions/7557017/approximate-string-matching-using-backtracking/
module BackTrack
  extend Ambiguity

  OK_PATTERN = Regexp.new('^[bflsycwphqrimtnkvadegu]+$')
  MAX_MIS    = 5 # Maximum number of mismatches allowed
  MAX_INS    = 5 # Maximum number of insertions allowed
  MAX_DEL    = 5 # Maximum number of deletions allowed

  # ------------------------------------------------------------------------------
  #   str.patmatch(pattern[, options])
  #   -> Match
  #   str.patmatch(pattern[, options]) { |match|
  #     block
  #   }
  #   -> Match
  #
  #   options:
  #     :start
  #     :stop
  #     :max_mismatches
  #     :max_insertions
  #     :max_deletions
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence from a given start position to the end of
  # the sequence or to a given stop position to locate a pattern allowing for a
  # maximum number of mismatches, insertions, and deletions. Insertions are
  # nucleotides found in the pattern but not in the sequence. Deletions are
  # nucleotides found in the sequence but not in the pattern.
  def patmatch(pattern, options = {})
    options[:start]          ||= 0
    options[:stop]           ||= self.length - 1
    options[:max_mismatches] ||= 0
    options[:max_insertions] ||= 0
    options[:max_deletions]  ||= 0

    self.patscan(pattern, options) do |m|
      if block_given?
        yield m
      else
        return m
      end

      break
    end

    if block_given?
      yield nil
    else
      return nil
    end
  end

  # ------------------------------------------------------------------------------
  #   str.patscan(pattern[, options])
  #   -> Array
  #   str.patscan(pattern[, options]) { |match|
  #     block
  #   }
  #   -> Match
  #
  #   options:
  #     :start
  #     :stop
  #     :max_mismatches
  #     :max_insertions
  #     :max_deletions
  #
  # ------------------------------------------------------------------------------
  # Method to iterate through a sequence from a given start position to the end of
  # the sequence or to a given stop position to locate a pattern allowing for a
  # maximum number of mismatches, insertions, and deletions. Insertions are
  # nucleotides found in the pattern but not in the sequence. Deletions are
  # nucleotides found in the sequence but not in the pattern. Matches found in
  # block context return the Match object. Otherwise matches are returned in an
  # Array of Match objects.
  def patscan(pattern, options = {})
    options[:start]          ||= 0
    options[:stop]           ||= self.length - 1
    options[:max_mismatches] ||= 0
    options[:max_insertions] ||= 0
    options[:max_deletions]  ||= 0

    raise BackTrackError, "Bad pattern: #{pattern}"                                          unless pattern.downcase =~ OK_PATTERN
    raise BackTrackError, "start: #{options[:start]} out of range (0 .. #{self.length - 1})"           unless (0 ... self.length).include? options[:start]
    raise BackTrackError, "stop: #{options[:stop]} out of range (0 .. #{self.length - 1})"             unless (0 ... self.length).include? options[:stop]
    raise BackTrackError, "max_mismatches: #{options[:max_mismatches]} out of range (0 .. #{MAX_MIS})" unless (0 .. MAX_MIS).include? options[:max_mismatches]
    raise BackTrackError, "max_insertions: #{options[:max_insertions]} out of range (0 .. #{MAX_INS})" unless (0 .. MAX_INS).include? options[:max_insertions]
    raise BackTrackError, "max_deletions: #{options[:max_deletions]} out of range (0 .. #{MAX_DEL})"   unless (0 .. MAX_DEL).include? options[:max_deletions]

    matches = []

    while result = scan_C(self.seq,
                          pattern,
                          options[:start],
                          options[:stop],
                          options[:max_mismatches],
                          options[:max_insertions],
                          options[:max_deletions]
                         )
      match = Match.new(result.first, result.last, self.seq[result.first ... result.first + result.last])

      if block_given?
        yield match
      else
        matches << match
      end

      options[:start] = result.first + 1
    end

    return matches unless block_given?
  end

  private

  inline do |builder|
    add_ambiguity_macro(builder)

    # Backtrack algorithm for matching a pattern (p) starting in a sequence (s) allowing for mis
    # mismatches, ins insertions and del deletions. ss is the start of the sequence, used only for
    # reporting the match endpoints. State is used to avoid ins followed by del and visa versa which
    # are nonsense.
    builder.prefix %{
      unsigned int backtrack(
        char         *ss,     // Sequence start
        char         *s,      // Sequence
        char         *p,      // Pattern
        unsigned int  mis,    // Max mismatches
        unsigned int  ins,    // Max insertions
        unsigned int  del,    // Max deletions
        int           state   // Last event: mis, ins or del
      )
      {
        unsigned int r = 0;

        while (*s && MATCH(*s, *p)) ++s, ++p;    // OK to always match longest segment

        if (!*p)
          return (unsigned int) (s - ss);
        else
        {
          if (mis && *s && *p &&            (r = backtrack(ss, s + 1, p + 1, mis - 1, ins, del, 0))) return r;
          if (ins && *p && (state != -1) && (r = backtrack(ss, s, p + 1, mis, ins - 1, del, 1)))     return r;
          if (del && *s && (state != 1)  && (r = backtrack(ss, s + 1, p, mis, ins, del - 1, -1)))    return r;
        }

        return 0;
      }
    }
 
    # Find pattern (p) in a sequence (s) starting at pos, with at most mis mismatches, ins
    # insertions and del deletions.
    builder.c %{
      VALUE scan_C(
        VALUE _s,       // Sequence
        VALUE _p,       // Pattern
        VALUE _start,   // Search postition start
        VALUE _stop,    // Search position stop
        VALUE _mis,     // Maximum mismatches
        VALUE _ins,     // Maximum insertions
        VALUE _del      // Maximum deletions
      )
      {
        char         *s     = StringValuePtr(_s);
        char         *p     = StringValuePtr(_p);
        unsigned int  start = FIX2UINT(_start);
        unsigned int  stop  = FIX2UINT(_stop);
        unsigned int  mis   = FIX2UINT(_mis);
        unsigned int  ins   = FIX2UINT(_ins);
        unsigned int  del   = FIX2UINT(_del);

        char         *ss    = s;
        int           state = 0;
        unsigned int  i     = 0;
        unsigned int  e     = 0;
        VALUE         tuple;

        s += start;

        for (i = start; i <= stop; i++, s++)
        {
          if ((e = backtrack(ss, s, p, mis, ins, del, state)))
          {
            tuple = rb_ary_new();
            rb_ary_push(tuple, INT2FIX((int) (s - ss)));
            rb_ary_push(tuple, INT2FIX((int) e - (s - ss)));
            return tuple;
          }
        }

        return Qnil;
      }
    }
  end

  # Class containing match information.
  class Match
    attr_reader :pos, :length, :match

    def initialize(pos, length, match)
      @pos    = pos
      @length = length
      @match  = match
    end

    def to_s
      "#{pos}:#{length}:#{match}"
    end
  end
end


__END__
