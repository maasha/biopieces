package Maasha::SAM;

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


# Routines to handle SAM and BAM format.
# http://samtools.sourceforge.net/


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Maasha::Common;
use Maasha::Fastq;
use Data::Dumper;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    QNAME => 0,
    FLAG  => 1,
    RNAME => 2,
    POS   => 3,
    MAPQ  => 4,
    CIGAR => 5,
    MRNM  => 6,
    MPOS  => 7,
    ISIZE => 8,
    SEQ   => 9,
    QUAL  => 10,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub sam_entry_get
{
    # Martin A. Hansen, September 2009.

    # Parses a SAM entry from a given file handle.

    my ( $fh,   # file handle
       ) = @_;

    # Returns a list.

    my ( $line, @fields );

    while ( $line = <$fh> )
    {
        chomp $line;

        next if substr( $line, 0, 1 ) eq '@';

        @fields = split "\t", $line;

        return wantarray ? @fields : \@fields;
    }

    return;
}


sub sam_entry_put
{

}


sub sam2biopiece
{
    # Martin A. Hansen, September 2009.

    # Converts a SAM entry to a Biopiece record.

    my ( $entry,   # SAM entry
       ) = @_;
    
    # Returns a hashref.

    my ( $record, $i, $tag, $vtype, $value );

    return if $entry->[ RNAME ] eq '*';

    $record->{ 'REC_TYPE' } = 'SAM';
    $record->{ 'Q_ID' }     = $entry->[ QNAME ];
    $record->{ 'FLAG' }     = $entry->[ FLAG ];
    $record->{ 'S_ID' }     = $entry->[ RNAME ];
    $record->{ 'S_BEG' }    = $entry->[ POS ];
    $record->{ 'MAPQ' }     = $entry->[ MAPQ ];
    $record->{ 'CIGAR' }    = $entry->[ CIGAR ];
    $record->{ 'MRNM' }     = $entry->[ MRNM ];
    $record->{ 'S_BEG2' }   = $entry->[ MPOS ];
    $record->{ 'ISIZE' }    = $entry->[ ISIZE ];
    $record->{ 'SEQ' }      = $entry->[ SEQ ];
    $record->{ 'SCORES' }   = $entry->[ QUAL ];
    $record->{ 'SCORES' }   =~ s/(.)/chr( ( ord( $1 ) - 33 ) + 64 )/ge; # convert phred-33 to phred-64 scores
    $record->{ 'SCORE' }    = sprintf( "%.2f", Maasha::Fastq::phred_str_mean( $entry->[ QUAL ] ) );

    $record->{ 'S_BEG' } -= 1 if $record->{ 'S_BEG' }  != 0;
    $record->{ 'S_BEG' } -= 1 if $record->{ 'S_BEG2' } != 0;

    $record->{ 'S_END' } = $record->{ 'S_BEG' } + length( $record->{ 'SEQ' } ) - 1;

    $record->{ 'READ_PAIRED' }    = $record->{ 'FLAG' } & 0x0001;
    $record->{ 'READ_MAPPED' }    = $record->{ 'FLAG' } & 0x0002;
    $record->{ 'Q_SEQ_UNMAPPED' } = $record->{ 'FLAG' } & 0x0004;
    $record->{ 'MATE_UNMAPPED' }  = $record->{ 'FLAG' } & 0x0008;

    if ( $record->{ 'FLAG' } & 0x0010 ) {   # 0 for forward, 1 for reverse
        $record->{ 'STRAND' } = '-';
    } else {
        $record->{ 'STRAND' } = '+';
    }

    $record->{ 'MATE_STRAND' }    = $record->{ 'FLAG' } & 0x0020;
    $record->{ '1ST_READ' }       = $record->{ 'FLAG' } & 0x0040;
    $record->{ '2ND_READ' }       = $record->{ 'FLAG' } & 0x0080;
    $record->{ 'ALIGN_PRIMARY' }  = $record->{ 'FLAG' } & 0x0100;
    $record->{ 'READ_FAIL' }      = $record->{ 'FLAG' } & 0x0200;
    $record->{ 'READ_BAD' }       = $record->{ 'FLAG' } & 0x0400;

    if ( $record->{ 'READ_PAIRED' } ) {
        $record->{ 'BLOCK_COUNT' } = 2;
    } else {
        $record->{ 'BLOCK_COUNT' } = 1;
    }

    # extra fields - (hate hate hate SAM!!!)
    
    for ( $i = QUAL + 1; $i < @{ $entry }; $i++ )
    {
        ( $tag, $vtype, $value ) = split /:/, $entry->[ $i ];

        if ( $tag eq "MD" or $tag eq "NM" ) {
            $record->{ $tag } = $value;       
        }
    }

    if ( defined $record->{ "NM" } and $record->{ "NM" } > 0 ) {
        $record->{ "ALIGN" } = sam2align( $record->{ 'SEQ' }, $record->{ 'CIGAR' }, $record->{ 'NM' }, $record->{ 'MD' } );
    } else {
        $record->{ "ALIGN" } = ".";
    }

    return wantarray ? %{ $record } : $record;
}


sub sam2align
{
    my ( $seq,
         $cigar,
         $nm,
         $md,
       ) = @_;

    # Returns a string.

    my ( $offset, $len, $op, $i, $nt, $nt2, @nts, $insertions, @align, $aln_str );

    $offset     = 0;
    $insertions = 0;

    while ( length( $cigar ) > 0 )
    {
        if ( $cigar =~ s/^(\d+)(\w)// )
        {
            $len = $1;
            $op  = $2;

            if ( $op eq 'I' )
            {
                for ( $i = 0; $i < $len; $i++ )
                {
                    $nt = substr $seq, $offset + $i, 1;

                    push @align, [ $offset + $i, "->$nt" ];

                    $nm--;
                }
            }

            $offset += $len;
        }
    }
    
    $offset = 0;

    while ( $nm > 0 )
    {
        if ( $md =~ s/^(\d+)// )   # match
        {
            $offset += $1;
        }
        elsif( $md =~ s/^\^([ATCGN]+)// )  # insertions
        {
            @nts = split //, $1;

            foreach $nt ( @nts )
            {
                $nt2 = substr $seq, $offset, 1;

                push @align, [ $offset, "$nt2>-" ];
        
                $offset++;

                $insertions++;

                $nm--;
            }
        }
        elsif ( $md =~ s/^([ATCGN]+)// ) # mismatch
        {
            @nts = split //, $1;

            foreach $nt ( @nts )
            {
                $nt2 = substr $seq, $offset - $insertions, 1;

                push @align, [ $offset, "$nt>$nt2" ];

                $offset++;

                $nm--;
            }
        }
        else
        {
            Maasha::Common::error( qq(Bad SAM field -> MD: "$md") );
        }
    }

    $aln_str = "";

    @align = sort { $a->[ 0 ] <=> $b->[ 0 ] } @align;

    map { $aln_str .= "$_->[ 0 ]:$_->[ 1 ]," } @align;

    $aln_str =~ s/,$//;

    return $aln_str;
}


sub biopiece2sam
{

}



# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;
