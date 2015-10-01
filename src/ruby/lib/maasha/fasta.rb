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
require 'maasha/filesys'

# Error class for all exceptions to do with FASTA.
class FastaError < StandardError; end

class Fasta < Filesys
  # Method to get the next FASTA entry form an ios and return this
  # as a Seq object. If no entry is found or eof then nil is returned.
  def get_entry
    block = nil 

    while block = @io.gets($/ + '>') and block.chomp($/ + '>').empty?
    end

    return nil if block.nil?

    block.chomp!($/ + '>')

    (seq_name, seq) = block.split($/, 2)

    raise FastaError, "Bad FASTA format" if seq_name.nil? or seq.nil?

    entry          = Seq.new
    entry.seq      = seq.gsub(/\s/, '')
    entry.seq_name = seq_name.sub(/^>/, '').rstrip
    entry.type     = nil

    raise FastaError, "Bad FASTA format" if entry.seq_name.empty?
    raise FastaError, "Bad FASTA format" if entry.seq.empty?

    entry
  end

  # Method to get the next pseudo FASTA entry consisting of a sequence name and
  # space seperated quality scores in decimals instead of sequence. This is
  # the quality format used by Sanger and 454.
  def get_decimal_qual
    block = @io.gets($/ + '>')
    return nil if block.nil?

    block.chomp!($/ + '>')

    (seq_name, qual) = block.split($/, 2)

    raise FastaError, "Bad FASTA qual format" if seq_name.nil? or qual.nil?

    entry          = Seq.new
    entry.seq_name = seq_name.sub(/^>/, '').rstrip
    entry.seq      = nil
    entry.type     = nil
    entry.qual     = qual.tr("\n", " ").strip.split(" ").collect { |q| (q.to_i + SCORE_BASE).chr }.join("")

    raise FastaError, "Bad FASTA format" if entry.seq_name.empty?
    raise FastaError, "Bad FASTA format" if entry.qual.empty?

    entry
  end
end


__END__
