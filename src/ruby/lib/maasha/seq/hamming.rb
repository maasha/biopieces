# Copyright (C) 2013 Martin A. Hansen.

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
require 'maasha/seq/ambiguity'

# Class to calculate the Hamming distance between two
# given strings.
# http://en.wikipedia.org/wiki/Hamming_distance
class Hamming
  extend Ambiguity

  # Class method for calculating the Hamming distance between
  # two given strings allowing for IUPAC ambiguity codes.
  def self.distance(str1, str2)
    raise "string length mismatch: #{str1.length} != #{str2.length}" if str1.length != str2.length

    hd = self.new
    hd.hamming_distance_C(str1, str2, str1.length)
  end

  # >>>>>>>>>>>>>>> RubyInline C code <<<<<<<<<<<<<<<

  inline do |builder|
    add_ambiguity_macro(builder)

    # C method for calculating Hamming Distance.
    builder.c %{
      VALUE hamming_distance_C(
        VALUE _str1,   // String 1
        VALUE _str2,   // String 2
        VALUE _len     // String length
      )
      {
        char         *str1 = StringValuePtr(_str1);
        char         *str2 = StringValuePtr(_str2);
        unsigned int  len  = FIX2UINT(_len);

        unsigned int hamming_dist = 0;
        unsigned int i            = 0;

        for (i = 0; i < len; i++)
        {
          if (! MATCH(str1[i], str2[i]))
          {
            hamming_dist++;
          }
        }

        return UINT2NUM(hamming_dist);
      }
    }
  end
end

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
