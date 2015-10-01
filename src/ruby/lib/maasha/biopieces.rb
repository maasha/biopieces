raise "Ruby 1.9 or later required" if RUBY_VERSION < "1.9"

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

require 'date'
require 'fileutils'
require 'optparse'
require 'pp'
require 'stringio'
require 'zlib'

BEGIN { Dir.mkdir ENV["BP_TMP"] unless File.directory? ENV["BP_TMP"] }

TEST = false

# Monkey patch (evil) changing the to_s method of the Hash class to
# return a Hash in Biopieces format; keys and value pairs on one line
# each seperated with ': ' and terminated by a line of '---'.
class Hash
  def to_s
    string = ""

    self.each do |key, value|
      string << "#{key.to_s}: #{value}\n"
    end

    string << "---\n"

    string
  end
end

# Error class for all exceptions to do with the Biopieces class.
class BiopiecesError < StandardError; end

# Biopieces are command line scripts and uses OptionParser to parse command line
# options according to a list of casts. Each cast prescribes the long and short
# name of the option, the type, if it is mandatory, the default value, and allowed
# and disallowed values. An optional list of extra casts can be supplied, and the
# integrity of the casts are checked. Following the command line parsing, the
# options are checked according to the casts. Methods are also included for handling
# the parsing and emitting of Biopiece records, which are ASCII text records consisting
# of lines with a key/value pair separated by a colon and a white space ': '.
# Each record is separated by a line with three dashes '---'.
class Biopieces
  include Enumerable

  # Class method to check the integrity of a list of casts, followed by parsing
  # options from argv and finally checking the options according to the casts.
  def self.options_parse(argv, cast_list=[], script_path=$0)
    casts          = Casts.new(cast_list)
    option_handler = OptionHandler.new(argv, casts, script_path)
    options        = option_handler.options_parse

    options
  end

  # Class method for opening data streams for reading and writing Biopiece
  # records. Records are read from STDIN (default) or file (possibly gzipped)
  # and written to STDOUT (default) or file.
  def self.open(input = STDIN, output = STDOUT)
    io_in  = self.open_input(input)
    io_out = self.open_output(output)

    if block_given?   # FIXME begin block outmost?
      begin
        yield io_in, io_out
      ensure
        io_in.close
        io_out.close
      end
    else
      return io_in, io_out
    end
  end

  # Class method to create a temporary directory inside the ENV["BP_TMP"] directory.
  def self.mktmpdir
    time = Time.now.to_i
    user = ENV["USER"]
    pid  = $$
    path = File.join(ENV["BP_TMP"], [user, time + pid, pid, "bp_tmp"].join("_"))
    Dir.mkdir(path)
    Status.new.set_tmpdir(path)
    path
  end

  # Initialize a Biopiece object for either reading or writing from _ios_.
  def initialize(ios, stdio = nil)
    @ios   = ios
    @stdio = stdio
  end

  # Method to write a Biopiece record to _ios_.
  def puts(record)
    @ios << record.to_s
  end

  # Method to close _ios_.
  def close
    @ios.close unless @stdio
  end

  # Method to parse and yield a Biopiece record from _ios_.
  def each_record
    while record = get_entry
      yield record
    end

    self # conventionally
  end

  alias :each :each_record

  def get_entry
    record = {}

    @ios.each_line do |line|
      case line
      when /^([^:]+): (.*)$/
        record[$1.to_sym] = $2
      when /^---$/
        break
      else
        raise BiopiecesError, "Bad record format: #{line}"
      end
    end

    return record unless record.empty?
  end

  alias :get_record :each_entry

  private

  # Class method for opening data stream for reading Biopiece records.
  # Records are read from STDIN (default) or file (possibly gzipped).
  def self.open_input(input)
    if input.nil?
      if STDIN.tty?
        input = self.new(StringIO.new)
      else
        input = self.new(STDIN, true)
      end
    elsif File.exists? input
      ios = File.open(input, 'r')

      begin
        ios = Zlib::GzipReader.new(ios)
      rescue
        ios.rewind
      end

      input = self.new(ios)
    end

    input
  end

  # Class method for opening data stream for writing Biopiece records.
  # Records are written to STDOUT (default) or file.
  def self.open_output(output)
    if output.nil?
      output = self.new(STDOUT, true)
    elsif not output.is_a? IO
      output = self.new(File.open(output, 'w'))
    end

    output
  end
end


# Error class for all exceptions to do with option casts.
class CastError < StandardError; end

# Class to handle casts of command line options. Each cast prescribes the long and
# short name of the option, the type, if it is mandatory, the default value, and
# allowed and disallowed values. An optional list of extra casts can be supplied,
# and the integrity of the casts are checked.
class Casts < Array
  TYPES     = %w[flag string list int uint float file file! files files! dir dir! genome]
  MANDATORY = %w[long short type mandatory default allowed disallowed]

  # Initialize cast object with an optional options cast list to which
  # ubiquitous casts are added after which all casts are checked.
  def initialize(cast_list=[])
    @cast_list = cast_list
    ubiquitous
    check
    long_to_sym
    self.push(*@cast_list)
  end

  private

  # Add ubiquitous options casts.
  def ubiquitous
    @cast_list << {:long=>'help',       :short=>'?', :type=>'flag',  :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    @cast_list << {:long=>'stream_in',  :short=>'I', :type=>'file!', :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    @cast_list << {:long=>'stream_out', :short=>'O', :type=>'file',  :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
    @cast_list << {:long=>'verbose',    :short=>'v', :type=>'flag',  :mandatory=>false, :default=>nil, :allowed=>nil, :disallowed=>nil}
  end

  # Check integrity of the casts.
  def check
    check_keys
    check_values
    check_duplicates
  end
  
  # Check if all mandatory keys are present in casts and raise if not.
  def check_keys
    @cast_list.each do |cast|
      MANDATORY.each do |mandatory|
        raise CastError, "Missing symbol in cast: '#{mandatory}'" unless cast.has_key? mandatory.to_sym
      end
    end
  end

  # Check if all values in casts are valid.
  def check_values
    @cast_list.each do |cast|
      check_val_long(cast)
      check_val_short(cast)
      check_val_type(cast)
      check_val_mandatory(cast)
      check_val_default(cast)
      check_val_allowed(cast)
      check_val_disallowed(cast)
    end
  end

  # Check if the values to long are legal and raise if not.
  def check_val_long(cast)
    unless cast[:long].is_a? String and cast[:long].length > 1
      raise CastError, "Illegal cast of long: '#{cast[:long]}'"
    end
  end
  
  # Check if the values to short are legal and raise if not.
  def check_val_short(cast)
    unless cast[:short].is_a? String and cast[:short].length == 1
      raise CastError, "Illegal cast of short: '#{cast[:short]}'"
    end
  end

  # Check if values to type are legal and raise if not.
  def check_val_type(cast)
    type_hash = {}
    TYPES.each do |type|
      type_hash[type] = true
    end

    unless type_hash[cast[:type]]
      raise CastError, "Illegal cast of type: '#{cast[:type]}'"
    end
  end

  # Check if values to mandatory are legal and raise if not.
  def check_val_mandatory(cast)
    unless cast[:mandatory] == true or cast[:mandatory] == false
      raise CastError, "Illegal cast of mandatory: '#{cast[:mandatory]}'"
    end
  end

  # Check if values to default are legal and raise if not.
  def check_val_default(cast)
    unless cast[:default].nil?          or
           cast[:default].is_a? String  or
           cast[:default].is_a? Integer or
           cast[:default].is_a? Float
      raise CastError, "Illegal cast of default: '#{cast[:default]}'"
    end
  end

  # Check if values to allowed are legal and raise if not.
  def check_val_allowed(cast)
    unless cast[:allowed].is_a? String or cast[:allowed].nil?
      raise CastError, "Illegal cast of allowed: '#{cast[:allowed]}'"
    end
  end

  # Check if values to disallowed are legal and raise if not.
  def check_val_disallowed(cast)
    unless cast[:disallowed].is_a? String or cast[:disallowed].nil?
      raise CastError, "Illegal cast of disallowed: '#{cast[:disallowed]}'"
    end
  end

  # Check cast for duplicate long or short options names.
  def check_duplicates
    check_hash = {}
    @cast_list.each do |cast|
      raise CastError, "Duplicate argument: '--#{cast[:long]}'" if check_hash[cast[:long]]
      raise CastError, "Duplicate argument: '-#{cast[:short]}'" if check_hash[cast[:short]]
      check_hash[cast[:long]]  = true
      check_hash[cast[:short]] = true
    end
  end

  # Convert values to :long keys to symbols for all casts.
  def long_to_sym
    @cast_list.each do |cast|
      cast[:long] = cast[:long].to_sym
    end
  end
end


# Class for parsing argv using OptionParser according to given casts.
# Default options are set, file glob expressions expanded, and options are
# checked according to the casts. Usage information is printed and exit called
# if required.
class OptionHandler
  REGEX_LIST   = /^(list|files|files!)$/
  REGEX_INT    = /^(int|uint)$/
  REGEX_STRING = /^(file|file!|dir|dir!|genome)$/

  def initialize(argv, casts, script_path)
    @argv        = argv
    @casts       = casts
    @script_path = script_path
    @options     = {}
  end

  # Parse options from argv using OptionParser and casts denoting long and
  # short option names. Usage information is printed and exit called.
  # A hash with options is returned.
  def options_parse
    option_parser = OptionParser.new do |option|
      @casts.each do |cast|
        case cast[:type]
        when 'flag'
          option.on("-#{cast[:short]}", "--#{cast[:long]}") do |o|
            @options[cast[:long]] = o
          end
        when 'float'
          option.on("-#{cast[:short]}", "--#{cast[:long]} F", Float) do |f|
            @options[cast[:long]] = f
          end
        when 'string'
          option.on("-#{cast[:short]}", "--#{cast[:long]} S", String) do |s|
            @options[cast[:long]] = s
          end
        when REGEX_LIST
          option.on( "-#{cast[:short]}", "--#{cast[:long]} A", Array) do |a|
            @options[cast[:long]] = a
          end
        when REGEX_INT
          option.on("-#{cast[:short]}", "--#{cast[:long]} I", Integer) do |i|
            @options[cast[:long]] = i
          end
        when REGEX_STRING
          option.on("-#{cast[:short]}", "--#{cast[:long]} S", String) do |s|
            @options[cast[:long]] = s
          end
        else
          raise ArgumentError, "Unknown option type: '#{cast[:type]}'"
        end
      end
    end

    option_parser.parse!(@argv)

    if print_usage_full?
      print_usage_and_exit(true)
    elsif print_usage_short?
      print_usage_and_exit
    end

    options_default
    options_glob
    options_check

    @options
  end

  # Given the script name determine the path of the wiki file with the usage info.
  def wiki_path
    path = File.join(ENV["BP_DIR"], "bp_usage", File.basename(@script_path)) + ".wiki"
    raise "No such wiki file: #{path}" unless File.file? path
    path
  end

  # Check if full "usage info" should be printed.
  def print_usage_full?
    @options[:help]
  end

  # Check if short "usage info" should be printed.
  def print_usage_short?
    if not STDIN.tty?
      return false
    elsif @options[:stream_in]
      return false
    elsif @options[:data_in]
      return false
    elsif wiki_path =~ /^(list_biopieces|list_genomes|list_mysql_databases|biostat)$/  # TODO get rid of this!
      return false
    else
      return true
    end
  end

  # Print usage info by Calling an external script 'print_wiki'
  # using a system() call and exit. An optional 'full' flag
  # outputs the full usage info.
  def print_usage_and_exit(full=nil)
    if TEST
      return
    else
      if full
        system("print_wiki --data_in #{wiki_path} --help")
      else
        system("print_wiki --data_in #{wiki_path}")
      end

      raise "Failed printing wiki: #{wiki_path}" unless $?.success?

      exit
    end
  end

  # Set default options value from cast unless a value is set.
  def options_default
    @casts.each do |cast|
      if cast[:default]
        unless @options[cast[:long]]
          if cast[:type] == 'list'
            @options[cast[:long]] = cast[:default].split ','
          else
            @options[cast[:long]] = cast[:default]
          end
        end
      end
    end
  end

  # Expands glob expressions to a full list of paths.
  # Examples: "*.fna" or "foo.fna,*.fna" or "foo.fna,/bar/*.fna"
  def options_glob
    @casts.each do |cast|
      if cast[:type] == 'files' or cast[:type] == 'files!'
        if @options[cast[:long]]
          files = []
        
          @options[cast[:long]].each do |path|
            if path.include? "*"
              Dir.glob(path).each do |file|
                files << file if File.file? file
              end
            else
              files << path
            end
          end

          @options[cast[:long]] = files
        end
      end
    end
  end

  # Check all options according to casts.
  def options_check
    @casts.each do |cast|
      options_check_mandatory(cast)
      options_check_int(cast)
      options_check_uint(cast)
      options_check_file(cast)
      options_check_files(cast)
      options_check_dir(cast)
      options_check_allowed(cast)
      options_check_disallowed(cast)
    end
  end
  
  # Check if a mandatory option is set and raise if it isn't.
  def options_check_mandatory(cast)
    if cast[:mandatory]
      raise ArgumentError, "Mandatory argument: --#{cast[:long]}" unless @options[cast[:long]]
    end
  end

  # Check int type option and raise if not an integer.
  def options_check_int(cast)
    if cast[:type] == 'int' and @options[cast[:long]]
      unless @options[cast[:long]].is_a? Integer
        raise ArgumentError, "Argument to --#{cast[:long]} must be an integer, not '#{@options[cast[:long]]}'"
      end
    end
  end
  
  # Check uint type option and raise if not an unsinged integer.
  def options_check_uint(cast)
    if cast[:type] == 'uint' and @options[cast[:long]]
      unless @options[cast[:long]].is_a? Integer and @options[cast[:long]] >= 0
        raise ArgumentError, "Argument to --#{cast[:long]} must be an unsigned integer, not '#{@options[cast[:long]]}'"
      end
    end
  end

  # Check file! type argument and raise if file don't exists.
  def options_check_file(cast)
    if cast[:type] == 'file!' and @options[cast[:long]]
      raise ArgumentError, "No such file: '#{@options[cast[:long]]}'" unless File.file? @options[cast[:long]]
    end
  end

  # Check files! type argument and raise if files don't exists.
  def options_check_files(cast)
    if cast[:type] == 'files!' and @options[cast[:long]]
      @options[cast[:long]].each do |path|
        next if path == "-"
        raise ArgumentError, "File not readable: '#{path}'" unless File.readable? path
      end
    end
  end
  
  # Check dir! type argument and raise if directory don't exist.
  def options_check_dir(cast)
    if cast[:type] == 'dir!' and @options[cast[:long]]
      raise ArgumentError, "No such directory: '#{@options[cast[:long]]}'" unless File.directory? @options[cast[:long]]
    end
  end
  
  # Check options and raise unless allowed.
  def options_check_allowed(cast)
    if cast[:allowed] and @options[cast[:long]]
      allowed_hash = {}
      cast[:allowed].split(',').each { |a| allowed_hash[a.to_s] = 1 }
  
      raise ArgumentError, "Argument '#{@options[cast[:long]]}' to --#{cast[:long]} not allowed" unless allowed_hash[@options[cast[:long]].to_s]
    end
  end
  
  # Check disallowed argument values and raise if disallowed.
  def options_check_disallowed(cast)
    if cast[:disallowed] and @options[cast[:long]]
      cast[:disallowed].split(',').each do |val|
        raise ArgumentError, "Argument '#{@options[cast[:long]]}' to --#{cast[:long]} is disallowed" if val.to_s == @options[cast[:long]].to_s
      end
    end
  end
end

# Class for manipulating the execution status of Biopieces by setting a
# status file with a time stamp, process id, and command arguments. The
# status file is used for creating log entries and for displaying the
# runtime status of Biopieces.
class Status
  # Write the status to a status file.
  def set
    time0  = Time.new.strftime("%Y-%m-%d %X")

    File.open(path, "w") do |fh|
      fh.flock(File::LOCK_EX)
      fh.puts [time0, ARGV.join(" ")].join(";")
    end
  end

  # Append the a temporary directory path to the status file.
  def set_tmpdir(tmpdir_path)
    status = ""

    File.open(path, "r") do |fh|
      fh.flock(File::LOCK_SH)
      status = fh.read.chomp
    end

    status = "#{status};#{tmpdir_path}\n"

    File.open(path, "w") do |fh|
      fh.flock(File::LOCK_EX)
      fh << status
    end
  end

  # Extract the temporary directory path from the status file,
  # and return this or nil if not found.
  def get_tmpdir
    File.open(path, "r") do |fh|
      fh.flock(File::LOCK_SH)
      tmpdir_path = fh.read.chomp.split(";").last
      return tmpdir_path if File.directory?(tmpdir_path)
    end

    nil
  end

  # Write the Biopiece status to the log file.
  def log(exit_status)
    time1   = Time.new.strftime("%Y-%m-%d %X")
    user    = ENV["USER"]
    script  = File.basename($0)

    time0 = nil
    args  = nil

    File.open(path, "r") do |fh|
      fh.flock(File::LOCK_SH)
      time0, args = fh.first.split(";")
    end

    elap     = time_diff(time0, time1)
    command  = [script, args].join(" ") 
    log_file = File.join(ENV["BP_LOG"], "biopieces.log")

    File.open(log_file, "a") do |fh|
      fh.flock(File::LOCK_EX)
      fh.puts [time0, time1, elap, user, exit_status, command].join("\t")
    end
  end

  # Delete status file.
  def delete
    File.delete(path)
  end
  
  private

  # Path to status file
  def path
    user   = ENV["USER"]
    script = File.basename($0)
    pid    = $$
    path   = File.join(ENV["BP_TMP"], [user, script, pid, "status"].join("."))

    path
  end

  # Get the elapsed time from the difference between two time stamps.
  def time_diff(t0, t1)
    Time.at((DateTime.parse(t1).to_time - DateTime.parse(t0).to_time).to_i).gmtime.strftime('%X')
  end
end


# Set status when 'biopieces' is required.
Status.new.set

# Clean up when 'biopieces' exists.
at_exit do
  exit_status = $! ? $!.inspect : "OK"

  case exit_status
  when /error|errno/i
    exit_status = "ERROR"
  when "Interrupt"
    exit_status = "INTERRUPTED"
  when /SIGTERM/
    exit_status = "TERMINATED"
  when /SIGQUIT/
    exit_status = "QUIT"
  end

  status = Status.new
  tmpdir = status.get_tmpdir
  FileUtils.remove_entry_secure(tmpdir, true) unless tmpdir.nil?
  status.log(exit_status)
  status.delete
end


__END__

