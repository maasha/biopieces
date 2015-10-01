# Copyright (C) 2007-2012 Martin A. Hansen.

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


module Math
  # Class method to calculate the distance from at point to a line.
  # The point and line are given as pairs of coordinates.
  def self.dist_point2line(
    px,  # point  x coordinate
    py,  # point  y coordinate
    x1,  # line 1 x coordinate
    y1,  # line 1 y coordinate
    x2,  # line 2 x coordinate
    y2   # line 2 y coordinate
  )

    a = (y2 - y1).to_f / (x2 - x1).to_f
    b = y1 - a * x1

    (a * px + b - py).abs / Math.sqrt(a ** 2 + 1)
  end


  # Class method to calculate the distance between two points given
  # as pairs of coordinates.
  def self.dist_point2point(x1, y1, x2, y2)
    Math.sqrt((x2.to_f - x1.to_f) ** 2 + (y2.to_f - y1.to_f) ** 2)
  end
end
