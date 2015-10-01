package Maasha::BGB::Wiggle;

# Copyright (C) 2010 Martin A. Hansen.

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


# Routines for creating Biopieces Browser wiggle tracks.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Common;
use Maasha::Calc;
use Maasha::Filesys;
use Maasha::KISS;
use Maasha::Matrix;

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
};

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub wiggle_encode
{
    # Martin A. Hansen, February 2010.
   
    # Read a KISS file and encode a Wiggle list.

    my ( $file,   # KISS file
       ) = @_;

    # Returns a list.
    
    my ( $fh, $entry, $vals, $i );

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $entry = Maasha::KISS::kiss_entry_get( $fh ) ) {
        map { $vals->[ $_ ]++ } ( $entry->[ S_BEG ] .. $entry->[ S_END ] );
    }

    close $fh;

    for ( $i = 0; $i < scalar @{ $vals }; $i++ ) {
        $vals->[ $i ] = 0 if not defined $vals->[ $i ];
    }

    return wantarray ? @{ $vals } : $vals;
}


sub wiggle_normalize
{
    my ( $vals,   # Wiggle values
         $size,   # New list size
       ) = @_;

    # Returns a list

    if ( scalar @{ $vals } < $size ) {
        Maasha::Matrix::list_inflate( $vals, $size );
    } elsif ( scalar @{ $vals } > $size ) {
        Maasha::Matrix::list_deflate( $vals, $size );
    }

    return wantarray ? @{ $vals } : $vals;
}


sub wiggle_store
{
    # Martin A. Hansen, February 2010.

    # Store a list of wiggle values as a byte array to a 
    # specified file.
    
    my ( $file,   # path to file
         $vals,   # Wiggle values
       ) = @_;

    # Returns nothing.

    my ( $bin, $fh );

    $bin = pack( "S*", @{ $vals } );

    $fh = Maasha::Filesys::file_write_open( $file );

    print $fh $bin;

    close $fh;
}


sub wiggle_retrieve
{
    # Martin A. Hansen, February 2010.

    # Restore an interval of Wiggle values from
    # a specified Wiggle file and return these
    # as a list.

    my ( $file,   # path to wiggle file
         $beg,    # begin position
         $end,    # end position
       ) = @_;

    # Returns a list.

    my ( $fh, $bin, @vals );

    Maasha::Common::error( qq(begin < 0: $beg) ) if $beg < 0;
    Maasha::Common::error( qq(begin > end: $beg > $end) ) if $beg > $end;

    $fh = Maasha::Filesys::file_read_open( $file );

    sysseek( $fh, $beg * 2, 0 );
    sysread( $fh, $bin, ( $end - $beg + 1 ) * 2 );

    close $fh;

    @vals = unpack( "S*", $bin );

    map { push @vals, 0 } ( scalar @vals .. $end - $beg  );  # Padding

    return wantarray ? @vals : \@vals;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;


__END__
