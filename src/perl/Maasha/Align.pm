package Maasha::Align;

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


# Routines to perform and print pairwise and multiple alignments


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use IPC::Open2;
use Maasha::Common;
use Maasha::Fasta;
use Maasha::Calc;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );

use constant {
    SEQ_NAME => 0,
    SEQ      => 1,
};

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub align
{
    # Martin A. Hansen, August 2007.

    # Aligns a given list of FASTA entries and returns a
    # list of aligned sequences as FASTA entries.
    # (currently uses Muscle, but other align engines can
    # be used with a bit of tweaking).

    my ( $entries,   # Fasta entries
         $args,      # additional alignment program specific arguments - OPTIONAL
       ) = @_;

    # Returns a list.

    my ( @aligned_entries, $muscle_args );

    $muscle_args  = "-quiet";
    $muscle_args .= $args if $args;

    @aligned_entries = align_muscle( $entries, $muscle_args );

    return wantarray ? @aligned_entries : \@aligned_entries;
}


sub align_muscle
{
    # Martin A. Hansen, June 2007.

    # Aligns a given list of FASTA entries using Muscle.
    # Returns a list of aligned sequences as FASTA entries.

    my ( $entries,   # FASTA entries
         $args,      # additional Muscle arguments - OPTIONAL
       ) = @_;

    # Returns a list.

    my ( $pid, $fh_in, $fh_out, $cmd, $entry, @aligned_entries );

    $cmd  = "muscle";
    $cmd .= " " . $args if $args;

    $pid = open2( $fh_out, $fh_in, $cmd );

    map { Maasha::Fasta::put_entry( $_, $fh_in ) } @{ $entries };

    close $fh_in;

    while ( $entry = Maasha::Fasta::get_entry( $fh_out ) ) {
        push @aligned_entries, $entry;
    }

    close $fh_out;

    waitpid $pid, 0;

    return wantarray ? @aligned_entries : \@aligned_entries;
}


sub align_print_pairwise
{
    # Martin A. Hansen, June 2007.

    # Prints a given pairwise alignment in FASTA format.

    my ( $entry1,   # first entry
         $entry2,   # second entry
         $fh,       # output filehandle - OPTIONAL
         $wrap,     # wrap width        - OPTIONAL
       ) = @_;

    # returns nothing

    my ( @entries, $ruler1, $ruler2, $pins );

    $ruler1 = align_ruler( $entry1, 1 );
    $ruler2 = align_ruler( $entry2, 1 );
    $pins   = align_pins( $entry1, $entry2 );

    push @entries, $ruler1, $entry1, $pins, $entry2, $ruler2;

    align_print( \@entries, $fh, $wrap );
}


sub align_print_multi
{
    # Martin A. Hansen, June 2007.

    # Prints a given multiple alignment in FASTA format.

    my ( $entries,     # list of aligned FASTA entries
         $fh,          # output filehandle    - OPTIONAL
         $wrap,        # wrap width           - OPTIONAL
         $no_ruler,    # omit ruler flag      - OPTIONAL
         $no_cons,     # omit consensus flag  - OPTIONAL
       ) = @_;

    # returns nothing

    my ( @entries, $ruler, $consensus );

    $ruler     = align_ruler( $entries->[ 0 ] );
    $consensus = align_consensus( $entries ) if not $no_cons;

    unshift @{ $entries }, $ruler if not $no_ruler;
    push    @{ $entries }, $consensus if not $no_cons;

    align_print( $entries, $fh, $wrap );
}


sub align_print
{
    # Martin A. Hansen, June 2007.

    # Prints an alignment.

    my ( $entries,   # Alignment as FASTA entries
         $fh,        # output filehandle  - OPTIONAL
         $wrap,      # wrap alignment     - OPTIONAL
       ) = @_;

    # returns nothing

    my ( $max, $blocks, $block, $entry );

    $max = 0;

    map { $max = length $_->[ SEQ_NAME ] if length $_->[ SEQ_NAME ] > $max } @{ $entries };

    $blocks = align_wrap( $entries, $wrap );

    foreach $block ( @{ $blocks } )
    {
        foreach $entry ( @{ $block } )
        {
            $entry->[ SEQ_NAME ] =~ s/stats|ruler|consensus//;                                                                          

            if ( $fh ) {
                print $fh $entry->[ SEQ_NAME ], " " x ( $max + 3 - length $entry->[ SEQ_NAME ] ), $entry->[ SEQ ], "\n";                                 
            } else {
                print $entry->[ SEQ_NAME ], " " x ( $max + 3 - length $entry->[ SEQ_NAME ] ), $entry->[ SEQ ], "\n";                                 
            }
        }
    }
}


sub align_wrap
{
    # Martin A. Hansen, October 2005.

    # Given a set of fasta entries wraps these
    # according to a given width.

    my ( $entries,     # list of fasta_entries
         $wrap,        # wrap width - OPTIONAL
       ) = @_;

    # returns AoA

    my ( $ruler, $i, $c, @lines, @blocks );

    $wrap ||= 999999999;

    $i = 0;

    while ( $i < length $entries->[ 0 ]->[ SEQ ] )
    {
        undef @lines;

        for ( $c = 0; $c < @{ $entries }; $c++ )
        {
            if ( $entries->[ $c ]->[ SEQ_NAME ] eq "ruler" )
            {
                $ruler = substr $entries->[ $c ]->[ SEQ ], $i, $wrap;

                if ( $ruler =~ /^(\d+)/ ) {
                    $ruler =~ s/^($1)/' 'x(length $1)/e;
                }

                if ( $ruler =~ /(\d+)$/ ) {
                    $ruler =~ s/($1)$/' 'x(length $1)/e;
                }

                push @lines, [ "ruler", $ruler ];
            }
            else
            {
                push @lines, [ $entries->[ $c ]->[ SEQ_NAME ], substr $entries->[ $c ]->[ SEQ ], $i, $wrap ];
            }
        }

        push @blocks, [ @lines ];

        $i += $wrap;
    }

    return wantarray ? @blocks: \@blocks;
}


sub align_pins
{
    # Martin A. Hansen, June 2007.

    # Given two aligned FASTA entries, generates an entry with pins.

    my ( $entry1,   # first entry
         $entry2,   # second entry
         $type,     # residue type - OPTIONAL
       ) = @_;

    # returns tuple

    my ( $blosum, $i, $char1, $char2, $pins );

    $type ||= Maasha::Seq::seq_guess_type( $entry1->[ SEQ ] );

    $blosum = blosum_read() if $type =~ "PROTEIN";

    for ( $i = 0; $i < length $entry1->[ SEQ ]; $i++ )
    {
        $char1 = uc substr $entry1->[ SEQ ], $i, 1;
        $char2 = uc substr $entry2->[ SEQ ], $i, 1;

        if ( $blosum and $char1 eq $char2 ) {
            $pins .= $char1;
        } elsif ( $char1 eq $char2 ) {
            $pins .= "|";
        } elsif ( $blosum and defined $blosum->{ $char1 }->{ $char2 } and $blosum->{ $char1 }->{ $char2 } > 0 ) {
            $pins .= "+";
        } else {
            $pins .= " ";
        }
    }

    return wantarray ? ( "consensus", $pins ) : [ "consensus", $pins ];
}


sub align_ruler
{
    # Martin A. Hansen, February 2007;

    # Gererates a ruler for a given FASTA entry (with indels).

    my ( $entry,        # FASTA entry
         $count_gaps,   # flag for counting indels in pairwise alignments.
       ) = @_;

    # Returns tuple

    my ( $i, $char, $skip, $count, $gap, $tics );

    $char = "";
    $gap  = 0;
    $i    = 1;

    while ( $i <= length $entry->[ SEQ ] )
    {
        $char = substr( $entry->[ SEQ ], $i - 1, 1 ) if $count_gaps;
 
        $gap++ if $char eq "-";

        if ( $skip )
        {
            $skip--;
        }
        else
        {
            $count = $i - $gap;
            $count = 1 if $char eq "-";

            if ( $count % 100 == 0 )
            {
                if ( $count + length( $count ) >= length $entry->[ SEQ ] )
                {
                    $tics .= "|";
                }
                else
                {
                    $tics .= "|" . $count;
                    $skip = length $count;
                }
            }
            elsif ( $count % 50 == 0 ) {
                $tics .= ":";
            } elsif ( $count % 10 == 0 ) {
                $tics .= ".";
            } else {
                $tics .= " ";
            }
        }

        $i++;
    }

    return wantarray ? ( "ruler", $tics ) : [ "ruler", $tics ];
}


sub align_consensus
{
    # Martin A. Hansen, June 2006.

    # Given an alignment as a list of FASTA entries,
    # generates a consensus sequences based on the
    # entropies for each column similar to the way
    # a sequence logo i calculated. Returns the
    # consensus sequence as a FASTA entry.

    my ( $entries,   # list of aligned FASTA entries
         $type,      # residue type       - OPTIONAL
         $min_sim,   # minimum similarity - OPTIONAL
       ) = @_;

    # Returns tuple

    my ( $bit_max, $data, $pos, $char, $score, $entry );

    $type    ||= Maasha::Seq::seq_guess_type( $entries->[ 0 ]->[ SEQ ] );
    $min_sim ||= 50;

    if ( $type =~ /protein/ ) {
        $bit_max = 4;   
    } else {
        $bit_max = 2;
    }

    $data = Maasha::Seq::seqlogo_calc( $bit_max, $entries );

    foreach $pos ( @{ $data } )
    {
        if ( $pos->[ -1 ] )
        {
            ( $char, $score ) = @{ $pos->[ -1 ] };
            
            if ( ( $score / $bit_max ) * 100 >= $min_sim ) {
                $entry->[ SEQ ] .= $char;
            } else {
                $entry->[ SEQ ] .= "-";
            }
        }
        else
        {
            $entry->[ SEQ ] .= "-";
        }
    }

    $entry->[ SEQ_NAME ] = "Consensus: $min_sim%";

    return wantarray ? @{ $entry } : $entry;
}


sub align_sim_global
{
    # Martin A. Hansen, June 2007.

    # Calculate the global similarity of two aligned entries
    # The similarity is calculated as the number of matching
    # residues divided by the length of the shortest sequence.

    my ( $entry1,   # first  aligned entry
         $entry2,   # second aligned entry
       ) = @_;

    # returns float

    my ( $seq1, $seq2, $len1, $len2, $i, $match_tot, $min, $sim );

    $seq1 = $entry1->[ SEQ ];
    $seq2 = $entry2->[ SEQ ];

    # $seq1 =~ tr/-//d;
    # $seq2 =~ tr/-//d;

    $seq1 =~ s/^-*//;
    $seq2 =~ s/^-*//;
    $seq1 =~ s/-*$//;
    $seq2 =~ s/-*$//;
   
    $len1 = length $seq1;
    $len2 = length $seq2;

    return 0 if $len1 == 0 or $len2 == 0;

    $match_tot = 0;

    for ( $i = 0; $i < $len1; $i++ ) {
        $match_tot++ if substr( $entry1->[ SEQ ], $i, 1 ) eq substr( $entry2->[ SEQ ], $i, 1 );
    }

    $min = Maasha::Calc::min( $len1, $len2 );

    $sim = sprintf( "%.2f", ( $match_tot / $min ) * 100 );

    return $sim;
}


sub align_tile
{
    # Martin A. Hansen, February 2008.

    # Tile a list of query sequences agains a reference sequence,
    # using pairwise alignments. The result is returned as a list of
    # aligned FASTA entries.
    
    my ( $ref_entry,   # reference entry as [ SEQ_NAME, SEQ ] tuple
         $q_entries,   # list of [ SEQ_NAME, SEQ ] tuples
         $args,        # argument hash
       ) = @_;

    # Returns a list.

    my ( $entry, $seq1, $seq2, $type, $align1, $align2, $sim1, $sim2, $gaps, @entries );

    $args->{ "identity" } ||= 70;

    foreach $entry ( @{ $q_entries } )
    {
        $seq1 = $entry->[ SEQ ];

        $type = Maasha::Seq::seq_guess_type( $seq1 );

        if ( $type eq "RNA" ) {
            $seq2 = Maasha::Seq::rna_revcomp( $seq1 );
        } elsif ( $type eq "DNA" ) {
            $seq2 = Maasha::Seq::dna_revcomp( $seq1 );
        } else {
            Maasha::Common::error( qq(Bad sequence type->$type) );
        }

        $align1 = Maasha::Align::align_muscle( [ $ref_entry, [ $entry->[ SEQ_NAME ] . "_+", $seq1 ] ], "-quiet -maxiters 1" );
        $align2 = Maasha::Align::align_muscle( [ $ref_entry, [ $entry->[ SEQ_NAME ] . "_-", $seq2 ] ], "-quiet -maxiters 1" );

        if ( $args->{ "supress_indels" } )
        {
            align_supress_indels( $align1 );
            align_supress_indels( $align2 );
        }

        $sim1 = Maasha::Align::align_sim_global( $align1->[ 0 ], $align1->[ 1 ] );
        $sim2 = Maasha::Align::align_sim_global( $align2->[ 0 ], $align2->[ 1 ] );

        if ( $sim1 < $args->{ "identity" } and $sim2 < $args->{ "identity" } )
        {
            # do nothing
        }
        elsif ( $sim1 > $sim2 )
        {
            $gaps = $align1->[ 0 ]->[ SEQ ] =~ tr/-//;

            $align1->[ 1 ]->[ SEQ ] =~ s/-{$gaps}$// if $gaps;
            
            $entry->[ SEQ_NAME ] = "$align1->[ 1 ]->[ SEQ_NAME ]_$sim1";
            $entry->[ SEQ ]  = $align1->[ 1 ]->[ SEQ ];

            push @entries, $entry;
        }
        else
        {
            $gaps = $align2->[ 0 ]->[ SEQ ] =~ tr/-//;

            $align2->[ 1 ]->[ SEQ ] =~ s/-{$gaps}$// if $gaps;

            $entry->[ SEQ_NAME ] = "$align2->[ 1 ]->[ SEQ_NAME ]_$sim2";
            $entry->[ SEQ ]  = $align2->[ 1 ]->[ SEQ ];

            push @entries, $entry;
        }
    }

    @entries = sort { $b->[ SEQ ] cmp $a->[ SEQ ] } @entries;

    unshift @entries, $ref_entry;

    return wantarray ? @entries : \@entries;
}


sub align_supress_indels
{
    # Martin A. Hansen, June 2008.

    # Given a pairwise alignment, removes
    # indels in the first sequence AND corresponding
    # sequence in the second.

    my ( $align,   # pairwise alignment
       ) = @_;

    # Returns nothing

    my ( $count, $seq, $i );

    $count = $align->[ 0 ]->[ SEQ ] =~ tr/-//;

    if ( $count > 0 )
    {
        for ( $i = 0; $i < length $align->[ 0 ]->[ SEQ ]; $i++ )
        {
            if ( substr( $align->[ 0 ]->[ SEQ ], $i, 1 ) ne '-' ) {
                $seq .= substr( $align->[ 1 ]->[ SEQ ], $i, 1 );
            }
        
        }

        $align->[ 0 ]->[ SEQ ] =~ tr/-//d;
        $align->[ 1 ]->[ SEQ ] = $seq;
    }
}


sub align_invert
{
    # Martin A. Hansen, February 2008.

    # Invert an alignment in such a way that only
    # residues differing from the first sequence (the reference sequence)
    # are shown. The matching sequence can either be lowercased (soft) or replaced
    # with _.

    my ( $entries,   # list of FASTA entries.
         $soft,      
       ) = @_;

    # Returns nothing.

    my ( $i, $c, $char1, $char2 );

    map { $_->[ SEQ ] =~ tr/-/_/ } @{ $entries };

    for ( $i = 0; $i < length $entries->[ 0 ]->[ SEQ ]; $i++ )
    {
        $char1 = uc substr $entries->[ 0 ]->[ SEQ ], $i, 1;

        for ( $c = 1; $c < @{ $entries }; $c++ )
        {
            $char2 = uc substr $entries->[ $c ]->[ SEQ ], $i, 1;

            if ( $char1 eq $char2 )
            {
                if ( $soft ) {
                    substr $entries->[ $c ]->[ SEQ ], $i, 1, lc $char2;
                } else {
                    substr $entries->[ $c ]->[ SEQ ], $i, 1, "-";
                }
            }
        }
    }
}


sub blosum_read
{
    # Martin A. Hansen, January 2006.

    # this routine parses the BLOSUM62 matrix,
    # which is located in the __DATA__ section

    # returns HoH

    my ( @lines, @chars, $i, $c, @list, $HoH );

    @lines = <DATA>;
    @lines = grep { $_ !~ /^$|^#/ } @lines;

    @chars = split /\s+/, $lines[ 0 ];

    $i = 1;

    while( $lines[ $i ] )
    { 
        last if $lines[ $i ] =~ /^__END__/;

        @list = split /\s+/, $lines[ $i ];

        for ( $c = 1; $c < @list; $c++ ) {
            $HoH->{ $list[ 0 ] }->{ $chars[ $c ] } = $list[ $c ];
        }

        $i++;
    }

    return wantarray ? %{ $HoH } : $HoH;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__DATA__


#  Matrix made by matblas from blosum62.iij
#  * column uses minimum score
#  BLOSUM Clustered Scoring Matrix in 1/2 Bit Units
#  Blocks Database = /data/blocks_5.0/blocks.dat
#  Cluster Percentage: >= 62
#  Entropy =   0.6979, Expected =  -0.5209
   A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  B  Z  X  *
A  4 -1 -2 -2  0 -1 -1  0 -2 -1 -1 -1 -1 -2 -1  1  0 -3 -2  0 -2 -1  0 -4 
R -1  5  0 -2 -3  1  0 -2  0 -3 -2  2 -1 -3 -2 -1 -1 -3 -2 -3 -1  0 -1 -4 
N -2  0  6  1 -3  0  0  0  1 -3 -3  0 -2 -3 -2  1  0 -4 -2 -3  3  0 -1 -4 
D -2 -2  1  6 -3  0  2 -1 -1 -3 -4 -1 -3 -3 -1  0 -1 -4 -3 -3  4  1 -1 -4 
C  0 -3 -3 -3  9 -3 -4 -3 -3 -1 -1 -3 -1 -2 -3 -1 -1 -2 -2 -1 -3 -3 -2 -4 
Q -1  1  0  0 -3  5  2 -2  0 -3 -2  1  0 -3 -1  0 -1 -2 -1 -2  0  3 -1 -4 
E -1  0  0  2 -4  2  5 -2  0 -3 -3  1 -2 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4 
G  0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 -1 -2 -1 -4 
H -2  0  1 -1 -3  0  0 -2  8 -3 -3 -1 -2 -1 -2 -1 -2 -2  2 -3  0  0 -1 -4 
I -1 -3 -3 -3 -1 -3 -3 -4 -3  4  2 -3  1  0 -3 -2 -1 -3 -1  3 -3 -3 -1 -4 
L -1 -2 -3 -4 -1 -2 -3 -4 -3  2  4 -2  2  0 -3 -2 -1 -2 -1  1 -4 -3 -1 -4 
K -1  2  0 -1 -3  1  1 -2 -1 -3 -2  5 -1 -3 -1  0 -1 -3 -2 -2  0  1 -1 -4 
M -1 -1 -2 -3 -1  0 -2 -3 -2  1  2 -1  5  0 -2 -1 -1 -1 -1  1 -3 -1 -1 -4 
F -2 -3 -3 -3 -2 -3 -3 -3 -1  0  0 -3  0  6 -4 -2 -2  1  3 -1 -3 -3 -1 -4 
P -1 -2 -2 -1 -3 -1 -1 -2 -2 -3 -3 -1 -2 -4  7 -1 -1 -4 -3 -2 -2 -1 -2 -4 
S  1 -1  1  0 -1  0  0  0 -1 -2 -2  0 -1 -2 -1  4  1 -3 -2 -2  0  0  0 -4 
T  0 -1  0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -2 -1  1  5 -2 -2  0 -1 -1  0 -4 
W -3 -3 -4 -4 -2 -2 -3 -2 -2 -3 -2 -3 -1  1 -4 -3 -2 11  2 -3 -4 -3 -2 -4 
Y -2 -2 -2 -3 -2 -1 -2 -3  2 -1 -1 -2 -1  3 -3 -2 -2  2  7 -1 -3 -2 -1 -4 
V  0 -3 -3 -3 -1 -2 -2 -3 -3  3  1 -2  1 -1 -2 -2  0 -3 -1  4 -3 -2 -1 -4 
B -2 -1  3  4 -3  0  1 -1  0 -3 -4  0 -3 -3 -2  0 -1 -4 -3 -3  4  1 -1 -4 
Z -1  0  0  1 -3  3  4 -2  0 -3 -3  1 -1 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4 
X  0 -1 -1 -1 -2 -1 -1 -1 -1 -1 -1 -1 -1 -1 -2  0  0 -2 -1 -1 -1 -1 -1 -4 
* -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4  1 


__END__
