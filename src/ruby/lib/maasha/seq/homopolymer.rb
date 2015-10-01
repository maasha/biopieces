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


module Homopolymer
  # Error class for all exceptions to do with Homopolymer.
  class HomopolymerError < StandardError; end

  def each_homopolymer(min = 1)
    list = []

    self.seq.upcase.scan(/A{#{min},}|T{#{min},}|G{#{min},}|C{#{min},}|N{#{min},}/) do |match|
      hp = Homopolymer.new(match, match.length, $`.length)

      if block_given?
        yield hp
      else
        list << hp
      end
    end

    block_given? ? self : list
  end

  class Homopolymer
    attr_reader :pattern, :length, :pos

    def initialize(pattern, length, pos)
      @pattern = pattern
      @length  = length
      @pos     = pos
    end
  end
end
