#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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

require 'test/unit'
require 'test/helper'
require 'maasha/seq'

class BackTrackTest < Test::Unit::TestCase
  def setup
    #                    0         1
    #                    01234567890123456789
    @seq = Seq.new(seq: "tacgatgctagcatgcacgg")
    @seq.extend(BackTrack)
  end

  test "#patscan with bad pattern raises" do
    ["", "X", "1"].each { |pattern|
      assert_raise(BackTrackError) { @seq.patscan(pattern) }
    }
  end

  test "#patscan with OK pattern dont raise" do
    ["N", "atcg"].each { |pattern|
      assert_nothing_raised { @seq.patscan(pattern) }
    }
  end

  test "#patscan with bad start raises" do
    [-1, 20].each { |start| 
      assert_raise(BackTrackError) { @seq.patscan("N", start: start) }
    }
  end

  test "#patscan with OK start dont raise" do
    [0, 19].each { |start| 
      assert_nothing_raised { @seq.patscan("N", start: start) }
    }
  end

  test "#patscan with bad stop raises" do
    [-1, 20].each { |stop|
      assert_raise(BackTrackError) { @seq.patscan("N", stop: stop) }
    }
  end

  test "#patscan with OK stop dont raise" do
    [0, 19].each { |stop|
      assert_nothing_raised { @seq.patscan("N", stop: stop) }
    }
  end

  test "#patscan with stop returns correctly" do
    assert_nil(@seq.patmatch("G", start: 0, stop: 2))
    assert_equal("3:1:g", @seq.patmatch("G", start: 0, stop: 3).to_s)
  end

  test "#patscan with bad mis raises" do
    [-1, 6].each { |mis| 
      assert_raise(BackTrackError) { @seq.patscan("N", max_mismatches: mis) }
    }
  end

  test "#patscan with OK mis dont raise" do
    [0, 5].each { |mis| 
      assert_nothing_raised { @seq.patscan("N", max_mismatches: mis) }
    }
  end

  test "#patscan with bad ins raises" do
    [-1, 6].each { |ins| 
      assert_raise(BackTrackError) { @seq.patscan("N", max_insertions: ins) }
    }
  end

  test "#patscan with OK ins dont raise" do
    [0, 5].each { |ins| 
      assert_nothing_raised { @seq.patscan("N", max_insertions: ins) }
    }
  end

  test "#patscan with bad del raises" do
    [-1, 6].each { |del| 
      assert_raise(BackTrackError) { @seq.patscan("N", max_deletions: del) }
    }
  end

  test "#patscan with OK del dont raise" do
    [0, 5].each { |del| 
      assert_nothing_raised { @seq.patscan("N", max_deletions: del) }
    }
  end

  test "#patscan perfect left is ok" do
    assert_equal("0:7:tacgatg", @seq.patscan("TACGATG").first.to_s)
  end

  test "#patscan perfect right is ok" do
    assert_equal("13:7:tgcacgg", @seq.patscan("TGCACGG").first.to_s)
  end

  test "#patscan ambiguity is ok" do
    assert_equal("13:7:tgcacgg", @seq.patscan("TGCACNN").first.to_s)
  end

  test "#patscan start is ok" do
    assert_equal("10:1:g", @seq.patscan("N", start: 10).first.to_s)
    assert_equal("19:1:g", @seq.patscan("N", start: 10).last.to_s)
  end

  test "#patscan mis left is ok" do
    assert_equal("0:7:tacgatg", @seq.patscan("Aacgatg", max_mismatches: 1).first.to_s)
  end

  test "#patscan mis right is ok" do
    assert_equal("13:7:tgcacgg", @seq.patscan("tgcacgA", max_mismatches: 1).first.to_s)
  end

  test "#patscan ins left is ok" do
    assert_equal("0:7:tacgatg", @seq.patscan("Atacgatg", max_insertions: 1).first.to_s)
  end

  test "#patscan ins right is ok" do
    assert_equal("13:7:tgcacgg", @seq.patscan("tgcacggA", max_insertions: 1).first.to_s)
  end

  test "#patscan del left is ok" do
    assert_equal("0:7:tacgatg", @seq.patscan("acgatg", max_deletions: 1).first.to_s)
  end

  test "#patscan del right is ok" do
    assert_equal("12:8:atgcacgg", @seq.patscan("tgcacgg", max_deletions: 1).first.to_s)
  end

  test "#patscan ambiguity mis ins del all ok" do
    assert_equal("0:20:tacgatgctagcatgcacgg", @seq.patscan("tacatgcNagGatgcCacgg",
                                                           max_mismatches: 1,
                                                           max_insertions: 1,
                                                           max_deletions: 1).first.to_s)
  end
end

