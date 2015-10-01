#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

require 'maasha/seq'
require 'test/unit'
require 'test/helper'
require 'pp'

class TestTrim < Test::Unit::TestCase 
  def setup
    @entry = Seq.new
  end

  test "Seq.quality_trim with missing seq raises" do
    @entry.qual = "hhhh"
    assert_raise(TrimError) { @entry.quality_trim_right(20) }
    assert_raise(TrimError) { @entry.quality_trim_right!(20) }
    assert_raise(TrimError) { @entry.quality_trim_left(20) }
    assert_raise(TrimError) { @entry.quality_trim_left!(20) }
    assert_raise(TrimError) { @entry.quality_trim(20) }
    assert_raise(TrimError) { @entry.quality_trim!(20) }
  end

  test "Seq.quality_trim with missing qual raises" do
    @entry.seq = "ATCG"
    assert_raise(TrimError) { @entry.quality_trim_right(20) }
    assert_raise(TrimError) { @entry.quality_trim_right!(20) }
    assert_raise(TrimError) { @entry.quality_trim_left(20) }
    assert_raise(TrimError) { @entry.quality_trim_left!(20) }
    assert_raise(TrimError) { @entry.quality_trim(20) }
    assert_raise(TrimError) { @entry.quality_trim!(20) }
  end

  test "Seq.quality_trim with bad min raises" do
    @entry.seq  = "ATCG"
    @entry.qual = "hhhh"

    [-1, 41].each do |min|
      assert_raise(TrimError) { @entry.quality_trim_right(min) }
      assert_raise(TrimError) { @entry.quality_trim_right!(min) }
      assert_raise(TrimError) { @entry.quality_trim_left(min) }
      assert_raise(TrimError) { @entry.quality_trim_left!(min) }
      assert_raise(TrimError) { @entry.quality_trim(min) }
      assert_raise(TrimError) { @entry.quality_trim!(min) }
    end
  end

  test "Seq.quality_trim with ok min dont raise" do
    @entry.seq  = "ATCG"
    @entry.qual = "hhhh"

    [0, 40].each do |min|
      assert_nothing_raised { @entry.quality_trim_right(min) }
      assert_nothing_raised { @entry.quality_trim_right!(min) }
      assert_nothing_raised { @entry.quality_trim_left(min) }
      assert_nothing_raised { @entry.quality_trim_left!(min) }
      assert_nothing_raised { @entry.quality_trim(min) }
      assert_nothing_raised { @entry.quality_trim!(min) }
    end
  end

  test "Seq.quality_trim_right returns correctly" do
    @entry.seq  = "AAAAATCG"
    @entry.qual = "IIIIIHGF"
    new_entry = @entry.quality_trim_right(38)
    assert_equal("AAAAATC", new_entry.seq) 
    assert_equal("IIIIIHG", new_entry.qual) 
    assert_equal("AAAAATCG", @entry.seq) 
    assert_equal("IIIIIHGF", @entry.qual) 
  end

  test "Seq.quality_trim_right! returns correctly" do
    @entry.seq  = "AAAAATCG"
    @entry.qual = "IIIIIHGF"
    @entry.quality_trim_right!(38)
    assert_equal("AAAAATC", @entry.seq) 
    assert_equal("IIIIIHG", @entry.qual) 
  end

  test "Seq.quality_trim_right! with all low qual returns correctly" do
    @entry.seq  = "GCTAAAAA"
    @entry.qual = "@@@@@@@@"
    @entry.quality_trim_right!(38)
    assert_equal("", @entry.seq) 
    assert_equal("", @entry.qual) 
  end

  test "Seq.quality_trim_left returns correctly" do
    @entry.seq  = "GCTAAAAA"
    @entry.qual = "FGHIIIII"
    new_entry = @entry.quality_trim_left(38)
    assert_equal("CTAAAAA", new_entry.seq) 
    assert_equal("GHIIIII", new_entry.qual) 
    assert_equal("GCTAAAAA", @entry.seq) 
    assert_equal("FGHIIIII", @entry.qual) 
  end

  test "Seq.quality_trim_left! returns correctly" do
    @entry.seq  = "GCTAAAAA"
    @entry.qual = "FGHIIIII"
    @entry.quality_trim_left!(38)
    assert_equal("CTAAAAA", @entry.seq) 
    assert_equal("GHIIIII", @entry.qual) 
  end

  test "Seq.quality_trim_left! with all low qual returns correctly" do
    @entry.seq  = "GCTAAAAA"
    @entry.qual = "@@@@@@@@"
    @entry.quality_trim_left!(38)
    assert_equal("", @entry.seq) 
    assert_equal("", @entry.qual) 
  end

  test "Seq.quality_trim returns correctly" do
    @entry.seq  = "GCTAAAAAGTG"
    @entry.qual = "FGHIIIIIHGF"
    new_entry = @entry.quality_trim(38)
    assert_equal("CTAAAAAGT", new_entry.seq) 
    assert_equal("GHIIIIIHG", new_entry.qual) 
    assert_equal("GCTAAAAAGTG", @entry.seq) 
    assert_equal("FGHIIIIIHGF", @entry.qual) 
  end

  test "Seq.quality_trim! returns correctly" do
    @entry.seq  = "GCTAAAAAGTG"
    @entry.qual = "FGHIIIIIHGF"
    @entry.quality_trim!(38)
    assert_equal("CTAAAAAGT", @entry.seq) 
    assert_equal("GHIIIIIHG", @entry.qual) 
  end

  test "Seq.quality_trim! with min len bang returns correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.qual = "IEFGHIHGFEI"
    @entry.quality_trim!(37, 2)
    assert_equal("TCAAACG", @entry.seq) 
    assert_equal("FGHIHGF", @entry.qual) 
  end

  test "Seq.quality_trim! with all low qual returns correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.qual = "@@@@@@@@@@@"
    @entry.quality_trim!(37, 2)
    assert_equal("", @entry.seq) 
    assert_equal("", @entry.qual) 
  end

  test "#patmatch_trim_right! without match don't trim" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.patmatch_trim_left!("GAAAC")
    assert_equal("GCTCAAACGTG", @entry.seq) 
  end

  test "#patmatch_trim_right! without match returns nil" do
    @entry.seq  = "GCTCAAACGTG"
    assert_nil(@entry.patmatch_trim_left!("GAAAC"))
  end

  test "#patmatch_trim_right! without qual trims correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.patmatch_trim_left!("AAAC")
    assert_equal("GTG", @entry.seq) 
  end

  test "#patmatch_trim_right! with qual trims correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.qual = "IEFGHIHGFEI"
    @entry.patmatch_trim_left!("AAAC")
    assert_equal("GTG", @entry.seq) 
    assert_equal("FEI", @entry.qual) 
  end

  test "#patmatch_trim_left! without match trims correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.patmatch_trim_right!("GAAAC")
    assert_equal("GCTCAAACGTG", @entry.seq) 
  end

  test "#patmatch_trim_left! without match returns nil" do
    @entry.seq  = "GCTCAAACGTG"
    assert_nil(@entry.patmatch_trim_right!("GAAAC"))
  end

  test "#patmatch_trim_left! without qual trims correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.patmatch_trim_right!("AAAC")
    assert_equal("GCTC", @entry.seq) 
  end

  test "#patmatch_trim_left! with qual trims correctly" do
    @entry.seq  = "GCTCAAACGTG"
    @entry.qual = "IEFGHIHGFEI"
    @entry.patmatch_trim_right!("AAAC")
    assert_equal("GCTC", @entry.seq) 
    assert_equal("IEFG", @entry.qual) 
  end
end

__END__
