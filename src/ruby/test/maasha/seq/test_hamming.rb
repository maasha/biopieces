#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

require 'test/unit'
require 'test/helper'
require 'maasha/seq/hamming'

class HammingTest < Test::Unit::TestCase
  test "Hamming.distance returns 0 with identical strings" do
    assert_equal(0, Hamming.distance("atcg", "atcg"))
  end
  
  test "Hamming.distance with mismatch only returns correctly" do
    assert_equal(1, Hamming.distance("atcg", "atgg"))
  end

  test "Hamming.distance with ambiguity code returns correctly" do
    assert_equal(0, Hamming.distance("atcg", "nnnn"))
  end
end
