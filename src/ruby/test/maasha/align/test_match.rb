#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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
require 'maasha/align/match'

class MatchTest < Test::Unit::TestCase
  def setup
    @match = Match.new(1, 1, 3)
  end

  test "#q_end returns correctly" do
    assert_equal(3, @match.q_end)
  end

  test "#s_end returns correctly" do
    assert_equal(3, @match.s_end)
  end

  test "#to_s returns correctly" do
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0",     @match.to_s)
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0 tcg", @match.to_s("atcg"))
  end

  test "#expand to left end returns correctly" do
    assert_equal("q: 0 3 s: 0 3 l: 4 s: 0.0", @match.expand("atcg", "atcg", 0, 0, 3, 3).to_s)
  end

  test "#expand to left mismatch returns correctly" do
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0", @match.expand("gtcg", "atcg", 0, 0, 3, 3).to_s)
  end

  test "#expand to left space beg returns correctly" do
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0", @match.expand("atcg", "atcg", 1, 1, 3, 3).to_s)
  end

  test "#expand to right end returns correctly" do
    assert_equal("q: 0 4 s: 0 4 l: 5 s: 0.0", @match.expand("atcga", "atcga", 0, 0, 4, 4).to_s)
  end

  test "#expand to right mismatch returns correctly" do
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0", @match.expand("gtcga", "atcgg", 0, 0, 4, 4).to_s)
  end

  test "#expand to right space end returns correctly" do
    assert_equal("q: 1 3 s: 1 3 l: 3 s: 0.0", @match.expand("atcga", "atcga", 1, 1, 3, 3).to_s)
  end
end

