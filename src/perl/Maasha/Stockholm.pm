package Maasha::Stockholm;

# Copyright (C) 2006 Martin A. Hansen.

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


# Routines for manipulation of the Stockholm format.
# http://www.cgb.ki.se/cgb/groups/sonnhammer/Stockholm.html


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Common;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub get_stockholm_entry
{
    # Martin A. Hansen, February 2007.

    # Given a file handle, returns the next stockholm
    # entry as a list of lines.

    my ( $fh,   # file handle
       ) = @_;

    # returns a list

    my ( $line, @lines );

    while ( defined $fh and $line = <$fh> )
    {
        chomp $line;

        push @lines, $line;

        last if $line eq "//";
    }

    if ( not @lines ) {
        return undef;
    } else {
        return wantarray ? @lines : \@lines;
    }
}


sub parse_stockholm_entry
{
    # Martin A. Hansen, February 2007.
    
    # given a Stockholm entry as a list of lines,
    # parses this into an elaborate data structure.
    # Compultory fields: AC ID DE AU SE SS BM GA TC NC TP SQ
    # Non-compultory fields: PI DC DR RC RN RM RT RA RL CC

    my ( $entry,   # stockholm entry
       ) = @_;

    # returns data structure

    my ( $line, %hash, %align_hash, @align_list, @align );

    foreach $line ( @{ $entry } )
    {
        next if $line =~ /^# /;

        if ( $line =~ /^#=GF\s+([^\s]+)\s+(.*)$/ )
        {
            push @{ $hash{ "GF" }{ $1 } }, $2;
        }
        elsif ( $line =~ /^#=GC\s+([^\s]+)\s+(.*)$/ )
        {
            push @{ $hash{ "GC" }{ $1 } }, $2;
        }
        elsif ( $line =~ /^#=GS\s+([^\s]+)\s+([^\s]+)\s+(.*)$/ )
        {
            push @{ $hash{ "GS" }{ $1 }{ $2 } }, $3;
        }
        elsif ( $line =~ /^#=GR\s+([^\s]+)\s+([^\s]+)\s+(.*)$/ )
        {
            push @{ $hash{ "GR" }{ $1 }{ $2 } }, $3;
        }
        elsif ( $line =~ /^([^\s]+)\s+(.+)$/ )
        {
            push @align_list, $1 if not exists $align_hash{ $1 };

            $align_hash{ $1 } .= $2;
        }
    }

    map { $hash{ "GF" }{ $_ } = join " ", @{ $hash{ "GF" }{ $_ } } } keys %{ $hash{ "GF" } };
    map { $hash{ "GC" }{ $_ } = join  "", @{ $hash{ "GC" }{ $_ } } } keys %{ $hash{ "GC" } };
    map { push @align, [ $_, $align_hash{ $_ } ] } @align_list;

    push @align, [ "SS_cons", $hash{ "GC" }{ "SS_cons" } ];
    push @align, [ "RF", $hash{ "GC" }{ "RF" } ] if $hash{ "GC" }{ "RF" };

    delete $hash{ "GC" };

    $hash{ "ALIGN" } = \@align;

    return wantarray ? %hash : \%hash;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
