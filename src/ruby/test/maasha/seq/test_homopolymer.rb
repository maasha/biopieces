#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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

require 'test/unit'
require 'test/helper'
require 'maasha/seq'

class HomopolymerTest < Test::Unit::TestCase
  def setup
    #                      0         1
    #                      01234567890123456789
    @entry = Seq.new(seq: "tacgatgctagcatgcacgg")
    @entry.extend(Homopolymer)
  end

  test "#each_homopolymer returns empty with empty sequence" do
    @entry.seq = ""
    assert_equal([], @entry.each_homopolymer)
  end

  test "#each_homopolymer returns empty when none found" do
    @entry.seq = "AtTcCcGggGnnNnn"
    assert_equal([], @entry.each_homopolymer(6))
  end

  test "#each_homopolymer returns correctly" do
    @entry.seq = "AtTcCcGggGnnNnn"
    assert_equal('CCC', @entry.each_homopolymer(3).first.pattern)
    assert_equal(3,     @entry.each_homopolymer(3).first.pos)
    assert_equal(3,     @entry.each_homopolymer(3).first.length)
  end

  test "#each_homopolymer in block context returns correctly" do
    @entry.seq = "AtTcCcGggGnnNnn"

    @entry.each_homopolymer(3) do |hp|
      assert_equal('CCC', hp.pattern)
      assert_equal(3,     hp.pos)
      assert_equal(3,     hp.length)

      break
    end
  end
end
