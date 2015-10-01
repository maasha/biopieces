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

require 'narray'

# Error class for all exceptions to do with String.
class StringError < StandardError; end

# Monkey patching Class String to add bitwise operators.
class String
  # Method to that returns the case senstive Hamming Distance between two strings.
  # http://en.wikipedia.org/wiki/Hamming_distance
  def hamming_distance(str)
    (self ^ str).tr("\x00",'').length
  end

  # Method that performs bitwise AND operation where bits
  # are copied if they exists in BOTH operands.
  def &(str)
    narray1, narray2 = to_narray(self, str)

    (narray1 & narray2).to_s
  end

  # Method that performs bitwise OR operation where bits
  # are copied if they exists in EITHER operands.
  def |(str)
    narray1, narray2 = to_narray(self, str)

    (narray1 | narray2).to_s
  end

  # Method that performs bitwise XOR operation where bits
  # are copied if they exists in ONE BUT NOT BOTH operands.
  def ^(str)
    narray1, narray2 = to_narray(self, str)

    (narray1 ^ narray2).to_s
  end

  private

  def to_narray(str1, str2)
    if str1.length != str2.length
      raise StringError, "Uneven string lengths: #{str1.length} != #{str2.length}"
    end

    narray1 = NArray.to_na(str1, "byte")
    narray2 = NArray.to_na(str2, "byte")

    [narray1, narray2]
  end
end
