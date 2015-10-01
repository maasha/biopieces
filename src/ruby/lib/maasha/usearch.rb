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

require 'maasha/fasta'
require 'maasha/align'

# Error class for all exceptions to do with Usearch.
class UsearchError < StandardError; end

USEARCH = "usearch7"

class Usearch
  include Enumerable

  def initialize(infile, outfile, options)
    @infile  = infile
    @outfile = outfile
    @options = options
    @command = []

    raise UsearchError, %{Empty input file -> "#{@infile}"} if File.size(@infile) == 0
  end

  # Method that calls Usearch sorting for sorting a FASTA file
  # according to decending sequence length.
  def sortbylength
    # usearch -sortbylength seqs.fasta -output seqs_sorted.fasta -minseqlength 64
    @command << USEARCH
    @command << "-sortbylength #{@infile}"
    @command << "-output #{@infile}.sort"

		execute

    File.rename "#{@infile}.sort", @infile
  end

  # Method that calls Usearch sorting for sorting a FASTA file
  # according to cluster size.
  def sortbysize
    # usearch -sortbysize seqs.fasta -output seqs_sorted.fasta -minsize 4
    @command << USEARCH
    @command << "-sortbysize #{@infile}"
    @command << "-output #{@infile}.sort"

		execute

    File.rename "#{@infile}.sort", @infile
  end

  # Method to execute cluster_fast.
  def cluster_fast
    # usearch -cluster_fast query.fasta -id 0.9 -centroids nr.fasta -uc clusters.uc
    @command << USEARCH
    @command << "-cluster_fast #{@infile}"
    @command << "-id #{@options[:identity]}"
    @command << "-threads #{@options[:cpus]}"

    if @options[:msa]
      @command << "-msaout #{@outfile}"
    else
      @command << "-uc #{@outfile}"
    end

    execute
  end

  # Method to execute cluster_smallmem.
  # NB sequences must be sorted with sortbylength or sortbysize.
  def cluster_smallmem
    # usearch -cluster_smallmem query.fasta -id 0.9 -centroids nr.fasta -uc clusters.uc
    @command << USEARCH
    @command << "-cluster_smallmem #{@infile}"
    @command << "-id #{@options[:identity]}"
    @command << "-strand both" if @options[:comp]

    if @options[:msa]
      @command << "-msaout #{@outfile}"
    else
      @command << "-uc #{@outfile}"
    end

    execute
  end

  # Method to execute database local search.
  def usearch_local
    # usearch -usearch_local query.fasta -db proteins.udb -id 0.8 -alnout results.aln
    # usearch -usearch_local query.fasta -db ESTs.fasta -id 0.9 -evalue 1e-6 -blast6out results.m8 -strand plus -maxaccepts 8 -maxrejects 256
    
    @command << USEARCH
    @command << "-usearch_local #{@infile}"
    @command << "-db #{@options[:database]}"
    @command << "-blast6out #{@outfile}"
    @command << "-strand both"
    @command << "-id #{@options[:identity]}"  if @options[:identity]
    @command << "-evalue #{@options[:e_val]}" if @options[:e_val]
    @command << "-maxaccepts #{@options[:maxaccepts]}"
    @command << "-threads #{@options[:cpus]}"

    execute
  end

  # Method to execute database global search.
  def usearch_global
    # usearch -usearch_global query.fasta -db proteins.udb -id 0.8 -alnout results.aln
    # usearch -usearch_global query.fasta -db ESTs.fasta -id 0.9 -blast6out results.m8 -strand plus -maxaccepts 8 -maxrejects 256

    @command << USEARCH
    @command << "-usearch_global #{@infile}"
    @command << "-db #{@options[:database]}"
    @command << "-blast6out #{@outfile}"
    @command << "-strand both"
    @command << "-id #{@options[:identity]}"
    @command << "-evalue #{@options[:e_val]}" if @options[:e_val]
    @command << "-maxaccepts #{@options[:maxaccepts]}"
    @command << "-threads #{@options[:cpus]}"

    execute
  end

  # Method to execute uchime chimera detection.
  def uchime
    @command << USEARCH
    @command << "--uchime #{@infile}"
    @command << "--db #{@options[:database]}"
    @command << "--uchimeout #{@outfile}"

    execute
  end

  # Method to execute ustar alignment.
  def ustar
    command = %Q{grep "^[SH]" #{@outfile} > #{@outfile}.sub}
    system(command)
    raise "Command failed: #{command}" unless $?.success?

    File.rename "#{@outfile}.sub", @outfile

    @command << USEARCH
    @command << "--uc2fastax #{@outfile}"
    @command << "--input #{@infile}"
    @command << "--output #{@infile}.sub"

    execute

    @command << USEARCH
    @command << "--staralign #{@infile}.sub"
    @command << "--output #{@outfile}"

    execute

    File.delete "#{@infile}.sub"
  end

	# Method to parse a Uclust .uc file and for each line of data
	# yield a Biopiece record.
  def each_cluster
    record = {}

    File.open(@outfile, "r") do |ios|
      ios.each_line do |line|
        if line !~ /^#/
          fields = line.chomp.split("\t")

          next if fields[0] == 'C'

          record[:TYPE]     = fields[0]
          record[:CLUSTER]  = fields[1].to_i
          record[:IDENT]    = fields[3].to_f
          record[:Q_ID]     = fields[8]

          yield record
        end
      end
    end

    self # conventionally
  end

	# Method to parse a Useach user defined tabular file and for each line of data
	# yield a Biopiece record.
  def each_hit
    record = {}

    File.open(@outfile, "r") do |ios|
      ios.each_line do |line|
        fields = line.chomp.split("\t")
        record[:REC_TYPE]   = "USEARCH"
        record[:Q_ID]       = fields[0]
        record[:S_ID]       = fields[1]
        record[:IDENT]      = fields[2].to_f
        record[:ALIGN_LEN]  = fields[3].to_i
        record[:MISMATCHES] = fields[4].to_i
        record[:GAPS]       = fields[5].to_i
        record[:Q_BEG]      = fields[6].to_i - 1
        record[:Q_END]      = fields[7].to_i - 1
        record[:S_BEG]      = fields[8].to_i - 1
        record[:S_END]      = fields[9].to_i - 1
        record[:E_VAL]      = fields[10] == '*' ? '*' : fields[10].to_f
        record[:SCORE]      = fields[11] == '*' ? '*' : fields[11].to_f
        record[:STRAND]     = record[:S_BEG].to_i < record[:S_END].to_i ? '+' : '-'

        record[:S_BEG], record[:S_END] = record[:S_END], record[:S_BEG] if record[:STRAND] == '-'

        yield record
      end
    end

    self # conventionally
  end

  # Method to parse a FASTA file with Ustar alignments and for each alignment
  # yield an Align object.
  def each_alignment
    old_cluster = 0
    entries     = []

    Fasta.open(@outfile, "r") do |ios|
      ios.each do |entry|
        entry.seq.tr! '+', '-'
        entries << entry

        if entry.seq_name == 'consensus'
          yield Align.new(entries[0 .. -2])
          entries = []
        end
      end
    end

    self
  end

  private

	# Method to execute a command using a system() call.
	# The command is composed of bits from the @command variable.
	def execute
		@command << "--quiet" unless @options[:verbose]
		command = @command.join(" ")
    $stderr.puts "Running command: #{command}" if @options[:verbose]
    system(command)
    raise "Command failed: #{command}" unless $?.success?

		@command = []
	end
end

__END__

