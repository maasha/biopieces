package Maasha::Patscan;

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


# This module contains commonly used routines


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Common;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub read_patterns
{
    # Martin A. Hansen, August 2007.

    # Read a list of patterns from file with one pattern
    # per line.

    my ( $path,   # full path to file
       ) = @_;

    # Returns list.

    my ( $fh, $line, @patterns );

    $fh = Maasha::Common::read_open( $path );

    while ( $line = <$fh> )
    {
        $line =~ s/\r|\n//g;

        next if $line eq "";

        push @patterns, $line;
    }

    close $fh;

    return wantarray ? @patterns : \@patterns;
}


sub parse_patterns
{
    # Martin A. Hansen, November 2007.

    # Splits a string of patterns with out breaking patterns with [,,].

    my ( $str,   # comma separated list of patterns
       ) = @_;

    # Returns a list.

    my ( $i, $char, $brackets, @patterns );

    $brackets = 0;

    for ( $i = 0; $i < length $str; $i++ )
    {
        $char = substr $str, $i, 1;

        if ( $char eq "[" ) {
            $brackets++;
        } elsif ( $char eq "]" ) {
            $brackets--;
        } elsif ( $char eq "," and $brackets != 0 ) {
            substr $str, $i, 1, '!';
        }
    }

    @patterns = split ",", $str;

    map { s/!/,/g } @patterns;

    return wantarray ? @patterns : \@patterns;
}


sub parse_scan_result
{
    # Martin A. Hansen, January 2007.

    # Parses scan_for_matches results

    my ( $entry,     # FASTA tuple
         $pattern,   # pattern used in patscan
       ) = @_;

    # Returns hash.

    my ( $head, $seq, $beg, $end, $len, $strand, %match );

    ( $head, $seq ) = @{ $entry };

    if ( $head =~ /^(.+):\[(\d+),(\d+)\]$/ )
    {
        $head = $1;
        $beg  = $2;
        $end  = $3;

        if ( $beg > $end )
        {
            ( $beg, $end ) = ( $end, $beg );

            $strand = "-";
        }
        else
        {
            $strand = "+";
        }

        $len = $end - $beg + 1;

        %match = (
            "REC_TYPE"  => "PATSCAN",
            "PATTERN"   => $pattern,
            "Q_ID"      => $pattern,
            "S_ID"      => $head,
            "S_BEG"     => $beg - 1, # sfm is 1-based
            "S_END"     => $end - 1, # sfm is 1-based
            "MATCH_LEN" => $len,
            "SCORE"     => 100,
            "STRAND"    => $strand,
            "HIT"       => $seq,
        );
    }
    else
    {
        warn qq(WARNING: Could not parse match header->$head<-\n);
    }

    return wantarray ? %match : \%match;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
