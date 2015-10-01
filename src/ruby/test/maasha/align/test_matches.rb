#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# Copyright (C) 2012 Martin A. Hansen.

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
require 'maasha/align/matches'

class MatchesTest < Test::Unit::TestCase
  test "Matches.find with no match returns correctly" do
    assert_equal("[]", Matches.find("atcg", "atcg", 0, 0, 3, 3, 8).to_s)
  end

  test "Matches.find with one match returns correctly" do
    assert_equal(["q: 2 3 s: 0 1 l: 2 s: 0.0"], Matches.find("01cg", "cg23", 0, 0, 3, 3, 2).map(&:to_s))
    assert_equal(["q: 0 1 s: 2 3 l: 2 s: 0.0"], Matches.find("cg23", "01cg", 0, 0, 3, 3, 2).map(&:to_s))
  end

  test "Matches.find with two matches returns correctly" do
    assert_equal(["q: 0 1 s: 0 1 l: 2 s: 0.0", "q: 3 4 s: 3 4 l: 2 s: 0.0"], Matches.find("atXcg", "atYcg", 0, 0, 4, 4, 2).map(&:to_s))
    assert_equal(["q: 0 1 s: 0 1 l: 2 s: 0.0", "q: 3 4 s: 3 4 l: 2 s: 0.0"], Matches.find("atYcg", "atXcg", 0, 0, 4, 4, 2).map(&:to_s))
  end

  test "Matches.find dont expand match outside space" do
    assert_equal(["q: 1 2 s: 1 2 l: 2 s: 0.0"], Matches.find("atcg", "atcg", 1, 1, 2, 2, 2).map(&:to_s))
  end

  test "Matches.find right expands correctly" do
    assert_equal(["q: 0 3 s: 0 3 l: 4 s: 0.0"], Matches.find("atcg", "atcg", 0, 0, 3, 3, 3).map(&:to_s))
  end

#  test "Matches.find left expands correctly" do
#    flunk
#    assert_equal("[q: 1 2 s: 1 2 l: 2 s: 0.0]", Matches.find("ccccc", "cccc", 0, 0, 3, 3, 2).to_s)
#  end
end

