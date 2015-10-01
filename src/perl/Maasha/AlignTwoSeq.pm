package Maasha::AlignTwoSeq;

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


# Routines to create a pair-wise alignment.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Calc;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    SCORE_FACTOR_LEN    => 3,
    SCORE_FACTOR_CORNER => 2,
    SCORE_FACTOR_DIAG   => 1,
    SCORE_FACTOR_NARROW => 0.5,
    VERBOSE             => 0,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub align_two_seq
{
    # Martin A. Hansen, August 2006.

    # Generates an alignment by chaining matches, which are subsequences
    # shared between two sequences. The routine functions by considering 
    # only matches within a given search space. If no matches are given
    # these will be located and matches will be included depending on a
    # calculated score. New search spaces spanning the spaces between
    # matches and the search space boundaries will be cast and recursed
    # into.
    
    # Usage: align_two_seq( { Q_SEQ => \$q_seq, S_SEQ => \$s_seq }, [] );

    my ( $space,     # search space
         $matches,   # list of matches
       ) = @_;

    # Returns a list.

    my ( @chain, $best_match, $left_space, $right_space );

    new_space( $space );

    matches_select( $matches, $space );

    if ( scalar @{ $matches } == 0 )   # no matches - find some!
    {
        $matches = matches_find( $space );

        if ( scalar @{ $matches } > 0 ) {
            push @chain, align_two_seq( $space, $matches );
        }
    }
    else   # matches are included according to score
    {
        $matches = matches_filter( $space, $matches );

        $best_match = shift @{ $matches };

        if ( $best_match )
        {
            push @chain, $best_match;

            $left_space  = new_space_left( $best_match, $space );
            $right_space = new_space_right( $best_match, $space );

            push @chain, align_two_seq( $left_space, $matches )  if defined $left_space;
            push @chain, align_two_seq( $right_space, $matches ) if defined $right_space;
        }
    }

    return wantarray ? @chain : \@chain;
}


sub new_space
{
    # Martin A. Hansen, August 2009.

    # Define a new search space if not previously
    # defined. This occurs if align_two_seq() is
    # called initially with only the sequences.

    my ( $space,   # search space
       ) = @_;

    # Returns nothing.

    if ( not defined $space->{ 'Q_MAX' } )
    {
        $space->{ 'Q_MIN' } = 0;
        $space->{ 'S_MIN' } = 0;
        $space->{ 'Q_MAX' } = length( ${ $space->{ 'Q_SEQ' } } ) - 1,
        $space->{ 'S_MAX' } = length( ${ $space->{ 'S_SEQ' } } ) - 1,
    }
}


sub new_space_left
{
    # Martin A. Hansen, August 2009.

    # Create a new search space between the beginning of
    # the current search space and the best match.

    my ( $best_match,   # best match
         $space,        # search space
       ) = @_;

    # Returns hashref.

    my ( $new_space );

    if ( $best_match->{ 'Q_BEG' } - $space->{ 'Q_MIN' } >= 2 and $best_match->{ 'S_BEG' } - $space->{ 'S_MIN' } >= 2 )
    {
        $new_space = {
            Q_SEQ => $space->{ 'Q_SEQ' },
            S_SEQ => $space->{ 'S_SEQ' },
            Q_MIN => $space->{ 'Q_MIN' },
            Q_MAX => $best_match->{ 'Q_BEG' } - 1,
            S_MIN => $space->{ 'S_MIN' },
            S_MAX => $best_match->{ 'S_BEG' } - 1,
        };
    }

    return wantarray ? %{ $new_space } : $new_space;
}


sub new_space_right
{
    # Martin A. Hansen, August 2009.

    # Create a new search space between the best match
    # and the end of the current search space.

    my ( $best_match,   # best match
         $space,        # search space
       ) = @_;

    # Returns hashref.

    my ( $new_space );

    if ( $space->{ 'Q_MAX' } - $best_match->{ 'Q_END' } >= 2 and $space->{ 'S_MAX' } - $best_match->{ 'S_END' } >= 2 )
    {
        $new_space = {
            Q_SEQ => $space->{ 'Q_SEQ' },
            S_SEQ => $space->{ 'S_SEQ' },
            Q_MIN => $best_match->{ 'Q_END' } + 1,
            Q_MAX => $space->{ 'Q_MAX' },
            S_MIN => $best_match->{ 'S_END' } + 1,
            S_MAX => $space->{ 'S_MAX' },
        };
    }

    return wantarray ? %{ $new_space } : $new_space;
}


sub matches_select
{
    # Martin A. Hansen, August 2006.

    # Given a list of matches and a search space,
    # include only those matches contained within
    # this search space.

    my ( $matches,   # list of matches
         $space,     # search space
       ) = @_;

    # Returns nothing.

    @{ $matches } = grep { $_->{ 'Q_BEG' } >= $space->{ 'Q_MIN' } and
                           $_->{ 'S_BEG' } >= $space->{ 'S_MIN' } and
                           $_->{ 'Q_END' } <= $space->{ 'Q_MAX' } and
                           $_->{ 'S_END' } <= $space->{ 'S_MAX' } } @{ $matches };
}


sub word_size_calc
{
    # Martin A. Hansen, August 2008.
  
    # Given a search space calculates the wordsize for a word so a match
    # occurs only a few times. More matches may be needed at low similarity in
    # order to avoid starting with a wrong match.

    my ( $space,   # search space
       ) = @_;

    # Returns integer.

    my ( $factor, $word_size );

    $factor = 0.05;

    if ( $space->{ 'Q_MAX' } - $space->{ 'Q_MIN' } < $space->{ 'S_MAX' } - $space->{ 'S_MIN' } ) {
        $word_size = int( $factor * ( $space->{ 'Q_MAX' } - $space->{ 'Q_MIN' } ) ) + 1;
    } else {
        $word_size = int( $factor * ( $space->{ 'S_MAX' } - $space->{ 'S_MIN' } ) ) + 1;
    }

    return $word_size;
}


sub seq_index
{
    # Martin A. Hansen, August 2009.

    # Indexes a query sequence in a specified search space
    # Overlapping words are saved as keys in an index hash,
    # and a list of word postions are saved as value.

    my ( $space,       # search space
         $word_size,   # word size
       ) = @_;

    # Returns a hashref.
    
    my ( $i, $word, %index );

    for ( $i = $space->{ 'Q_MIN' }; $i <= $space->{ 'Q_MAX' } - $word_size + 1; $i++ )
    {
        $word = uc substr ${ $space->{ 'Q_SEQ' } }, $i, $word_size;

        next if $word =~ tr/N//;   # Skip sequences with Ns.

        push @{ $index{ $word } }, $i;
    }

    return wantarray ? %index : \%index;
}


sub seq_scan
{
    # Martin A. Hansen, August 2009.

    my ( $index,       # sequence index
         $space,       # search space
         $word_size,   # word size
       ) = @_;

    # Returns a list.

    my ( $i, $word, $pos, $match, @matches, $redundant );

    $redundant = {};

    for ( $i = $space->{ 'S_MIN' }; $i <= $space->{ 'S_MAX' } - $word_size + 1; $i++ )
    {
        $word = uc substr ${ $space->{ 'S_SEQ' } }, $i, $word_size;

        if ( exists $index->{ $word } )
        {
            foreach $pos ( @{ $index->{ $word } } )
            {
                $match = {
                    'Q_BEG' => $pos,
                    'Q_END' => $pos + $word_size - 1,
                    'S_BEG' => $i,
                    'S_END' => $i + $word_size - 1,
                    'LEN'   => $word_size,
                    'SCORE' => 0,
                };

                if ( not match_redundant( $match, $redundant ) )
                {
                    match_expand( $match, $space );

                    push @matches, $match;

                    match_redundant_add( $match, $redundant );
                }
            }
        }
    }

    return wantarray ? @matches : \@matches;
}


sub matches_find
{
    # Martin A. Hansen, November 2006

    # Given two sequences, find all maximum expanded matches between these.

    my ( $space,   # search space
       ) = @_;

    # returns list of matches

    my ( $word_size, $index, $matches );

    $word_size = word_size_calc( $space );

    $matches = [];

    while ( scalar @{ $matches } == 0 and $word_size > 0 )
    {
        $index   = seq_index( $space, $word_size );
        $matches = seq_scan( $index, $space, $word_size );

        $word_size--;
    }

    return wantarray ? @{ $matches } : $matches;
}


sub match_expand
{
    # Martin A. Hansen, August 2009.

    # Given a match and a search space hash,
    # expand the match maximally both forward and
    # backward direction.

    my ( $match,   # match to expand
         $space,   # search space
       ) = @_;

    # Returns nothing.

    match_expand_forward( $match, $space );
    match_expand_backward( $match, $space );
}


sub match_expand_forward
{
    # Martin A. Hansen, August 2009.

    # Given a match and a search space hash,
    # expand the match maximally in the forward
    # direction.

    my ( $match,   # match to expand
         $space,   # search space
       ) = @_;

    # Returns nothing.

    while ( $match->{ 'Q_END' } <= $space->{ 'Q_MAX' } and
            $match->{ 'S_END' } <= $space->{ 'S_MAX' } and 
            uc substr( ${ $space->{ 'Q_SEQ' } }, $match->{ 'Q_END' }, 1 ) eq uc substr( ${ $space->{ 'S_SEQ' } }, $match->{ 'S_END' }, 1 ) )
    {
        $match->{ 'Q_END' }++;
        $match->{ 'S_END' }++;
        $match->{ 'LEN' }++;
    }

    $match->{ 'Q_END' }--;
    $match->{ 'S_END' }--;
    $match->{ 'LEN' }--;
}


sub match_expand_backward
{
    # Martin A. Hansen, August 2009.

    # Given a match and a search space hash,
    # expand the match maximally in the backward
    # direction.

    my ( $match,   # match to expand
         $space,   # search space
       ) = @_;

    # Returns nothing.

    while ( $match->{ 'Q_BEG' } >= $space->{ 'Q_MIN' } and
            $match->{ 'S_BEG' } >= $space->{ 'S_MIN' } and 
            uc substr( ${ $space->{ 'Q_SEQ' } }, $match->{ 'Q_BEG' }, 1 ) eq uc substr( ${ $space->{ 'S_SEQ' } }, $match->{ 'S_BEG' }, 1 ) )
    {
        $match->{ 'Q_BEG'}--;
        $match->{ 'S_BEG'}--;
        $match->{ 'LEN' }++;
    }

    $match->{ 'Q_BEG'}++;
    $match->{ 'S_BEG'}++;
    $match->{ 'LEN' }--;
}


sub match_redundant
{
    # Martin A. Hansen, August 2009
    
    my ( $new_match,   # match
         $redundant,   # hashref
       ) = @_;

    # Returns boolean.

    my ( $match );

    foreach $match ( @{ $redundant->{ $new_match->{ 'Q_BEG' } } } )
    {
        if ( $new_match->{ 'S_BEG' } >= $match->{ 'S_BEG' } and $new_match->{ 'S_END' } <= $match->{ 'S_END' } ) {
            return 1;
        }
    }

    return 0;
}


sub match_redundant_add
{
    # Martin A. Hansen, August 2009

    my ( $match,       # match
         $redundant,   # hash ref
       ) = @_;

    # Returns nothing.

    map { push @{ $redundant->{ $_ } }, $match } ( $match->{ 'Q_BEG' } .. $match->{ 'Q_END' } );
}


sub matches_filter
{
    # Martin A. Hansen, August 2009.

    my ( $space,     # search space
         $matches,   # list of matches
       ) = @_;

    # Returns a list.

    my ( $best_match, $match, @new_matches );

    $best_match = shift @{ $matches };

    match_score( $best_match, $space );

    foreach $match ( @{ $matches } )
    {
        match_score( $match, $space );

        if ( $match->{ 'SCORE' } > 0 )
        {
            if ( $match->{ 'SCORE' } > $best_match->{ 'SCORE' } ) {
                $best_match = $match;
            } else {
                push @new_matches, $match;
            }
        }
    }

    unshift @new_matches, $best_match if $best_match->{ 'SCORE' } > 0;

    return wantarray ? @new_matches : \@new_matches;
}


sub match_score
{
    # Martin A. Hansen, August 2009
    
    # Given a match and a search space scores the match according to three criteria:
    
    # 1) length of match - the longer the better.
    # 2) distance to closest corner - the shorter the better.
    # 3) distance to closest narrow end of the search space - the shorter the better.
    
    # Each of these scores are divided by search space dimensions, and the total score
    # is calculated: total = score_len - score_corner - score_narrow.
    
    # The higher the score, the better the match.

    my ( $match,   # match
         $space,   # search space
       ) = @_;

    # Returns nothing.

    my ( $score_len, $score_corner, $score_diag, $score_narrow, $score_total );

    $score_len    = match_score_len( $match );
    $score_corner = match_score_corner( $match, $space );
    $score_diag   = match_score_diag( $match, $space );
    $score_narrow = match_score_narrow( $match, $space );

    $score_total  = $score_len - $score_corner - $score_diag - $score_narrow;

    printf STDERR "LEN: %d   CORNER: %d   DIAG: %d   NARROW: %d   TOTAL: %d\n", $score_len, $score_corner, $score_diag, $score_narrow, $score_total if VERBOSE;

    $match->{ 'SCORE' } = $score_total;
}


sub match_score_len
{
    # Martin A. Hansen, August 2009

    # Score according to match length.

    my ( $match,   # match
       ) = @_;

    # Returns integer.

    return $match->{ 'LEN' } * SCORE_FACTOR_LEN;
}


sub match_score_corner
{
    # Martin A. Hansen, August 2009

    # Score according to distance from corner.

    my ( $match,   # match
         $space,   # search space
       ) = @_;

    # Returns integer.

    my ( $left_dist, $right_dist, $score_corner );

    $left_dist  = Maasha::Calc::dist_point2point( $space->{ 'Q_MIN' }, $space->{ 'S_MIN' }, $match->{ 'Q_BEG' } , $match->{ 'S_BEG' } );
    $right_dist = Maasha::Calc::dist_point2point( $space->{ 'Q_MAX' }, $space->{ 'S_MAX' }, $match->{ 'Q_END' } , $match->{ 'S_END' } );

    $score_corner = Maasha::Calc::min( $left_dist, $right_dist );

    return $score_corner * SCORE_FACTOR_CORNER;
}


sub match_score_diag
{
    # Martin A. Hansen, August 2009

    # Score according to distance from diagonal.

    my ( $match,   # match
         $space,   # search space
       ) = @_;

    # Returns integer.

    my ( $q_dim, $s_dim, $beg_diag_dist, $end_diag_dist, $min_diag_dist, $score_diag );

    $q_dim = $space->{ 'Q_MAX' } - $space->{ 'Q_MIN' } + 1;
    $s_dim = $space->{ 'S_MAX' } - $space->{ 'S_MIN' } + 1;

    if ( $q_dim >= $s_dim ) # s_dim is the narrow end
    {
        $beg_diag_dist = Maasha::Calc::dist_point2line( $match->{ 'Q_BEG' },
                                                        $match->{ 'S_BEG' },
                                                        $space->{ 'Q_MIN' },
                                                        $space->{ 'S_MIN' },
                                                        $space->{ 'Q_MIN' } + $s_dim,
                                                        $space->{ 'S_MIN' } + $s_dim );

        $end_diag_dist = Maasha::Calc::dist_point2line( $match->{ 'Q_BEG' },
                                                        $match->{ 'S_BEG' },
                                                        $space->{ 'Q_MAX' } - $s_dim,
                                                        $space->{ 'S_MAX' } - $s_dim,
                                                        $space->{ 'Q_MAX' },
                                                        $space->{ 'S_MAX' } );
    }
    else
    {
        $beg_diag_dist = Maasha::Calc::dist_point2line( $match->{ 'Q_BEG' },
                                                        $match->{ 'S_BEG' },
                                                        $space->{ 'Q_MIN' },
                                                        $space->{ 'S_MIN' },
                                                        $space->{ 'Q_MIN' } + $q_dim,
                                                        $space->{ 'S_MIN' } + $q_dim );

        $end_diag_dist = Maasha::Calc::dist_point2line( $match->{ 'Q_BEG' },
                                                        $match->{ 'S_BEG' },
                                                        $space->{ 'Q_MAX' } - $q_dim,
                                                        $space->{ 'S_MAX' } - $q_dim,
                                                        $space->{ 'Q_MAX' },
                                                        $space->{ 'S_MAX' } );
    }

    $min_diag_dist = Maasha::Calc::min( $beg_diag_dist, $end_diag_dist );

    $score_diag = $min_diag_dist;

    return $score_diag * SCORE_FACTOR_DIAG;
}


sub match_score_narrow
{
    # Martin A. Hansen, August 2009

    # Score according to distance to the narrow end of the search space.

    my ( $match,   # match
         $space,   # search space
       ) = @_;

    # Returns integer.

    my ( $max_narrow_dist, $q_dim, $s_dim, $beg_narrow_dist, $end_narrow_dist, $score_narrow );

    $max_narrow_dist = 0;

    $q_dim = $space->{ 'Q_MAX' } - $space->{ 'Q_MIN' } + 1;
    $s_dim = $space->{ 'S_MAX' } - $space->{ 'S_MIN' } + 1;

    if ( $q_dim > $s_dim ) # s_dim is the narrow end
    {
        $beg_narrow_dist = $match->{ 'Q_BEG' } - $space->{ 'Q_MIN' };
        $end_narrow_dist = $space->{ 'Q_MAX' } - $match->{ 'Q_BEG' };

        $max_narrow_dist = Maasha::Calc::max( $beg_narrow_dist, $end_narrow_dist );
    }
    elsif ( $q_dim < $s_dim ) # q_dim is the narrow end
    {
        $beg_narrow_dist = $match->{ 'S_BEG' } - $space->{ 'S_MIN' };
        $end_narrow_dist = $space->{ 'S_MAX' } - $match->{ 'S_BEG' };

        $max_narrow_dist = Maasha::Calc::max( $beg_narrow_dist, $end_narrow_dist );
    }

    $score_narrow = $max_narrow_dist;

    return $score_narrow * SCORE_FACTOR_NARROW;
}


sub shift_case
{
    # Martin A. Hansen, August 2009.

    # Given a list of matches and sequence references
    # uppercase only matching sequnce while lowercasing the rest.

    my ( $matches,   # list of matches
         $q_seq,     # query sequence ref
         $s_seq,     # subject sequence ref
       ) = @_;

    # Returns nothing.

    my ( $match );

    ${ $q_seq } = lc ${ $q_seq };
    ${ $s_seq } = lc ${ $s_seq };

    foreach $match ( @{ $matches } )
    {
        substr ${ $q_seq }, $match->{ 'Q_BEG' }, $match->{ 'LEN' }, uc substr ${ $q_seq }, $match->{ 'Q_BEG' }, $match->{ 'LEN' };
        substr ${ $s_seq }, $match->{ 'S_BEG' }, $match->{ 'LEN' }, uc substr ${ $s_seq }, $match->{ 'S_BEG' }, $match->{ 'LEN' };
    }
}



sub insert_indels
{
    # Martin A. Hansen, August 2009.

    # Given a list of matches and sequence references
    # insert indels to form aligned sequences.

    my ( $matches,   # list of matches
         $q_seq,     # query sequence ref
         $s_seq,     # subject sequence ref
       ) = @_;

    my ( $i, $q_dist, $s_dist, $q_indels, $s_indels, $diff );

    $q_indels = 0;
    $s_indels = 0;

    if ( @{ $matches } > 0 )
    {
        @{ $matches } = sort { $a->{ 'Q_BEG' } <=> $b->{ 'Q_BEG' } } @{ $matches };  # FIXME is this necessary?

        # >>>>>>>>>>>>>> FIRST MATCH <<<<<<<<<<<<<<

        $diff = $matches->[ 0 ]->{ 'Q_BEG' } - $matches->[ 0 ]->{ 'S_BEG' };

        if ( $diff > 0 )
        {
            substr ${ $s_seq }, 0, 0, '-' x $diff;

            $s_indels += $diff;
        }
        elsif ( $diff < 0 )
        {
            substr ${ $q_seq }, 0, 0, '-' x abs $diff;

            $q_indels += abs $diff;
        }

        # >>>>>>>>>>>>>> MIDDLE MATCHES <<<<<<<<<<<<<<

        for ( $i = 0; $i < scalar @{ $matches } - 1; $i++ )
        {
            $q_dist = $matches->[ $i + 1 ]->{ 'Q_BEG' } - $matches->[ $i ]->{ 'Q_END' };
            $s_dist = $matches->[ $i + 1 ]->{ 'S_BEG' } - $matches->[ $i ]->{ 'S_END' };

            $diff   = $q_dist - $s_dist;

            if ( $diff > 0 )
            {
                substr ${ $s_seq }, $s_indels + $matches->[ $i ]->{ 'S_END' } + 1, 0, '-' x $diff;

                $s_indels += $diff;
            }
            elsif ( $diff < 0 )
            {
                substr ${ $q_seq }, $q_indels + $matches->[ $i ]->{ 'Q_END' } + 1, 0, '-' x abs $diff;

                $q_indels += abs $diff;
            }
        }
    }

    # >>>>>>>>>>>>>> LAST MATCH <<<<<<<<<<<<<<

    $diff = length( ${ $q_seq } ) - length( ${ $s_seq } );

    if ( $diff > 0 )
    {
        ${ $s_seq } .= '-' x $diff;

        $s_indels += $diff;
    }
    else
    {
        ${ $q_seq } .= '-' x abs $diff;

        $q_indels += abs $diff;
    }
}

1;

__END__


sub align_sim_local
{
    # Martin A. Hansen, May 2007.

    # Calculate the local similarity of an alignment based on
    # an alignment chain. The similarity is calculated as
    # the number of matching residues divided by the overall
    # length of the alignment chain. This means that a short
    # but "good" alignment will yield a high similarity, while
    # a long "poor" alignment will yeild a low similarity.

    my ( $chain,   # list of matches in alignment
       ) = @_;

    # returns a float

    my ( $match, $match_tot, $q_beg, $q_end, $s_beg, $s_end, $q_diff, $s_diff, $max, $sim );

    return 0 if not @{ $chain };

    $match_tot = 0;
    $q_end     = 0;
    $s_end     = 0;
    $q_beg     = 999999999;
    $s_beg     = 999999999;

    foreach $match ( @{ $chain } )
    {
        $match_tot += $match->[ LEN ];
    
        $q_beg = $match->[ Q_BEG ] if $match->[ Q_BEG ] < $q_beg;
        $s_beg = $match->[ S_BEG ] if $match->[ S_BEG ] < $s_beg;
    
        $q_end = $match->[ Q_END ] if $match->[ Q_END ] > $q_end;
        $s_end = $match->[ S_END ] if $match->[ S_END ] > $s_end;
    }

    $q_diff = $q_end - $q_beg + 1;
    $s_diff = $s_end - $s_beg + 1;

    $max = Maasha::Calc::max( $q_diff, $s_diff );

    $sim = sprintf( "%.2f", ( $match_tot / $max ) * 100 );

    return $sim;
}


sub align_sim_global
{
    # Martin A. Hansen, June 2007.

    # Calculate the global similarity of an alignment based on
    # an alignment chain. The similarity is calculated as
    # the number of matching residues divided by the
    # length of the shortest sequence.

    my ( $chain,   # list of matches in alignment
         $q_seq,   # ref to query sequence
         $s_seq,   # ref to subject sequence
       ) = @_;

    # returns a float

    my ( $match_tot, $min, $sim );

    return 0 if not @{ $chain };

    $match_tot = 0;

    map { $match_tot += $_->[ LEN ] } @{ $chain }; 

    $min = Maasha::Calc::min( length( ${ $q_seq } ), length( ${ $s_seq } ) );

    $sim = sprintf( "%.2f", ( $match_tot / $min ) * 100 );

    return $sim;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
