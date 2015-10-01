package Maasha::Filesys;


# Copyright (C) 2006-2008 Martin A. Hansen.

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


# This module contains routines for manipulation of files and directories.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use IO::File;
use Storable;
use Data::Dumper;
use Maasha::Common;
use Digest::MD5;

use Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA = qw( Exporter ) ;


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FILES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub file_read_open
{
    # Martin A. Hansen, January 2004.

    # Read opens a file that may be gzipped and returns a filehandle.

    my ( $path,   # full path to file
       ) = @_;

    # Returns filehandle

    my ( $fh );

    if ( is_gzipped( $path ) ) {
        if ( `uname` =~ /Darwin/ ) {
            $fh = new IO::File "gzcat $path|" or Maasha::Common::error( qq(Could not read-open file "$path": $!) );
        } else {
            $fh = new IO::File "zcat $path|" or Maasha::Common::error( qq(Could not read-open file "$path": $!) );
        }
    } else {
        $fh = new IO::File $path, "r" or Maasha::Common::error( qq(Could not read-open file "$path": $!) );
    }

    return $fh;
}


sub files_read_open
{
    # Martin A. Hansen, May 2009.

    # Cats a number of files and returns a filehandle.

    my ( $files,   # full path to file
       ) = @_;

    # returns filehandle

    my ( $file, $fh, $type, %type_hash, $file_string );

    foreach $file ( @{ $files } )
    {
        Maasha::Common::error( qq(No such file: $file) ) if not -f $file;
    
        $type = `file $file`;

        if ( $type =~ /gzip compressed/ ) {
            $type_hash{ 'gzip' } = 1;
        } else {
            $type_hash{ 'ascii' } = 1;
        }
    }

    Maasha::Common::error( qq(Mixture of zipped and unzipped files) ) if scalar keys %type_hash > 1;

    $file_string = join " ", @{ $files };

    if ( $type =~ /gzip compressed/ ) {
        $fh = new IO::File "zcat $file_string|" or Maasha::Common::error( qq(Could not open pipe: $!) );
    } else {
        $fh = new IO::File "cat $file_string|" or Maasha::Common::error( qq(Could not open pipe: $!) );
    }

    return $fh;
}


sub file_write_open
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


sub file_append_open
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


sub stdin_read
{
    # Martin A. Hansen, July 2007.

    # Returns a filehandle to STDIN

    my ( $fh );

    $fh = new IO::File "<&STDIN" or Maasha::Common::error( qq(Could not read from STDIN: $!) );

    return $fh;
}


sub stdout_write
{
    # Martin A. Hansen, July 2007.

    # Returns a filehandle to STDOUT

    my ( $fh );

    $fh = new IO::File ">&STDOUT" or Maasha::Common::error( qq(Could not write to STDOUT: $!) );

    return $fh;
}


sub file_read
{
    # Martin A. Hansen, December 2004.

    # given a file, a seek beg position and
    # length, returns the corresponding string.
    
    my ( $fh,     # file handle to file
         $beg,    # read start in file
         $len,    # read length of block
        ) = @_;

    # returns string

    my ( $string );

    Maasha::Common::error( qq(Negative length: $len) ) if $len < 0;

    sysseek $fh, $beg, 0;
    sysread $fh, $string, $len;

    return $string;
}


sub file_store
{
    # Martin A. Hansen, December 2004.

    # writes a data structure to file.

    my ( $path,      # full path to file
         $data,      # data structure
       ) = @_;
    
    Storable::store( $data, $path ) or Maasha::Common::error( qq(Could not write-open file "$path": $!) );
}


sub file_retrieve
{
    # Martin A. Hansen, December 2004.

    # retrieves hash data structure
    # (this routines needs to test if its a hash, array or else)

    my ( $path,   # full path to data file
       ) = @_;

    my ( $data );

    $data = Storable::retrieve( $path ) or Maasha::Common::error( qq(Could not read-open file "$path": $!) );

    return wantarray ? %{ $data } : $data;
}


sub file_copy
{
    # Martin A. Hansen, November 2008.

    # Copy the content of a file from source path to
    # destination path.

    my ( $src,   # source path
         $dst,   # destination path
       ) = @_;

    # Returns nothing.

    my ( $fh_in, $fh_out, $line );

    Maasha::Common::error( qq(copy failed: destination equals source "$src") ) if $src eq $dst;

    $fh_in  = file_read_open( $src );
    $fh_out = file_write_open( $dst );

    while ( $line = <$fh_in> ) {
        print $fh_out $line;
    } 

    close $fh_in;
    close $fh_out;
}


sub is_gzipped
{
    # Martin A. Hansen, November 2008.

    # Checks if a given file is gzipped.
    # Currrently uses a call to the systems
    # file tool. Returns 1 if gzipped otherwise
    # returns 0.

    my ( $path,   # path to file
       ) = @_;

    # Returns boolean.

    my ( $type );
    
    $type = `file $path`;

    if ( $type =~ /gzip compressed/ ) {
        return 1;
    } else {
        return 0;
    }
}


sub file_size
{
    # Martin A. Hansen, March 2007

    # returns the file size for a given file

    my ( $path,   # full path to file
       ) = @_;

    # returns integer

    my $file_size = -s $path;

    return $file_size;
}


sub file_md5
{
    # Martin A. Hansen, December 2009.

    # Get an MD5 sum for a given file.

    my ( $file,   # file path
       ) = @_;

    # Returns a string.

    my ( $fh, $md5 );

    $fh = file_read_open( $file );

    $md5 = Digest::MD5->new;

    $md5->addfile( $fh );

    close $fh;

    return $md5->hexdigest;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DIRECTORIES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub dir_create
{
    # Martin A. Hansen, July 2007.

    # Creates a directory.

    my ( $path,   # full path to dir
       ) = @_;

    # Returns created path.

    if ( -d $path ) {
        Maasha::Common::error( qq(Directory already exists "$path") );
    } else {
        mkdir $path or Maasha::Common::error( qq(Could not create directory "$path": $!) );
    }

    return $path;
}


sub dir_create_if_not_exists
{
    # Martin A. Hansen, May 2008.

    # Creates a directory if it does not already exists.

    my ( $path,   # full path to dir
       ) = @_;

    # Returns path.

    if ( not -d $path ) {
        mkdir $path or Maasha::Common::error( qq(Could not create directory "$path": $!) );
    }

    return $path;
}


sub dir_remove
{
    # Martin A. Hansen, April 2008.

    # Removes a directory recursively.

    my ( $path,   # directory
       ) = @_;

    Maasha::Common::run( "rm", "-rf $path" ) if -d $path;
}


sub ls_dirs
{
    # Martin A. Hansen, June 2007.

    # returns all dirs in a given directory.

    my ( $path,   # full path to directory
       ) = @_;

    # returns a list of filenames.

    my ( $dh, @dirs );

    $dh = open_dir( $path );

    @dirs =  read_dir( $dh );
    @dirs = grep { -d "$path/$_" } @dirs;

    map { $_ = "$path/$_" } @dirs;

    close $dh;

    @dirs = sort @dirs;

    return wantarray ? @dirs : \@dirs;
}


sub ls_dirs_base
{
    # Martin A. Hansen, November 2009.

    # Returns all directory basenames execpt . and ..
    # from a given directory.

    my ( $path,
       ) = @_;

    # Returns a list.

    my ( @dirs, $dir, @list );

    @dirs = Maasha::Filesys::ls_dirs( $path );

    foreach $dir ( @dirs )
    {
        next if $dir =~ /\/\.\.?$/;

        push @list, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @list : \@list;
}


sub ls_files
{
    # Martin A. Hansen, June 2007.

    # returns all files in a given directory.

    my ( $path,   # full path to directory
       ) = @_;

    # returns a list of filenames.

    my ( $dh, @files );

    $dh = open_dir( $path );

    @files =  read_dir( $dh );
    @files = grep { -f "$path/$_" } @files;

    map { $_ = "$path/$_" } @files;

    close $dh;

    return wantarray ? @files : \@files;
}


sub open_dir
{
    # Martin A. Hansen, June 2007.

    # open a directory and returns a directory handle

    use IO::Dir;

    my ( $path,   # full path to directory
       ) = @_;

    # returns object

    my $dh;

    $dh = IO::Dir->new( $path ) or Maasha::Common::error( qq(Could not open dir "$path": $!) );

    return $dh;
}


sub read_dir
{
    # Martin A. Hansen, June 2007.

    # read all files and directories from a directory.

    my ( $dh,   # directory handle object
       ) = @_;

    # returns list

    my ( $elem, @elems );

    while ( defined( $elem = $dh->read ) ) {
        push @elems, $elem;
    }

    return wantarray ? @elems : \@elems;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;


__END__
