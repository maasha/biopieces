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

# Class to calculate the Levenshtein distance between two
# given strings.
# http://en.wikipedia.org/wiki/Levenshtein_distance
class Levenshtein
  extend Ambiguity

  BYTES_IN_INT = 4

  def self.distance(s, t)
    return 0        if s == t;
    return t.length if s.length == 0;
    return s.length if t.length == 0;

    v0 = "\0" * (t.length + 1) * BYTES_IN_INT
    v1 = "\0" * (t.length + 1) * BYTES_IN_INT

    l = self.new
    l.levenshtein_distance_C(s, t, s.length, t.length, v0, v1)
  end

  # >>>>>>>>>>>>>>> RubyInline C code <<<<<<<<<<<<<<<

  inline do |builder|
    add_ambiguity_macro(builder)

    builder.prefix %{
      unsigned int min(unsigned int a, unsigned int b, unsigned int c)
      {
          unsigned int m = a;

          if (m > b) m = b;
          if (m > c) m = c;

          return m;
      }
    }

    builder.c %{
      VALUE levenshtein_distance_C(
        VALUE _s,       // string
        VALUE _t,       // string
        VALUE _s_len,   // string length
        VALUE _t_len,   // string length
        VALUE _v0,      // score vector
        VALUE _v1       // score vector
      )
      {
        char         *s     = (char *) StringValuePtr(_s);
        char         *t     = (char *) StringValuePtr(_t);
        unsigned int  s_len = FIX2UINT(_s_len);
        unsigned int  t_len = FIX2UINT(_t_len);
        unsigned int  *v0   = (unsigned int *) StringValuePtr(_v0);
        unsigned int  *v1   = (unsigned int *) StringValuePtr(_v1);

        unsigned int i    = 0;
        unsigned int j    = 0;
        unsigned int cost = 0;
       
        for (i = 0; i < t_len + 1; i++)
          v0[i] = i;
       
        for (i = 0; i < s_len; i++)
        {
          v1[0] = i + 1;
       
          for (j = 0; j < t_len; j++)
          {
            cost = (MATCH(s[i], t[j])) ? 0 : 1;
            v1[j + 1] = min(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
          }
       
          for (j = 0; j < t_len + 1; j++)
            v0[j] = v1[j];
        }
       
        return UINT2NUM(v1[t_len]);
      }
    }
  end
end

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
