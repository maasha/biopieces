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

require 'maasha/boulder'
require 'test/unit'
require 'test/helper'
require 'stringio'

class TestBoulder < Test::Unit::TestCase 
  test "#each raises on missing seperator" do
    boulder = Boulder.new(StringIO.new("TEST_BAD=testbad\n"))
    assert_raise(BoulderError) { boulder.each }
  end

  test "#each raises on missing key val seperator" do
    boulder = Boulder.new(StringIO.new("TEST_BAD\n=\n"))
    assert_raise(BoulderError) { boulder.each }
  end

  test "#each raises on missing value" do
    boulder = Boulder.new(StringIO.new("TEST_BAD=\n=\n"))
    assert_raise(BoulderError) { boulder.each }
  end

  test "#each raises on missing key" do
    boulder = Boulder.new(StringIO.new("=testbad\n=\n"))
    assert_raise(BoulderError) { boulder.each }
  end

  test "#each with one key val pair returns correctly" do
    boulder = Boulder.new(StringIO.new("TEST0=thisistest0\n=\n"))

    boulder.each do |record|
      assert_equal({:TEST0=>'thisistest0'},record)
    end
  end

  test "#each with two key val pairs return correctly" do
    boulder = Boulder.new(StringIO.new("TEST0=thisistest0\nTEST1=thisistest1\n=\n"))

    boulder.each do |record|
      assert_equal({:TEST0=>'thisistest0', :TEST1=>'thisistest1'},record)
    end
  end

  test "#to boulder returns correctly" do
    boulder = Boulder.new()

    assert_equal("TEST0=thisistest0\n=\n", boulder.to_boulder({:TEST0=>'thisistest0'}))
  end
end
