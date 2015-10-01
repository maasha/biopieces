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

# Class for running the Prodigal gene finder.
# http://prodigal.ornl.gov/
class Prodigal
  include Enumerable

  # Method to initialize a Prodigal object
  # given a temporary infile, outfile and options hash.
  def initialize(infile, outfile, options)
    @infile  = infile    # FASTA
    @outfile = outfile   # GFF
    @options = options   # Options hash
  end

  # Method to run Prodigal.
  def run
    commands = []
    commands << "prodigal"
    commands << "-c" if @options[:full]
    commands << "-p #{@options[:procedure]}"
    commands << "-f gff"
    commands << "-i #{@infile}"
    commands << "-a #{@outfile}"
    commands << "-m"
    commands << "-q" unless @options[:verbose]

    execute(commands, @options[:verbose])
  end

  # Method for iterating over the Prodigal results,
  # which are in GFF format.
  def each
    Fasta.open(@outfile, 'r') do |ios|
      ios.each do |entry|
        record = {}

        fields = entry.seq_name.split(" # ")

        record[:REC_TYPE] = "GENE"
        record[:S_ID]     = fields[0]
        record[:S_BEG]    = fields[1].to_i - 1
        record[:S_END]    = fields[2].to_i - 1
        record[:S_LEN]    = record[:S_END] - record[:S_BEG] + 1
        record[:STRAND]   = fields[3] == '1' ? '+' : '-'
        record[:SEQ]      = entry.seq
        record[:SEQ_LEN]  = entry.length

        yield record
      end
    end
  end

  # Method that returns the sum of the predicted gene lengths.
  def coverage
    coverage = 0

    self.each do |gb|
      coverage += gb[:S_END] - gb[:S_BEG]
    end

    coverage
  end

  private

  # Method to execute commands on the command line.
  # TODO this wants to be in a module on its own.
  def execute(commands, verbose = false)
    commands.unshift "nice -n 19"
    commands << " > /dev/null"

    command = commands.join(" ")

    system(command)
    raise "Command failed: #{command}" unless $?.success?
  end
end

__END__
