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

require 'maasha/filesys'

# Error class for all exceptions to do with Boulder.
class BoulderError < StandardError; end

# Record seperator
SEP = "\n=\n"

# Class to manipulate boulder records - Lincoln Steins own
# YAML like format:
# http://stein.cshl.org/boulder/docs/Boulder.html
class Boulder < Filesys
  # Initialize a Boulder object.
  # Options are for testing purposes only.
  def initialize(input=STDIN, output=STDOUT)
    @input  = input
    @output = output
  end

  def each
    while not @input.eof? do
      block = @input.gets(SEP)
      raise BoulderError, "Missing record seperator" unless block =~ /#{SEP}$/

      record = {}

      block.chomp(SEP).each_line do |line|
        key, val = line.chomp.split('=', 2)

        raise BoulderError, "Missing key/value seperator" if val.nil?
        raise BoulderError, "Missing key"                 if key.empty?
        raise BoulderError, "Missing value"               if val.empty?

        record[key.to_sym] = val
      end

      yield record
    end
  end

  # Method that converts and returns a hash record as
  # a Boulder string.
  def to_boulder(record)
    str = ""

    record.each_pair do |key, val|
      str << "#{key}=#{val}\n"
    end

    str << "=\n"

    str
  end
end
