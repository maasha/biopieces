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

require 'open3'

# Error class for all exceptions to do with Filesys.
class FilesysError < StandardError; end

class Filesys
  include Enumerable

  # Class method that returns a path to a unique temporary file.
  # If no directory is specified reverts to the systems tmp directory.
  def self.tmpfile(tmp_dir = ENV["TMPDIR"])
    time = Time.now.to_i
    user = ENV["USER"]
    pid  = $$
    path = tmp_dir + [user, time + pid, pid].join("_") + ".tmp"
    path
  end

  def self.open(*args)
    file    = args.shift
    mode    = args.shift
    options = args.shift || {}

    if mode == 'w'
      case options[:compress]
      when :gzip
        ios, = Open3.pipeline_w("gzip -f", out: file)
      when :bzip, :bzip2
        ios, = Open3.pipeline_w("bzip2 -c", out: file)
      else 
        ios = File.open(file, mode, options)
      end
    else
      if file == '-'
        ios = STDIN
      else
        case `file -Lk #{file}`
        when /gzip/
          ios = IO.popen("gzip -cd #{file}", :external_encoding=>"EUC-JP")
        when /bzip/
          ios = IO.popen("bzcat #{file}")
        when /ASCII/
          ios = File.open(file, mode, options)
        else
          raise "Unknown file type: #{`file -L #{file}`}"
        end
      end
    end

    if block_given?
      begin
        yield self.new(ios)
      ensure
        ios.close
      end
    else
      return self.new(ios)
    end
  end

  def initialize(ios)
    @io = ios
  end

  def puts(*args)
    @io.puts(*args)
  end

  def close
    @io.close
  end

  def eof?
    @io.eof?
  end

  # Iterator method for parsing entries.
  def each
    while entry = get_entry do
      yield entry
    end
  end
end

