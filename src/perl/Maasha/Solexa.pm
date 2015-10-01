package Maasha::Solexa;


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


use Maasha::Calc;
use Data::Dumper;

use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

use constant {
    SEQ_NAME => 0,
    SEQ      => 1,
    SCORE    => 2,
};

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub solexa_get_entry_octal
{
    # Martin A. Hansen, August 2008

    # Get the next Solexa entry form a file and returns
    # a triple of [ seq_name, seq, score ].
    # We asume a Solexa entry consists of four lines:

    # @HWI-EAS157_20FFGAAXX:2:1:888:434
    # TTGGTCGCTCGCTCCGCGACCTCAGATCAGACGTGG
    # +HWI-EAS157_20FFGAAXX:2:1:888:434
    # hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhKhe

    my ( $fh,   # filehandle to Solexa file
       ) = @_;

    # Returns a list.

    my ( $seq_header, $seq, $score_head, $score );

    $seq_header   = <$fh>;
    $seq          = <$fh>;
    $score_header = <$fh>;
    $score        = <$fh>;

    return if not defined $score;

    chomp $seq_header;
    chomp $seq;
    chomp $score_header;
    chomp $score;

    $seq_header =~ s/^@//;
    $score      =~ s/(.)/int( score_oct2dec( $1 ) ) . ";"/ge;

    return wantarray ? ( $seq_header, $seq, $score ) : [ $seq_header, $seq, $score ];
}


sub score_oct2dec
{
    # Martin A. Hansen, August 2008

    # Converts a Solexa score in octal format to decimal format.

    # http://maq.sourceforge.net/fastq.shtml

    my ( $char,   # octal score
       ) = @_;

    # Returns a float

    return 10 * log( 1 + 10 ** ( ( ord( $char ) - 64 ) / 10.0 ) ) / log( 10 );
}


sub solexa_get_entry_decimal
{
    # Martin A. Hansen, August 2008

    # Get the next Solexa entry form a file and returns
    # a triple of [ seq_name, seq, score ].
    # We asume a Solexa entry consists of four lines:

    # @USI-EAS18_131_4_1_352_619
    # ATGGATGGGTTGGAGATGCCCTCTGTAGGCACCAT
    # +USI-EAS18_131_4_1_352_619
    # 40 40 40 40 40 40 40 40 40 40 40 25 25 40 40 34 40 40 40 40 32 39 40 36 34 19 40 19 30 16 21 11 21 18 11

    my ( $fh,   # filehandle to Solexa file
       ) = @_;

    # Returns a list.

    my ( $seq_header, $seq, $score_head, $score );

    $seq_header   = <$fh>;
    $seq          = <$fh>;
    $score_header = <$fh>;
    $score        = <$fh>;

    return if not defined $score;

    chomp $seq_header;
    chomp $seq;
    chomp $score_header;
    chomp $score;

    $seq_header =~ s/^@//;
    $score      =~ s/ /;/g;

    return wantarray ? ( $seq_header, $seq, $score ) : [ $seq_header, $seq, $score ];
}


sub solexa2biopiece
{
    # Martin A. Hansen, September 2008.

    # Converts a Solexa entry to a Biopiece record.

    my ( $entry,     # Solexa entry
         $quality,   # Quality cutoff
       ) = @_;

    # Returns a hashref.

    my ( @seqs, @scores, $i, %record );

    @seqs   = split //,  $entry->[ SEQ ];
    @scores = split /;/, $entry->[ SCORE ];

    for ( $i = 0; $i < @scores; $i++ ) {
        $seqs[ $i ] = lc $seqs[ $i ] if $scores[ $i ] < $quality;
    }

    $record{ "SEQ_NAME" }   = $entry->[ SEQ_NAME ];
    $record{ "SEQ" }        = $entry->[ SEQ ];
    $record{ "SCORES" }     = $entry->[ SCORE ];
    $record{ "SEQ_LEN" }    = scalar @seqs;
    $record{ "SCORE_MEAN" } = sprintf ( "%.2f", Maasha::Calc::mean( \@scores ) );

    return wantarray ? %record : \%record;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
