package Maasha::Matrix;

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


# This modules contains subroutines for simple matrix manipulations.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
no warnings 'recursion';
use strict;
use Data::Dumper;
use Storable qw( dclone );
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Calc;
use vars qw ( @ISA @EXPORT );
use Exporter;

@ISA = qw( Exporter );

use constant {
    ROWS => 0,
    COLS => 1,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub matrix_dims
{
    # Martin A. Hansen, April 2007

    # returns the dimensions of a matrix: rows x cols

    my ( $matrix,   # AoA data structure
       ) = @_;

    # returns a tuple

    my ( $rows, $cols );

    $rows = scalar @{ $matrix };
    $cols = scalar @{ $matrix->[ 0 ] };

    return wantarray ? ( $rows, $cols ) : [ $rows, $cols ];
}


sub matrix_check
{
    # Martin A. Hansen, April 2007.

    # Checks that the matrix of even columns.
    # return 1 if ok else 0.

    my ( $matrix,      # AoA data structure
       ) = @_;

    # returns boolean

    my ( $dims, $row, $check );

    $dims = matrix_dims( $matrix );

    $check = $dims->[ COLS ];

    foreach $row ( @{ $matrix } ) {
        return 0 if scalar @{ $row } != $check;
    }

    return 1;
}


sub matrix_summary
{
    # Martin A. Hansen, April 2007.

    # For each column in a given matrix print:

    my ( $matrix,   # AoA data structure
       ) = @_;

    my ( $dims, $i, $col, $list, $type, $sort, $uniq, $min, $max, $mean );

    die qq(ERROR: cannot summarize uneven matrix\n) if not matrix_check( $matrix );
    
    $dims = matrix_dims( $matrix );

    print join( "\t", "TYPE", "LEN", "UNIQ", "SORT", "MIN", "MAX", "MEAN" ), "\n";

    for ( $i = 0; $i < $dims->[ COLS ]; $i++ )
    {
        $col  = cols_get( $matrix, $i, $i );
        $list = matrix_flip( $col )->[ 0 ];

        if ( list_check_numeric( $list ) ) {
            $type = "num";
        } else {
            $type = "alph";
        }

        if ( list_check_sort( $list, $type ) ) {
            $sort = "yes";
        } else {
            $sort = "no";
        }

        if ( $type eq "num" )
        {
            if ( $sort eq "yes" )
            {
                $min = $list->[ 0 ];
                $max = $list->[ -1 ];
            }
            else
            {
                ( $min, $max ) = Maasha::Calc::minmax( $list );
            }

            $mean = sprintf( "%.2f", Maasha::Calc::mean( $list ) );
        }
        else
        {
            $min  = "N/A";
            $max  = "N/A";
            $mean = "N/A";
        }

        $uniq = list_uniq( $list );
    
        print join( "\t", $type, $dims->[ ROWS ], $uniq, $sort, $min, $max, $mean ), "\n";
    }
}


sub matrix_flip
{
    # Martin A. Hansen, April 2007

    # flips a matrix making rows to columns and visa versa.

    my ( $matrix,   # AoA data structure
       ) = @_;

    # returns AoA

    my ( $i, $c, $dims, $AoA );

    die qq(ERROR: cannot flip uneven matrix\n) if not matrix_check( $matrix );

    $dims = matrix_dims( $matrix );

    for ( $i = 0; $i < $dims->[ ROWS ]; $i++ )
    {
        for ( $c = 0; $c < $dims->[ COLS ]; $c++ ) {
            $AoA->[ $c ]->[ $i ] = $matrix->[ $i ]->[ $c ];
        }
    }

    @{ $matrix } = @{ $AoA };

    return wantarray ? @{ $matrix } : $matrix;
}


sub matrix_deflate_rows
{
    # Martin A. Hansen, September 2009.

    # Reduces the number of elements in all rows,
    # by collectiong elements in buckets that are
    # averaged.

    my ( $matrix,   # AoA data structure
         $new_size
       ) = @_;

    # Returns nothing.

    my ( $row );

    foreach $row ( @{ $matrix } ) {
        list_deflate( $row, $new_size );
    }
}


sub matrix_deflate_cols
{
    # Martin A. Hansen, September 2009.

    # Reduces the number of elements in all columns,
    # by collectiong elements in buckets that are
    # averaged.

    my ( $matrix,   # AoA data structure
         $new_size
       ) = @_;

    # Returns nothing.

    my ( $col );

    matrix_flip( $matrix );

    foreach $col ( @{ $matrix } ) {
        list_deflate( $col, $new_size );
    }

    matrix_flip( $matrix );
}


sub matrix_rotate_right
{
    # Martin A. Hansen, April 2007

    # Rotates elements in a given matrix a given
    # number of positions to the right by popping columns,
    # from the right matrix edge and prefixed to the left edge.

    my ( $matrix,   # AoA data structure
         $shift,    # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $i, $dims, $col, $AoA );

    $shift ||= 1;

    die qq(ERROR: cannot right rotate uneven matrix\n) if not matrix_check( $matrix );

    $dims = matrix_dims( $matrix );

    for ( $i = 0; $i < $shift; $i++ )
    {
        $col = cols_get( $matrix, $dims->[ COLS ] - 1, $dims->[ COLS ] - 1 );
        $AoA = cols_get( $matrix, 0, $dims->[ COLS ] - 2 );

        cols_unshift( $AoA, $col );

        $matrix = $AoA;
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub matrix_rotate_left
{
    # Martin A. Hansen, April 2007

    # Rotates elements in a given matrix a given
    # number of positions to the left while columns
    # are shifted from the left matrix edge and appended,
    # to the right edge.

    my ( $matrix,   # AoA data structure
         $shift,    # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $i, $dims, $col, $AoA );

    $shift ||= 1;

    die qq(ERROR: cannot right rotate uneven matrix\n) if not matrix_check( $matrix );

    $dims = matrix_dims( $matrix );

    for ( $i = 0; $i < $shift; $i++ )
    {
        $col = cols_get( $matrix, 0, 0 );
        $AoA = cols_get( $matrix, 1, $dims->[ COLS ] - 1 );

        cols_push( $AoA, $col );

        $matrix = $AoA;
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub matrix_rotate_up
{
    # Martin A. Hansen, April 2007

    # Rotates elements in a given matrix a given
    # number of positions up while rows are shifted
    # from the top of the matrix to the bottom.

    my ( $matrix,   # AoA data structure
         $shift,    # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $dims, $i, $row, $AoA );

    $shift ||= 1;

    $dims = matrix_dims( $matrix );

    for ( $i = 0; $i < $shift; $i++ )
    {
        $row = rows_get( $matrix, 0, 0 );
        $AoA = rows_get( $matrix, 1, $dims->[ ROWS ] - 1 );

        rows_push( $AoA, dclone $row );

        $matrix = $AoA;
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub matrix_rotate_down
{
    # Martin A. Hansen, April 2007

    # Rotates elements in a given matrix a given
    # number of positions down while rows are shifted
    # from the bottom matrix edge to the top edge.

    my ( $matrix,   # AoA data structure
         $shift,    # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $dims, $i, $row, $AoA );

    $shift ||= 1;

    $dims = matrix_dims( $matrix );

    for ( $i = 0; $i < $shift; $i++ )
    {
        $row = rows_get( $matrix, $dims->[ ROWS ] - 1, $dims->[ ROWS ] - 1 );
        $AoA = rows_get( $matrix, 0, $dims->[ ROWS ] - 2 );
    
        rows_unshift( $AoA, $row );

        $matrix = $AoA;
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub submatrix
{
    # Martin A. Hansen, April 2007

    # returns a submatrix sliced from a given matrix

    my ( $matrix,    # AoA data structure
         $row_beg,   # first row - OPTIONAL (default 0)
         $row_end,   # last row  - OPTIONAL (default last row)
         $col_beg,   # first col - OPTIONAL (default 0)
         $col_end,   # last col  - OPTIONAL (default last col)
       ) = @_;

    # returns AoA

    my ( $submatrix, $subsubmatrix );

    $submatrix    = rows_get( $matrix, $row_beg, $row_end );
    $subsubmatrix = cols_get( $submatrix, $col_beg, $col_end );

    return wantarray ? @{ $subsubmatrix } : $subsubmatrix;
}


sub row_get
{
    # Martin A. Hansen, April 2008.

    # Returns a single row from a given matrix.

    my ( $matrix,    # AoA data structure
         $row,       # row to get
       ) = @_;

    # Returns a list;

    my ( $dims, $i, @list );

    $dims = matrix_dims( $matrix );

    Maasha::Common::error( qq(Row->$row outside of matrix->$dims->[ ROWS ]) ) if $row > $dims->[ ROWS ];

    @list = @{ $matrix->[ $row ] };

    return wantarray ? @list : \@list;
}


sub rows_get
{
    # Martin A. Hansen, April 2007

    # returns a range of requested rows from a given matrix.

    my ( $matrix,    # AoA data structure
         $row_beg,   # first row - OPTIONAL (default 0)
         $row_end,   # last row  - OPTIONAL (default last row)
       ) = @_;

    # returns AoA

    my ( @rows, $i );

    $row_beg ||= 0;

    if ( not defined $row_end ) {
        $row_end = scalar @{ $matrix };
    }

    if ( $row_end >= scalar @{ $matrix } )
    {
        warn qq(WARNING: row end larger than matrix\n);
        $row_end = scalar( @{ $matrix } ) - 1;
    }

    die qq(ERROR: row begin "$row_beg" larger than row end "$row_end"\n) if $row_end < $row_beg;

    if ( $row_beg == 0 and $row_end == scalar( @{ $matrix } ) - 1 ) {
        @rows = @{ $matrix };
    } else {
        @rows = @{ $matrix }[ $row_beg .. $row_end ];
    }

    return wantarray ? @rows : \@rows;
}


sub col_get
{
    # Martin A. Hansen, April 2008.

    # Returns a single column from a given matrix.

    my ( $matrix,    # AoA data structure
         $col,       # column to get
       ) = @_;

    # Returns a list;

    my ( $dims, $i, @list );

    $dims = matrix_dims( $matrix );

    Maasha::Common::error( qq(Column->$col outside of matrix->$dims->[ COLS ]) ) if $col > $dims->[ COLS ];

    for ( $i = 0; $i < $dims->[ ROWS ]; $i++ ) {
        push @list, $matrix->[ $i ]->[ $col ];
    }

    return wantarray ? @list : \@list;
}


sub cols_get
{
    # Martin A. Hansen, April 2007.

    # returns a range of requested columns from a given matrix

    my ( $matrix,    # AoA data structure
         $col_beg,   # first column - OPTIONAL (default 0)
         $col_end,   # last column  - OPTIONAL (default last column)
       ) = @_;
    
    # returns AoA

    my ( $dims, @cols, $row, @AoA );

    $dims = matrix_dims( $matrix );

    $col_beg ||= 0;

    if ( not defined $col_end ) {
        $col_end = $dims->[ COLS ] - 1;
    }

    if ( $col_end > $dims->[ COLS ] - 1 )
    {
        warn qq(WARNING: column end larger than matrix\n);
        $col_end = $dims->[ COLS ] - 1;
    }

    die qq(ERROR: column begin "$col_beg" larger than column end "$col_end"\n) if $col_end < $col_beg;

    if ( $col_beg == 0 and $col_end == $dims->[ COLS ] - 1 )
    {
        @AoA = @{ $matrix };
    }
    else
    {
        foreach $row ( @{ $matrix } )
        {
            @cols = @{ $row }[ $col_beg .. $col_end ];

            push @AoA, [ @cols ];
        }
    }

    return wantarray ? @AoA : \@AoA;
}


sub col_sum
{
    my ( $matrix,
         $col,
       ) = @_;

    my ( $list, $sum );

    $list = cols_get( $matrix, $col, $col );
    $list = matrix_flip( $list )->[ 0 ];

    die qq(ERROR: cannot sum non-nummerical column\n);

    $sum = Maasha::Calc::sum( $list );

    return $sum;
}


sub rows_push
{
    # Martin A. Hansen, April 2007.

    # Appends one or more rows to a matrix.

    my ( $matrix,    # AoA data structure
         $rows,      # list of rows
       ) = @_;
    
    # returns AoA

    push @{ $matrix }, @{ $rows };

    return wantarray ? @{ $matrix } : $matrix;
}


sub rows_unshift
{
    # Martin A. Hansen, April 2007.

    # Prefixes one or more rows to a matrix.

    my ( $matrix,    # AoA data structure
         $rows,      # list of rows
       ) = @_;
    
    # returns AoA

    unshift @{ $matrix }, @{ $rows };

    return wantarray ? @{ $matrix } : $matrix;
}


sub cols_push
{
    # Martin A. Hansen, April 2007.

    # Appends one or more lists as columns to a matrix.

    my ( $matrix,    # AoA data structure
         $cols,      # list of columns
       ) = @_;
    
    # returns AoA

    my ( $dims_matrix, $dims_cols, $i );

    $dims_matrix = matrix_dims( $matrix );
    $dims_cols   = matrix_dims( $cols );

    die qq(ERROR: Cannot merge columns with different row count\n) if $dims_matrix->[ ROWS ] != $dims_cols->[ ROWS ];

    for ( $i = 0; $i < $dims_matrix->[ ROWS ]; $i++ )
    {
        push @{ $matrix->[ $i ] }, @{ $cols->[ $i ] };
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub cols_unshift
{
    # Martin A. Hansen, April 2007.

    # Prefixes one or more lists as columns to a matrix.

    my ( $matrix,    # AoA data structure
         $cols,      # list of columns
       ) = @_;
    
    # returns AoA

    my ( $dims_matrix, $dims_cols, $i );

    $dims_matrix = matrix_dims( $matrix );
    $dims_cols   = matrix_dims( $cols );

    die qq(ERROR: Cannot merge columns with different row count\n) if $dims_matrix->[ ROWS ] != $dims_cols->[ ROWS ];

    for ( $i = 0; $i < $dims_matrix->[ ROWS ]; $i++ ) {
        unshift @{ $matrix->[ $i ] }, @{ $cols->[ $i ] };
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub rows_rotate_left
{
    # Martin A. Hansen, April 2007.

    # Given a matrix and a range of rows, rotates these rows
    # left by shifting a given number of elements from
    # the first position to the last.

    my ( $matrix,    # AoA data structure
         $beg,       # first row to shift
         $end,       # last row to shit
         $shift,     # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $i, $c, $row );

    $shift ||= 1;

    for ( $i = $beg; $i <= $end; $i++ )
    {
        $row = rows_get( $matrix, $i, $i );

        for ( $c = 0; $c < $shift; $c++ )
        {
            $row = list_rotate_left( @{ $row } );
            $matrix->[ $i ] = $row;
        }
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub rows_rotate_right
{
    # Martin A. Hansen, April 2007.

    # Given a matrix and a range of rows, rotates these rows
    # right by shifting a given number of elements from the
    # last position to the first.

    my ( $matrix,    # AoA data structure
         $beg,       # first row to shift
         $end,       # last row to shit
         $shift,     # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $dims, $i, $c, $row );

    $shift ||= 1;

    $dims = matrix_dims( $matrix );

    die qq(ERROR: end < beg: $end < $beg\n) if $end < $beg;
    die qq(ERROR: row outside matrix\n)     if $end >= $dims->[ ROWS ];

    for ( $i = $beg; $i <= $end; $i++ )
    {
        $row = rows_get( $matrix, $i, $i );

        for ( $c = 0; $c < $shift; $c++ )
        {
            $row = list_rotate_right( @{ $row } );
            $matrix->[ $i ] = $row;
        }
    }

    return wantarray ? @{ $matrix } : $matrix;
}


sub cols_rotate_up
{
    # Martin A. Hansen, April 2007.

    # Given a matrix and a range of columns, rotates these columns
    # ups by shifting the the first cell of each row from the
    # first position to the last.

    my ( $matrix,    # AoA data structure
         $beg,       # first row to shift
         $end,       # last row to shit
         $shift,     # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $dims, $i, $c, $cols_pre, $col_select, $cols_post, $list );

    $shift ||= 1;

    $dims = matrix_dims( $matrix );

    $cols_pre  = cols_get( $matrix, 0, $beg - 1 ) if $beg > 0;
    $cols_post = cols_get( $matrix, $end + 1, $dims->[ COLS ] - 1 ) if $end < $dims->[ COLS ] - 1;

    for ( $i = $beg; $i <= $end; $i++ )
    {
        $col_select = cols_get( $matrix, $i, $i );

        $list = matrix_flip( $col_select )->[ 0 ];

        for ( $c = 0; $c < $shift; $c++ ) {
            $list = list_rotate_left( $list );
        }

        $col_select = matrix_flip( [ $list ] );

        if ( $cols_pre ) {
            cols_push( $cols_pre, $col_select );
        } else {
            $cols_pre = $col_select;
        }
    }

    cols_push( $cols_pre, $cols_post ) if $cols_post;

    $matrix = $cols_pre;

    return wantarray ? @{ $matrix } : $matrix;
}


sub cols_rotate_down
{
    # Martin A. Hansen, April 2007.

    # Given a matrix and a range of columns, rotates these columns
    # ups by shifting the the first cell of each row from the
    # first position to the last.

    my ( $matrix,    # AoA data structure
         $beg,       # first row to shift
         $end,       # last row to shit
         $shift,     # number of shifts - DEFAULT=1
       ) = @_;

    # returns AoA

    my ( $dims, $i, $c, $cols_pre, $col_select, $cols_post, $list );

    $shift ||= 1;

    $dims = matrix_dims( $matrix );

    $cols_pre  = cols_get( $matrix, 0, $beg - 1 ) if $beg > 0;
    $cols_post = cols_get( $matrix, $end + 1, $dims->[ COLS ] - 1 ) if $end < $dims->[ COLS ] - 1;

    for ( $i = $beg; $i <= $end; $i++ )
    {
        $col_select = cols_get( $matrix, $i, $i );

        $list = matrix_flip( $col_select )->[ 0 ];

        for ( $c = 0; $c < $shift; $c++ ) {
            $list = list_rotate_right( $list );
        }

        $col_select = matrix_flip( [ $list ] );

        if ( $cols_pre ) {
            cols_push( $cols_pre, $col_select );
        } else {
            $cols_pre = $col_select;
        }
    }

    cols_push( $cols_pre, $cols_post ) if $cols_post;

    $matrix = $cols_pre;

    return wantarray ? @{ $matrix } : $matrix;
}


sub list_rotate_left
{
    # Martin A. Hansen, April 2007.

    # given a list, shifts off the first element,
    # and appends to the list, which is returned.

    my ( $list,   # list to rotate
       ) = @_;

    my ( @new_list, $elem );

    @new_list = @{ $list };
 
    $elem = shift @new_list;

    push @new_list, $elem;

    return wantarray ? @new_list : \@new_list;
}


sub list_rotate_right
{
    # Martin A. Hansen, April 2007.

    # given a list, pops off the last element,
    # and prefixes to the list, which is returned.

    my ( $list,   # list to rotate
       ) = @_;

    my ( @new_list, $elem );

    @new_list = @{ $list };
 
    $elem = pop @new_list;

    unshift @new_list, $elem;

    return wantarray ? @new_list : \@new_list;
}


sub list_check_numeric
{
    # Martin A. Hansen, April 2007.

    # Checks if a given list only contains
    # numerical elements. return 1 if numerical,
    # else 0.

    my ( $list,   # list to check
       ) = @_;

    # returns integer

    my ( $elem );

    foreach $elem ( @{ $list } ) {
        return 0 if not Maasha::Calc::is_a_number( $elem );
    }

    return 1;
}


sub list_check_sort
{
    # Martin A. Hansen, April 2007.

    # Checks if a given list is sorted.
    # If the sort type is not specified, we
    # are going to check the type and make a guess.
    # Returns 1 if sorted else 0.

    my ( $list,   # list to check
         $type,   # numerical of alphabetical
       ) = @_;

    # returns integer 

    my ( $i, $cmp );

    if ( not $type )
    {
        if ( list_check_numeric( $list ) ) {
            $type = "n";
        } else {
            $type = "a";
        }
    }
    else
    {
        if ( $type =~ /^a.*/i ) {
            $type = "a";
        } else {
            $type = "n";
        }
    }

    if ( @{ $list } > 1 )
    {
        if ( $type eq "n" )
        {
            for ( $i = 1; $i < @{ $list }; $i++ )
            {
                $cmp = $list->[ $i - 1 ] <=> $list->[ $i ];

                return 0 if $cmp > 0;
            }
        }
        else
        {
            for ( $i = 1; $i < @{ $list }; $i++ )
            {
                $cmp = $list->[ $i - 1 ] cmp $list->[ $i ];
                
                return 0 if $cmp > 0;
            }
        }
    }

    return 1;
}


sub list_deflate
{
    # Martin A. Hansen, February 2010.
    
    # Deflates a list of values to a specified size. 
    
    my ( $list,
         $new_size,
       ) = @_;

    # Returns nothing.

    my ( $len, $l_len, $r_len, $diff, $block_size, $space, $i );

    while ( scalar @{ $list } > $new_size )
    {
        $len        = @{ $list };
        $diff       = $len - $new_size;
        $block_size = int( $len / $new_size );

        if ( $block_size > 1 )
        {
            for ( $i = @{ $list } - $block_size; $i >= 0; $i -= $block_size ) {
                splice @{ $list }, $i, $block_size, Maasha::Calc::mean( [ @{ $list }[ $i .. $i + $block_size - 1 ] ] );
            }
        }
        else
        {
             $space = $len / $diff;
 
             if ( ( $space % 2 ) == 0 )
             {
                 splice @{ $list }, $len / 2 - 1, 2, Maasha::Calc::mean( [ @{ $list }[ $len / 2 - 1 .. $len / 2 ] ] );
             }
             else
             {
                 $l_len = $len * ( 1 / 3 );
                 $r_len = $len * ( 2 / 3 );

                 splice @{ $list }, $r_len, 2, Maasha::Calc::mean( [ @{ $list }[ $r_len .. $r_len + 1 ] ] );
                 splice @{ $list }, $l_len, 2, Maasha::Calc::mean( [ @{ $list }[ $l_len .. $l_len + 1 ] ] ) if @{ $list } > $new_size;
             }
        }
    }
}


sub list_inflate
{
    # Martin A. Hansen, February 2010.
    
    # Inflates a list of values to a specified size. Newly
    # introduced elements are interpolated from neighboring elements.
    
    my ( $list,
         $new_size,
       ) = @_;

    # Returns nothing.

    my ( $len, $diff, $block_size, $space, $i );

    while ( $new_size - scalar @{ $list } > 0 )
    {
        $len        = @{ $list };
        $diff       = $new_size - $len;
        $block_size = int( $diff / ( $len - 1 ) );

        if ( $block_size > 0 )
        {
            for ( $i = 1; $i < @{ $list }; $i += $block_size + 1 ) {
                splice @{ $list }, $i, 0, interpolate( $list->[ $i - 1 ], $list->[ $i ], $block_size );
            }
        }
        else
        {
            $space = $len / $diff;

            if ( ( $space % 2 ) == 0 )
            {
                splice @{ $list }, $len / 2, 0, interpolate( $list->[ $len / 2 ], $list->[ $len / 2 + 1 ], 1 );
            }
            else
            {
                splice @{ $list }, $len * ( 2 / 3 ), 0, interpolate( $list->[ $len * ( 2 / 3 ) ], $list->[ $len * ( 2 / 3 ) + 1 ], 1 );
                splice @{ $list }, $len * ( 1 / 3 ), 0, interpolate( $list->[ $len * ( 1 / 3 ) ], $list->[ $len * ( 1 / 3 ) + 1 ], 1 ) if @{ $list } < $new_size;
            }
        }
    }
}


sub interpolate
{
    # Martin A. Hansen, March 2010

    # Given two values insert a specified number of values evenly
    # between these NOT encluding the given values.

    my ( $beg,     # Begin of interval
         $end,     # End of interval
         $count,   # Number of values to introduce
       ) = @_;

    # Returns a list

    my ( $diff, $factor, $i, @list );

    $diff   = $end - $beg;

    $factor = $diff / ( $count + 1 );

    for ( $i = 1; $i <= $count; $i++ ) {
        push @list, $beg + $i * $factor;
    }

    return wantarray ? @list : \@list;
}


sub list_uniq
{
    # Martin A. Hansen, April 2007.

    # returns the number of unique elements in a
    # given list.

    my ( $list,   # list
       ) = @_;

    # returns integer

    my ( %hash, $count );

    map { $hash{ $_ } = 1 } @{ $list };

    $count = scalar keys %hash;

    return $count;
}


sub tabulate
{
    # Martin A. Hansen, April 2007.

    my ( $matrix,    # AoA data structure
         $col,
       ) = @_;

    my ( $dims, $list, $i, $max, $len, %hash, $elem, @list );

    $dims = matrix_dims( $matrix );

    $list = cols_get( $matrix, $col, $col );
    $list = matrix_flip( $list )->[ 0 ];

    $max = 0;

    for ( $i = 0; $i < @{ $list }; $i++ )
    {
        $hash{ $list->[ $i ] }++;

        $len = length $list->[ $i ];

        $max = $len if $len > $max;
    }
    
    @list = keys %hash;

    if ( list_check_numeric( $list ) ) {
        @list = sort { $a <=> $b } @list;
    } else {
        @list = sort { $a cmp $b } @list;
    }

    foreach $elem ( @list )
    {
        print $elem, " " x ( $max - length( $elem ) ),
        sprintf( "   %6s   ", $hash{ $elem } ),
        sprintf( "%.2f\n", ( $hash{ $elem } / $dims->[ ROWS ] ) * 100 );
    }
}


sub merge_tabs
{
    # Martin A. Hansen, July 2008.

    # Merge two given tables based on identifiers in a for each table
    # specified column which should contain a unique identifier.
    # Initially the tables are sorted and tab2 is merged onto tab1
    # row-wise.

    my ( $tab1,       # table 1 - an AoA.
         $tab2,       # table 2 - an AoA.
         $col1,       # identifier in row1
         $col2,       # identifier in row2
         $sort_type,  # alphabetical or numeric comparison
       ) = @_;

    # Returns nothing.

    my ( $num, $cmp, $i, $c, @row_cpy, $max );

    $max = 0;
    $num = 0;

    if ( $sort_type =~ /num/i )
    {
        $num = 1;

        @{ $tab1 } = sort { $a->[ $col1 ] <=> $b->[ $col1 ] } @{ $tab1 };
        @{ $tab2 } = sort { $a->[ $col2 ] <=> $b->[ $col2 ] } @{ $tab2 };
    }
    else
    {
        @{ $tab1 } = sort { $a->[ $col1 ] cmp $b->[ $col1 ] } @{ $tab1 };
        @{ $tab2 } = sort { $a->[ $col2 ] cmp $b->[ $col2 ] } @{ $tab2 };
    }

    $i = 0;
    $c = 0;

    while ( $i < @{ $tab1 } and $c < @{ $tab2 } )
    {
        if ( $num ) {
            $cmp = $tab1->[ $i ]->[ $col1 ] <=> $tab2->[ $c ]->[ $col2 ];
        } else {
            $cmp = $tab1->[ $i ]->[ $col1 ] cmp $tab2->[ $c ]->[ $col2 ];
        }
    
        if ( $cmp == 0 )
        {
            @row_cpy = @{ $tab2->[ $c ] };

            splice @row_cpy, $col2, 1;

            push @{ $tab1->[ $i ] }, @row_cpy;

            $i++;
            $c++;
        }
        elsif ( $cmp > 0 )
        {
            $c++;
        }
        else
        {
            map { push @{ $tab1->[ $i ] }, "null" } 0 .. ( scalar @{ $tab2->[ $c ] } - 2 );

            $i++;
        }
    }

    map { push @{ $tab1->[ -1 ] }, "null" } 0 .. ( scalar @{ $tab1->[ 0 ] } - scalar @{ $tab1->[ -1 ] } + 1 );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BINARY SEARCH <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub interval_search
{
    # Martin A. Hansen, February 2008.

    # Uses binary search to locate the interval containing a
    # given number. The intervals are defined by begin and end
    # positions in seperate columns in a matrix. If a interval is
    # found then the index of that matrix row is returned, otherwise
    # -1 is returned.

    my ( $matrix,   # data structure
         $col1,     # column with interval begins
         $col2,     # column with interval ends
         $num,      # number to search for
       ) = @_;

    # Returns an integer.

    my ( $high, $low, $try );

    $low  = 0;
    $high = @{ $matrix };

    while ( $low < $high )
    {
        $try = int( ( $high + $low ) / 2 );
    
        # print "num->$num   low->$low   high->$high   try->$try   int1->$matrix->[ $try ]->[ $col1 ]   int2->$matrix->[ $try ]->[ $col2 ]\n";

        if ( $num < $matrix->[ $try ]->[ $col1 ] ) {
            $high = $try;
        } elsif ( $num > $matrix->[ $try ]->[ $col2 ] ) {
            $low = $try + 1;
        } else {
            return $try;
        }
    }

    return -1;
}


sub list_search
{
    # Martin A. Hansen, February 2008.

    # Uses binary search to locate a number in a list of numbers.
    # If the number is found, then the index (the position of the number
    # in the list) is returned, otherwise -1 is returned.

    my ( $list,   # list of numbers
         $num,    # number to search for
       ) = @_;

    # Returns an integer.

    my ( $high, $low, $try );

    $low  = 0;
    $high = @{ $list };

    while ( $low < $high )
    {
        $try = int( ( $high + $low ) / 2 );
    
        # print "num->$num   low->$low   high->$high   try->$try   int->$list->[ $try ]\n";

        if ( $num < $list->[ $try ] ) {
            $high = $try;
        } elsif ( $num > $list->[ $try ] ) {
            $low = $try + 1;
        } else {
            return $try;
        }
    }

    return -1;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DISK SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub matrix_read
{
    # Martin A. Hansen, April 2007

    # Reads tabular data from file into a matrix
    # AoA data structure.

    my ( $path,        # full path to file with data
         $delimiter,   # column delimiter - OPTIONAL (default tab)
         $comments,    # regex for comment lines to skip - OPTIONAL
         $fields_ok,   # list of fields to accept        - OPTIONAL
       ) = @_;

    # returns AoA

    my ( $fh, $line, @fields, @AoA );

    $delimiter ||= "\t";

    $fh = Maasha::Filesys::file_read_open( $path );

    while ( $line = <$fh> )
    {
        chomp $line;

        next if $comments and $line =~ /^$comments/;

        @fields = split /$delimiter/, $line;

        map { splice( @fields, $_, 1 ) } @{ $fields_ok } if $fields_ok;

        push @AoA, [ @fields ];
    }

    close $fh;

    return wantarray ? @AoA : \@AoA;
}


sub matrix_write
{
    # Martin A. Hansen, April 2007

    # Writes a tabular data structure to STDOUT or file.

    my ( $matrix,      # AoA data structure
         $path,        # full path to output file - OPTIONAL (default STDOUT)
         $delimiter,   # column delimiter         - OPTIONAL (default tab)
       ) = @_;

    my ( $fh, $row );

    $fh = Maasha::Filesys::file_write_open( $path ) if $path;

    $delimiter ||= "\t";

    foreach $row ( @{ $matrix } )
    {
        if ( $fh ) {
            print $fh join( $delimiter, @{ $row } ), "\n";
        } else {
            print join( $delimiter, @{ $row } ), "\n";
        }
    }

    close $fh if $fh;
}


sub matrix_store
{
    # Martin A. Hansen, April 2007.

    # stores a matrix to a binary file.

    my ( $path,      # full path to file
         $matrix,    # data structure
       ) = @_;

    Maasha::Filesys::file_store( $path, $matrix );
}


sub matrix_retrive
{
    # Martin A. Hansen, April 2007.

    # retrieves a matrix from a binary file

    my ( $path,   # full path to file
       ) = @_;

    my $matrix = Maasha::Filesys::file_retrieve( $path );

    return wantarray ? @{ $matrix } : $matrix;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
