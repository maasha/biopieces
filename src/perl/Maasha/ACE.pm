package Maasha::ACE;

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


# Routines to parse ACE format.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Storable;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::KISS;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );


@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub ace_entries_get
{
    # Martin A. Hansen, December 2009.
    #
    # Fetches the next contig from an ACE file.

    my ( $fh,
       ) = @_;

    my ( $block, $line, @lines, $records );

    local $/ = "\nCO ";

    while ( $block = <$fh> )
    {
        chomp $block;

        next if $block =~ /^AS/;

        if ( defined $block )
        {
            @lines = split "\n", "CO $block";

            $records = ace_entry_parse( \@lines );

            return wantarray ? @{ $records } : $records;
        }
    }
}


sub ace_entry_parse
{
    # Martin A. Hansen, December 2009.

    # Parses an ACE entry given as a list of lines and
    # returns a list of hashref.

    my ( $entry,  # list of lines
       ) = @_;

    # Returns a list.

    my ( $i, $contig, $reads, $read_name, $read_seq, $record, @records );

    $i = 0;

    while ( $i < scalar @{ $entry } )
    {
        if ( $entry->[ $i ] =~ /^CO ([^ ]+) (\d+) (\d+) (\d+) (U|C)/ )
        {
            $contig->{ 'CONTIG_NAME' }       = $1;
            $contig->{ 'CONTIG_BASES' }      = $2;
            $contig->{ 'CONTIG_READS' }      = $3;
            $contig->{ 'CONTIG_SEGMENT' }    = $4;
            $contig->{ 'CONTIG_COMPLEMENT' } = $5;
            $contig->{ 'CONTIG_SEQ' }        = "";

            $i++;

            while ( $entry->[ $i ] ne "" )
            {
                $contig->{ 'CONTIG_SEQ' } .= $entry->[ $i ];

                $i++;
            }
        }
        elsif ( $entry->[ $i ] =~ /^AF ([^ ]+) (U|C) (-?\d+)/ )
        {
            $reads->{ $1 }->{ 'AF_READ_COMPLEMENT' } = $2;
            $reads->{ $1 }->{ 'AF_READ_BEG' }        = ( $3 - 1 );
        }
        elsif ( $entry->[ $i ] =~ /^BS (\d+) (\d+) (.+)/ )
        {
            # skip
        }
        elsif ( $entry->[ $i ] =~ /^RD ([^ ]+) (\d+) (\d+) (\d+)/ )
        {
            $read_name = $1;

            $reads->{ $read_name }->{ 'RD_READ_LEN' }   = $2;
            $reads->{ $read_name }->{ 'RD_READ_ITEMS' } = $3;
            $reads->{ $read_name }->{ 'RD_READ_TAGS' }  = $4;

            $read_seq   = "";

            $i++;

            while ( $entry->[ $i ] ne "" )
            {
                $read_seq .= $entry->[ $i ];

                $i++;
            }

            $reads->{ $read_name }->{ 'RD_READ_SEQ' } = $read_seq;
        }
        elsif ( $entry->[ $i ] =~ /^QA (\d+) (\d+) (\d+) (\d+)/ )
        {
            $reads->{ $read_name }->{ 'QA_CLIP_BEG' }  = ( $1 - 1 );
            $reads->{ $read_name }->{ 'QA_CLIP_END' }  = ( $2 - 1 );
            $reads->{ $read_name }->{ 'QA_ALIGN_BEG' } = ( $3 - 1 );
            $reads->{ $read_name }->{ 'QA_ALIGN_END' } = ( $4 - 1 );
        }

        $i++;
    }

    my ( $read, $s_seq, $q_seq, $len, $align );

    foreach $read ( keys %{ $reads } )
    {
        $len   = $reads->{ $read }->{ 'QA_ALIGN_END' } - $reads->{ $read }->{ 'QA_ALIGN_BEG' } + 1;
        $s_seq = substr $contig->{ 'CONTIG_SEQ' }, $reads->{ $read }->{ 'AF_READ_BEG' } + $reads->{ $read }->{ 'QA_ALIGN_BEG' }, $len;
        $q_seq = substr $reads->{ $read }->{ 'RD_READ_SEQ' }, $reads->{ $read }->{ 'QA_ALIGN_BEG' }, $len;

        $s_seq =~ tr/*/-/;
        $q_seq =~ tr/*/-/;

        if ( $reads->{ $read }->{ 'AF_READ_COMPLEMENT' } eq 'C' )
        {
            $record->{ 'STRAND' } = '-';

            Maasha::Seq::dna_comp( \$s_seq );
            Maasha::Seq::dna_comp( \$q_seq );
        }
        else
        {
            $record->{ 'STRAND' } = '+';
        }

       # print Dumper( $read, $reads->{ $read } );

        $align = Maasha::KISS::kiss_align_enc( \$s_seq, \$q_seq, $reads->{ $read }->{ 'QA_ALIGN_BEG' } );

        $record->{ 'S_ID' }  = $contig->{ 'CONTIG_NAME' };
        $record->{ 'S_BEG' } = $reads->{ $read }->{ 'AF_READ_BEG' };
        $record->{ 'S_END' } = $record->{ 'S_BEG' } + $len - 1;   # FIXME
        $record->{ 'Q_ID' }  = $read;
        $record->{ 'Q_ID' }  =~ s/\..+//;
        $record->{ 'ALIGN' } = join ",", @{ $align };

        if ( 0 )   # DEBUG
        {
            print "LEN: $len\n";
            print "S_SEQ: $s_seq\n";
            print "Q_SEQ: $q_seq\n\n";
            print "READ: $read\n";
            print Dumper( $reads->{ $read } );
            print Dumper( $record );
        }

        if ( $record->{ 'S_BEG' } >= 0 ) # FIXME
        {
            push @records, Storable::dclone $record;
        }
    }

    return wantarray ? @records : \@records;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
