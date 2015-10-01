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

# Error class for all exceptions to do with Genbank/EMBL/DDBJ feature table locators.
class LocatorError < StandardError; end

# Class that handles Genbank/EMBL/DDBJ feature table locators.
class Locator
  attr_accessor :locator, :seq, :subseq

  # Method to initialize a locator object.
  def initialize(locator, seq)
    @locator = locator
    @seq     = seq
    @subseq  = Seq.new(seq: "", type: :dna)
    parse_locator(locator)
  end

  # Method that returns the strand (+ or - ) of the locator.
  def strand
    if @locator.match("complement")
      return "-"
    else
      return "+"
    end
  end

  # Method that returns the begin position of the locator (0-based).
  def s_beg
    if @locator =~ /(\d+)/
      return $1.to_i - 1
    end
  end

  # Method that returns the end position of the locator (0-based).
  def s_end
    if @locator.reverse =~ /(\d+)/
      return $1.reverse.to_i - 1
    end
  end

  private

  # Method that uses recursion to parse a locator string from a feature table
  # and fetches the appropriate subsequence. The operators join(), complement(),
  # and order() are handled. The locator string is broken into a comma separated
  # lists, and modified if the parens donnot balance. Otherwise the comma
  # separated list of ranges are stripped from operators, and the subsequence
  # are fetched and handled according to the operators. SNP locators are also 
  # dealt with (single positions).
  def parse_locator(locator, join = nil, comp = nil, order = nil)
    intervals = locator.split(",")

    unless balance_parens?(intervals.first)   # locator includes a join/comp/order of several ranges
      case locator
      when /^join\((.*)\)$/
        locator = $1
        join    = true
      when /^complement\((.*)\)$/
        locator = $1
        comp    = true
      when /^order\((.*)\)$/
        locator = $1
        order   = true
      end

      parse_locator(locator, join, comp, order)
    else
      intervals.each do |interval|
        case interval
        when /^join\((.*)\)$/
          locator = $1
          join    = true
          parse_locator(locator, join, comp, order)
        when /^complement\((.*)\)$/
          locator = $1
          comp    = true
          parse_locator(locator, join, comp, order)
        when /^order\((.*)\)$/
          locator = $1
          order   = true
          parse_locator(locator, join, comp, order)
        when /^[<>]?(\d+)[^\d]+(\d+)$/
          int_beg = $1.to_i - 1
          int_end = $2.to_i - 1

          newseq = Seq.new(seq: @seq.seq[int_beg..int_end], type: :dna)

					unless newseq.seq.nil?
						newseq.reverse!.complement! if comp

						@subseq.seq << (order ? " " + newseq.seq : newseq.seq)
					end
        when /^(\d+)$/
          pos = $1.to_i - 1

          newseq = Seq.new(seq: @seq.seq[pos], type: :dna)

					unless newseq.seq.nil?
          	newseq.reverse!.complement! if comp 

          	@subseq.seq << (order ? " " + newseq.seq : newseq.seq)
					end
        else
          $stderr.puts "WARNING: Could not match locator ->#{locator}<-";
          @subseq.seq << ""
        end
      end
    end

    return @subseq
  end

  # Method that checks if the parans in a locater string balances.
  def balance_parens?(locator)
    parens = 0

    locator.each_char do |char|
      case char
      when '(' then parens += 1
      when ')' then parens -= 1
      end
    end

    if parens == 0
      return true
    else
      return false
    end
  end
end


__END__

