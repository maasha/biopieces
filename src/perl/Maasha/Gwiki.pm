package Maasha::Gwiki;

# Copyright (C) 2008-2009 Martin A. Hansen.

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


# Routines for manipulation of Google's wiki format


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Term::ANSIColor;
use Maasha::Common;
use Maasha::Filesys;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub gwiki2ascii
{
    # Martin A. Hansen, June 2008.

    # Convert Google style wiki as ASCII text lines.

    my ( $wiki,  # wiki data structure 
       ) = @_;

    # Returns a list of lines.

    my ( $block, $triple, $line, @lines, $i );

    foreach $block ( @{ $wiki } )
    {
        if ( $block->[ 0 ]->{ 'FORMAT' } eq "heading" )
        {
            push @lines, text_underline( text_bold( "\n$block->[ 0 ]->{ 'TEXT' }" ) );
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "subheading" )
        {
            push @lines, text_bold( "$block->[ 0 ]->{ 'TEXT' }" );
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "summary" )
        {
            $block->[ 0 ]->{ 'TEXT' } =~ s/^#summary\s+//;

            push @lines, text_bold( "Summary" ), "\n$block->[ 0 ]->{ 'TEXT' }";
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "level_3" )
        {
            push @lines, "$block->[ 0 ]->{ 'TEXT' }";
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "verbatim" )
        {
            map { push @lines, text_white( "   $_->{ 'TEXT' }" ) } @{ $block };
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "itemize" )
        {
            for ( $i = 0; $i < @{ $block }; $i++ ) {
                push @lines, "   * $block->[ $i ]->{ 'TEXT' }";
            }
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "enumerate" )
        {
            for ( $i = 0; $i < @{ $block }; $i++ ) {
                push @lines, "   " . ( $i + 1 ) . ". $block->[ $i ]->{ 'TEXT' }";
            }
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "paragraph" )
        {
            foreach $triple ( @{ $block } )
            {
                $line = $triple->{ 'TEXT' };

                $line =~ s/!(\w)/$1/g;
                $line =~ s/^\s*//;
                $line =~ s/\s*$//;
                $line =~ s/\s+/ /g;
                $line =~ tr/`//d;
                $line =~ s/\[([^\]]+?)\]/&text_underline($1)/ge;
                $line =~ s/\*(\w+)\*/&text_bold($1)/ge           if $line =~ /(^| )\*\w+\*( |$)/;
                $line =~ s/_(\w+)_/&text_underline($1)/ge        if $line =~ /(^| )_\w+_( |$)/;

                push @lines, $_ foreach Maasha::Common::wrap_line( $line, 80 );
            }
        }
        elsif ( $block->[ 0 ]->{ 'FORMAT' } eq "whitespace" )
        {
            push @lines, "";
        }
    }

    return wantarray ? @lines : \@lines;
}


sub gwiki_read
{
    # Martin A. Hansen, June 2008.

    # Parses a subset of features from Googles wiki format
    # into a data structure. The structure consists of a 
    # list of blocks. Each block consists of one or more lines,
    # represented as triples with the line text, section, and format option.

    # http://code.google.com/p/support/wiki/WikiSyntax

    my ( $file,   # file to parse
       ) = @_;

    # Returns data structure.

    my ( $fh, @lines, $i, $c, $section, $paragraph, @block, @output );

    $fh = Maasha::Filesys::file_read_open( $file );

    @lines = <$fh>;
    
    chomp @lines;

    close $fh;

    $i = 0;
    $c = 0;

    while ( $i < @lines )
    {
        undef @block;

        if ( $lines[ $i ] =~ /(#summary.+)/ ) # TODO: unsolved problem with anchor!
        {
            $section = $1;

            push @block, {
                TEXT    => $section,
                SECTION => $section,
                FORMAT  => "summary",
            };
        }
        elsif ( $lines[ $i ] =~ /^===\s*(.+)\s*===$/ )
        {
            $section = $1;

            push @block, {
                TEXT    => $section,
                SECTION => $section,
                FORMAT  => "level_3",
            };
        }
        elsif ( $lines[ $i ] =~ /^==\s*(.+)\s*==$/ )
        {
            $section = $1;

            push @block, {
                TEXT    => $section,
                SECTION => $section,
                FORMAT  => "subheading",
            };
        }
        elsif ( $lines[ $i ] =~ /^=\s*(.+)\s*=$/ )
        {
            $section = $1;

            push @block, {
                TEXT    => $section,
                SECTION => $section,
                FORMAT  => "heading",
            };
        }
        elsif ( $lines[ $i ] =~ /^\{\{\{$/ )
        {
            $c = $i + 1;

            while ( $lines[ $c ] !~ /^\}\}\}$/ )
            {
                push @block, {
                    TEXT    => $lines[ $c ],
                    SECTION => $section,
                    FORMAT  => "verbatim",
                };

                $c++;
            }

            $c++;
        }
        elsif ( $lines[ $i ] =~ /^\s{1,}\*\s*.+/ )
        {
            $c = $i;

            while ( $lines[ $c ] =~ /^\s{1,}\*\s*(.+)/ )
            {
                push @block, {
                    TEXT    => $1,
                    SECTION => $section,
                    FORMAT  => "itemize"
                };

                $c++;
            }
        }
        elsif ( $lines[ $i ] =~ /^\s{1,}#\s*.+/ )
        {
            $c = $i;

            while ( $lines[ $c ] =~ /^\s{1,}#\s*(.+)/ )
            {
                push @block, {
                    TEXT    => $1,
                    SECTION => $section,
                    FORMAT  => "enumerate"
                };

                $c++;
            }
        }
        elsif ( $lines[ $i ] !~ /^\s*$/ )
        {
            undef $paragraph;

            $c = $i;

            while ( defined $lines[ $c ] and $lines[ $c ] !~ /^\s*$/ )
            {
                $paragraph .= " $lines[ $c ]";

                $c++;
            }

            push @block, {
                TEXT    => $paragraph,
                SECTION => $section,
                FORMAT  => "paragraph",
            };
        }
        elsif ( $lines[ $i ] =~ /^\s*$/ )
        {
            push @block, {
                TEXT    => "",
                SECTION => $section,
                FORMAT  => "whitespace",
            };
        }

        push @output, [ @block ], if @block;

        if ( $c > $i ) {
            $i = $c;
        } else {
            $i++;
        }
    }

    return wantarray ? @output : \@output;
}


sub text_bold
{
    my ( $txt,
       ) = @_;

    return colored( $txt, "bold" );
}


sub text_underline
{
    my ( $txt,
       ) = @_;

    return colored( $txt, "underline" );
}

sub text_white
{
    my ( $txt,
       ) = @_;

    return colored( $txt, "white" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

