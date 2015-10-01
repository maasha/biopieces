#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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


require 'maasha/bitarray'
require 'test/unit'
require 'test/helper'

class TestBitArray < Test::Unit::TestCase 
  def setup
    @ba = BitArray.new(10)
  end

  test "BitArray.new raises on bad sizes" do
    [ -1, 0, 1.1, "a" ].each do |size|
      assert_raise(BitArrayError) { BitArray.new(size) }
    end
  end

  test "BitArray.new dont raise on ok sizes" do
    [ 1, 10, 1000 ].each do |size|
      assert_nothing_raised { BitArray.new(size) }
    end
  end

  test "#size returns correctly" do
    assert_equal(10, @ba.size)
  end

  test "#to_s returns correctly" do
    assert_equal("0000000000", @ba.to_s)
  end

  test "#fill returns correctly" do
    assert_equal("1111111111", @ba.fill!.to_s)
  end

  test "#clear returns correctly" do
    assert_equal("0000000000", @ba.fill!.clear!.to_s)
  end

  test "#bit_set with bad pos raises" do
    [-1, 10, 1.1].each do |pos|
      assert_raise(BitArrayError) { @ba.bit_set(pos) }
    end
  end

  test "#bit_unset" do
    @ba.fill!

    str = "1111111111"

    (0.upto 9).each do |pos|
      @ba.bit_unset(pos)
      str[pos] = "0"
      assert_equal(str, @ba.to_s)
    end
  end

  test "#bit_unset with bad pos raises" do
    [-1, 10, 1.1].each do |pos|
      assert_raise(BitArrayError) { @ba.bit_unset(pos) }
    end
  end

  test "#bit_set? with bad pos raises" do
    [-1, 10, 1.1].each do |pos|
      assert_raise(BitArrayError) { @ba.bit_set?(pos) }
    end
  end

  test "#bit_set? returns correctly" do
    (0.upto 9).each do |pos|
      @ba.bit_set(pos)
      assert_equal(true, @ba.bit_set?(pos))
    end
  end

  test "#bits_on returns correctly" do
    @ba.bit_set(4)
    @ba.bit_set(0)
    @ba.bit_set(1)
    assert_equal(3, @ba.bits_on)
  end

  test "#bits_off returns correctly" do
    @ba.bit_set(4)
    assert_equal(9, @ba.bits_off)
  end

  test "#& with uneven sizes raises" do
    ba = BitArray.new(11)
    assert_raise(BitArrayError) { @ba & ba }
  end

  test "#& returns correctly" do
    ba = BitArray.new(10)
    @ba.bit_set(4)
    @ba.bit_set(5)
    ba.bit_set(5)
    ba.bit_set(6)
    assert_equal("0000010000", (@ba & ba).to_s)
  end

  test "#| with uneven sizes raises" do
    ba = BitArray.new(11)
    assert_raise(BitArrayError) { @ba | ba }
  end

  test "#| returns correctly" do
    ba = BitArray.new(10)
    @ba.bit_set(4)
    @ba.bit_set(5)
    ba.bit_set(5)
    ba.bit_set(6)
    assert_equal("0000111000", (@ba | ba).to_s)
  end

  test "#^ with uneven sizes raises" do
    ba = BitArray.new(11)
    assert_raise(BitArrayError) { @ba ^ ba }
  end

  test "#^ returns correctly" do
    ba = BitArray.new(10)
    @ba.bit_set(4)
    @ba.bit_set(5)
    ba.bit_set(5)
    ba.bit_set(6)
    assert_equal("0000101000", (@ba ^ ba).to_s)
  end

  test "#~ returns correctly" do
    @ba.bit_set(0)
    @ba.bit_set(9)

    assert_equal("0111111110", (~@ba).to_s)
  end

  test "#interval_set with bad interval raises" do
    assert_raise(BitArrayError) { @ba.interval_set(-1, 4) }
    assert_raise(BitArrayError) { @ba.interval_set(1, 10) }
    assert_raise(BitArrayError) { @ba.interval_set(4, 2) }
  end

  test "#interval_set returns correctly" do
    @ba.interval_set(0, 0)
    assert_equal("1000000000", @ba.to_s)
    @ba.interval_set(9, 9)
    assert_equal("1000000001", @ba.to_s)
    @ba.interval_set(2, 7)
    assert_equal("1011111101", @ba.to_s)
    @ba.interval_set(1, 8)
    assert_equal("1111111111", @ba.to_s)
  end

  test "#interval_unset with bad interval raises" do
    assert_raise(BitArrayError) { @ba.interval_unset(-1, 4) }
    assert_raise(BitArrayError) { @ba.interval_unset(1, 10) }
    assert_raise(BitArrayError) { @ba.interval_unset(4, 2) }
  end

  test "#interval_unset returns correctly" do
    ~@ba

    @ba.interval_unset(0, 0)
    assert_equal("0111111111", @ba.to_s)
    @ba.interval_unset(9, 9)
    assert_equal("0111111110", @ba.to_s)
    @ba.interval_unset(2, 7)
    assert_equal("0100000010", @ba.to_s)
    @ba.interval_unset(1, 8)
    assert_equal("0000000000", @ba.to_s)
  end

  test "#each_interval returns correctly" do
    @ba.fill!
    @ba.bit_unset(4)
    
    assert_equal([[0, 3], [5, 9]], @ba.each_interval.to_a)
  end
end

