package Maasha::Solid;


# Copyright (C) 2007-2008 Martin A. Hansen.

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


# Routines for manipulation Solid sequence files with di-base encoding.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CONSTANTS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


my %CONVERT_HASH = (
    'A0' => 'A',   'AA' => 0,
    'A1' => 'C',   'AC' => 1,
    'A2' => 'G',   'AG' => 2,
    'A3' => 'T',   'AT' => 3,
    'C0' => 'C',   'CA' => 1,
    'C1' => 'A',   'CC' => 0,
    'C2' => 'T',   'CG' => 3,
    'C3' => 'G',   'CT' => 2,
    'G0' => 'G',   'GA' => 2,
    'G1' => 'T',   'GC' => 3,
    'G2' => 'A',   'GG' => 0,
    'G3' => 'C',   'GT' => 1,
    'T0' => 'T',   'TA' => 3,
    'T1' => 'G',   'TC' => 2,
    'T2' => 'C',   'TG' => 1,
    'T3' => 'A',   'TT' => 0,
                   'AN' => 4,
                   'CN' => 4,
                   'GN' => 4,
                   'TN' => 4,
                   'NA' => 5,
                   'NC' => 5,
                   'NG' => 5,
                   'NT' => 5,
                   'NN' => 6,
);


# from Solid - ABI

sub define_color_code {

    my %color = ();

    $color{AA} = 0;
    $color{CC} = 0;
    $color{GG} = 0;
    $color{TT} = 0;
    $color{AC} = 1;
    $color{CA} = 1;
    $color{GT} = 1;
    $color{TG} = 1;
    $color{AG} = 2;
    $color{CT} = 2;
    $color{GA} = 2;
    $color{TC} = 2;
    $color{AT} = 3;
    $color{CG} = 3;
    $color{GC} = 3;
    $color{TA} = 3;
    $color{AN} = 4;
    $color{CN} = 4;
    $color{GN} = 4;
    $color{TN} = 4;
    $color{NA} = 5;
    $color{NC} = 5;
    $color{NG} = 5;
    $color{NT} = 5;
    $color{NN} = 6;

    return(%color);
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub color_space2seq
{
    # Martin A. Hansen, April 2008.

    # Converts a di-base encoded Solid sequence to
    # regular sequence.

    my ( $seq_cs,   # di-base encode sequence
       ) = @_;

    # Returns a string.

    my ( @codes, $base, $i, $seq );

    @codes = split //, $seq_cs;
    $base  = shift @codes;
    $seq   = $base;

    for ( $i = 0; $i < @codes; $i++ )
    {
        $base = $CONVERT_HASH{ $base . $codes[ $i ] };
        $seq .= $base;
    }

    return $seq;
}


sub seq2color_space
{
    # Martin A. Hansen, April 2008.

    # Converts a sequence to di-base encoded Solid sequence.

    my ( $seq,   # sequence
       ) = @_;

    # Returns a string.

    my ( $i, $seq_cs );

    $seq_cs = substr $seq, 0, 1;

    for ( $i = 0; $i < length( $seq ) - 1; $i++ ) {
        $seq_cs .= $CONVERT_HASH{ substr( $seq, $i, 2 ) };
    }

    return $seq_cs;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
