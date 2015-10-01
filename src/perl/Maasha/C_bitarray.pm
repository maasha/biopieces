package Maasha::C_bitarray;

# Copyright (C) 2008 Martin A. Hansen.

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


# This modules make all functions for casting, filling, and scanning a C integer array.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



use warnings;
use strict;

use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );

use Inline ( C => Config => DIRECTORY => $ENV{ 'BP_TMP' } );

use Inline C => << 'END_C';

#include <assert.h>


void c_array_interval_fill( SV *array, int beg, int end, int score )
{
    /* Martin A. Hansen, November 2008. */

    /* Incretments all values in a C array */
    /* with a given score in a given interval. */

    int i;
    int len;
    int size;

    int *a = ( int * ) SvPV( array, len );

    size = len / sizeof( int );

 printf( "C: len: %d    size: %d   sizeof( int ): %ld\n", len, size, sizeof(int) );

    assert( beg >= 0 );
    assert( end >= 0 );
    assert( beg <= size );
    assert( end <= size );
    assert( score > 0 );

    for ( i = beg; i < end + 1; i++ ) {
        a[ i ] += score;
    }
}


void c_array_interval_scan( SV *array, int pos )
{
    /* Martin A. Hansen, November 2008. */

    /* Locates the next interval of non-zero */
    /* integers in a C array given a starting pos. */

    int i;
    int len;
    int size;
    int beg;
    int end;

    int *a = ( int * ) SvPV( array, len );

    size = len / sizeof( int );

    assert( pos >= 0 );
    assert( pos <= size );

    while ( pos < size && a[ pos ] == 0 ) { pos++; }

    beg = pos;

    while ( pos < size && a[ pos ] != 0 ) { pos++; }

    end = pos - 1;

    if ( beg > end )
    {
        beg = -1;
        end = -1;
    }

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    Inline_Stack_Push( sv_2mortal( newSViv( beg ) ) );
    Inline_Stack_Push( sv_2mortal( newSViv( end ) ) );

    Inline_Stack_Done;
}


void c_array_interval_get( SV *array, int beg, int end )
{
    /* Martin A. Hansen, November 2008. */

    /* Get all values from an array in a given interval, */
    /* and return these as a Perl list. */

    int i;
    int len;
    int size;

    int *a = ( int * ) SvPV( array, len );

    size = len / sizeof( int );

    assert( beg >= 0 );
    assert( end >= 0 );
    assert( beg <= size );
    assert( end <= size );

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    for ( i = beg; i < end + 1; i++ ) {
        Inline_Stack_Push( sv_2mortal( newSViv( a[ i ] ) ) );
    }

    Inline_Stack_Done;
}


void c_array_print( SV *array )
{
    /* Martin A. Hansen, November 2008. */

    /* Outputs a C array to stdout. */

    int i;
    int len;

    int *a = ( int * ) SvPV( array, len );

    for ( i = 0; i < len / sizeof( int ); ++i ) {
        printf( "%d\n", a[ i ] );
    }
}

END_C
 

sub c_array_init
{
    # Martin A. Hansen, November 2008.

    # Initializes a zeroed C integer array using
    # Perls vec function to create a bit array.

    my ( $size,   # number of elements in array
         $bits,   # bit size
       ) = @_;

    # Returns a bit vector

    my ( $vec );

    $vec = '';

    #vec( $vec, $size - 1, $bits ) = 0;
    vec( $vec, 4 * $size - 1, $bits / 4 ) = 0;

    printf STDERR "P: size: %d   bits: %d   len: %d   size: %d\n", $size, $bits, length( $vec ), length( $vec ) / 4;

    return $vec;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
