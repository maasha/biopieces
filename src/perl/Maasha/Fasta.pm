package Maasha::Fasta;

# Copyright (C) 2006-2009 Martin A. Hansen.

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


# Routines for manipulation of FASTA files and FASTA entries.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Exporter;
use Data::Dumper;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    SEQ_NAME => 0,
    SEQ  => 1,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub get_entry
{
    # Martin A. Hansen, January 2007.

    # Given a filehandle to an FASTA file,
    # fetches the next FASTA entry, and returns
    # this as a tuple of [ header, sequence ].

    my ( $fh,    # filehandle to FASTA file
       ) = @_;

    # Returns string.
    
    my ( $block, @lines, $seq_name, $seq, $entry );

    local $/ = "\n>";

    while ( $block = <$fh> )
    {
        chomp $block;

        last if $block !~ /^\s+$/;
    }

    return if not defined $block;

    # $block =~ />?([^\n]+)\n/m;
    $block =~ /^>?(.+)\n/m;
    $seq_name = $1;
    $seq      = $';

    local $/ = "\n";

    chomp $seq;

    $seq_name =~ tr/\r//d;
    $seq      =~ tr/ \t\n\r//d;

    $entry = [ $seq_name, $seq ];

    return wantarray ? @{ $entry } : $entry;
}


sub put_entry
{
    # Martin A. Hansen, January 2007.

    # Writes a FASTA entry to a file handle.

    my ( $entry,     # a FASTA entries
         $fh,        # file handle to output file - OPTIONAL
         $wrap,      # line width                 - OPTIONAL
       ) = @_;

    # Returns nothing.

    Maasha::Common::error( qq(FASTA entry has no header) )   if not defined $entry->[ SEQ_NAME ];
    Maasha::Common::error( qq(FASTA entry has no sequence) ) if not defined $entry->[ SEQ ];

    if ( $wrap ) {
        Maasha::Fasta::wrap( $entry, $wrap );
    }

    if ( defined $fh ) {
        print $fh ">$entry->[ SEQ_NAME ]\n$entry->[ SEQ ]\n";
    } else {
        print ">$entry->[ SEQ_NAME ]\n$entry->[ SEQ ]\n";
    }
}


sub put_entries
{
    # Martin A. Hansen, September 2009

    # Write FASTA entries to a file.

    my ( $entries,   # list of FASTA entries
         $file,      # output file
         $wrap,      # line width  -  OPTIONAL
       ) = @_;

    # Returns nothing

    my ( $fh );

    $fh = Maasha::Filesys::file_write_open( $file );

    map { put_entry( $_, $fh, $wrap ) } @{ $entries };

    close $fh;
}


sub wrap
{
    # Martin A. Hansen, June 2007

    # Wraps the sequence of a given FASTA entry
    # to a given length.

    my ( $entry,   # FASTA entry
         $wrap,    # wrap length
       ) = @_;

    # Returns nothing.

    Maasha::Seq::wrap( \$entry->[ SEQ ], $wrap );
}


sub fasta_index
{
    # Martin A. Hansen, July 2008.

    # Given a path to a FASTA file create a FASTA index
    # and save to the specified path.

    my ( $fasta_path,   # path to FASTA file
         $index_dir,    # directory 
         $index_name,   # path to index file
       ) = @_;

    # Returns nothing.

    my ( $index );

    $index = index_create( $fasta_path );

    Maasha::Filesys::dir_create_if_not_exists( $index_dir );

    Maasha::Fasta::index_store( "$index_dir/$index_name", $index );
}


sub index_check
{
    # Martin A. Hansen, September 2009.

    # Given a path to a FASTA file and a FASTA index
    # check if the FILESIZE matches.

    my ( $fasta_path,   # path to FASTA file
         $index_path,   # path to index file
       ) = @_;

    # Returns boolean.

    my ( $index );

    $index = Maasha::Fasta::index_retrieve( $index_path );

    if ( Maasha::Filesys::file_size( $fasta_path ) == $index->{ 'FILE_SIZE' } ) {
        return 1;
    }

    return 0;
}


sub index_create
{
    # Matin A. Hansen, December 2004.

    # Given a FASTA file formatted with one line of header and one line of sequence,
    # returns a list of header, seq offset and seq length (first nucleotide is 0). Also,
    # the file size of the indexed file is written to the index for checking purposes.

    my ( $path,   #  full path to file with multiple FASTA entries
       ) = @_;

    # Returns a hashref.

    my ( $fh, $entry, $offset, $len, $tot, %index );

    $index{ 'FILE_SIZE' } = Maasha::Filesys::file_size( $path );

    $offset = 0;
    $len    = 0;
    $tot    = 0;

    $fh = Maasha::Filesys::file_read_open( $path );

    while ( $entry = get_entry( $fh ) )
    {
        warn qq(WARNING: header->$entry->[ SEQ_NAME ] alread exists in index) if exists $index{ $entry->[ SEQ_NAME ] };

        $offset += $len + 2 + length $entry->[ SEQ_NAME ];
        $len  = length $entry->[ SEQ ];

        $index{ $entry->[ SEQ_NAME ] } = [ $offset, $len ];

        $offset++;

        $tot += length( $entry->[ SEQ_NAME ] ) + length( $entry->[ SEQ ] ) + 3;
    }
    
    close $fh;

    if ( $index{ 'FILE_SIZE' } != $tot ) {
        Maasha::Common::error( qq(Filesize "$index{ 'FILE_SIZE' }" does not match content "$tot" -> malformatted FASTA file) );
    }

    return wantarray ? %index : \%index;
}


sub index_lookup
{
    # Martin A. Hansen, July 2007.

    # Lookup a list of exact matches in the index and returns these.

    my ( $index,     # index list
         $headers,   # headers to lookup
       ) = @_;

    # Returns a list.

    my ( $head, @results );

    foreach $head ( @{ $headers } )
    {
        if ( exists $index->{ $head } ) {
            push @results, [ $head, $index->{ $head }->[ 0 ], $index->{ $head }->[ 1 ] ];
        }
    }

    return wantarray ? @results : \@results;
}


sub index_store
{
    # Martin A. Hansen, May 2007.

    # Stores a FASTA index to binary file.

    my ( $path,   # full path to file
         $index,  # list with index
       ) = @_;

    # returns nothing

    Maasha::Filesys::file_store( $path, $index );
}


sub index_retrieve
{
    # Martin A. Hansen, May 2007.

    # Retrieves a FASTA index from binary file.

    my ( $path,   # full path to file
       ) = @_;

    # returns list

    my $index;

    $index = Maasha::Filesys::file_retrieve( $path );

    return wantarray ? @{ $index } : $index;
}


sub biopiece2fasta
{
    # Martin A. Hansen, July 2008.

    # Given a biopiece record converts it to a FASTA record.
    # If no generic SEQ or SEQ_NAME is found, the Q_* and S_* are
    # tried in that order.

    my ( $record,    # record
       ) = @_;

    # Returns a tuple.

    my ( $seq_name, $seq );

    $seq_name = $record->{ "SEQ_NAME" } || $record->{ "Q_ID" }  || $record->{ "S_ID" };
    $seq      = $record->{ "SEQ" }      || $record->{ "Q_SEQ" } || $record->{ "S_SEQ" };

    if ( defined $seq_name and defined $seq ) {
        return wantarray ? ( $seq_name, $seq ) : [ $seq_name, $seq ];
    } else {
        return;
    }
}


sub fasta2biopiece
{
    # Martin A. Hansen, May 2009

    # Convert a FASTA record to a Biopiece record.

    my ( $entry,   # FASTA entry
       ) = @_;

    # Returns a hashref.

    my ( $record );

    if ( defined $entry->[ SEQ_NAME ] and $entry->[ SEQ ] )
    {
        $record = {
            SEQ_NAME => $entry->[ SEQ_NAME ],
            SEQ      => $entry->[ SEQ ],
            SEQ_LEN  => length $entry->[ SEQ ],
        };
    }

    return wantarray ? %{ $record } : $record;
}



# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
