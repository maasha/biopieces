#!/usr/bin/env ruby

# Copyright (C) 2011 Martin A. Hansen (mail@maasha.dk).

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

require 'pp'
require 'tmpdir'
require 'base64'
require 'erb'

class Report
  def initialize(sff_file)
    @sff_file = sff_file
    tmpdir    = Dir.mktmpdir

    @seq_analysis   = SeqAnalyze.new(@sff_file, tmpdir)
    @plots          = PlotData.new(@sff_file, tmpdir)
    @table_mid_join = MidTable.new(@sff_file, tmpdir)
  end

  # Support templating of member data.
  def get_binding
    binding
  end

  private

  class SeqAnalyze
    attr_reader :count, :min, :max, :mean, :bases, :gc, :hard, :soft

    def initialize(sff_file, tmpdir)
      @sff_file  = sff_file
      @anal_file = File.join(tmpdir, "out1.txt")
      @count     = 0
      @min       = 0
      @max       = 0
      @mean      = 0
      @bases     = 0
      @gc        = 0
      @hard      = 0
      @soft      = 0

      bp_seq_analyze
      parse_analyze_vals
    end

    private

    def bp_seq_analyze
      STDERR.puts "Analyzing sequences ... "
      system(
        "read_sff -i #{@sff_file} |
         progress_meter |
         analyze_seq |
         analyze_vals -k SEQ,GC%,HARD_MASK%,SOFT_MASK% -x |
         write_tab -o #{@anal_file} -x"
       )
      STDERR.puts "done.\n"
    end

    def parse_analyze_vals
      File.open(@anal_file, "r") do |ios|
        while not ios.eof?
          line   = ios.readline.chomp
          fields = line.split("\t")

          case fields.first
          when "SEQ"        then @count, @min, @max, @bases, @mean = fields[2 .. 6]
          when "GC%"        then @gc   = fields[6]
          when "HARD_MASK%" then @hard = fields[6]
          when "SOFT_MASK%" then @soft = fields[6]
          end
        end
      end
    end
  end

  class PlotData
    attr_reader :lendist_unclipped, :lendist_clipped, :scores_unclipped, :scores_clipped, :mean_scores, :nucleotide_dist500, :nucleotide_dist50

    def initialize(sff_file, tmpdir)
      @sff_file = sff_file
      @plot1    = File.join(tmpdir, "plot1.png")
      @plot2    = File.join(tmpdir, "plot2.png")
      @plot3    = File.join(tmpdir, "plot3.png")
      @plot4    = File.join(tmpdir, "plot4.png")
      @plot5    = File.join(tmpdir, "plot5.png")
      @plot6    = File.join(tmpdir, "plot6.png")
      @plot7    = File.join(tmpdir, "plot7.png")

      bp_plot

      @lendist_unclipped  = png2base64(@plot1)
      @lendist_clipped    = png2base64(@plot3)
      @scores_unclipped   = png2base64(@plot2)
      @scores_clipped     = png2base64(@plot4)
      @mean_scores        = png2base64(@plot5)
      @nucleotide_dist500 = png2base64(@plot6)
      @nucleotide_dist50  = png2base64(@plot7)
    end

    def bp_plot
      STDERR.puts "Creating plots ... "
      system(
        "read_sff -m -i #{@sff_file} |
         progress_meter |
         plot_distribution -k SEQ_LEN -T 'Length Distribution - unclipped' -t png -o #{@plot1} |
         plot_scores -c -T 'Mean Quality Scores - unclipped' -t png -o #{@plot2} |
         clip_seq |
         plot_distribution -k SEQ_LEN -T 'Length Distribution - clipped' -t png -o #{@plot3} |
         plot_scores -c -T 'Mean Quality Scores - clipped' -t png -o #{@plot4} |
         mean_scores |
         bin_vals -k SCORES_MEAN -b 5 |
         plot_histogram -s num -k SCORES_MEAN_BIN -T 'Mean score bins' -X 'Bins (size 5)' -Y 'Count' -t png -o #{@plot5} |
         extract_seq -l 500 |
         plot_nucleotide_distribution -c -t png -o #{@plot6} |
         extract_seq -l 50 |
         plot_nucleotide_distribution -t png -o #{@plot7} -x"
      )
      STDERR.puts "done.\n"
    end

    private

    def png2base64(file)
      png = ""

      File.open(file, "r") do |ios|
        png = ios.read
      end

      "data:image/png;base64," + Base64.encode64(png)
    end
  end

  class MidTable
    def initialize(sff_file, tmpdir)
      @sff_file  = sff_file
      @mid1_file = File.join(tmpdir, "mid1.tab")
      @mid2_file = File.join(tmpdir, "mid2.tab")
      @mid3_file = File.join(tmpdir, "mid3.tab")
      @mid4_file = File.join(tmpdir, "mid_join.tab")

      bp_find_mids
      bp_merge_mid_tables
    end

    def each
      File.open(@mid4_file, "r") do |ios|
        while not ios.eof? do
          fields = ios.readline.chomp.split("\t")
          yield MidRow.new(fields[0], fields[1], fields[2], fields[3], fields[4])
        end
      end
    end

    private

    def bp_find_mids
      STDERR.puts "Finding barcodes in raw sequences ... "
      system(
        "read_sff -i #{@sff_file} |
         find_barcodes -p 4 -gr |
         count_vals -k BARCODE_NAME |
         uniq_vals -k BARCODE_NAME |
         write_tab -c -k BARCODE_NAME,BARCODE,BARCODE_NAME_COUNT -o #{@mid1_file} -x"
      )
      STDERR.puts "done.\n"
      STDERR.puts "Finding barcodes in sequences >= 250 ... "
      system(
        "read_sff -i #{@sff_file} |
         grab -e 'SEQ_LEN >= 250' |
         find_barcodes -p 4 -gr |
         count_vals -k BARCODE_NAME |
         uniq_vals -k BARCODE_NAME |
         write_tab -c -k BARCODE_NAME,BARCODE,BARCODE_NAME_COUNT -o #{@mid2_file} -x"
      )
      STDERR.puts "done.\n"
      STDERR.puts "Finding barcodes in sequences >= 250 with mean score >= 20 ... "
      system(
        "read_sff -i #{@sff_file} |
         mean_scores |
         grab -e 'SEQ_LEN >= 250' |
         grab -e 'SCORES_MEAN >= 20' |
         find_barcodes -p 4 -gr |
         count_vals -k BARCODE_NAME |
         uniq_vals -k BARCODE_NAME |
         write_tab -c -k BARCODE_NAME,BARCODE,BARCODE_NAME_COUNT -o #{@mid3_file} -x"
      )
      STDERR.puts "done.\n"
    end

    def bp_merge_mid_tables
      STDERR.print "Joining MID tables ... "
      system(
        "read_tab -i #{@mid1_file} |
         rename_keys -k BARCODE_NAME,A |
         rename_keys -k BARCODE_NAME_COUNT,TOTAL |
         read_tab -i #{@mid2_file} |
         rename_keys -k BARCODE_NAME,B |
         rename_keys -k BARCODE_NAME_COUNT,L250 |
         merge_records -k A,B |
         read_tab -i #{@mid3_file} |
         rename_keys -k BARCODE_NAME,C |
         rename_keys -k BARCODE_NAME_COUNT,L250_S20 |
         merge_records -k A,C |
         rename_keys -k A,BARCODE_NAME |
         sort_records -k BARCODE_NAME |
         write_tab -ck BARCODE_NAME,BARCODE,TOTAL,L250,L250_S20 -o #{@mid4_file} -x"
      )
      STDERR.puts "done.\n"
    end

    class MidRow
      attr_reader :mid_num, :mid_seq, :total, :l250, :l250_s20

      def initialize(mid_num, mid_seq, total, l250, l250_s20)
        @mid_num  = mid_num
        @mid_seq  = mid_seq
        @total    = total
        @l250     = l250
        @l250_s20 = l250_s20
      end
    end
  end
end

template = %{
  <html>
    <head>
      <title>QA 454 Report</title>
    </head>
    <body>
      <h1>QA 454 Report</h1>
      <p>Date: #{Time.now}</p>
      <p>File: <%= @sff_file %></p>
      <h2>Sequence analysis</h2>
      <ul>
        <li>Number of sequences in the file: <%= @seq_analysis.count %></li>
        <li>Minimum sequence length found: <%= @seq_analysis.min %></li>
        <li>Maximum sequence length found: <%= @seq_analysis.max %></li>
        <li>Mean sequence length found: <%= @seq_analysis.mean %></li>
        <li>Total number of bases in the file: <%= @seq_analysis.bases %></li>
        <li>Mean GC% content: <%= @seq_analysis.gc %></li>
        <li>Mean of hard masked sequence (i.e. % of N's): <%= @seq_analysis.hard %></li>
        <li>Mean of soft masked sequence (i.e. % lowercase residues = clipped sequence): <%= @seq_analysis.soft %></li>
      </ul>
      <h2>Sequence length distribution</h2>
      <p>The length distribution of unclipped reads:</p>
      <p><img alt="plot_lendist_unclipped" src="<%= @plots.lendist_unclipped %>" width="600" /></p>
      <p>The length distribution of clipped reads:</p>
      <p><img alt="plot_lendist_clipped" src="<%= @plots.lendist_clipped %>" width="600" /></p>
      <h2>Quality score means</h2>
      <p>The mean scores of the unclipped sequences:</p>
      <p><img alt="plot_scores_unclipped" src="<%= @plots.scores_unclipped %>" width="600" /></p>
      <p>The mean scores of the clipped sequences:</p>
      <p><img alt="plot_scores_clipped" src="<%= @plots.scores_clipped %>" width="600" /></p>
      <p>Histogram of bins with mean quality scores:</p>
      <p><img alt="plot_mean_scores" src="<%= @plots.mean_scores %>" width="600" /></p>
      <h2>MID tag analysis</h2>
      <p>The below table contains the identified MID tags and the number of times they were found:<p>
      <ul>
      <li>BARCODE_NAME is the MID tag identifier.</li>
      <li>BARCODE is the sequence of the MID tag.</li>
      <li>TOTAL is the number of times this MID tag was found.</li>
      <li>L250 is the a subset count of TOTAL af sequences longer than 250 bases</li>
      <li>L250_S20 is a subset count of L250 af sequences with a mean score above 20</li>
      </ul>
      <table>
      <% @table_mid_join.each do |row| %>
        <tr>
        <td><%= row.mid_num %></td>
        <td><%= row.mid_seq %></td>
        <td><%= row.total %></td>
        <td><%= row.l250 %></td>
        <td><%= row.l250_s20 %></td>
        </tr>
      <% end %>
      </table>
      <h2>Residue frequency analysis</h2>
      <p>Plot of nucleotide distribution in percent of the first 50 bases:</p>
      <p><img alt="plot_nucleotide_distribution" src="<%= @plots.nucleotide_dist50 %>" width="600" /></p>
      <p>Plot of nucleotide distribution in percent of the first 500 bases:</p>
      <p><img alt="plot_nucleotide_distribution" src="<%= @plots.nucleotide_dist500 %>" width="600" /></p>
    </body>
  </html>
}.gsub(/^\s+/, '')

html = ERB.new(template)

ARGV.each do |file|
  report = Report.new(file)
                
  html.run(report.get_binding)
end

__END__
