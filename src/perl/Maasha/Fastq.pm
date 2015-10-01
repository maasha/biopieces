package Maasha::Fastq;

# Copyright (C) 2006-2009 Martin A. Hansen.

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


# Routines for manipulation of FASTQ files and FASTQ entries.

# http://maq.sourceforge.net/fastq.shtml


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Calc;
use vars qw( @ISA @EXPORT );

use constant {
    SEQ_NAME => 0,
    SEQ      => 1,
    SCORES   => 2,
};

@ISA = qw( Exporter );

use Inline ( C => <<'END_C', DIRECTORY => $ENV{ "BP_TMP" } );

/*
About Phred or FASTQ format:

This format is an adaption of the fasta format that contains quality scores.
However, the fastq format is not completely compatible with the fastq files
currently in existence, which is read by various applications (for example,
BioPerl). Because a larger dynamic range of quality scores is used, the
quality scores are encoded in ASCII as 64+score, instead of the standard
32+score. This method is used to avoid running into non-printable characters.


About Solexa or SCARF format:

SCARF (Solexa compact ASCII read format)—This easy-to-parse text based format,
stores all the information for a single read in one line. Allowed values are
--numeric and --symbolic. --numeric outputs the quality values as a
space-separated string of numbers. --symbolic outputs the quality values as a
compact string of ASCII characters. Subtract 64 from the ASCII code to get the
corresponding quality values. Under the current numbering scheme, quality
values can theoretically be as low as -5, which has an ASCII encoding of 59=';'.

See also:

http://maq.sourceforge.net/fastq.shtml */

#define BASE_SOLEXA 64
#define BASE_PHRED 33


int phred2dec( char c )
{
    /* Martin A. Hansen, July 2009 */

    /* Converts a Phred score in octal (a char) to a decimal score, */
    /* which is returned. */

    int score = 0;

    score = ( int ) c - BASE_PHRED;

    return score;
}


int solexa2dec( char c )
{
    /* Martin A. Hansen, July 2009 */

    /* Converts a Solexa score in octal (a char) to a decimal score, */
    /* which is returned. */

    int score = 0;

    score = ( int ) c - BASE_SOLEXA;

    return score;
}


char dec2phred( int score )
{
    /* Martin A. Hansen, July 2009 */

    /* Converts a decimal score to an octal score (a char) in the Phred range, */
    /* which is returned. */

    char c = 0;

    c = ( char ) score + BASE_PHRED;

    return c;
}


char dec2solexa( int score )
{
    /* Martin A. Hansen, September 2009 */

    /* Converts a decimal score to an octal score (a char) in the Solexa range, */
    /* which is returned. */

    char c = 0;

    c = ( char ) score + BASE_SOLEXA;

    return c;
}


char solexa2phred( char score )
{
    /* Martin A. Hansen, September 2009 */

    /* Converts an octal score in the Solexa range to an octal score */
    /* in the Pred range, which is returned. */

    int  dec = 0;
    char c   = 0;

    dec = solexa2dec( score );
    c   = dec2phred( c );

    return c;
}


char phred2solexa( char score )
{
    /* Martin A. Hansen, September 2009 */

    /* Converts an octal score in the Solexa range to an octal score */
    /* in the Pred range, which is returned. */

    int  dec = 0;
    char c   = 0;

    dec = phred2dec( score );
    c   = dec2solexa( c );

    return c;
}


void solexa_str2phred_str( char *scores )
{
    /* Martin A. Hansen, September 2009 */

    /* Converts a string of Solexa octal scores to Phred octal scores in-line. */

    int i = 0;
    
    for ( i = 0; i < strlen( scores ); i++ ) {
        scores[ i ] = solexa2phred( scores[ i ] );
    }
}


void phred_str2solexa_str( char *scores )
{
    /* Martin A. Hansen, September 2009 */

    /* Converts a string of Phred octal scores to Solexa octal scores in-line. */

    int i = 0;
    
    for ( i = 0; i < strlen( scores ); i++ ) {
        scores[ i ] = phred2solexa( scores[ i ] );
    }
}


double phred_str_mean( char *scores )
{
    /* Martin A. Hansen, November 2009 */

    /* Calculates the mean score as a float which is retuned. */

    int    len  = 0;
    int    i    = 0;
    int    sum  = 0;
    double mean = 0.0;

    len = strlen( scores );

    for ( i = 0; i < len; i++ ) {
        sum += phred2dec( scores[ i ] );
    }

    mean = ( double ) sum / ( double ) len;

    return mean;
}


double solexa_str_mean( char *scores )
{
    /* Martin A. Hansen, November 2009 */

    /* Calculates the mean score as a float which is retuned. */

    int    len  = 0;
    int    i    = 0;
    int    sum  = 0;
    double mean = 0.0;

    len = strlen( scores );

    for ( i = 0; i < len; i++ ) {
        sum += solexa2dec( scores[ i ] );
    }

    mean = ( double ) sum / ( double ) len;

    return mean;
}


void solexa_str_mean_window( char *scores, int window_size, double min )
{
    /* Martin A. Hansen, June 2010. */

    /* Scans a score string by running a sliding window across   */
    /* the string and for each position calculate the mean score */
    /* for the window. Terminates and returns mean score if this */
    /* is lower than a given minimum otherwise the smallest mean */
    /* score is returned. */

    int    found = 0;
    int    i     = 0;
    int    pos   = -1;
    double sum   = 0;
    double mean  = 0.0;

    if ( window_size > strlen( scores ) )
    {
        fprintf( stderr, "ERROR: window_size > scores string: %d > %d\n\n", window_size, strlen(scores) );
        exit( 1 );
    }

    /* ---- fill up window ---- */
    
    for ( i = 0; i < window_size; i++ ) {
        sum += solexa2dec( scores[ i ] );
    }

    mean = sum / window_size;

    if ( mean <= min ) {
        found = 1;
        pos   = 0;
    }

    /* --- scan the rest of the scores ---- */

    while ( ! found && i < strlen( scores ) )
    {
        sum += solexa2dec( scores[ i ] );
        sum -= solexa2dec( scores[ i - window_size ] );

        mean = ( mean < sum / window_size ) ? mean : sum / window_size;

        // printf( "char->%c   score->%d   sum->%f   mean->%f\n", scores[i], solexa2dec(scores[i]),sum, mean);

        i++;

        if ( mean <= min ) {
            found = 1;
            pos   = i - window_size;
        }
    }

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    Inline_Stack_Push( sv_2mortal( newSViv( mean ) ) );
    Inline_Stack_Push( sv_2mortal( newSViv( pos ) ) );

    Inline_Stack_Done;
}


void softmask_solexa_str( char *seq, char *scores, int threshold )
{
    /* Martin A. Hansen, July 2009 */

    /* Given a sequence string and a score string (in Solexa range) */
    /* lowercases all residues where the decimal score is below a given threshold. */

    int i = 0;

    for ( i = 0; i < strlen( seq ); i++ )
    {
        if ( solexa2dec( scores[ i ] ) < threshold ) {
            seq[ i ] = tolower( seq[ i ] );
        }
    }
}


void softmask_phred_str( char *seq, char *scores, int threshold )
{
    /* Martin A. Hansen, July 2009 */

    /* Given a sequence string and a score string (in Phred range) */
    /* lowercases all residues where the decimal score is below a given threshold. */

    int i = 0;

    for ( i = 0; i < strlen( seq ); i++ )
    {
        if ( phred2dec( scores[ i ] ) < threshold ) {
            seq[ i ] = tolower( seq[ i ] );
        }
    }
}


int trim_left( char *scores, int min )
{
    /* Martin A. Hansen, June 2010 */

    /* Starting from the left in a score string, */
    /* locate the position when the score is above */
    /* a given min.*/

    int pos = 0;

    while ( pos < strlen( scores ) && solexa2dec( scores[ pos ] ) <= min ) {
        pos++;
    }

    return pos;
}


int trim_right( char *scores, int min )
{
    /* Martin A. Hansen, June 2010 */

    /* Starting from the right in a score string, */
    /* locate the position when the score is above */
    /* a given min.*/

    int len = strlen( scores );
    int pos = len;

    while ( pos > 0 && solexa2dec( scores[ pos ] ) <= min ) {
        pos--;
    }

    if ( pos == 0 ) {
        pos = len;
    }

    return pos;
}

END_C


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub solexa_str2dec_str
{
    # Martin A. Hansen, September 2009

    # Converts a string of Solexa octal scores to a ; separated
    # string of decimal scores.

    my ( $scores,   # Solexa scores
       ) = @_;
    
    # Returns a string.

    $scores =~ s/(.)/ solexa2dec( $1 ) . ";"/eg;

    return $scores;
}


sub phred_str2dec_str
{
    # Martin A. Hansen, September 2009

    # Converts a string of Phred octal scores to a ; separated
    # string of decimal scores.

    my ( $scores,   # Phred scores
       ) = @_;
    
    # Returns a string.

    $scores =~ s/(.)/ phred2dec( $1 ) . ";"/eg;

    return $scores;
}


sub dec_str2solexa_str
{
    # Martin A. Hansen, May 2010.

    # Converts a ; separated string of decimal scores to a
    # string of Solexa octal scores.

    my ( $scores,   # Decimal score string
       ) = @_;

    # Returns a string.

    $scores =~ s/(-\d{1,2})/0/g;
    $scores =~ s/(\d{1,2});?/dec2solexa( $1 )/eg;

    return $scores;
}

sub dec_str2phred_str
{
    # Martin A. Hansen, November 2013.

    # Converts a ; separated string of decimal scores to a
    # string of Phred scores.

    my ( $scores,   # Decimal score string
       ) = @_;

    # Returns a string.

    $scores =~ s/(-\d{1,2})/0/g;
    $scores =~ s/(\d{1,2});?/dec2phred( $1 )/eg;

    return $scores;
}

sub get_entry
{
    # Martin A. Hansen, July 2009.

    # Gets the next FASTQ entry from a given filehandle.

    my ( $fh,   # filehandle
       ) = @_;

    # Returns a list

    my ( $seq, $seq_name, $qual, $qual_name );

    $seq_name  = <$fh>;
    $seq       = <$fh>;
    $qual_name = <$fh>;
    $qual      = <$fh>;

    return unless $seq;

    chomp $seq;
    chomp $seq_name;
    chomp $qual;
    chomp $qual_name;

    $seq_name =~ s/^@//;

    return wantarray ? ( $seq_name, $seq, $qual ) : [ $seq_name, $seq, $qual ];
}


sub put_entry
{
    # Martin A. Hansen, July 2009.

    # Output a FASTQ entry to STDOUT or a filehandle.

    my ( $entry,   # FASTQ entry
         $fh,      # filehandle - OPTIONAL
       ) = @_;

    # Returns nothing.

    $fh ||= \*STDOUT;

    print $fh "@" . $entry->[ SEQ_NAME ] . "\n";
    print $fh $entry->[ SEQ ] . "\n";
    print $fh "+\n";
    print $fh $entry->[ SCORES ] . "\n";
}


sub fastq2biopiece
{
    # Martin A. Hansen, July 2009.
    
    # Converts a FASTQ entry to a Biopiece record, where
    # the FASTQ quality scores are converted to numerics.

    my ( $entry,     # FASTQ entry,
       ) = @_;

    # Returns a hash.

    my ( $record );

    $record->{ 'SEQ' }        = $entry->[ SEQ ];
    $record->{ 'SEQ_NAME' }   = $entry->[ SEQ_NAME ];
    $record->{ 'SCORES' }     = $entry->[ SCORES ];
    $record->{ 'SEQ_LEN' }    = length $entry->[ SEQ ];

    return wantarray ? %{ $record } : $record;
}


sub biopiece2fastq
{
    # Martin A. Hansen, July 2009.
    
    # Converts a Biopiece record to a FASTQ entry.

    my ( $record,   # Biopiece record
       ) = @_;

    # Returns a list.

    my ( $list );

    if ( exists $record->{ 'SEQ' } and exists $record->{ 'SEQ_NAME' } and exists $record->{ 'SCORES' } )
    {
        $list->[ SEQ_NAME ] = $record->{ 'SEQ_NAME' };
        $list->[ SEQ ]      = $record->{ 'SEQ' };
        $list->[ SCORES ]   = $record->{ 'SCORES' };
    
        $list->[ SCORES ] =~ s/(\d+);/chr( ( $1 <= 93 ? $1 : 93 ) + 33 )/ge;

        return wantarray ? @{ $list } : $list;
    }

    return;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
