# Copyright (C) 2013 Martin A. Hansen.

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

# Error class for all exceptions to do with Table.
class TableError < StandardError; end

class Table
  def initialize(options = {})
    @options = options
    @header  = []
    @table   = []

    table_parse if @options[:file_in]
  end

  def rows
    @table.size
  end

  def columns
    @table.first.size
  end

  def each_row
    @table.each do |row|
      yield row
    end

    self
  end

  def each_column
    @table.first.each_with_index do |key, i|
      column = []
      column << @header[i] unless @header.empty?

      self.each_row { |r| column << r[i] }

      yield column
    end

    self
  end

  def to_s
    lines = []
    lines << "#" + @header.join("\t") unless @header.empty?

    self.each_row { |r| lines << r.join("\t") }
    lines.join("\n")
  end

  private

  def table_parse
    File.open(@options[:file_in]) do |ios|
      ios.each do |line|
        if line[0] == '#'
          if @header.empty?
            @header = line[1 .. line.size].chomp.split(" ")

            uniq = {}
            
            @header.each do |key|
              raise TableError, "Duplicate header: #{key}" if uniq[key]
              uniq[key] = true
            end
          end
        else
          fields = line.chomp.split(" ")

          unless @header.empty? 
            raise TableError, "Bad number of fields: #{fields.size} - expecting: #{@header.size}" unless @header.size == fields.size
          end

          @table << fields
        end
      end
    end
  end
end
