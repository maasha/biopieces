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

require 'maasha/seq'
require 'test/unit'
require 'test/helper'

class TestSeq < Test::Unit::TestCase 
  def setup
    @entry = Seq.new
  end

  test "Seq.new with differnet length SEQ and SCORES raises" do
    assert_raise(SeqError) { Seq.new(seq_name: "test", seq: "ATCG", type: :dna, qual: "hhh") }
  end

  test "Seq.new_bp returns correctly" do
    record = {:SEQ_NAME => "test", :SEQ => "ATCG", :SEQ_TYPE => :dna, :SCORES => "hhhh"}
    seq    = Seq.new_bp(record)
    assert_equal("test", seq.seq_name)
    assert_equal("ATCG", seq.seq)
    assert_equal(:dna,  seq.type)
    assert_equal("hhhh", seq.qual)
  end

  test "#is_dna? with no sequence type returns false" do
    assert(@entry.is_dna? == false)
  end

  test "#is_dna? with dna sequence type returns true" do
    @entry.type = :dna
    assert(@entry.is_dna? == true)
  end

  test "#is_rna? with no sequence type returns false" do
    assert(@entry.is_rna? == false)
  end

  test "#is_rna? with rna sequence type returns true" do
    @entry.type = :rna
    assert(@entry.is_rna? == true)
  end

  test "#is_protein? with no sequence type returns false" do
    assert(@entry.is_protein? == false)
  end

  test "#is_protein? with protein sequence type returns true" do
    @entry.type = :protein
    assert_equal(true, @entry.is_protein?)
  end

  test "#type_guess without sequence raises" do
    assert_raise(SeqError) { @entry.type_guess }
  end

  test "#type_guess with protein returns protein" do
    @entry.seq = 'atcatcrFgatcg'
    assert_equal(:protein, @entry.type_guess)
  end

  test "#type_guess with rna returns rna" do
    @entry.seq = 'atcatcrUgatcg'
    assert_equal(:rna, @entry.type_guess)
  end

  test "#type_guess with dna returns dna" do
    @entry.seq = 'atcatcgatcg'
    assert_equal(:dna, @entry.type_guess)
  end

  test "#type_guess! without sequence raises" do
    assert_raise(SeqError) { @entry.type_guess! }
  end

  test "#type_guess! with protein returns protein" do
    @entry.seq = 'atcatcrFgatcg'
    @entry.type_guess!
    assert_equal(:protein, @entry.type)
  end

  test "#type_guess! with rna returns rna" do
    @entry.seq = 'atcatcrUgatcg'
    @entry.type_guess!
    assert_equal(:rna, @entry.type)
  end

  test "#type_guess! with dna returns dna" do
    @entry.seq = 'atcatcgatcg'
    @entry.type_guess!
    assert_equal(:dna, @entry.type)
  end

  test "#length returns corretly" do
    @entry.seq = 'ATCG'
    assert_equal(4, @entry.length)
  end

  test "#indels returns correctly" do
    @entry.seq = 'ATCG.-~_'
    assert_equal(4, @entry.indels)
  end

  test "#to_rna with no sequence raises" do
    @entry.type = :dna
    assert_raise(SeqError) { @entry.to_rna }
  end

  test "#to_rna with bad type raises" do
    @entry.seq  = 'ATCG'
    @entry.type = :rna
    assert_raise(SeqError) { @entry.to_rna }
  end

  test "#to_rna transcribes correctly" do
    @entry.seq  = 'ATCGatcg'
    @entry.type = :dna
    assert_equal("AUCGaucg", @entry.to_rna)
  end

  test "#to_rna changes entry type to rna" do
    @entry.seq  = 'ATCGatcg'
    @entry.type = :dna
    @entry.to_rna
    assert_equal(:rna, @entry.type)
  end

  test "#to_dna with no sequence raises" do
    @entry.type = :rna
    assert_raise(SeqError) { @entry.to_dna }
  end

  test "#to_dna with bad type raises" do
    @entry.seq  = 'AUCG'
    @entry.type = :dna
    assert_raise(SeqError) { @entry.to_dna }
  end

  test "#to_dna transcribes correctly" do
    @entry.seq  = 'AUCGaucg'
    @entry.type = :rna
    assert_equal("ATCGatcg", @entry.to_dna)
  end

  test "#to_dna changes entry type to dna" do
    @entry.seq  = 'AUCGaucg'
    @entry.type = :rna
    @entry.to_dna
    assert_equal(:dna, @entry.type)
  end

  test "#to_bp returns correct record" do
    @entry.seq_name = 'test'
    @entry.seq      = 'ATCG'
    assert_equal({:SEQ_NAME=>"test", :SEQ=>"ATCG", :SEQ_LEN=>4}, @entry.to_bp)
  end

  test "#to_bp with missing seq_name raises" do
    @entry.seq = 'ATCG'
    assert_raise(SeqError) { @entry.to_bp }
  end

  test "#to_bp with missing sequence raises" do
    @entry.seq_name = 'test'
    assert_raise(SeqError) { @entry.to_bp }
  end

  test "#to_fasta with missing seq_name raises" do
    @entry.seq = 'ATCG'
    assert_raise(SeqError) { @entry.to_fasta }
  end

  test "#to_fasta with empty seq_name raises" do
    @entry.seq_name = ''
    @entry.seq      = 'ATCG'
    assert_raise(SeqError) { @entry.to_fasta }
  end

  test "#to_fasta with missing seq raises" do
    @entry.seq_name = 'test'
    assert_raise(SeqError) { @entry.to_fasta }
  end

  test "#to_fasta with empty seq raises" do
    @entry.seq_name = 'test'
    @entry.seq      = ''
    assert_raise(SeqError) { @entry.to_fasta }
  end

  test "#to_fasta returns correct entry" do
    @entry.seq_name = 'test'
    @entry.seq      = 'ATCG'
    assert_equal(">test\nATCG\n", @entry.to_fasta)
  end

  test "#to_fasta wraps correctly" do
    entry = Seq.new(seq_name: "test", seq: "ATCG")
    assert_equal(">test\nAT\nCG\n", entry.to_fasta(2))
  end

  test "#to_fastq returns correct entry" do
    @entry.seq_name = 'test'
    @entry.seq      = 'ATCG'
    @entry.qual     = 'hhhh'
    assert_equal("@test\nATCG\n+\nhhhh\n", @entry.to_fastq)
  end

  test "#to_key with bad residue raises" do
    entry = Seq.new(seq_name: "test", seq: "AUCG")
    assert_raise(SeqError) { entry.to_key }
  end

  test "#to_key returns correctly" do
    entry = Seq.new(seq_name: "test", seq: "ATCG")
    assert_equal(54, entry.to_key)
  end

  test "#reverse returns correctly" do
    @entry.seq = "ATCG"
    new_entry  = @entry.reverse
    assert_equal("GCTA", new_entry.seq)
    assert_equal("ATCG", @entry.seq)
  end

  test "#reverse! returns correctly" do
    @entry.seq = "ATCG"
    @entry.reverse!
    assert_equal("GCTA", @entry.seq)
  end

  test "#complement with no sequence raises" do
    @entry.type = :dna
    assert_raise(SeqError) { @entry.complement }
  end

  test "#complement with bad type raises" do
    @entry.seq  = 'ATCG'
    @entry.type = :protein
    assert_raise(SeqError) { @entry.complement }
  end

  test "#complement for DNA is correct" do
    @entry.seq  = 'ATCGatcg'
    @entry.type = :dna
    comp        = @entry.complement
    assert_equal("TAGCtagc", comp.seq)
    assert_equal("ATCGatcg", @entry.seq)
  end

  test "#complement for RNA is correct" do
    @entry.seq  = 'AUCGaucg'
    @entry.type = :rna
    comp        = @entry.complement
    assert_equal("UAGCuagc", comp.seq)
    assert_equal("AUCGaucg", @entry.seq)
  end

  test "#complement! with no sequence raises" do
    @entry.type = :dna
    assert_raise(SeqError) { @entry.complement! }
  end

  test "#complement! with bad type raises" do
    @entry.seq  = 'ATCG'
    @entry.type = :protein
    assert_raise(SeqError) { @entry.complement! }
  end

  test "#complement! for DNA is correct" do
    @entry.seq  = 'ATCGatcg'
    @entry.type = :dna
    assert_equal("TAGCtagc", @entry.complement!.seq)
  end

  test "#complement! for RNA is correct" do
    @entry.seq  = 'AUCGaucg'
    @entry.type = :rna
    assert_equal("UAGCuagc", @entry.complement!.seq)
  end

  test "#hamming_distance returns correctly" do
    seq1 = Seq.new(seq: "ATCG")
    seq2 = Seq.new(seq: "atgg")
    assert_equal(1, seq1.hamming_distance(seq2))
  end

  test "#hamming_distance with ambiguity codes return correctly" do
    seq1 = Seq.new(seq: "ATCG")
    seq2 = Seq.new(seq: "atng")

    assert_equal(1, seq1.hamming_distance(seq2))
    assert_equal(0, seq1.hamming_distance(seq2, ambiguity: true))
  end

  test "#edit_distance returns correctly" do
    seq1 = Seq.new(seq: "ATCG")
    seq2 = Seq.new(seq: "tgncg")
    assert_equal(2, seq1.edit_distance(seq2))
  end

  test "#generate with length < 1 raises" do
    assert_raise(SeqError) { @entry.generate(-10, :dna) }
    assert_raise(SeqError) { @entry.generate(0, :dna) }
  end

  test "#generate with bad type raises" do
    assert_raise(SeqError) { @entry.generate(10, "foo") }
  end

  test "#generate with ok type dont raise" do
    %w[dna rna protein].each do |type|
      assert_nothing_raised { @entry.generate(10, type.to_sym) }
    end
  end

  test "#shuffle returns correctly" do
    orig       = "actgactgactgatcgatcgatcgatcgtactg" 
    @entry.seq = "actgactgactgatcgatcgatcgatcgtactg"
    entry_shuf = @entry.shuffle
    assert_equal(orig, @entry.seq)
    assert_not_equal(@entry.seq, entry_shuf.seq)
  end

  test "#shuffle! returns correctly" do
    @entry.seq = "actgactgactgatcgatcgatcgatcgtactg"
    assert_not_equal(@entry.seq, @entry.shuffle!.seq)
  end

  test "#+ without qual returns correctly" do
    entry = Seq.new(seq_name: "test1", seq: "at") + Seq.new(seq_name: "test2", seq: "cg")
    assert_nil(entry.seq_name)
    assert_equal("atcg", entry.seq)
    assert_nil(entry.type)
    assert_nil(entry.qual)
  end

  test "#+ with qual returns correctly" do
    entry = Seq.new(seq_name: "test1", seq: "at", type: :dna, qual: "II") + Seq.new(seq_name: "test2", seq: "cg", type: :dna, qual: "JJ")
    assert_nil(entry.seq_name)
    assert_equal("atcg", entry.seq)
    assert_equal(:dna,   entry.type)
    assert_equal("IIJJ", entry.qual)
  end

  test "#<< with different types raises" do
    @entry.seq = "atcg"
    assert_raise(SeqError) { @entry << Seq.new(seq_name: "test", seq: "atcg", type: :dna) }
  end

  test "#<< with missing qual in one entry raises" do
    @entry.seq  = "atcg"
    @entry.type = :dna
    assert_raise(SeqError) { @entry << Seq.new(seq_name: "test", seq: "atcg", type: :dna, qual: "IIII") }
    @entry.qual = "IIII"
    assert_raise(SeqError) { @entry << Seq.new(seq_name: "test", seq: "atcg", type: :dna) }
  end

  test "#<< with nil qual in both entries dont raise" do
    @entry.seq = "atcg"
    assert_nothing_raised { @entry << Seq.new(seq_name: "test", seq: "atcg") }
  end

  test "#<< with qual in both entries dont raise" do
    @entry.seq  = "atcg"
    @entry.type = :dna
    @entry.qual = "IIII"
    assert_nothing_raised { @entry << Seq.new(seq_name: "test", seq: "atcg", type: :dna, qual: "IIII") }
  end

  test "#<< without qual returns correctly" do
    @entry.seq  = "atcg"
    @entry <<  Seq.new(seq_name: "test", seq: "ATCG")
    assert_equal("atcgATCG", @entry.seq)
  end

  test "#<< with qual returns correctly" do
    @entry.seq  = "atcg"
    @entry.type = :dna
    @entry.qual = "HHHH"
    @entry <<  Seq.new(seq_name: "test", seq: "ATCG", type: :dna, qual: "IIII")
    assert_equal("atcgATCG", @entry.seq)
    assert_equal("HHHHIIII", @entry.qual)
  end

  test "#[] with qual returns correctly" do
    entry = Seq.new(seq_name: "test", seq: "atcg", type: :dna, qual: "FGHI")

    e = entry[2]

    assert_equal("test", e.seq_name)
    assert_equal("c",    e.seq)
    assert_equal(:dna,   e.type)
    assert_equal("H",    e.qual)
    assert_equal("atcg", entry.seq)
    assert_equal("FGHI", entry.qual)
  end

  test "#[] without qual returns correctly" do
    entry = Seq.new(seq_name: "test", seq: "atcg")

    e = entry[2]

    assert_equal("test", e.seq_name)
    assert_equal("c",    e.seq)
    assert_nil(e.qual)
    assert_equal("atcg", entry.seq)
  end

  test "[]= with qual returns correctly" do
    entry = Seq.new(seq_name: "test", seq: "atcg", type: :dna, qual: "FGHI")

    entry[0] = Seq.new(seq_name: "foo", seq: "T", type: :dna, qual: "I")

    assert_equal("test", entry.seq_name)
    assert_equal("Ttcg", entry.seq)
    assert_equal(:dna,   entry.type)
    assert_equal("IGHI", entry.qual)
  end

  test "[]= without qual returns correctly" do
    entry = Seq.new(seq_name: "test", seq: "atcg")

    entry[0] = Seq.new(seq_name: "foo", seq: "T")

    assert_equal("test", entry.seq_name)
    assert_equal("Ttcg", entry.seq)
  end

  test "#subseq_rand returns correct sequence" do
    @entry.seq  = "ATCG"
    assert_equal("ATCG", @entry.subseq_rand(4).seq)
  end

  test "#indels_remove without qual returns correctly" do
    @entry.seq  = "A-T.CG~CG"
    @entry.qual = nil
    assert_equal("ATCGCG", @entry.indels_remove.seq)
  end

  test "#indels_remove with qual returns correctly" do
    @entry.seq  = "A-T.CG~CG"
    @entry.qual = "a@b@cd@fg"
    assert_equal("ATCGCG", @entry.indels_remove.seq)
    assert_equal("abcdfg", @entry.indels_remove.qual)
  end

  test "#composition returns correctly" do
    @entry.seq = "AAAATTTCCG"
    assert_equal(4, @entry.composition["A"])
    assert_equal(3, @entry.composition["T"])
    assert_equal(2, @entry.composition["C"])
    assert_equal(1, @entry.composition["G"])
    assert_equal(0, @entry.composition["X"])
  end

  test "#hard_mask returns correctly" do
    @entry.seq = "--AAAANn"
    assert_equal(33.33, @entry.hard_mask)
  end

  test "#soft_mask returns correctly" do
    @entry.seq = "--AAAa"
    assert_equal(25.00, @entry.soft_mask)
  end

  test "#mask_seq_hard! with nil seq raises" do
    @entry.seq  = nil
    @entry.qual = ""

    assert_raise(SeqError) { @entry.mask_seq_hard!(20) }
  end

  test "#mask_seq_hard! with nil qual raises" do
    @entry.seq  = ""
    @entry.qual = nil

    assert_raise(SeqError) { @entry.mask_seq_hard!(20) }
  end

  test "#mask_seq_hard! with bad cutoff raises" do
    assert_raise(SeqError) { @entry.mask_seq_hard!(-1) }
    assert_raise(SeqError) { @entry.mask_seq_hard!(41) }
  end

  test "#mask_seq_hard! with OK cutoff dont raise" do
    @entry.seq  = "ATCG"
    @entry.qual = "RSTU"

    assert_nothing_raised { @entry.mask_seq_hard!(0) }
    assert_nothing_raised { @entry.mask_seq_hard!(40) }
  end

  test "#mask_seq_hard! returns correctly" do
    @entry.seq  = "-ATCG"
    @entry.qual = "33456"

    assert_equal("-NNCG", @entry.mask_seq_hard!(20).seq)
  end

  test "#mask_seq_soft! with nil seq raises" do
    @entry.seq  = nil
    @entry.qual = ""

    assert_raise(SeqError) { @entry.mask_seq_soft!(20) }
  end

  test "#mask_seq_soft! with nil qual raises" do
    @entry.seq  = ""
    @entry.qual = nil

    assert_raise(SeqError) { @entry.mask_seq_soft!(20) }
  end

  test "#mask_seq_soft! with bad cutoff raises" do
    assert_raise(SeqError) { @entry.mask_seq_soft!(-1) }
    assert_raise(SeqError) { @entry.mask_seq_soft!(41) }
  end

  test "#mask_seq_soft! with OK cutoff dont raise" do
    @entry.seq  = "ATCG"
    @entry.qual = "RSTU"

    assert_nothing_raised { @entry.mask_seq_soft!(0) }
    assert_nothing_raised { @entry.mask_seq_soft!(40) }
  end

  test "#mask_seq_soft! returns correctly" do
    @entry.seq  = "-ATCG"
    @entry.qual = "33456"

    assert_equal("-atCG", @entry.mask_seq_soft!(20).seq)
  end

  # qual score detection

  test "#qual_base33? returns correctly" do
    # self.qual.match(/[!-:]/)
    @entry.qual = '!"#$%&\'()*+,-./0123456789:'
    assert_equal(true,  @entry.qual_base33? )
    @entry.qual = 32.chr
    assert_equal(false, @entry.qual_base33? )
    @entry.qual = 59.chr
    assert_equal(false, @entry.qual_base33? )
  end

  test "#qual_base64? returns correctly" do
    # self.qual.match(/[K-h]/)
    @entry.qual = 'KLMNOPQRSTUVWXYZ[\]^_`abcdefgh'
    assert_equal(true,  @entry.qual_base64? )
    @entry.qual = 74.chr
    assert_equal(false, @entry.qual_base64? )
    @entry.qual = 105.chr
    assert_equal(false, @entry.qual_base64? )
  end

  test "#qual_valid? with nil qual raises" do
    assert_raise(SeqError) { @entry.qual_valid?(:base_33) }
    assert_raise(SeqError) { @entry.qual_valid?(:base_64) }
  end

  test "#qual_valid? with bad encoding raises" do
    @entry.qual = "abc"
    assert_raise(SeqError) { @entry.qual_valid?("foobar") }
  end

  test "#qual_valid? with OK range returns correctly" do
    @entry.qual = ((Seq::SCORE_MIN + 33).chr .. (Seq::SCORE_MAX + 33).chr).to_a.join
    assert_equal(true,  @entry.qual_valid?(:base_33))
    @entry.qual = ((Seq::SCORE_MIN + 64).chr .. (Seq::SCORE_MAX + 64).chr).to_a.join
    assert_equal(true,  @entry.qual_valid?(:base_64))
  end

  test "#qual_valid? with bad range returns correctly" do
    @entry.qual = ((Seq::SCORE_MIN + 33 - 1).chr .. (Seq::SCORE_MAX + 33).chr).to_a.join
    assert_equal(false,  @entry.qual_valid?(:base_33))
    @entry.qual = ((Seq::SCORE_MIN + 33).chr .. (Seq::SCORE_MAX + 33 + 1).chr).to_a.join
    assert_equal(false,  @entry.qual_valid?(:base_33))

    @entry.qual = ((Seq::SCORE_MIN + 64 - 1).chr .. (Seq::SCORE_MAX + 64).chr).to_a.join
    assert_equal(false,  @entry.qual_valid?(:base_64))
    @entry.qual = ((Seq::SCORE_MIN + 64).chr .. (Seq::SCORE_MAX + 64 + 1).chr).to_a.join
    assert_equal(false,  @entry.qual_valid?(:base_64))
  end

  # convert sanger to ...

  test "#qual_convert! from base33 to base33 returns OK" do
    @entry.qual = 'BCDEFGHI'
    assert_equal('BCDEFGHI', @entry.qual_convert!(:base_33, :base_33).qual)
  end

  test "#qual_convert! from base33 to base64 returns OK" do
    @entry.qual = 'BCDEFGHI'
    assert_equal('abcdefgh', @entry.qual_convert!(:base_33, :base_64).qual)
  end

  test "#qual_convert! from base64 to base64 returns OK" do
    @entry.qual = 'BCDEFGHI'
    assert_equal('BCDEFGHI', @entry.qual_convert!(:base_64, :base_64).qual)
  end

  test "#qual_convert! from base64 to base33 returns OK" do
    @entry.qual = 'abcdefgh'
    assert_equal('BCDEFGHI', @entry.qual_convert!(:base_64, :base_33).qual)
  end

  test "#qual_coerce! returns correctly" do
    @entry.qual = ('!' .. '~').to_a.join
    assert_equal(%q{!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII}, @entry.qual_coerce!(:base_33).qual)
    @entry.qual = ('!' .. '~').to_a.join
    assert_equal(%q{@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghhhhhhhhhhhhhhhhhhhhhhh}, @entry.qual_coerce!(:base_64).qual)
  end

  test "#scores_mean without qual raises" do
    @entry.qual = nil
    assert_raise(SeqError) { @entry.scores_mean }
  end

  test "#scores_mean returns correctly" do
    @entry.qual = '!!II'
    assert_equal(20.0, @entry.scores_mean)
  end
end
