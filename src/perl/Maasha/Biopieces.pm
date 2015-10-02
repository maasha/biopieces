package Maasha::Biopieces;


# Copyright (C) 2007-2009 Martin A. Hansen.

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


# Routines for manipulation, parsing and emitting of human/machine readable biopieces records.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use Getopt::Long qw( :config bundling );
use Data::Dumper;
use Maasha::Match;
use Maasha::Common;
use Maasha::Filesys;
use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
    read_stream
    write_stream
    get_record
    put_record
);


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SIGNAL HANDLER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


$SIG{ '__DIE__' } = \&sig_handler;
$SIG{ 'INT' }     = \&sig_handler;
$SIG{ 'TERM' }    = \&sig_handler;


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub status_set
{
    my ( $time_stamp, $script, $user, $pid, $file, $fh );

    $time_stamp = Maasha::Common::time_stamp();
    $user       = Maasha::Common::get_user();
    $script     = Maasha::Common::get_scriptname();
    $pid        = Maasha::Common::get_processid();

    $file = bp_tmp() . "/" . join( ".", $user, $script, $pid ) . ".status";
    $fh   = Maasha::Filesys::file_write_open( $file );
    flock($fh, 2);

    print $fh join( ";", $time_stamp, join( " ", @ARGV ) ) . "\n";

    close $fh;
}


sub status_log
{
    # Martin A. Hansen, June 2009.

    # Retrieves initial status information written with status_set and uses this
    # to write a status entry to the log file.

    my ( $status,   # status - OPTIONAL
       ) = @_;

    # Returns nothing.

    my ( $time0, $time1, $script, $user, $pid, $file, $fh, $elap, $fh_global, $fh_local, $line, $args, $tmp_dir );

    $status ||= "OK";

    $time1      = Maasha::Common::time_stamp();
    $user       = Maasha::Common::get_user();
    $script     = Maasha::Common::get_scriptname();
    $pid        = Maasha::Common::get_processid();

    $file = bp_tmp() . "/" . join( ".", $user, $script, $pid ) . ".status";

    return if not -f $file;

    $fh   = Maasha::Filesys::file_read_open( $file );
    flock($fh, 1);
    $line = <$fh>;
    chomp $line;
    close $fh;

    unlink $file;

    ( $time0, $args, $tmp_dir ) = split /;/, $line;

    Maasha::Filesys::dir_remove( $tmp_dir ) if defined $tmp_dir;

    $elap = Maasha::Common::time_stamp_diff( $time0, $time1 );

    $fh_global = Maasha::Filesys::file_append_open( "$ENV{ 'BP_LOG' }/biopieces.log" );
    flock($fh_global, 2);
    $fh_local  = Maasha::Filesys::file_append_open( "$ENV{ 'HOME' }/.biopieces.log" );
    flock($fh_local, 2);

    print $fh_global join( "\t", $time0, $time1, $elap, $user, $status, "$script $args" ) . "\n";
    print $fh_local  join( "\t", $time0, $time1, $elap, $user, $status, "$script $args" ) . "\n";

    $fh_global->autoflush( 1 );
    $fh_local->autoflush( 1 );

    close $fh_global;
    close $fh_local;
}


sub log_biopiece
{
    # Martin A. Hansen, January 2008.

    # Log messages to logfile.

    # Returns nothing.

    my ( $time_stamp, $user, $script, $fh );

    $time_stamp = Maasha::Common::time_stamp();
    $user       = Maasha::Common::get_user();
    $script     = Maasha::Common::get_scriptname();

    $fh = Maasha::Filesys::file_append_open( "$ENV{ 'BP_LOG' }/biopieces.log" );
    flock($fh, 2);

    print $fh "$time_stamp\t$user\t$script ", join( " ", @ARGV ), "\n";

    $fh->autoflush( 1 );

    close $fh;
}


sub read_stream
{
    # Martin A. Hansen, July 2007.

    # Opens a stream to STDIN or a file,

    my ( $file,   # file - OPTIONAL
       ) = @_;

    # Returns filehandle.

    my ( $fh );

    if ( not -t STDIN ) {
        $fh = Maasha::Filesys::stdin_read();
    } elsif ( not $file ) {
        # Maasha::Common::error( qq(no data stream) );
    } else {
        $fh = Maasha::Filesys::file_read_open( $file );
    }

    return $fh;
}


sub write_stream
{
    # Martin A. Hansen, August 2007.

    # Opens a stream to STDOUT or a file.

    my ( $path,   # path          - OPTIONAL
         $gzip,   # compress data - OPTIONAL
       ) = @_;

    # Returns filehandle.

    my ( $fh );

    if ( $path ) {
        $fh = Maasha::Filesys::file_write_open( $path, $gzip );
    } else {
        $fh = Maasha::Filesys::stdout_write();
    }

    return $fh;
}


sub close_stream
{
    # Martin A. Hansen, May 2009.

    # Close stream if open.

    my ( $fh,   # filehandle
       ) = @_;

    # Returns nothing.

    close $fh if defined $fh;
}


sub get_record
{
    # Martin A. Hansen, July 2007.

    # Reads one record at a time and converts that record
    # to a Perl data structure (a hash) which is returned.

    my ( $fh,   # handle to stream
       ) = @_;

    # Returns a hash.

    my ( $block, @lines, $line, $key, $value, %record );

    return if not defined $fh;

    local $/ = "\n---\n";

    $block = <$fh>;

    return if not defined $block;

    chomp $block;

    @lines = split "\n", $block;

    foreach $line ( @lines )
    {
        ( $key, $value ) = split ": ", $line, 2;

        $record{ $key } = $value;
    }

    return wantarray ? %record : \%record;
}


sub put_record
{
    # Martin A. Hansen, July 2007.

    # Given a Perl datastructure (a hash ref) emits this to STDOUT or a filehandle.

    my ( $data,   # data structure
         $fh,     # file handle - OPTIONAL
       ) = @_;

    # Returns nothing.

    if ( scalar keys %{ $data } )
    {
        if ( $fh )
        {
            map { print $fh "$_: $data->{ $_ }\n" } keys %{ $data };
            print $fh "---\n";
        }
        else
        {
            map { print "$_: $data->{ $_ }\n" } keys %{ $data };
            print "---\n";
        }
    }

    undef $data;
}


sub parse_options
{
    # Martin A. Hansen, May 2009

    # Parses and checks options for Biopieces.

    # First the argument list is checked for duplicates and then
    # options are parsed from ARGV after which it is checked if
    # the Biopieces usage information should be printed. Finally,
    # all options from ARGV are checked according to the argument list.

    my ( $arg_list,   # data structure with argument description
       ) = @_;

    # Returns hashref.

    my ( $arg, @list, $options );

    # ---- Adding the mandatory arguments to the arg_list ----

    push @{ $arg_list }, (
        { long => 'help',       short => '?', type => 'flag',  mandatory => 'no', default => undef, allowed => undef, disallowed => undef },
        { long => 'stream_in',  short => 'I', type => 'file!', mandatory => 'no', default => undef, allowed => undef, disallowed => undef },
        { long => 'stream_out', short => 'O', type => 'file',  mandatory => 'no', default => undef, allowed => undef, disallowed => undef },
        { long => 'verbose',    short => 'v', type => 'flag',  mandatory => 'no', default => undef, allowed => undef, disallowed => undef },
    );

    check_duplicates_args( $arg_list );

    # ---- Compiling options list ----

    foreach $arg ( @{ $arg_list } )
    {
        if ( $arg->{ 'type' } eq 'flag' ) {
            push @list, "$arg->{ 'long' }|$arg->{ 'short' }";
        } else {
            push @list, "$arg->{ 'long' }|$arg->{ 'short' }=s";
        }
    }

    # ---- Parsing options from @ARGV ----

    $options = {};

    Getopt::Long::GetOptions( $options, @list );

    # print Dumper( $options );

    check_print_usage( $options );

    # ---- Expanding and checking options ----

    foreach $arg ( @{ $arg_list } )
    {
        check_mandatory(  $arg, $options );
        set_default(      $arg, $options );
        check_uint(       $arg, $options );
        check_int(        $arg, $options );
        set_list(         $arg, $options );
        check_dir(        $arg, $options );
        check_file(       $arg, $options );
        set_files(        $arg, $options );
        check_files(      $arg, $options );
        check_allowed(    $arg, $options );
        check_disallowed( $arg, $options );
    }

    # print Dumper( $options );

    # return wantarray ? $options : %{ $options }; # WTF! Someone changed the behaviour of wantarray???

    return $options;
}


sub check_duplicates_args
{
    # Martin A. Hansen, May 2009

    # Check if there are duplicate long or short arguments,
    # and raise an error if so.

    my ( $arg_list,   # List of argument hashrefs,
       ) = @_;

    # Returns nothing.

    my ( $arg, %check_hash );

    foreach $arg ( @{ $arg_list } )
    {
        Maasha::Common::error( qq(Duplicate long argument: $arg->{ 'long' }) )   if exists $check_hash{ $arg->{ 'long' } };
        Maasha::Common::error( qq(Duplicate short argument: $arg->{ 'short' }) ) if exists $check_hash{ $arg->{ 'short' } };

        $check_hash{ $arg->{ 'long' } } = 1;
        $check_hash{ $arg->{ 'short' } } = 1;
    }
}


sub check_print_usage
{
    # Martin A. Hansen, May 2009.

    # Check if we need to print usage and print usage
    # and exit if that is the case.

    my ( $options,   # option hash
       ) = @_;

    # Returns nothing.

    my ( %options, $help, $script, $wiki );

    %options = %{ $options };
    $help    = $options{ 'help' };
    delete $options{ 'help' };

    $script = Maasha::Common::get_scriptname();

    if ( $script ne 'print_wiki' )
    {
        if ( $help or -t STDIN )
        {
            if ( not ( exists $options{ 'stream_in' } or $options{ 'data_in' } ) )
            {
                if ( scalar keys %options == 0 )
                {
                    $wiki = $ENV{ 'BP_DIR' } . "/wiki/$script.md";

                    if ( $help ) {
                        `print_wiki --data_in=$wiki --help`;
                    } elsif ( $script =~ /^(list_biopieces|list_genomes|list_mysql_databases|biostat)$/ ) {
                        return;
                    } else {
                        `print_wiki --data_in=$wiki`;
                    }

                    exit;
                }
            }
        }
    }
}


sub check_mandatory
{
    # Martin A. Hansen, May 2009.

    # Check if mandatory arguments are set and raises an error if not.

    my ( $arg,       # hashref
         $options,   # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'mandatory' } eq 'yes' and not defined $options->{ $arg->{ 'long' } } ) {
        Maasha::Common::error( qq(Argument --$arg->{ 'long' } is mandatory) );
    }
}


sub set_default
{
    # Martin A. Hansen, May 2009.

    # Set default values in option hash.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( not defined $options->{ $arg->{ 'long' } } ) {
        $options->{ $arg->{ 'long' } } = $arg->{ 'default' }
    }
}


sub check_uint
{
    # Martin A. Hansen, May 2009.

    # Check if value to argument is an unsigned integer and
    # raises an error if not.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'uint' and defined $options->{ $arg->{ 'long' } } )
    {
        if ( $options->{ $arg->{ 'long' } } !~ /^\d+$/ ) {
            Maasha::Common::error( qq(Argument --$arg->{ 'long' } must be an unsigned integer - not $options->{ $arg->{ 'long' } }) );
        }
    }
}


sub check_int
{
    # Martin A. Hansen, May 2009.

    # Check if value to argument is an integer and
    # raises an error if not.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'int' and defined $options{ $arg->{ 'long' } } )
    {
        if ( $options->{ $arg->{ 'long' } } !~ /^-?\d+$/ ) {
            Maasha::Common::error( qq(Argument --$arg->{ 'long' } must be an integer - not $options->{ $arg->{ 'long' } }) );
        }
    }
}


sub set_list
{
    # Martin A. Hansen, May 2009.

    # Splits an argument of type 'list' into a list that is put
    # in the options hash.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'list' and defined $options->{ $arg->{ 'long' } } ) {
        $options->{ $arg->{ 'long' } } = [ split /,/, $options->{ $arg->{ 'long' } } ];
    }
}


sub check_dir
{
    # Martin A. Hansen, May 2009.

    # Check if an argument of type 'dir!' truly is a directory and
    # raises an error if not.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'dir!' and defined $options->{ $arg->{ 'long' } } )
    {
        if ( not -d $options->{ $arg->{ 'long' } } ) {
            Maasha::Common::error( qq(No such directory: "$options->{ $arg->{ 'long' } }") );
        }
    }
}


sub check_file
{
    # Martin A. Hansen, May 2009.

    # Check if an argument of type 'file!' truly is a file and
    # raises an error if not.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'file!' and defined $options->{ $arg->{ 'long' } } )
    {
        if ( not -f $options->{ $arg->{ 'long' } } ) {
            Maasha::Common::error( qq(No such file: "$options->{ $arg->{ 'long' } }") );
        }
    }
}


sub set_files
{
    # Martin A. Hansen, May 2009.

    # Split the argument to 'files' into a list that is put on the options hash.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    if ( $arg->{ 'type' } eq 'files' and defined $options->{ $arg->{ 'long' } } ) {
        $options->{ $arg->{ 'long' } } = [ split /,/, $options->{ $arg->{ 'long' } } ];
    }
}


sub check_files
{
    # Martin A. Hansen, May 2009.

    # Split the argument to 'files!' and check if each file do exists before adding
    # the file list to the options hash.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    my ( $elem, @files );

    if ( $arg->{ 'type' } eq 'files!' and defined $options->{ $arg->{ 'long' } } )
    {
        foreach $elem ( split /,/, $options->{ $arg->{ 'long' } } )
        {
            if ( -f $elem ) {
                push @files, $elem;
            } elsif ( $elem =~ /\*/ ) {
                push @files, glob( $elem );
            }
        }

        if ( scalar @files == 0 ) {
            Maasha::Common::error( qq(Argument to --$arg->{ 'long' } must be a valid file or fileglob expression - not $options->{ $arg->{ 'long' } }) );
        }

        $options->{ $arg->{ 'long' } } = [ @files ];
    }
}


sub check_allowed
{
    # Martin A. Hansen, May 2009.

    # Check if all values to all arguement are allowed and raise an
    # error if not.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    my ( $elem );

    if ( defined $arg->{ 'allowed' } and defined $options->{ $arg->{ 'long' } } )
    {
        map { $val_hash{ $_ } = 1 } split /,/, $arg->{ 'allowed' };

        if ( $arg->{ 'type' } =~ /^(list|files|files!)$/ )
        {
            foreach $elem ( @{ $options->{ $arg->{ 'long' } } } )
            {
                if ( not exists $val_hash{ $elem } ) {
                    Maasha::Common::error( qq(Argument to --$arg->{ 'long' } $elem is not allowed) );
                }
            }
        }
        else
        {
            if ( not exists $val_hash{ $options->{ $arg->{ 'long' } } } ) {
                Maasha::Common::error( qq(Argument to --$arg->{ 'long' } $options->{ $arg->{ 'long' } } is not allowed) );
            }
        }
    }
}


sub check_disallowed
{
    # Martin A. Hansen, May 2009.

    # Check if any values to all arguemnts are disallowed and raise an error if so.

    my ( $arg,      # hashref
         $options,  # options hash
       ) = @_;

    # Returns nothing.

    my ( $val, %val_hash );

    if ( defined $arg->{ 'disallowed' } and defined $options->{ $arg->{ 'long' } } )
    {
        foreach $val ( split /,/, $arg->{ 'disallowed' } )
        {
            if ( $options->{ $arg->{ 'long' } } eq $val ) {
                Maasha::Common::error( qq(Argument to --$arg->{ 'long' } $val is disallowed) );
            }
        }
    }
}


# marked for deletion - obsolete?
#sub getopt_files
#{
#    # Martin A. Hansen, November 2007.
#
#    # Extracts files from an explicit GetOpt::Long argument
#    # allowing for the use of glob. E.g.
#    # --data_in=test.fna
#    # --data_in=test.fna,test2.fna
#    # --data_in=*.fna
#    # --data_in=test.fna,/dir/*.fna
#
#    my ( $option,   # option from GetOpt::Long
#       ) = @_;
#
#    # Returns a list.
#
#    my ( $elem, @files );
#
#    foreach $elem ( split ",", $option )
#    {
#        if ( -f $elem ) {
#            push @files, $elem;
#        } elsif ( $elem =~ /\*/ ) {
#            push @files, glob( $elem );
#        }
#    }
#
#    return wantarray ? @files : \@files;
#}


sub sig_handler
{
    # Martin A. Hansen, April 2008.

    # Removes temporary directory and exits gracefully.
    # This subroutine is meant to be run always as the last
    # thing even if a script is dies or is interrupted
    # or killed.

    my ( $sig,   # signal from the %SIG
       ) = @_;

    # print STDERR "signal->$sig<-\n";

    my $script = Maasha::Common::get_scriptname();

    chomp $sig;

    sleep 1;

    if ( $sig =~ /MAASHA_ERROR/ )
    {
        print STDERR "\nProgram '$script' had an error"                     . "  -  Please wait for temporary data to be removed\n";
        status_log( "ERROR" );
    }
    elsif ( $sig eq "INT" )
    {
        print STDERR "\nProgram '$script' interrupted (ctrl-c was pressed)" . "  -  Please wait for temporary data to be removed\n";
        status_log( "INTERRUPTED" );
    }
    elsif ( $sig eq "TERM" )
    {
        print STDERR "\nProgram '$script' terminated (someone used kill?)"  . "  -  Please wait for temporary data to be removed\n";
        status_log( "TERMINATED" );
    }
    else
    {
        print STDERR "\nProgram '$script' died->$sig"                       . "  -  Please wait for temporary data to be removed\n";
        status_log( "DIED" );
    }

    clean_tmp();

    exit( 0 );
}


sub clean_tmp
{
    # Martin A. Hansen, July 2008.

    # Cleans out any unused temporary files and directories in BP_TMP.

    # Returns nothing.

    my ( $tmpdir, @dirs, $curr_pid, $dir, $user, $sid, $pid );

    $tmpdir = bp_tmp();

    $curr_pid = Maasha::Common::get_processid();

    @dirs = Maasha::Filesys::ls_dirs( $tmpdir );

    foreach $dir ( @dirs )
    {
        if ( $dir =~ /^$tmpdir\/(.+)_(\d+)_(\d+)_bp_tmp$/ )
        {
            $user = $1;
            $sid  = $2;
            $pid  = $3;

#            next if $user eq "maasha"; # DEBUG

            if ( $user eq Maasha::Common::get_user() )
            {
                if ( not Maasha::Common::process_running( $pid ) )
                {
                    # print STDERR "Removing stale dir: $dir\n";
                    Maasha::Filesys::dir_remove( $dir );
                }
                elsif ( $pid == $curr_pid )
                {
                    # print STDERR "Removing current dir: $dir\n";
                    Maasha::Filesys::dir_remove( $dir );
                }
            }
        }
    }
}


sub get_tmpdir
{
    # Martin A. Hansen, April 2008.

    # Create a temporary directory based on
    # $ENV{ 'BP_TMP' } and sessionid. The directory
    # name is written to the status file.

    # Returns a path.

    my ( $user, $sid, $pid, $script, $path, $file, $fh, $line );

    $user   = Maasha::Common::get_user();
    $sid    = Maasha::Common::get_sessionid();
    $pid    = Maasha::Common::get_processid();
    $script = Maasha::Common::get_scriptname();

    $path = bp_tmp() . "/" . join( "_", $user, $sid, $pid, "bp_tmp" );
    $file = bp_tmp() . "/" . join( ".", $user, $script, $pid ) . ".status";

    $fh   = Maasha::Filesys::file_read_open( $file );
    flock($fh, 1);
    $line = <$fh>;
    chomp $line;
    close $fh;

    $fh   = Maasha::Filesys::file_write_open( $file );
    flock($fh, 2);
    print $fh "$line;$path\n";
    close $fh;

    Maasha::Filesys::dir_create( $path );

    return $path;
}


sub biopiecesrc
{
    # Martin A. Hansen, July 2009.

    # Read Biopiece configuration info from .biopiecesrc.
    # and returns the value of a given key.

    my ( $key,   # configuration key
       ) = @_;

    # Returns a string.

    my ( $file, $fh, $record );

    $file = "$ENV{ 'HOME' }/.biopiecesrc";

    return undef if not -f $file;

    $fh     = Maasha::Filesys::file_read_open( $file );
    flock($fh, 1);
    $record = get_record( $fh );
    close $fh;

    if ( exists $record->{ $key } ) {
        return $record->{ $key };
    } else {
        return undef;
    }
}

sub bp_tmp
{
    # Martin A. Hansen, March 2013.

    # Returns the BP_TMP path.
    # Errs if no BP_TMP in ENV and
    # creates BP_TMP if it doesn't exists.

    my ( $path );

    Maasha::Common::error( qq(no BP_TMP set in %ENV) ) if not -d $ENV{ 'BP_TMP' };

    $path = $ENV{ 'BP_TMP' };

    unless ( -d $path ) { # No BP_TMP so we create it
        mkdir $path or die qq(failed to create dir "$path": $!);
    }

    return $path;
}

END
{
#    clean_tmp();   # FIXME - is this the bug?
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;

__END__
