#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

# Copyright (C) 2007-2013 Martin A. Hansen.

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
require 'maasha/fastq'
require 'stringio'

class FastqTest < Test::Unit::TestCase
  def setup
    @io    = StringIO.new("@test1\nATCG\n+\nABCD\n@test2\natcg\n+test2\n@ABG\n")
    @fastq = Fastq.new(@io)
  end

  test "#get_entry obtains the correct seq_name" do
    assert_equal("test1", @fastq.get_entry.seq_name)
  end

  test "#get_entry with two entries obtain correct sequences" do
    assert_equal("ATCG", @fastq.get_entry.seq)
    assert_equal("atcg", @fastq.get_entry.seq)
  end
end
