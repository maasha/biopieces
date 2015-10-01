#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

# Copyright (C) 2007-2010 Martin A. Hansen.

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


require 'maasha/bits'
require 'test/unit'
require 'test/helper'

class TestBits < Test::Unit::TestCase 
  test "#hamming_distance with uneven lengths raises" do
    assert_raise(StringError) { "ATCG".hamming_distance("A") }
  end

  test "#hamming_distance returns correctly" do
    assert_equal(0, "ATCG".hamming_distance("ATCG"))
    assert_equal(1, "ATCX".hamming_distance("ATCG"))
    assert_equal(2, "ATXX".hamming_distance("ATCG"))
    assert_equal(2, "ATcg".hamming_distance("ATCG"))
    assert_equal(3, "AXXX".hamming_distance("ATCG"))
    assert_equal(4, "XXXX".hamming_distance("ATCG"))
  end

  test "#& returns correctly" do
    assert_equal("ABCD", "abcd" & "____")
  end

  test "#| returns correctly" do
    assert_equal("abcd", "ab  " | "  cd")
  end

  test "#^ returns correctly" do
    assert_equal("ABCD", "ab  " ^ "  cd")
  end
end
