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

require 'maasha/seq'
require 'test/unit'
require 'test/helper'

class TestDigest < Test::Unit::TestCase 
  test "#each_digest raises on bad pattern residue" do
    entry = Seq.new
    assert_raise(DigestError) { entry.each_digest("X", 4) }
  end

  test "#each_digest dont raise on ok pattern residue" do
    entry = Seq.new(seq: "atcg")
    assert_nothing_raised { entry.each_digest("AGCUTRYWSMKHDVBNagcutrywsmkhdvbn", 4) }
  end

  test "#each_digest with no match returns correctly" do
    entry = Seq.new(seq: "aaaaaaaaaaa")
    assert_equal(entry.seq, entry.each_digest("CGCG", 1).first.seq)
  end

  test "#each_digest with matches returns correctly" do
    entry = Seq.new(seq: "TTTTaaaaTTTTbbbbTTTT")
    seqs  = entry.each_digest("TTNT", 1)
    assert_equal("T", seqs[0].seq)
    assert_equal("TTTaaaaT", seqs[1].seq)
    assert_equal("TTTbbbbT", seqs[2].seq)
    assert_equal("TTT",      seqs[3].seq)
  end
end


__END__
