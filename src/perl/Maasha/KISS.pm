package Maasha::KISS;

# Copyright (C) 2009 Martin A. Hansen.

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


# Routines for parsing and emitting KISS records.

# http://code.google.com/p/biopieces/wiki/KissFormat


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use JSON::XS;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Align;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    S_ID             => 0,
    S_BEG            => 1,
    S_END            => 2,
    Q_ID             => 3,
    SCORE            => 4,
    STRAND           => 5,
    HITS             => 6,
    ALIGN            => 7,
    BLOCK_COUNT      => 8,
    BLOCK_BEGS       => 9,
    BLOCK_LENS       => 10,
    BLOCK_TYPE       => 11,
    INDEX_BLOCK_SIZE => 100,
    INDEX_LEVEL      => 100_000_000,
    INDEX_FACTOR     => 100,

    BUCKET_SIZE      => 100,
    COUNT            => 0,
    OFFSET           => 1,

    INDEX_BEG        => 1,
    INDEX_END        => 2,
    INDEX            => 12,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub kiss_entry_get
{
    # Martin A. Hansen, November 2009.

    # Gets the next KISS entry from a file handle.

    my ( $fh,    # file handle
       ) = @_;

    # Returns a hashref.

    my ( $line, @fields );

    while ( $line = <$fh> )
    {
        chomp $line;

        next if $line =~ /^$|^#/;

        @fields = split /\t/, $line;

        Maasha::Common::error( qq(BAD kiss entry: $line) ) if not @fields == 12;
        
        return wantarray ? @fields : \@fields;
    }
}


sub kiss_retrieve
{
    # Martin A. Hansen, February 2010.

    # Retrieves KISS entries from a given sorted KISS file
    # within an optional interval.

    my ( $file,   # path to KISS file
         $beg,    # interval begin  -  OPTIONAL
         $end,    # interval end    -  OPTIONAL
       ) = @_;

    # Returns a list.

    my ( $fh, $entry, @entries );

    $beg ||= 0;
    $end ||= 999999999;

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $entry = kiss_entry_get( $fh ) )
    {
        last if $entry->[ S_BEG ] > $end;
        push @entries, $entry if $entry->[ S_END ] > $beg;
    }

    close $fh;

    return wantarray ? @entries : \@entries;
}


sub kiss_entry_parse
{
    # Martin A. Hansen, December 2009.

    # Parses a line with a KISS entry.

    my ( $line,   #  KISS line to parse
       ) = @_;

    # Returns a hash

    my ( @fields, %entry );

    @fields = split /\t/, $line;

    Maasha::Common::error( qq(BAD kiss entry: $line) ) if not @fields == 12;
    
    return wantarray ? @fields : \@fields;
}


sub kiss_entry_put
{
    # Martin A. Hansen, November 2009.

    # Outputs a KISS record to a given filehandle
    # or STDOUT if no filehandle is given.

    my ( $entry,   # KISS entry to output
         $fh,      # file handle  -  OPTIONAL
       ) = @_;

    # Returns nothing.
    
    Maasha::Common::error( qq(BAD kiss entry) ) if not scalar @{ $entry } == 12;

    if ( defined $entry->[ S_ID ]  and 
         defined $entry->[ S_BEG ] and
         defined $entry->[ S_END ]
       )
    {
        Maasha::Common::error( qq(Bad S_BEG value: $entry->[ S_BEG ] < 0 ) ) if $entry->[ S_BEG ] < 0;
        Maasha::Common::error( qq(Bad S_END value: $entry->[ S_END ] < $entry->[ S_BEG ] ) ) if $entry->[ S_END ] < $entry->[ S_BEG ];

        $fh ||= \*STDOUT;
    
        $entry->[ Q_ID ]        = "." if not defined $entry->[ Q_ID ];
        $entry->[ SCORE ]       = "." if not defined $entry->[ SCORE ];
        $entry->[ STRAND ]      = "." if not defined $entry->[ STRAND ];
        $entry->[ HITS ]        = "." if not defined $entry->[ HITS ];
        $entry->[ ALIGN ]       = "." if not defined $entry->[ ALIGN ];
        $entry->[ BLOCK_COUNT ] = "." if not defined $entry->[ BLOCK_COUNT ];
        $entry->[ BLOCK_BEGS ]  = "." if not defined $entry->[ BLOCK_BEGS ];
        $entry->[ BLOCK_LENS ]  = "." if not defined $entry->[ BLOCK_LENS ];
        $entry->[ BLOCK_TYPE ]  = "." if not defined $entry->[ BLOCK_TYPE ];

        print $fh join( "\t", @{ $entry } ), "\n";
    }
}


sub kiss_sort
{
    # Martin A. Hansen, November 2009.

    # Sorts a KISS file on S_BEG and S_END

    my ( $file,   # KISS file
       ) = @_;

    # Returns nothing.

    `sort -k 2,2n -k 3,3nr $file > $file.sort`;

    rename "$file.sort", $file;
}


sub kiss_index
{
    # Martin A. Hansen, December 2009.

    # Creates a lookup index of a sorted KISS file.

    my ( $file,   # path to KISS file
       ) = @_;

    # Returns nothing.

    my ( $fh, $offset, $line, $s_beg, $bucket, $index );

    $fh = Maasha::Filesys::file_read_open( $file );

    $offset = 0;

    while ( $line = <$fh> )
    {
        ( undef, $s_beg ) = split "\t", $line, 3;

        $bucket = int( $s_beg / BUCKET_SIZE ); 

        $index->[ $bucket ]->[ COUNT ]++;
        $index->[ $bucket ]->[ OFFSET ] = $offset if not defined $index->[ $bucket ]->[ OFFSET ];

        $offset += length $line;
    }

    close $fh;

    Maasha::KISS::kiss_index_store( "$file.index", $index );
}


sub kiss_index_offset
{
    # Martin A. Hansen, December 2009.

    # Given a KISS index and a begin position,
    # locate the offset closest to the begin position,
    # and return this.

    my ( $index,    # KISS index
         $beg,      # begin position
       ) = @_;

    # Returns a number.

    my ( $bucket );

    Maasha::Common::error( qq(Negative begin position: "$beg") ) if $beg < 0;

    $bucket = int( $beg / BUCKET_SIZE ); 

    $bucket = scalar @{ $index } if $bucket > scalar @{ $index };

    while ( $bucket >= 0 )
    {
        return $index->[ $bucket ]->[ OFFSET ] if defined $index->[ $bucket ];

        $bucket--;
    }
}


sub kiss_index_count
{
    # Martin A. Hansen, December 2009.

    # Given a KISS index and a begin/end interval
    # sum the number of counts in that interval,
    # and return this.

    my ( $index,   # KISS index
         $beg,     # Begin position
         $end,     # End position
       ) = @_;

    # Returns a number.

    my ( $bucket_beg, $bucket_end, $count, $i );

    Maasha::Common::error( qq(Negative begin position: "$beg") ) if $beg < 0;

    $bucket_beg = int( $beg / BUCKET_SIZE );
    $bucket_end = int( $end / BUCKET_SIZE );

    $bucket_end = scalar @{ $index } if $bucket_end > scalar @{ $index };

    $count = 0;

    for ( $i = $bucket_beg; $i <= $bucket_end; $i++ ) {
        $count += $index->[ $i ]->[ COUNT ] if defined $index->[ $i ];
    }

    return $count;
}


sub kiss_index_count_nc
{
    # Martin A. Hansen, December 2009.

    # Given a KISS index and a begin/end interval
    # sum the number of counts in that interval,
    # and return this.

    my ( $index,   # KISS index
         $beg,     # Begin position
         $end,     # End position
       ) = @_;

    # Returns a number.

    my ( $count );

    Maasha::Common::error( qq(Negative begin position: "$beg") ) if $beg < 0;

    $count = Maasha::NClist::nc_list_count_interval( $index, $beg, $end, INDEX_BEG, INDEX_END, INDEX );

    return $count;
}


sub kiss_index_get_entries
{
    # Martin A. Hansen, November 2009.

    # Given a path to a KISS file and a KISS index
    # along with a beg/end interval, locate all entries
    # in that interval and return those.

    my ( $file,    # path to KISS file
         $index,   # KISS index
         $beg,     # interval begin
         $end,     # interval end
       ) = @_;

    # Returns a list.

    my ( $offset, $fh, $entry, @entries );

    # $offset = kiss_index_offset( $index, $beg );

    $fh = Maasha::Filesys::file_read_open( $file );

    # sysseek( $fh, $offset, 0 );

    while ( $entry = Maasha::KISS::kiss_entry_get( $fh ) )
    {
        push @entries, $entry if $entry->[ S_END ] > $beg;
        
        last if $entry->[ S_BEG ] > $end;
    }

    close $fh;

    return wantarray ? @entries : \@entries;
}


sub kiss_index_get_entries_OLD
{
    # Martin A. Hansen, November 2009.

    # Given a path to a KISS file and a KISS index
    # along with a beg/end interval, locate all entries
    # in that interval and return those.

    my ( $file,    # path to KISS file
         $index,   # KISS index
         $beg,     # interval begin
         $end,     # interval end
       ) = @_;

    # Returns a list.

    my ( $offset, $fh, $entry, @entries );

    $offset = kiss_index_offset( $index, $beg );

    $fh = Maasha::Filesys::file_read_open( $file );

    sysseek( $fh, $offset, 0 );

    while ( $entry = Maasha::KISS::kiss_entry_get( $fh ) )
    {
        push @entries, $entry if $entry->[ S_END ] > $beg;
        
        last if $entry->[ S_BEG ] > $end;
    }

    close $fh;

    return wantarray ? @entries : \@entries;
}


sub kiss_index_get_blocks
{
    # Martin A. Hansen, December 2009.

    # Given a KISS index returns blocks from this in a 
    # given position interval. Blocks consisting of
    # hashes of BEG/END/COUNT.

    my ( $index,   # KISS index node
         $beg,     # interval begin
         $end,     # interval end
       ) = @_;

    # Returns a list.

    my ( $bucket_beg, $bucket_end, $i, @blocks );

    Maasha::Common::error( qq(Negative begin position: "$beg") ) if $beg < 0;

    $bucket_beg = int( $beg / BUCKET_SIZE ); 
    $bucket_end = int( $end / BUCKET_SIZE ); 

    $bucket_end = scalar @{ $index } if $bucket_end > scalar @{ $index };

    for ( $i = $bucket_beg; $i <= $bucket_end; $i++ )
    {
        if ( defined $index->[ $i ] )
        {
            push @blocks, {
                BEG   => BUCKET_SIZE * $i,
                END   => BUCKET_SIZE * ( $i + 1 ),
                COUNT => $index->[ $i ]->[ COUNT ],
            };
        }
    }

    return wantarray ? @blocks : \@blocks;
}


sub kiss_intersect
{
    # Martin A. Hansen, December 2009.

    # Given filehandles to two different unsorted KISS files
    # intersect the entries so that all entries from file1 that
    # overlap entries in file2 are returned - unless the inverse flag
    # is given in which case entreis from file1 that does not
    # overlap any entries in file2 are returned.

    my ( $fh1,       # filehandle to file1
         $fh2,       # filehandle to file2
         $inverse,   # flag indicating inverse matching - OPTIONAL
       ) = @_;

    # Returns a list

    my ( $entry, %lookup, $pos, $overlap, @entries );

    while ( $entry = kiss_entry_get( $fh2 ) ) {
        map { $lookup{ $_ } = 1 } ( $entry->[ S_BEG ] .. $entry->[ S_END ] );
    }

    while ( $entry = kiss_entry_get( $fh1 ) )
    {
        $overlap = 0;

        foreach $pos ( $entry->[ S_BEG ] .. $entry->[ S_END ] )
        {
            if ( exists $lookup{ $pos } )
            {
                $overlap = 1;

                last;
            }
        }

        if ( $overlap and not $inverse ) {
            push @entries, $entry;
        } elsif ( not $overlap and $inverse ) {
            push @entries, $entry;
        }
    }

    return wantarray ? @entries : \@entries;
}


sub kiss_index_store
{
    # Martin A. Hansen, November 2009.

    # Stores a KISS index to a file.

    my ( $path,    # path to KISS index
         $index,   # KISS index
       ) = @_;

    # Returns nothing.

    my ( $fh, $json );

    $json = JSON::XS::encode_json( $index );

    $fh = Maasha::Filesys::file_write_open( $path );

    print $fh $json;

    close $fh;
}


sub kiss_index_retrieve
{
    # Martin A. Hansen, November 2009.

    # Retrieves a KISS index from a file.

    my ( $path,   # Path to KISS index
       ) = @_;

    # Returns a data structure.

    my ( $fh, $json, $index );

    local $/ = undef;

    $fh = Maasha::Filesys::file_read_open( $path );

    $json = <$fh>;

    close $fh;

    $index = JSON::XS::decode_json( $json );

    return wantarray ? @{ $index } : $index;
}


sub kiss_align_enc
{
    # Martin A. Hansen, November 2009.

    # Encodes alignment descriptors for two
    # aligned sequences.

    my ( $s_seq,    # Subject sequence reference
         $q_seq,    # Query sequence reference
         $offset,   # alternate offset - OPTIONAL
       ) = @_;

    # Returns a list

    my ( $i, $s, $q, @align );

    # Maasha::Common::error( "Sequence lengths don't match" ) if length ${ $s_seq } != length ${ $q_seq };

    if ( length ${ $s_seq } != length ${ $q_seq } ) {   # for unknown reasons this situation may occur - TODO FIXME
        return wantarray ? () : [];
    }

    $offset ||= 0;

    for ( $i = 0; $i < length ${ $s_seq }; $i++ )
    {
        $s = uc substr ${ $s_seq }, $i, 1;
        $q = uc substr ${ $q_seq }, $i, 1;

        if ( $s eq '-' and $q eq '-' )
        {
            # do nothing
        }
        elsif ( $s eq $q )
        {
            $offset++;
        }
        else
        {
            push @align, "$offset:$s>$q";

            $offset++ if not $s eq '-';
        }
    }

    return wantarray ? @align : \@align;
}   


sub kiss_align_dec
{
    # Martin A. Hansen, November 2009.

    # Test routine of correct resolve of ALIGN descriptors.

    # S.aur_COL       41      75      5_vnlh2ywXsN1/1 1       -       .       17:A>T,31:A>N   .       .       .       .

    my ( $s_seqref,   # subject sequence reference
         $entry,      # KISS entry
       ) = @_;

    # Returns a string.

    my ( $align, $pos, $s_symbol, $q_symbol, $s_seq, $q_seq, $insertions );

    $s_seq = substr ${ $s_seqref }, $entry->{ 'S_BEG' }, $entry->{ 'S_END' } - $entry->{ 'S_BEG' } + 1;
    $q_seq = $s_seq;

    $insertions = 0;

    foreach $align ( split /,/, $entry->{ 'ALIGN' } )
    {
        if ( $align =~ /(\d+):(.)>(.)/ )
        {
            $pos      = $1;
            $s_symbol = $2;
            $q_symbol = $3;

            if ( $s_symbol eq '-' ) # insertion
            {
                substr $s_seq, $pos + $insertions, 0, $s_symbol;
                substr $q_seq, $pos + $insertions, 0, $q_symbol;

                $insertions++;
            }
            elsif ( $q_symbol eq '-' ) # deletion
            {
                substr $q_seq, $pos + $insertions, 1, $q_symbol;
            }
            else # mismatch
            {
                substr $q_seq, $pos + $insertions, 1, $q_symbol;
            }
        }
        else
        {
            Maasha::Common::error( qq(Bad alignment descriptor: "$align") );
        }
    }

    Maasha::Align::align_print_pairwise( [ $entry->{ 'S_ID' }, $s_seq ], [ $entry->{ 'Q_ID' }, $q_seq ] );
}


sub kiss2biopiece
{
    # Martin A. Hansen, November 2009.

    # Converts a KISS entry to a Biopiece record.

    my ( $entry,   # KISS entry
       ) = @_;

    # Returns a hashref

    my ( %record );

    Maasha::Common::error( qq(BAD kiss entry) ) if not scalar @{ $entry } == 12;

    $record{ 'S_ID' }        = $entry->[ S_ID ];
    $record{ 'S_BEG' }       = $entry->[ S_BEG ];
    $record{ 'S_END' }       = $entry->[ S_END ];
    $record{ 'Q_ID' }        = $entry->[ Q_ID ];
    $record{ 'SCORE' }       = $entry->[ SCORE ];
    $record{ 'STRAND' }      = $entry->[ STRAND ];
    $record{ 'HITS' }        = $entry->[ HITS ];
    $record{ 'ALIGN' }       = $entry->[ ALIGN ];
    $record{ 'BLOCK_COUNT' } = $entry->[ BLOCK_COUNT ];
    $record{ 'BLOCK_BEGS' }  = $entry->[ BLOCK_BEGS ];
    $record{ 'BLOCK_LENS' }  = $entry->[ BLOCK_LENS ];
    $record{ 'BLOCK_TYPE' }  = $entry->[ BLOCK_TYPE ];

    return wantarray ? %record : \%record;
}


sub biopiece2kiss
{
    # Martin A. Hansen, November 2009.

    # Converts a Biopiece record to a KISS entry.
 
    my ( $record,   # Biopiece record
       ) = @_;

    # Returns a hashref

    my ( $entry );

    if ( not defined $record->{ 'S_ID' }  and
         not defined $record->{ 'S_BEG' } and
         not defined $record->{ 'S_END' } )
    {
        return undef;
    }

    $entry->[ S_ID ]        = $record->{ 'S_ID' };
    $entry->[ S_BEG ]       = $record->{ 'S_BEG' };
    $entry->[ S_END ]       = $record->{ 'S_END' };
    $entry->[ Q_ID ]        = $record->{ 'Q_ID' }        || ".";
    $entry->[ SCORE ]       = $record->{ 'SCORE' }       || $record->{ 'BIT_SCORE' } || $record->{ 'ID' } || ".";
    $entry->[ STRAND ]      = $record->{ 'STRAND' }      || ".";
    $entry->[ HITS ]        = $record->{ 'HITS' }        || ".";
    $entry->[ ALIGN ]       = $record->{ 'ALIGN' }       || $record->{ 'DESCRIPTOR' } || ".";
    $entry->[ BLOCK_COUNT ] = $record->{ 'BLOCK_COUNT' } || ".";
    $entry->[ BLOCK_BEGS ]  = $record->{ 'BLOCK_BEGS' }  || $record->{ 'Q_BEGS' } || ".";
    $entry->[ BLOCK_LENS ]  = $record->{ 'BLOCK_LENS' }  || ".";
    $entry->[ BLOCK_TYPE ]  = $record->{ 'BLOCK_TYPE' }  || ".";

    return wantarray ? @{ $entry } : $entry;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;

__END__

sub kiss_index_nc
{
    # Martin A. Hansen, February 2010.

    # Creates a NC list index of a sorted KISS file.

    my ( $file,         # path to KISS file
       ) = @_;

    # Returns nothing.

    my ( $fh, $line, @fields, $nc_list );

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $line = <$fh> )
    {
        chomp $line;

        @fields = split "\t", $line;

        if ( not defined $nc_list ) {
            $nc_list = [ [ @fields ] ];
        } else {
            Maasha::NClist::nc_list_add( $nc_list, [ @fields ], INDEX_END, INDEX );
        }
    }

    close $fh;

    Maasha::NClist::nc_list_store( $nc_list, "$file.json" );
}


sub kiss_index_get_entries_nc
{
    # Martin A. Hansen, November 2009.

    # Given a path to a KISS file and a KISS index
    # along with a beg/end interval, locate all entries
    # in that interval and return those.

    my ( $index,   # KISS index
         $beg,     # interval begin
         $end,     # interval end
       ) = @_;

    # Returns a list.

    my ( $features );

    $features = Maasha::NClist::nc_list_get_interval( $index, $beg, $end, INDEX_BEG, INDEX_END, INDEX );

    return wantarray ? @{ $features } : $features;
}


sub kiss_index_retrieve_nc
{
    # Martin A. Hansen, November 2009.

    # Retrieves a KISS index from a file.

    my ( $path,   # Path to KISS index
       ) = @_;

    # Returns a data structure.

    my ( $index );

    $index = Maasha::NClist::nc_list_retrieve( $path );

    return wantarray ? @{ $index } : $index;
}
