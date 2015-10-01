#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

require 'test/unit'
require 'test/helper'
require 'maasha/cigar'

class CigarTest < Test::Unit::TestCase
  test "Cigar.new with bad cigar raises" do
    assert_raise(CigarError) { Cigar.new("@") }
    assert_raise(CigarError) { Cigar.new("1M1H1M") }
    assert_raise(CigarError) { Cigar.new("1M1S1M") }
  end

  test "Cigar.new with ok cigar dont raise" do
    assert_nothing_raised { Cigar.new("1M") }
    assert_nothing_raised { Cigar.new("1H1M1H") }
    assert_nothing_raised { Cigar.new("1S1M1S") }
    assert_nothing_raised { Cigar.new("1H1S1M1S1H") }
  end

  test "#to_s returns correctly" do
    assert_equal("1M", Cigar.new("1M").to_s)
  end

  test "#each returns correctly" do
    cigar = Cigar.new("10M")

    cigar.each { |len, op|
      assert_equal(10, len)
      assert_equal("M", op)
    }
  end

  test "#length returns correctly" do
    assert_equal(6, Cigar.new("1M2S3H").length)
  end

  test "#matches returns correctly" do
    assert_equal(1, Cigar.new("1M2S3H").matches)
  end

  test "#insertions returns correctly" do
    assert_equal(1, Cigar.new("10M1I").insertions)
  end

  test "#deletions returns correctly" do
    assert_equal(2, Cigar.new("10M2D").deletions)
  end

  test "#clip_hard returns correctly" do
    assert_equal(3, Cigar.new("10M3H").clip_hard)
  end

  test "#clip_soft returns correctly" do
    assert_equal(4, Cigar.new("10M4S").clip_soft)
  end
end
