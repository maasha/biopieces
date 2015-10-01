#!/usr/bin/env ruby

# Copyright (C) 2012 Martin A. Hansen (mail@maasha.dk).

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

class Numeric
  def commify
    self.to_s.gsub(/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/, '\1,')
  end
end

def parse_analysis(file)
  data = {}

  File.open(file, 'r') do |ios|
    ios.each do |line|
      key, val = line.chomp.split(': ')
        begin Integer(val)
          val = val.to_i.commify
        rescue
          begin Float(val)
            val = val.to_f.commify
          rescue
          end
        end

      data[key] = val
    end
  end

  return data
end

def png2base64(file)
  png = ""

  File.open(file, "r") do |ios|
    png = ios.read
  end

  "data:image/png;base64," + Base64.encode64(png)
end

if ARGV.empty?
  $stderr.puts "Usage: QA_Illumina_report.rb <FASTQ file> > <HTML file>" 
  exit
end

tmpdir   = Dir.mktmpdir
seq_file = ARGV.shift

analyze_vals_file              = File.join(tmpdir, 'analyze_vals.txt')
analyze_vals_trim_file         = File.join(tmpdir, 'analyze_vals_trim_noadapt.txt')
analyze_vals_trim_noadapt_file = File.join(tmpdir, 'analyze_vals_trim.txt')
lendist_file                   = File.join(tmpdir, 'lendist.png')
scores_file                    = File.join(tmpdir, 'scores.png')
nucdist_file                   = File.join(tmpdir, 'nucdist.png')
lendist_bin_file               = File.join(tmpdir, 'lendist_bin.png')
scores_bin_file                = File.join(tmpdir, 'scores_bin.png')

STDERR.puts "Analyzing sequences ... "

system(
  "read_fastq -e base_33 -i #{seq_file} |
   progress_meter |
   analyze_vals -k SEQ -o #{analyze_vals_file} |
   trim_seq -l 3 -m 25 |
   grab -e 'SEQ_LEN > 20' |
   analyze_vals -k SEQ -o #{analyze_vals_trim_file} |
   find_adaptor -l 6 -L 6 -f ACACGACGCTCTTCCGATCT -r AGATCGGAAGAGCACACGTC |
   clip_adaptor |
   grab -e 'SEQ_LEN > 0' |
   analyze_vals -k SEQ -o #{analyze_vals_trim_noadapt_file} |
   plot_distribution -k SEQ_LEN -T 'Sequence length distribution' -X 'Sequence length' -t png -o #{lendist_file} |
   plot_scores -c -t png -o #{scores_file} |
   plot_nucleotide_distribution -c -t png -o #{nucdist_file} |
   bin_vals -k SEQ_LEN -b 25 |
   plot_distribution -T '25 bases bin sequence length distribution' -X 'Sequence length' -k SEQ_LEN_BIN -t png -o #{lendist_bin_file} |
   mean_scores |
   bin_vals -k SCORES_MEAN -b 5 |
   plot_distribution -k SCORES_MEAN_BIN -T '5 bin mean score distribution' -X 'Mean scores' -t png -o #{scores_bin_file} -x"
)

STDERR.puts "done.\n"

analysis1 = parse_analysis(analyze_vals_file)
analysis2 = parse_analysis(analyze_vals_trim_file)
analysis3 = parse_analysis(analyze_vals_trim_noadapt_file)

template = %{
  <html>
    <head>
      <title>QA Illumina Report</title>
    </head>
    <body>
      <h1>QA Illumina Report</h1>
      <p>Date: #{Time.now}</p>
      <p>File: <%= seq_file %></p>
      <h2>Sequence composition</h2>
      <table>
      <tr><td></td><td>Before trimming</td><td>After trimming</td><td>After adaptor removal</td></tr>
      <tr><td>Number of sequences</td><td align='right'><%= analysis1['COUNT'] %></td><td align='right'><%= analysis2['COUNT'] %></td><td align='right'><%= analysis3['COUNT'] %></td></tr>
      <tr><td>Number of bases</td><td align='right'><%= analysis1['SUM'] %></td><td align='right'><%= analysis2['SUM'] %></td><td align='right'><%= analysis3['SUM'] %></td></tr>
      <tr><td>Min sequence length</td><td align='right'><%= analysis1['MIN'] %></td><td align='right'><%= analysis2['MIN'] %></td><td align='right'><%= analysis3['MIN'] %></td></tr>
      <tr><td>Max sequence length</td><td align='right'><%= analysis1['MAX'] %></td><td align='right'><%= analysis2['MAX'] %></td><td align='right'><%= analysis3['MAX'] %></td></tr>
      <tr><td>Mean sequence length</td><td align='right'><%= analysis1['MEAN'] %></td><td align='right'><%= analysis2['MEAN'] %></td><td align='right'><%= analysis3['MEAN'] %></td></tr>
      </table>
      <p>Sequence trimming was performed by removing from the ends all residues until 3 consecutive</p>
      <p>residues with quality score larger than or equal to 25.</p>
      <p>All plots are after sequence trimming and adaptor removal.</p>
      <h2>Sequence length distribution</h2>
      <p><img src="<%= png2base64(lendist_file) %>" width="600" /></p>
      <p><img src="<%= png2base64(lendist_bin_file) %>" width="600" /></p>
      <h2>Sequence quality scores</h2>
      <p><img src="<%= png2base64(scores_file) %>" width="600" /></p>
      <p><img src="<%= png2base64(scores_bin_file) %>" width="600" /></p>
      <h2>Sequence nucleotide distribution</h2>
      <p><img src="<%= png2base64(nucdist_file) %>" width="600" /></p>
    </body>
  </html>
}.gsub(/^\s+/, '')

html = ERB.new(template)

puts html.result(binding)

__END__
