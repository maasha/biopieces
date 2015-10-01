#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

require 'maasha/seq/assemble'
require 'test/unit'
require 'test/helper'
require 'pp'

class TestAssemble < Test::Unit::TestCase 
  test "Assemble.pair without overlap returns nil" do
    assert_nil(Assemble.pair(Seq.new(seq: "aaaa"), Seq.new(seq: "tttt")))
  end

  test "Assemble.pair with overlap returns correctly" do
    assert_equal("atcGatc", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "gatc")).seq)
    assert_equal("atCGat",  Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "cgat")).seq)
    assert_equal("aTCGa",   Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "tcga")).seq)
    assert_equal("ATCG",    Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "atcg")).seq)
  end

  test "Assemble.pair with first sequence longer than second and terminal overlap returns correctly" do
    e1 = Seq.new(seq_name: "t1", seq: "AGGCGT")
    e2 = Seq.new(seq_name: "t2", seq: "GT")
    a = Assemble.pair(e1, e2)
    assert_equal("t1:overlap=2:hamming=0", a.seq_name)
    assert_equal("aggcGT", a.seq)
  end

  test "Assemble.pair with first sequence longer than second and internal overlap returns correctly" do
    e1 = Seq.new(seq_name: "t1", seq: "AGGCGT")
    e2 = Seq.new(seq_name: "t2", seq: "GC")
    a = Assemble.pair(e1, e2)
    assert_equal("t1:overlap=2:hamming=0", a.seq_name)
    assert_equal("agGCgt", a.seq)
  end

  test "Assemble.pair with first sequence longer than second and initial overlap returns correctly" do
    e1 = Seq.new(seq_name: "t1", seq: "GTCAGA")
    e2 = Seq.new(seq_name: "t2", seq: "GT")
    a = Assemble.pair(e1, e2)
    assert_equal("t1:overlap=2:hamming=0", a.seq_name)
    assert_equal("GTcaga", a.seq)
  end

  test "Assemble.pair with first sequence shorter than second and initial overlap returns correctly" do
    e1 = Seq.new(seq_name: "t1", seq: "AG")
    e2 = Seq.new(seq_name: "t2", seq: "AGTCAG")
    a = Assemble.pair(e1, e2)
    assert_equal("t1:overlap=2:hamming=0", a.seq_name)
    assert_equal("AGtcag", a.seq)
  end

  test "Assemble.pair with overlap and overlap_min returns correctly" do
    assert_nil(Assemble.pair(Seq.new(seq: "atcg"), Seq.new(seq: "gatc"), :overlap_min => 2))
    assert_equal("atCGat", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "cgat"), :overlap_min => 2).seq)
  end

  test "Assemble.pair with overlap and overlap_max returns correctly" do
    assert_equal("aTCGa", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "tcga"), :overlap_max => 3).seq)
    assert_nil(Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg"), Seq.new(seq_name: "t2", seq: "atcg"), :overlap_max => 3))
  end

  test "Assemble.pair with overlap returns correct quality" do
    assert_equal("?", Assemble.pair(Seq.new(seq_name: "t1", seq: "a", qual: "I"), Seq.new(seq_name: "t2", seq: "a", qual: "5")).qual)
    assert_equal("GH??43", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg", qual: "GHII"), Seq.new(seq_name: "t2", seq: "cgat", qual: "5543")).qual)
    assert_equal("I???5", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcg", qual: "IIII"), Seq.new(seq_name: "t2", seq: "tcga", qual: "5555")).qual)
  end

  test "Assemble.pair with mismatch returns the highest scoring" do
    assert_equal("ATCGA", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcga", qual: "IIIII"), Seq.new(seq_name: "t2", seq: "attga", qual: "55555"), :mismatches_max => 20).seq)
    assert_equal("ATTGA", Assemble.pair(Seq.new(seq_name: "t1", seq: "atcga", qual: "55555"), Seq.new(seq_name: "t2", seq: "attga", qual: "IIIII"), :mismatches_max => 20).seq)
  end
end
