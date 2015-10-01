package Maasha::Common;


# Copyright (C) 2006-2007 Martin A. Hansen.

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


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DESCRIPTION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# This module contains commonly used routines


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Carp;
use Data::Dumper;
use Storable;
use IO::File;
use Time::HiRes qw( gettimeofday );
use Maasha::Config;

use Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA = qw( Exporter ) ;

use Inline ( C => <<'END_C', DIRECTORY => $ENV{ "BP_TMP" } );

int index_m( char *str, char *substr, size_t str_len, size_t substr_len, size_t offset, size_t max_mismatch )
{
    /* Martin A. Hansen & Selene Fernandez, August 2008 */

    /* Locates a substring within a string starting from offset and allowing for max_mismatch mismatches. */
    /* The begin position of the substring is returned if found otherwise -1 is returned. */

    int i = 0;
    int j = 0;

    size_t max_match = substr_len - max_mismatch;

    i = offset;

    while ( i < str_len - ( max_match + max_mismatch ) + 1 )
    {
        j = 0;
        
        while ( j < substr_len - ( max_match + max_mismatch ) + 1 )
        {
            if ( match_m( str, substr, str_len, substr_len, i, j, max_match, max_mismatch ) != 0 ) {
                return i;
            }

            j++;
        }
    
        i++;
    }

    return -1;
}


int match_m( char *str, char *substr, size_t str_len, size_t substr_len, size_t str_offset, size_t substr_offset, size_t max_match, size_t max_mismatch )
{
    /* Martin A. Hansen & Selene Fernandez, August 2008 */

    /* Compares a string and substring starting at speficied string and substring offset */
    /* positions allowing for a specified number of mismatches. Returns 1 if there is a */
    /* match otherwise returns 0. */

    size_t match    = 0;
    size_t mismatch = 0;

    while ( str_offset <= str_len && substr_offset <= substr_len )
    {
        if ( str[ str_offset ] == substr[ substr_offset ] )
        {
            match++;

            if ( match >= max_match ) {
                return 1;
            };
        }
        else
        {
            mismatch++;

            if ( mismatch > max_mismatch ) {
                return 0;
            }
        }
    
        str_offset++;
        substr_offset++;
    }

    return 0;
}


void str_analyze_C( const char *string )
{
    /* Martin A. Hansen, July 2009 */

    /* Scans a string incrementing the char count in an array. */

    int count[ 256 ] = { 0 };   /* Integer array spanning the ASCII alphabet */
    int i;

    for ( i = 0; i < strlen( string ); i++ ) {
        count[ ( int ) string[ i ] ]++;
    }

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    for ( i = 0; i < 256; i++ ) {
        Inline_Stack_Push( sv_2mortal( newSViv( count[ i ] ) ) );
    }

    Inline_Stack_Done;
}


END_C



# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub error
{
    # Martin A. Hansen, February 2008.

    # Print error message and exit with stack trace.

    my ( $msg,        # Error message.
         $no_stack,   # disable stack trace - OPTIONAL
       ) = @_;

    # Returns nothing.

    my ( $script, $error, @lines, $line, $routine, $file, $line_no, @table, $routine_max, $file_max, $line_max );

    chomp $msg;

    $script = get_scriptname();

    $error  = Carp::longmess();

    @lines  = split "\n", $error;

    $line   = shift @lines;

    push @table, [ "Routine", "File", "Line" ];
    push @table, [ "-------", "----", "----" ];

    $routine_max = length "Routine";
    $file_max    = length "File";
    $line_max    = length "Line";

    if ( $line =~ /^ at (.+) line (\d+)\.?$/ )
    {
        $file    = $1;
        $line_no = $2;

        $file_max = length $file    if length $file    > $file_max;
        $line_max = length $line_no if length $line_no > $line_max;

        push @table, [ "", $file, $line_no ];
    }
    else
    {
        die qq(ERROR: Unrecognized error line "$line"\n);
    }

    foreach $line ( @lines )
    {
        if ( $line =~ /^\s*(.+) called at (.+) line (\d+)\s*$/ )
        {
            $routine = $1;
            $file    = $2;
            $line_no = $3;
            
            $routine =~ s/\(.+\)$/ .../;

            $routine_max = length $routine if length $routine > $routine_max;
            $file_max    = length $file    if length $file    > $file_max;
            $line_max    = length $line_no if length $line_no > $line_max;

            push @table, [ $routine, $file, $line_no ];
        }
        else
        {
            die qq(ERROR: Unrecognized error line "$line"\n);
        }
    }

    $msg =~ s/\.$//;

    print STDERR qq(\nERROR!\n\nProgram \'$script\' failed: $msg.\n\n);

    die( "MAASHA_ERROR" ) if $no_stack;

    $routine_max += 3;
    $file_max    += 3;
    $line_max    += 3;

    foreach $line ( @table ) {
        printf( STDERR "%-${routine_max}s%-${file_max}s%s\n", @{ $line } );
    }

    print STDERR "\n";

    die( "MAASHA_ERROR" );
}


sub read_open
{
    # Martin A. Hansen, January 2004.

    # Read opens a file and returns a filehandle.

    my ( $path,   # full path to file
       ) = @_;

    # returns filehandle

    my ( $fh, $type );

    $type = `file $path` if -f $path;

    if ( $type =~ /gzip compressed/ ) {
        $fh = new IO::File "zcat $path|" or Maasha::Common::error( qq(Could not read-open file "$path": $!) );
    } else {
        $fh = new IO::File $path, "r" or Maasha::Common::error( qq(Could not read-open file "$path": $!) );
    }

    return $fh;
}


sub write_open
{
    # Martin A. Hansen, January 2004.

    # write opens a file and returns a filehandle

    my ( $path,   # full path to file
         $gzip,   # flag if data is to be gzipped - OPRIONAL
       ) = @_;

    # returns filehandle

    my ( $fh );

    if ( $gzip ) {
        $fh = new IO::File "|gzip -f>$path" or Maasha::Common::error( qq(Could not write-open file "$path": $!) );
    } else {
        $fh = new IO::File $path, "w" or Maasha::Common::error( qq(Could not write-open file "$path": $!) );
    }

    return $fh;
}


sub append_open
{
    # Martin A. Hansen, February 2006.

    # append opens file and returns a filehandle

    my ( $path,     # path to file
       ) = @_;

    # returns filehandle

    my ( $fh );

    $fh = new IO::File $path, "a" or Maasha::Common::error( qq(Could not append-open file "$path": $!) );

    return $fh;
}


sub pipe_open
{
    # Martin A. Hansen, January 2007.

    # opens a pipe and returns a filehandle

    my ( $fh );
    
    $fh = new IO::File "-" or Maasha::Common::error( qq(Could not open pipe: $!) );

    return $fh;
}


sub read_args
{
    # Martin A. Hansen, December 2006

    # reads arguments from @ARGV which is strictly formatted.
    # three kind of argments are accepted:
    # 1) file names           [filename]
    # 2) options with value   [--option=value]
    # 3) option without value [--option]

    my ( $args,      # list of arguments
         $ok_args,   # list of accepted arguments - OPTIONAL
       ) = @_;

    # returns a hashref

    my ( %ok_hash, $arg, @dirs, @files, %hash );

    foreach $arg ( @{ $args } )
    {
        if ( $arg =~ /^--([^=]+)=(.+)$/ ) {
            $hash{ $1 } = $2;
        } elsif ( $arg =~ /^--(.+)$/ ) {
            $hash{ $1 } = 1;
        } elsif ( -d $arg ) {
            push @dirs, $arg;
        } elsif ( -f $arg ) {
            push @files, $arg;
        } else {
            Maasha::Common::error( qq(Bad syntax in argument->"$arg") );
        }
    }

    $hash{ "DIRS" }  = \@dirs;
    $hash{ "FILES" } = \@files;

    if ( $ok_args )
    {
        map { $ok_hash{ $_ } = 1 } @{ $ok_args };

        $ok_hash{ "DIRS" }  = 1;
        $ok_hash{ "FILES" } = 1;

        map { Maasha::Common::error( qq(Unknown argument->"$_") ) if not exists $ok_hash{ $_ } } keys %hash;
    }

    return wantarray ? %hash : \%hash;
}


sub get_time
{
    # Martin A. Hansen, July 2008.

    # Get current time as a number.

    # Returns a number.

    return time;
}


sub get_time_hires
{
    # Martin A. Hansen, May 2008.

    # Get current time in high resolution.

    # Returns a float.

    return gettimeofday();
}


sub get_processid
{
    # Martin A. Hansen, July 2008.

    # Get process id for current process.

    # Returns a number.

    return $$;
}


sub get_sessionid
{
    # Martin A. Hansen, April 2008.

    # Create a session id based on time and pid.

    # Returns a number

    return get_time . get_processid;
}


sub get_user
{
    # Martin A. Hansen, July 2008.

    # Return the user name of the current user.

    # Returns a string.

    return $ENV{ 'USER' };
}


sub get_tmpdir
{
    # Martin A. Hansen, April 2008.

    # Create a temporary directory based on
    # $ENV{ 'BP_TMP' } and sessionid.

    # this thing is a really bad solution and needs to be removed.

    # Returns a path.

    my ( $user, $sid, $pid, $path );

    Maasha::Common::error( qq(no BP_TMP set in %ENV) ) if not -d $ENV{ 'BP_TMP' };

    $user = Maasha::Common::get_user();
    $sid  = Maasha::Common::get_sessionid();
    $pid  = Maasha::Common::get_processid();

    $path = "$ENV{ 'BP_TMP' }/" . join( "_", $user, $sid, $pid, "bp_tmp" );
    
    Maasha::Filesys::dir_create( $path );

    return $path;
}


sub get_scriptname
{
    # Martin A. Hansen, February 2007

    # returns the script name

    return ( split "/", $0 )[ -1 ];
}


sub get_basename
{
    # Martin A. Hansen, February 2007

    # Given a full path to a file returns the basename,
    # which is the part of the name before the last '.'.

    my ( $path,   # full path to filename
       ) = @_;

    my ( $basename );

    $basename = ( split "/", $path )[ -1 ];

    $basename =~ s/(.+)\.?.*/$1/;

    return $basename
}


sub get_fields
{
    # Martin A. Hansen, July 2008.

    # Given a filehandle to a file gets the
    # next line which is split into a list of
    # fields that is returned.

    my ( $fh,          # filehandle
         $delimiter,   # field seperator - OPTIONAL
       ) = @_;

    # Returns a list.

    my ( $line, @fields );

    $line = <$fh>;

    return if not defined $line;

    chomp $line;

    $delimiter ||= "\t";

    @fields = split "$delimiter", $line;

    return wantarray ? @fields : \@fields;
}


sub run
{
    # Martin A. Hansen, April 2007.

    # Run an execute with optional arguments.

    my ( $exe,      # executable to run
         $args,     # argument string
         $nice,     # nice flag
       ) = @_;

    # Returns nothing.

    my ( $command_line, $result );

    $command_line  = Maasha::Config::get_exe( $exe );
    $command_line .= " " . $args if $args;
    $command_line  = "nice -n19 " . $command_line if $nice;

    system( $command_line ) == 0 or Maasha::Common::error( qq(Could not execute "$command_line": $?) );
}


sub run_and_return
{
    # Martin A. Hansen, April 2008.

    # Run an execute with optional arguments returning the output
    # as a list.

    my ( $exe,      # executable to run
         $args,     # argument string
         $nice,     # nice flag
       ) = @_;

    # Returns a list.

    my ( $command_line, @result );

    $command_line  = Maasha::Config::get_exe( $exe );
    $command_line .= " " . $args if $args;
    $command_line  = "nice -n19 " . $command_line if $nice;

    @result = `$command_line`; 

    chomp @result;

    return wantarray ? @result : \@result;
}


sub time_stamp
{
    # Martin A. Hansen, February 2006.

    # returns timestamp for use in log file.
    # format: YYYY-MM-DD HH:MM:SS

    # returns string

    my ( $year, $mon, $day, $time );

    ( undef, undef, undef, $day, $mon, $year, undef, undef ) = gmtime( time );

    $mon  += 1;       # first month is 0, so we correct accordingly
    $year += 1900;

    $day  = sprintf "%02d", $day;
    $mon  = sprintf "%02d", $mon;

    $time = localtime;

    $time =~ s/.*(\d{2}:\d{2}:\d{2}).*/$1/;

    return "$year-$mon-$day $time";
}


sub time_stamp_diff
{
    # Martin A. Hansen, June 2009.

    # Return the difference between two time stamps in
    # the time stamp format.

    my ( $t0,   # time stamp 0
         $t1,   # time stamp 1
       ) = @_;

    # Returns a time stamp string.

    my ( $year0, $mon0, $day0, $hour0, $min0, $sec0,
         $year1, $mon1, $day1, $hour1, $min1, $sec1,
         $year,  $mon,  $day,  $hour,  $min,  $sec );

    $t0 =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
    $year0 = $1;
    $mon0  = $2;
    $day0  = $3;
    $hour0 = $4;
    $min0  = $5;
    $sec0  = $6;

    $sec0 += $day0 * 24 * 60 * 60;
    $sec0 += $hour0 * 60 * 60;;
    $sec0 += $min0  * 60;

    $t1 =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
    $year1 = $1;
    $mon1  = $2;
    $day1  = $3;
    $hour1 = $4;
    $min1  = $5;
    $sec1  = $6;

    $sec1 += $day1 * 24 * 60 * 60;
    $sec1 += $hour1 * 60 * 60;;
    $sec1 += $min1  * 60;

    $year = $year1 - $year0;
    $mon  = $mon1  - $mon0;
    $day  = $day1  - $day0; 

    $sec  = $sec1 - $sec0;

    $hour = int( $sec / ( 60 * 60 ) );
    $sec -= $hour * 60 * 60;

    $min  = int( $sec / 60 );
    $sec -= $min * 60;

    return join( ":", sprintf( "%02d", $hour ), sprintf( "%02d", $min ), sprintf( "%02d", $sec ) );
}


sub process_running
{
    # Martin A. Hansen, July 2008.

    # Given a process ID check if it is running
    # on the system. Return 1 if the process is
    # running else 0.

    my ( $pid,   # process ID to check.
       ) = @_;

    # Returns boolean

    my ( @ps_table );
    
    @ps_table = run_and_return( "ps", " a" );

    if ( grep /^\s*$pid\s+/, @ps_table ) {
        return 1;
    } else {
        return 0;
    }
}


sub wrap_line
{
    # Martin A. Hansen, May 2005

    # Takes a given line and wraps it to a given width,
    # without breaking any words.
    
    my ( $line,   # line to wrap
         $width,  # wrap width
       ) = @_;

    # Returns a list of lines.

    my ( @lines, $substr, $wrap_pos, $pos, $new_line );

    $pos = 0;

    while ( $pos < length $line )
    {
        $substr = substr $line, $pos, $width;

        if ( length $substr == $width )
        {
            $substr   = reverse $substr;
            $wrap_pos = index $substr, " ";

            $new_line = substr $line, $pos, $width - $wrap_pos;
            $new_line =~ s/ $//;
        
            $pos += $width - $wrap_pos;
        }
        else
        {
            $new_line = $substr;

            $pos += $width;
        }

        push @lines, $new_line;
    }

    return wantarray ? @lines : \@lines;
}


sub str_analyze
{
    # Martin A. Hansen, July 2009.

    # Analyzes the string composition of a given string.

    my ( $str,   # string to analyze
       ) = @_;

    # Returns hash

    my ( @composition, %hash, $i );

    @composition = Maasha::Common::str_analyze_C( $str ); 

    for ( $i = 32; $i <= 126; $i++ ) {          # Only include printable chars
        $hash{ chr $i } = $composition[ $i ]
    }

    return wantarray ? %hash : \%hash;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;
