# Copyright (C) 2011 Martin A. Hansen.

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

# Error class for all exceptions to do with Base36.
class Base36Error < StandardError; end

ALPH   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
BASE36 = 36

# Class containing methods to encode and decode Base 36.
# Note that the ALPH is [alph + num] and not [num + alph]
# which prevents us from simply using .to_i(36) and .to_s(36).
#
# http://en.wikipedia.org/wiki/Base_36
class Base36
  # Method that encodes an integer into a base36 string
  # that is returned.
  def self.encode(num)
    raise Base36Error unless num.is_a? Fixnum

    base36 = ""

    while num > 0
      base36 << ALPH[(num % BASE36)]
      num /= BASE36
    end

    base36 << ALPH[0] if num == 0

    base36.reverse
  end

  # Method that decodes a base36 string and returns an integer.
  def self.decode(base36)
    raise Base36Error if base36.empty?

    result = 0
    pos    = 0

    base36.upcase.reverse.each_char do |char|
      result += ALPH.index(char) * (BASE36 ** pos)
      pos    += 1
    end

    return result;
  end
end

__END__
