#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

require 'test/unit'
require 'test/helper'
require 'maasha/biopieces'
require 'stringio'

Biopieces::TEST     = true
OptionHandler::TEST = true

TYPES       = %w[flag string list int uint float file file! files files! dir dir! genome]
DUMMY_FILE  = __FILE__
SCRIPT_PATH = "write_fasta"

class BiopiecesTest < Test::Unit::TestCase
  # >>>>>>>>>>>>>>>>>>>> Testing Options.new <<<<<<<<<<<<<<<<<<<<

  test "Biopieces.options_parse with all cast keys dont raise" do
    argv  = []
    casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
    assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
  end

  test "Biopieces.options_parse with illegal long cast values raises" do
    [nil, true, false, 1, 0, "a"].each do |long|
      argv  = []
      casts = [{:long=>long, :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal long cast values dont raise" do
    ["foo", "!!", "0123"].each do |long|
      argv  = []
      casts = [{:long=>long, :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal short cast values raises" do
    [nil, true, false, "foo"].each do |short|
      argv  = []
      casts = [{:long=>"foo", :short=>short, :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal short cast values dont raise" do
    ["!", "1", "a"].each do |short|
      argv  = []
      casts = [{:long=>"foo", :short=>short, :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal type cast values raises" do
    [nil, true, false, "foo", 12, 0].each do |type|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>type, :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal type cast values dont raise" do
    TYPES.each do |type|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>type, :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal mandatory cast values raises" do
    ["yes", 12, 0, nil].each do |mandatory|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>mandatory, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal mandatory cast values dont raise" do
    [true, false].each do |mandatory|
      argv  = [ "--foo", "1" ]
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>mandatory, :default=>nil, :allowed=>nil, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal default cast values raises" do
    [true, false, [], {}].each do |default|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>default, :allowed=>nil, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal default cast values dont raise" do
    [nil, 0, 1, -1].each do |default|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>default, :allowed=>nil, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal allowed cast values raises" do
    [true, false, {}, [], 0, 0.1].each do |allowed|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>allowed, :disallowed=>nil}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal allowed cast values dont raise" do
    ["foo,bar,0",nil].each do |allowed|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>allowed, :disallowed=>nil}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with illegal disallowed cast values raises" do
    [true, false, {}, [], 0, 0.1].each do |disallowed|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>disallowed}]
      assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with legal disallowed cast values dont raise" do
    ["foo,bar,0",nil].each do |disallowed|
      argv  = []
      casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>disallowed}]
      assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
    end
  end

  test "Biopieces.options_parse with duplicate long cast values raises" do
    argv  = []
    casts = []
    casts << {:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    casts << {:long=>"foo", :short=>"b", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
  end

  test "Biopieces.options_parse with duplicate short cast values raises" do
    argv  = []
    casts = []
    casts << {:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    casts << {:long=>"bar", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    assert_raise(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
  end

  test "Biopieces.options_parse without duplicate long and short cast values dont raise" do
    argv  = []
    casts = []
    casts << {:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    casts << {:long=>"bar", :short=>"b", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    assert_nothing_raised(CastError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
  end

  # >>>>>>>>>>>>>>>>>>>> Testing Options.parse <<<<<<<<<<<<<<<<<<<<

  test "Biopieces.options_parse with empty argv and missing wiki file raises" do
    argv  = []
    casts = []
    assert_raise(RuntimeError) { Biopieces.options_parse(argv,casts, "foo") }
  end

  test "Biopieces.options_parse with empty argv and existing wiki file dont raise" do
    argv  = []
    casts = []
    assert_nothing_raised { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
  end

  test "Biopieces.options_parse with help in argv and existing wiki output long usage" do
    argv = ["--help"]
    assert_nothing_raised { Biopieces.options_parse(argv,[],SCRIPT_PATH) }
  end

  test "Biopieces.options_parse with stream in argv returns correct options" do
    argv = ["--stream_in", DUMMY_FILE]
    options = Biopieces.options_parse(argv,[],SCRIPT_PATH)
    assert_equal(DUMMY_FILE, options[:stream_in])
  end
 
   test "Biopieces.options_parse with I argv returns correct options" do
     argv    = ["-I", DUMMY_FILE]
     casts   = []
     options = Biopieces.options_parse(argv, casts, SCRIPT_PATH)
     assert_equal(DUMMY_FILE, options[:stream_in])
   end
 
   test "Biopieces.options_parse use cast default value if no argument given" do
     argv    = ["-I", DUMMY_FILE]
     casts   = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>"bar", :allowed=>nil, :disallowed=>nil}]
     options = Biopieces.options_parse(argv, casts, SCRIPT_PATH)
     assert_equal(options[:foo], "bar")
   end
 
   test "Biopieces.options_parse dont use default value if argument given" do
     argv    = ["--foo", "bleh", "-I", DUMMY_FILE]
     casts   = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>"bar", :allowed=>nil, :disallowed=>nil}]
     options = Biopieces.options_parse(argv, casts, SCRIPT_PATH)
     assert_equal(options[:foo], "bleh")
   end
 
   test "Biopieces.options_parse with mandatory cast and no argument raises" do
     argv  = ["-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>true, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_raise(ArgumentError) { Biopieces.options_parse(argv,casts,SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with mandatory cast and argument dont raise" do
     argv  = ["--foo", "bar", "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>true, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv,casts,SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with type cast int dont raise" do
     [0,-1,1,327649123746293746374276347824].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"int", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
       assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv,casts,SCRIPT_PATH) }
     end
   end
 
   test "Biopieces.options_parse with type cast uint dont raise" do
     [0,1,327649123746293746374276347824].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"uint", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
       assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
     end
   end
 
   test "Biopieces.options_parse with file cast and file dont exists raises" do
     argv  = ["--foo", "bleh", "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"file!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_raise(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with file cast and existing file dont raise" do
     argv  = ["--foo", DUMMY_FILE, "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"file!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with files cast and a file dont exists raises" do
     argv  = ["--foo", DUMMY_FILE + ",bleh", "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"files!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_raise(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with files cast and files exists dont raise" do
     argv  = ["--foo", DUMMY_FILE + "," + DUMMY_FILE, "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"files!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with glob argument expands correctly" do
     path = File.join(ENV['BP_DIR'], "bp_test")
     argv    = ["--foo", "#{path}/te*,#{path}/lib/*.sh", "-I", DUMMY_FILE]
     casts   = [{:long=>"foo", :short=>"f", :type=>"files!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     options = Biopieces.options_parse(argv, casts, SCRIPT_PATH)
     assert_equal(["#{path}/test_all", "#{path}/lib/test.sh"], options[:foo])
   end
 
   test "Biopieces.options_parse with dir cast and dir dont exists raises" do
     argv  = ["--foo", "bleh", "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"dir!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_raise(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with dir cast and dir exists dont raise" do
     argv  = ["--foo", "/", "-I", DUMMY_FILE]
     casts = [{:long=>"foo", :short=>"f", :type=>"dir!", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}]
     assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
   end
 
   test "Biopieces.options_parse with allowed cast and not allowed value raises" do
     ["bleh", "2", "3.3"].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>nil, :allowed=>"0,-1,0.0,1,bar", :disallowed=>nil}]
       assert_raise(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
     end
   end
 
   test "Biopieces.options_parse with allowed cast and allowed values dont raise" do
     ["0", "-1", "0.0", "1", "bar"].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>nil, :allowed=>"0,-1,0.0,1,bar", :disallowed=>nil}]
       assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
     end
   end
 
   test "Biopieces.options_parse with disallowed cast and disallowed value raises" do
     ["0", "-1", "0.0", "1", "bar"].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>"0,-1,0.0,1,bar"}]
       assert_raise(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
     end
   end
 
   test "Biopieces.options_parse with disallowed cast and allowed values dont raise" do
     ["bleh", "2", "3.3"].each do |val|
       argv  = ["--foo", "#{val}", "-I", DUMMY_FILE]
       casts = [{:long=>"foo", :short=>"f", :type=>"string", :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>"0,-1,0.0,1,bar"}]
       assert_nothing_raised(ArgumentError) { Biopieces.options_parse(argv, casts, SCRIPT_PATH) }
     end
   end
end
