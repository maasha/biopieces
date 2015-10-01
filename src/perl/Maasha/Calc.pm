package Maasha::Calc;

# Copyright (C) 2007 Martin A. Hansen.

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


# This modules contains subroutines for simple algebra.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Storable qw( dclone );
use vars qw ( @ISA @EXPORT );
use Exporter;

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub is_a_number
{
    # Identify if a string is a number or not.
    # Taken from perldoc -q 'is a number'.

    my ( $str,   # string to test
       ) = @_;

    # Returns boolean.

    if ( $str =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
        return 1;
    } else {
        return 0;
    }
}


sub commify
{
    # Martin A. Hansen, October 2009.

    # Insert comma in long numbers.

    my ( $num,   # number to commify
       ) = @_;

    # Returns a string.

    my ( $copy );

    $copy = $num;

    $copy =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;

    return $copy;
}


sub dist_point2line
{
    # Martin A. Hansen, June 2004.

    # calculates the distance from at point to a line.
    # the line is represented by a beg/end set of coordinates.

    my ( $px,    # point  x coordinate
         $py,    # point  y coordinate
         $x1,    # line 1 x coordinate
         $y1,    # line 1 y coordinate
         $x2,    # line 2 x coordinate
         $y2,    # line 2 y coordinate
       ) = @_;

    # returns float
       
    my ( $dist, $a, $b );

    $a = ( $y2 - $y1 ) / ( $x2 - $x1 );

    $b = $y1 - $a * $x1;

    $dist = abs( $a * $px + $b - $py ) / sqrt( $a ** 2 + 1 );

    return $dist;
}


sub dist_point2point
{
    # Martin A. Hansen, April 2004.

    # calculates the distance between two set of coordinates

    my ( $x1, 
         $y1,
         $x2,
         $y2,
       ) = @_;

    # returns float

    my $dist;

    $dist = sqrt( ( $x2 - $x1 ) ** 2 + ( $y2 - $y1 ) ** 2 );

    return $dist;
}


sub dist_interval
{
    # Martin A. Hansen, February 2008.

    # Returns the distance between two given intervals.
    # 0 indicates that the intervals are overlapping.

    my ( $beg1,
         $end1,
         $beg2,
         $end2,
       ) = @_;

    # Returns number

    if ( $beg2 > $end1 ) {
        return $beg2 - $end1;
    } elsif ( $beg1 > $end2 ) {
        return $beg1 - $end2;
    } else {
        return 0;
    }
}


sub mean
{
    # Martin A. Hansen, April 2007

    # Given a list of numbers, calculates and returns the mean.

    my ( $numbers,   #  list of numbers
       ) = @_;

    # returns decimal number

    my ( $sum, $mean );

    $sum = 0;

    map { $sum += $_ } @{ $numbers };

    $mean = $sum / @{ $numbers };

    return $mean;
}


sub median
{
    # Martin A. Hansen, January 2008

    # Given a list of numbers, calculates and returns the median.

    my ( $numbers,   #  list of numbers
       ) = @_;

    # returns decimal number

    my ( $num, $median );

    @{ $numbers } = sort { $a <=> $b } @{ $numbers }; 

    $num = scalar @{ $numbers };

    if ( $num % 2 == 0 ) {
        $median = mean( [ $numbers->[ $num / 2 ], $numbers->[ $num / 2 + 1 ] ] );
    } else {
        $median = $numbers->[ int( $num / 2 ) ];
    }

    return $median;
}


sub standard_deviation
{
    # Martin A. Hansen, September 2008

    # Given a list of numbers calculate and return the standard deviation:
    # http://en.wikipedia.org/wiki/Standard_deviation

    my ( $numbers,   # list of numbers
       ) = @_;

    # Returns a float.

    my ( $mean_num, $num, $dev, $dev_sum, $mean_dev, $std_dev );

    $mean_num = mean( $numbers );

    $dev_sum  = 0;

    foreach $num ( @{ $numbers } )
    {
        $dev = ( $num - $mean_num ) ** 2;
    
        $dev_sum += $dev;
    }

    $mean_dev = $dev_sum / scalar @{ $numbers };

    $std_dev  = sqrt( $mean_dev );

    return $std_dev;
}


sub min
{
    # Martin A. Hansen, August 2006.

    # Return the smallest of two given numbers.

    my ( $x,    # first number
         $y,    # second number
       ) = @_;

    # Returns number

    if ( $x <= $y ) {
        return $x;
    } else {
        return $y;
    }
}                                                                                                                                                        
                                                                                                                                                              
sub max
{
    # Martin A. Hansen, November 2006.                                                                                                                        

    # Return the largest of two given numbers.

    my ( $x,    # first number
         $y,    # second number
       ) = @_;

    # Returns number

    if ( $x > $y ) {
        return $x;
    } else {
        return $y;
    }
}


sub minmax
{
    # Martin A. Hansen, April 2007.

    # given a list of numbers returns a tuple with min and max

    my ( $list,   # list of numbers
       ) = @_;

    # returns a tuple

    my ( $num, $min, $max );

    $min = $max = $list->[ 0 ];

    foreach $num ( @{ $list } )
    {
        $min = $num if $num < $min;
        $max = $num if $num > $max;
    }

    return wantarray ? ( $min, $max ) : [ $min, $max ];
}


sub list_max
{
    # Martin A. Hansen, August 2007.

    # Returns the maximum number in a given list.

    my ( $list,   # list of numbers
       ) = @_;

    # Returns float

    my ( $max, $num );

    $max = $list->[ 0 ];

    foreach $num ( @{ $list } ) {
        $max = $num if $num > $max;
    }

    return $max;
}


sub list_min
{
    # Martin A. Hansen, August 2007.

    # Returns the minimum number in a given list.

    my ( $list,   # list of numbers
       ) = @_;

    # Returns float

    my ( $min, $num );

    $min = $list->[ 0 ];

    foreach $num ( @{ $list } ) {
        $min = $num if $num < $min;
    }

    return $min;
}


sub sum
{
    # Martin A. Hansen, April 2007.

    # Sums a list of given numbers and
    # returns the sum.

    my ( $list,   # list of numbers
       ) = @_;

    # returns float

    my ( $sum );

    $sum = 0;

    map { $sum += $_ } @{ $list };

    return $sum;
}


sub log10
{
    # Martin A. Hansen, August 2008.

    # Calculate the log10 of a given number.

    my ( $num,   # number
       ) = @_;

    # Returns a float.

    return log( $num ) / log( 10 );
}


sub interpolate_linear
{
    # Martin A. Hansen, February 2010.

    # Given two data points and an x value returns the
    # interpolant (y).
    #
    # Formula for linear interpolation:
    # http://en.wikipedia.org/wiki/Interpolation#Example

    my ( $x1,
         $y1,
         $x2,
         $y2,
         $x
       ) = @_;

    # Returns a float

    my ( $y );

    $y = $y1 + ( $x - $x1 ) * ( ( $y2 - $y1 ) / ( $x2 - $x1 ) );

    return $y;
}


sub overlap
{
    # Martin A. Hansen, November 2003.

    # Tests if two invervals overlap
    # returns 1 if overlapping else 0.
    
    my ( $beg1,
         $end1,
         $beg2,
         $end2,
       ) = @_;

    # returns integer

    if ( $beg1 > $end1 ) { ( $beg1, $end1 ) = ( $end1, $beg1 ) };
    if ( $beg2 > $end2 ) { ( $beg2, $end2 ) = ( $end2, $beg2 ) };

    if ( $end1 < $beg2 or $beg1 > $end2 ) {
        return 0;
    } else {
        return 1;
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
