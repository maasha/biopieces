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
require 'maasha/sam'
require 'stringio'

SAM_DATA =
%{@HD\tVN:1.3\tSO:coordinate
@SQ\tSN:ref\tLN:45
@CO\tMyComment
r001\t163\tref\t7\t30\t8M2I4M1D3M\t=\t37\t39\tTTAGATAAAGGATACTG\t*
r002\t0\tref\t9\t30\t3S6M1P1I4M\t*\t0\t0\tAAAAGATAAGGATA\t*
r003\t0\tref\t9\t30\t5H6M\t*\t0\t0\tAGCTAA\t*\tNM:i:1
r004\t0\tref\t16\t30\t6M14N5M\t*\t0\t0\tATAGCTTCAGC\t*
r003\t16\tref\t29\t30\t6H5M\t*\t0\t0\tTAGGC\t*\tNM:i:0
r001\t83\tref\t37\t30\t9M\t=\t7\t-39\tCAGCGCCAT\t*
}

class SamTest < Test::Unit::TestCase
  def setup
    @sam = Sam.new(StringIO.new(SAM_DATA))
  end

  test "#new with missing version number raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@HD")) }
  end

  test "#new with bad version number raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@HD\tXN:1.3")) }
  end

  test "#new with ok version number returns correctly" do
    sam = Sam.new(StringIO.new("@HD\tVN:1.3"))
    assert_equal(1.3, sam.header[:HD][:VN])
  end

  test "#new with bad sort order raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@HD\tVN:1.3\tSO:fish")) }
  end

  test "#new with ok sort order returns correctly" do
    %w{unknown unsorted queryname coordinate}.each do |order|
      sam = Sam.new(StringIO.new("@HD\tVN:1.3\tSO:#{order}"))
      assert_equal(order, sam.header[:HD][:SO])
    end
  end

  test "#new with missing sequence name raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@SQ")) }
  end

  test "#new with bad sequence name raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@SQ\tSN:")) }
  end

  test "#new with ok sequence name returns correctly" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45"))
    assert_equal({:LN=>45}, sam.header[:SQ][:SN][:ref])
  end

  test "#new with duplicate sequence name raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@SQ\tSN:ref\n@SQ\tSN:ref")) }
  end

  test "#new with missing sequence length raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@SQ\tSN:ref")) }
  end

  test "#new with bad sequence length raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@SQ\tSN:scaffold17_1_MH0083\tLN:x")) }
  end

  test "#new with ok sequence length returns correctly" do
    sam = Sam.new(StringIO.new("@SQ\tSN:scaffold17_1_MH0083\tLN:995"))
    assert_equal(995, sam.header[:SQ][:SN][:scaffold17_1_MH0083][:LN])
  end

  test "#new with full SQ dont raise" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\tAS:ident\tM5:87e6b2aedf51b1f9c89becfab9267f41\tSP:E.coli\tUR:http://www.biopieces.org"))
    assert_nothing_raised { sam.header }
  end

  test "#new with bad read group identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@RG\tID:")) }
  end

  test "#new with missing read group identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@RG")) }
  end

  test "#new with duplicate read group identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@RG\tID:123\n@RG\tID:123")) }
  end

  test "#new with ok read group identifier dont raise" do
    sam = Sam.new(StringIO.new("@RG\tID:123\n@RG\tID:124"))
    assert_nothing_raised { sam.header }
  end

  test "#new with bad flow order raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@RG\tID:123\tFO:3")) }
  end

  test "#new with ok flow order dont raise" do
    sam = Sam.new(StringIO.new("@RG\tID:123\tFO:*"))
    assert_nothing_raised { sam.header }
    sam = Sam.new(StringIO.new("@RG\tID:123\tFO:ACMGRSVTWYHKDBN"))
    assert_nothing_raised { sam.header }
  end

  test "#new with bad platform raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@RG\tID:123\tPL:maersk")) }
  end

  test "#new with ok platform dont raise" do
    sam = Sam.new(StringIO.new("@RG\tID:123\tPL:ILLUMINA"))
    assert_nothing_raised { sam.header }
  end

  test "#new with bad program identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@PG\tID:")) }
  end

  test "#new with missing program identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@PG")) }
  end

  test "#new with duplicate program identifier raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@PG\tID:123\n@PG\tID:123")) }
  end

  test "#new with bad comment raises" do
    assert_raise(SamError) { Sam.new(StringIO.new("@CO\t")) }
  end 

  test "#new with ok comment dont raise" do
    sam = Sam.new(StringIO.new("@CO\tfubar"))
    assert_nothing_raised { sam.header }
  end

  test "#each with bad field count raises" do
    fields = []

    (0 ... 11).each do |i|
      sam = Sam.new(StringIO.new(fields.join("\t") + $/))
      assert_raise(SamError) { sam.each }
      fields << "*"
    end
  end

  test "#each with ok field count dont raise" do
    sam = Sam.new(StringIO.new(SAM_DATA))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad qname raises" do
    sam = Sam.new(StringIO.new(" \t*\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok qname dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised(SamError) { sam.each }
  end

  test "#each with bad flag raises" do
    sam = Sam.new(StringIO.new("*\t-1\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }

    sam = Sam.new(StringIO.new("*\t65536\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok flag dont raise" do
    sam = Sam.new(StringIO.new("*\t0\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t65535\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad rname raises" do
    sam = Sam.new(StringIO.new("*\t*\t \t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok rname dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad pos raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t-1\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t536870912\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok pos dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t0\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t536870911\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad mapq raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t-1\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t256\t*\t*\t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok mapq dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t0\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t255\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad rnext raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t \t*\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok rnext dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t=\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t!\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad pnext raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t-1\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t536870912\t*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok pnext dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t0\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t536870911\t*\t*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad tlen raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t-536870912\t*\t*\n"))
    assert_raise(SamError) { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t536870912\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok tlen dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t-536870911\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t536870911\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad seq raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t\*\t \t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok seq dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t\*\tATCGatcg=.\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with bad qual raises" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t\*\t*\t \n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with ok qual dont raise" do
    sam = Sam.new(StringIO.new("*\t*\t*\t*\t*\t*\t*\t*\t\*\t*\t@\n"))
    assert_nothing_raised { sam.each(:base_33) }
  end

  test "#each with rname missing from header raises" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\tMIS\t*\t*\t*\t*\t*\t\*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with rname present in header dont raise" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\tref\t*\t*\t*\t*\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\t*\t*\t*\t*\t*\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#each with rnext missing from header raises" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\t*\t*\t*\t*\tMIS\t*\t\*\t*\t*\n"))
    assert_raise(SamError) { sam.each }
  end

  test "#each with rnext present in header dont raise" do
    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\t*\t*\t*\t*\t*\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\t*\t*\t*\t*\t=\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }

    sam = Sam.new(StringIO.new("@SQ\tSN:ref\tLN:45\n*\t*\t*\t*\t*\t*\tref\t*\t\*\t*\t*\n"))
    assert_nothing_raised { sam.each }
  end

  test "#to_bp returns correctly" do
    string = "ID00036734\t0\tgi48994873\t366089\t37\t37M1I62M\t*\t0\t0\tGTTCCGCTATCGGCTGAATTTGATTGCGAGTGAGATATTTTATGCCAGCCAGCCAGACGCAGACGCGCCGAGACAGAACTTAATGGGCCCGCTAACAGCG\t*\tXT:A:U\tNM:i:1\tX0:i:1\tX1:i:0\tXM:i:0\tXO:i:1\tXG:i:1\tMD:Z:99\n"

    sam = Sam.new(StringIO.new(string))

    sam.each do |s|
      assert_equal("SAM", Sam.to_bp(s)[:REC_TYPE])
      assert_equal("ID00036734", Sam.to_bp(s)[:Q_ID])
      assert_equal("-", Sam.to_bp(s)[:STRAND])
      assert_equal("gi48994873", Sam.to_bp(s)[:S_ID])
      assert_equal(366089, Sam.to_bp(s)[:S_BEG])
      assert_equal(37, Sam.to_bp(s)[:MAPQ])
      assert_equal("37M1I62M", Sam.to_bp(s)[:CIGAR])
      assert_equal("GTTCCGCTATCGGCTGAATTTGATTGCGAGTGAGATATTTTATGCCAGCCAGCCAGACGCAGACGCGCCGAGACAGAACTTAATGGGCCCGCTAACAGCG", Sam.to_bp(s)[:SEQ])
      assert_equal("37:->T", Sam.to_bp(s)[:ALIGN])
    end
  end

  test "#to_bp alignment descriptor without mismatch or indel returns correctly" do
    string = "q_id\t0\ts_id\t1000\t40\t10M\t*\t0\t0\tGTTCCGCTAT\t*\tXT:A:U\tNM:i:0\tX0:i:1\tX1:i:0\tXM:i:0\tXO:i:1\tXG:i:1\tMD:Z:10\n"

    sam = Sam.new(StringIO.new(string))

    sam.each do |s|
      assert_equal(nil, Sam.to_bp(s)[:ALIGN])
    end
  end

  test "#to_bp alignment descriptor with mismatches returns correctly" do
    string = "q_id\t0\ts_id\t1000\t40\t10M\t*\t0\t0\tgTTCCGCTAt\t*\tXT:A:U\tNM:i:2\tX0:i:1\tX1:i:0\tXM:i:0\tXO:i:1\tXG:i:1\tMD:Z:0C8A\n"

    sam = Sam.new(StringIO.new(string))

    sam.each do |s|
      assert_equal("0:C>g,9:A>t", Sam.to_bp(s)[:ALIGN])
    end
  end

  test "#to_bp alignment descriptor with insertions returns correctly" do
    string = "q_id\t0\ts_id\t1000\t40\t1I10M1I\t*\t0\t0\taGTTCCGCTATc\t*\tXT:A:U\tNM:i:2\tX0:i:1\tX1:i:0\tXM:i:0\tXO:i:1\tXG:i:1\tMD:Z:12\n"

    sam = Sam.new(StringIO.new(string))

    sam.each do |s|
      assert_equal("0:->a,11:->c", Sam.to_bp(s)[:ALIGN])
    end
  end

  test "#to_bp alignment descriptor with deletions returns correctly" do
    string = "q_id\t0\ts_id\t1000\t40\t2D10M\t*\t0\t0\tGTTCCGCTAT\t*\tXT:A:U\tNM:i:2\tX0:i:1\tX1:i:0\tXM:i:0\tXO:i:1\tXG:i:1\tMD:Z:^AC10\n"

    sam = Sam.new(StringIO.new(string))

    sam.each do |s|
      assert_equal("0:A>-,1:C>-", Sam.to_bp(s)[:ALIGN])
    end
  end

  test "#to_bp alignment descriptor with everything returns correctly" do
    string = "q_id\t16\ts_id\t66\t0\t13M5D51M1D161M14I4M\t*\t0\t0\tCAGCAGNNNCCNGGGTGNCCGCGTNCNNCNNGGGCATCCTNCNCCTGATCCTGTGGATCCTGGACGCCTGTTCTTCAAGTGCATCTACCGCTTCTTCAAGCACGGCCTGAAGCGCGGCCCGAGCACCGAGGGCGTGCCGGAGAGCATGCGCGAGGAGTACCGCAAGGAGCAGCAGAGCGCCGTGGACGCGGACGACAGCCACTTCGTGAGCATCGAGCTGGAGAAGCTTGGCACTGGCCGTCG\tIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\tAS:i:-123\tXN:i:0\tXM:i:18\tXO:i:3\tXG:i:20\tNM:i:38\tMD:Z:6C0G0A2C1^CTGGT4G5A0G1A0T1A0T0C8G1A21^C125C36C0T0T0\tYT:Z:UU\n"

    sam = Sam.new(StringIO.new(string))

    sam.each(:base_33) do |s|
      assert_equal("6:C>N,7:G>N,8:A>N,11:C>N,13:C>-,14:T>-,15:G>-,16:G>-,17:T>-,22:G>N,28:A>T,29:G>N,31:A>N,32:T>N,34:A>N,35:T>N,36:C>G,45:G>N,47:A>N,69:C>-,195:C>G,231:->G,232:->C,233:->T,234:->T,235:->G,236:->G,237:->C,238:->A,239:->C,240:->T,241:->G,242:->G,243:->C,244:->C,246:C>T,247:T>C,248:T>G", Sam.to_bp(s)[:ALIGN])
    end
  end
end

