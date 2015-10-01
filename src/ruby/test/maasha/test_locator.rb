#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

require 'maasha/seq'
require 'maasha/locator'
require 'test/unit'
require 'test/helper'

class TestLocator < Test::Unit::TestCase 
  def setup
    @seq = Seq.new(seq: "tcatgatcaagatctaacagcagaagtacacttctattta", type: :dna)
  end

  test "#new with single position returns correctly" do
    loc = Locator.new("10", @seq)
    assert_equal("a", loc.subseq.seq)
  end

  test "#new with single interval returns correctly" do
    loc = Locator.new("5..10", @seq)
    assert_equal("gatcaa", loc.subseq.seq)
  end

  test "#new with multiple intervals return correctly" do
    loc = Locator.new("5..10,15..20", @seq)
    assert_equal("gatcaataacag", loc.subseq.seq)
  end

  test "#new with join multiple intervals return correctly" do
    loc = Locator.new("join(5..10,15..20)", @seq)
    assert_equal("gatcaataacag", loc.subseq.seq)
  end

  test "#new with complement and single interval return correctly" do
    loc = Locator.new("complement(5..10)", @seq)
    assert_equal("ttgatc", loc.subseq.seq)
  end
end

