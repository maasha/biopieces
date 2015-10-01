package Maasha::TwoBit;

# Copyright (C) 2008 Martin A. Hansen.

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


# Stuff for interacting with the 2bit format as described here:
# http://genome.ucsc.edu/FAQ/FAQformat#format7


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use warnings;
use strict;
use vars qw( @ISA @EXPORT );

use Data::Dumper;

use Inline ( C => <<'END_C', DIRECTORY => $ENV{ "BP_TMP" } );

int find_block_beg( char *string, char c, int beg, int len )
{
    /* Martin A. Hansen, March 2008 */

    /* Given a string and a begin position, locates the next               */
    /* position in the string MATCHING a given char.                       */
    /* This position is returned. If the char is not found -1 is returned. */

    int i;

    for ( i = beg; i < len; i++ )
    {
        if ( string[ i ] == c ) {
            return i;
        }
    }

    return -1;
}


int find_block_len( char *string, char c, int beg, int len )
{
    /* Martin A. Hansen, March 2008 */

    /* Given a string and a begin position, locates the next length of            */
    /* a block consisting of a given char. The length of that block is returned.  */

    int i;

    i = beg;

    while ( i < len && string[ i ] == c )
    {
        i++;
    }

    return i - beg;
}


char l2n[26] = { 2, 255, 1, 255, 255, 255, 3, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 255, 255, 255, 255, 255, 255 };

void dna2bin( char *raw, int size )
{
    /* Khisanth from #perl March 2008 */

    /* Encodes a DNA string to a bit array */

    Inline_Stack_Vars;
    unsigned int i = 0;
    unsigned char packed_value = 0;
    char *packed = malloc( size / 4 );
    packed[0] = 0;

    for( i = 0; i < size / 4; i++ ) {
        packed_value = l2n[ raw[i*4] - 'A' ] << 6
            | l2n[ raw[i*4+1] - 'A' ] << 4
            | l2n[ raw[i*4+2] - 'A' ] << 2
            | l2n[ raw[i*4+3] - 'A' ];
        packed[i] = packed_value;
    }

    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSVpvn(packed, size / 4 )));
    Inline_Stack_Done;
    free(packed);
}


char *conv[256] = {
    "TTTT", "TTTC", "TTTA", "TTTG", "TTCT", "TTCC", "TTCA", "TTCG", "TTAT",
    "TTAC", "TTAA", "TTAG", "TTGT", "TTGC", "TTGA", "TTGG", "TCTT", "TCTC",
    "TCTA", "TCTG", "TCCT", "TCCC", "TCCA", "TCCG", "TCAT", "TCAC", "TCAA",
    "TCAG", "TCGT", "TCGC", "TCGA", "TCGG", "TATT", "TATC", "TATA", "TATG",
    "TACT", "TACC", "TACA", "TACG", "TAAT", "TAAC", "TAAA", "TAAG", "TAGT",
    "TAGC", "TAGA", "TAGG", "TGTT", "TGTC", "TGTA", "TGTG", "TGCT", "TGCC",
    "TGCA", "TGCG", "TGAT", "TGAC", "TGAA", "TGAG", "TGGT", "TGGC", "TGGA",
    "TGGG", "CTTT", "CTTC", "CTTA", "CTTG", "CTCT", "CTCC", "CTCA", "CTCG",
    "CTAT", "CTAC", "CTAA", "CTAG", "CTGT", "CTGC", "CTGA", "CTGG", "CCTT",
    "CCTC", "CCTA", "CCTG", "CCCT", "CCCC", "CCCA", "CCCG", "CCAT", "CCAC",
    "CCAA", "CCAG", "CCGT", "CCGC", "CCGA", "CCGG", "CATT", "CATC", "CATA",
    "CATG", "CACT", "CACC", "CACA", "CACG", "CAAT", "CAAC", "CAAA", "CAAG",
    "CAGT", "CAGC", "CAGA", "CAGG", "CGTT", "CGTC", "CGTA", "CGTG", "CGCT",
    "CGCC", "CGCA", "CGCG", "CGAT", "CGAC", "CGAA", "CGAG", "CGGT", "CGGC",
    "CGGA", "CGGG", "ATTT", "ATTC", "ATTA", "ATTG", "ATCT", "ATCC", "ATCA",
    "ATCG", "ATAT", "ATAC", "ATAA", "ATAG", "ATGT", "ATGC", "ATGA", "ATGG",
    "ACTT", "ACTC", "ACTA", "ACTG", "ACCT", "ACCC", "ACCA", "ACCG", "ACAT",
    "ACAC", "ACAA", "ACAG", "ACGT", "ACGC", "ACGA", "ACGG", "AATT", "AATC",
    "AATA", "AATG", "AACT", "AACC", "AACA", "AACG", "AAAT", "AAAC", "AAAA",
    "AAAG", "AAGT", "AAGC", "AAGA", "AAGG", "AGTT", "AGTC", "AGTA", "AGTG",
    "AGCT", "AGCC", "AGCA", "AGCG", "AGAT", "AGAC", "AGAA", "AGAG", "AGGT",
    "AGGC", "AGGA", "AGGG", "GTTT", "GTTC", "GTTA", "GTTG", "GTCT", "GTCC",
    "GTCA", "GTCG", "GTAT", "GTAC", "GTAA", "GTAG", "GTGT", "GTGC", "GTGA",
    "GTGG", "GCTT", "GCTC", "GCTA", "GCTG", "GCCT", "GCCC", "GCCA", "GCCG",
    "GCAT", "GCAC", "GCAA", "GCAG", "GCGT", "GCGC", "GCGA", "GCGG", "GATT",
    "GATC", "GATA", "GATG", "GACT", "GACC", "GACA", "GACG", "GAAT", "GAAC",
    "GAAA", "GAAG", "GAGT", "GAGC", "GAGA", "GAGG", "GGTT", "GGTC", "GGTA",
    "GGTG", "GGCT", "GGCC", "GGCA", "GGCG", "GGAT", "GGAC", "GGAA", "GGAG",
    "GGGT", "GGGC", "GGGA", "GGGG"
};


void bin2dna( char *raw, int size )
{
    /* Khisanth from #perl, March 2008 */

    /* Converts a bit array to DNA which is returned. */

    Inline_Stack_Vars;
    char *unpacked = malloc( 4 * size + 1 );

    int i = 0;
    unsigned char conv_index;
    unpacked[0] = 0;

    for( i = 0; i < size; i++ ) {
        memset( &conv_index, raw[i], 1 );
        memcpy( unpacked + i*4, conv[conv_index], 4);
    }

    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSVpvn(unpacked, 4 * size)));
    Inline_Stack_Done;
    free(unpacked);
}


void bin2dna_old( char *bin, int bin_len )
{
    /* Martin A. Hansen, March 2008 */

    /* Converts a binary string to DNA which is returned. */

    Inline_Stack_Vars;

    int i, c;

    char *dna = ( char* )( malloc( bin_len / 2 ) );

    c = 0;

    for ( i = 1; i < bin_len; i += 2 )
    {
        if ( bin[ i - 1 ] == '1' )
        {
            if ( bin[ i ] == '1' ) {
                dna[ c ] = 'G';
            } else {
                dna[ c ] = 'A';
            }
        }
        else
        {
            if ( bin[ i ] == '1' ) {
                dna[ c ] = 'C';
            } else {
                dna[ c ] = 'T';
            }
        }

        c++;
    }

    Inline_Stack_Reset;
    Inline_Stack_Push( sv_2mortal( newSVpvn( dna, ( bin_len / 2 ) ) ) );
    Inline_Stack_Done;

    free( dna );
}


void hard_mask( char *seq, int beg, int len, int sub_beg, int sub_len )
{
    /* Martin A. Hansen, March 2008 */

    /* Hard masks a sequnce in a given interval, which is trimmed, */
    /* if it does not match the sequence. */

    int i, mask_beg, mask_len;

    if ( sub_beg + sub_len >= beg && sub_beg <= beg + len )
    {
        mask_beg = beg - sub_beg;

        if ( mask_beg < 0 ) {
            mask_beg = 0;
        }

        mask_len = len;

        if ( sub_len < mask_len ) {
            mask_len = sub_len;
        }

        for ( i = mask_beg; i < mask_beg + mask_len; i++ ) {
            seq[ i ] = 'N';
        }
    }
}


void soft_mask( char *seq, int beg, int len, int sub_beg, int sub_len )
{
    /* Martin A. Hansen, March 2008 */

    /* Soft masks a sequnce in a given interval, which is trimmed, */
    /* if it does not match the sequence. */

    int i, mask_beg, mask_len;

    if ( sub_beg + sub_len >= beg && sub_beg <= beg + len )
    {
        mask_beg = beg - sub_beg;

        if ( mask_beg < 0 ) {
            mask_beg = 0;
        }

        mask_len = len;

        if ( sub_len < mask_len ) {
            mask_len = sub_len;
        }

        for ( i = mask_beg; i < mask_beg + mask_len; i++ ) {
            seq[ i ] = seq[ i ] ^ ' ';
        }
    }
}

END_C


use Maasha::Common;
use Maasha::Fasta;
use Maasha::Seq;

use constant {
    SEQ_NAME => 0,
    SEQ      => 1,
};

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub twobit_get_TOC
{
    # Martin A. Hansen, March 2008.

    # Fetches the table of contents (TOC) from a 2bit file.
    # The TOC is returned as a list of lists.

    # The 2bit format is described here:
    # http://genome.ucsc.edu/FAQ/FAQformat#format7

    my ( $fh,   # filehandle
       ) = @_;

    # Returns AoA.

    my ( $signature, $version, $seq_count, $reserved, $i, $seq_name_size, $string, $seq_name, $offset, @AoA );

    sysseek $fh, 0, 0;

    $signature = unpack_32bit( $fh );
    $version   = unpack_32bit( $fh );
    $seq_count = unpack_32bit( $fh );
    $reserved  = unpack_32bit( $fh );

    Maasha::Common::error( qq(2bit file signature didn't match - inverse bit order?) ) if $signature != 0x1A412743;

    for ( $i = 0; $i < $seq_count; $i++ )
    {
        $seq_name_size = unpack_8bit( $fh );

        sysread $fh, $string, $seq_name_size;

        $seq_name = unpack( "A$seq_name_size", $string );

        $offset = unpack_32bit( $fh );
        
        push @AoA, [ $seq_name, $offset ];
    }

    return wantarray ? @AoA : \@AoA;
}


sub twobit_get_seq
{
    # Martin A. Hansen, March 2008.

    # Given a filehandle to a 2bit file, gets the sequence
    # or subsequence from an 2bit file entry at the given
    # offset position.

    # The 2bit format is described here:
    # http://genome.ucsc.edu/FAQ/FAQformat#format7

    my ( $fh,        # filehandle
         $offset,    # byte position
         $sub_beg,   # begin of subsequence                - OPTIONAL
         $sub_len,   # length of subsequence               - OPTIONAL
         $mask,      # retrieve soft mask information flag - OPTIONAL
       ) = @_;

    # Returns a string.

    my ( $string, $seq_len, $n_count, $n, @n_begs, @n_sizes, $m_count, $m, @m_begs, @m_sizes, $reserved, $seq );

    $sub_beg ||= 0;
    $sub_len ||= 9999999999;

    sysseek $fh, $offset, 0;

    $seq_len = unpack_32bit( $fh );
    $sub_len = $seq_len if $sub_len > $seq_len;

    $n_count = unpack_32bit( $fh );

    map { push @n_begs,  unpack_32bit( $fh ) } 1 .. $n_count;
    map { push @n_sizes, unpack_32bit( $fh ) } 1 .. $n_count;

    $m_count = unpack_32bit( $fh );

    map { push @m_begs,  unpack_32bit( $fh ) } 1 .. $m_count;
    map { push @m_sizes, unpack_32bit( $fh ) } 1 .. $m_count;

    $reserved = unpack_32bit( $fh );

    $offset += 4 + 4 + $n_count * 8 + 4 + $m_count * 8 + 4;

    $seq = unpack_dna( $fh, $offset, $sub_beg, $sub_len );

    for ( $n = 0; $n < $n_count; $n++ )
    {
        hard_mask( $seq, $n_begs[ $n ], $n_sizes[ $n ], $sub_beg, $sub_len );

        last if $sub_beg + $sub_len < $n_begs[ $n ];
    }

    if ( $mask )
    {
        for ( $m = 0; $m < $m_count; $m++ )
        {
            soft_mask( $seq, $m_begs[ $m ], $m_sizes[ $m ], $sub_beg, $sub_len );

            last if $sub_beg + $sub_len < $m_begs[ $m ];
        }
    }

    return $seq;
}


sub unpack_8bit
{
    # Martin A. Hansen, March 2008.

    # Reads in 8 bits from the given filehandle
    # and returns the encoded value.

    # NB swap still needs fixing.

    my ( $fh,     # filehandle
         $swap,   # bit order swap flag  -  OPTIONAL
       ) = @_;

    # Returns integer.

    my ( $string, $val );

    sysread $fh, $string, 1;

    $val = unpack( "C", $string );

    return $val;
}


sub unpack_32bit
{
    # Martin A. Hansen, March 2008.

    # Reads in 32 bits from the given filehandle
    # and returns the encoded value.

    my ( $fh,     # filehandle
         $swap,   # bit order swap flag  -  OPTIONAL
       ) = @_;

    # Returns integer.

    my ( $string, $val );

    sysread $fh, $string, 4;

    if ( $swap ) {
        $val = unpack( "N", $string );
    } else {
        $val = unpack( "V", $string );
    }

    return $val;
}


sub unpack_dna
{
    # Martin A. Hansen, March 2008.

    # Unpacks the DNA beginning at the given filehandle.
    # The DNA packed to two bits per base, where the first
    # base is in the most significant 2-bit byte; the last
    # base is in the least significant 2 bits. The packed 
    # DNA field is padded with 0 bits as necessary to take
    # an even multiple of 32 bits in the file.

    # NB swap still needs fixing.

    my ( $fh,       # filehandle
         $offset,   # file offset
         $beg,      # sequence beg
         $len,      # sequence length
         $swap,     # bit order swap flag  -  OPTIONAL
       ) = @_;

    # Returns a string.

    my ( $bin, $bin_beg, $bin_len, $dna, $bin_diff, $len_diff );

    $bin_beg = int( $beg / 4 );
    $bin_beg-- if $beg % 4;
    $bin_beg = 0 if $bin_beg < 0;

    $bin_len = int( $len / 4 );
    $bin_len++ if $len % 4;

    sysseek $fh, $offset + $bin_beg, 0;
    sysread $fh, $bin, $bin_len;

    $dna = bin2dna( $bin, $bin_len );

    $bin_diff = $beg - $bin_beg * 4;
    $len_diff = $bin_len * 4 - $len;

    $dna =~ s/^.{$bin_diff}// if $bin_diff;
    $dna =~ s/.{$len_diff}$// if $len_diff;

    return $dna;
}


sub fasta2twobit
{
    # Martin A. Hansen, March 2008.

    # Converts a FASTA file to 2bit format.

    my ( $fh_in,    # file handle to FASTA file
         $fh_out,   # output file handle      -  OPTIONAL
         $mask,     # preserver soft masking  -  OPTIONAL
       ) = @_;

    my ( $seq_offset, $offset, $entry, $mask_index, $seq_len, $seq_name_len, $pack_len, $rec_len, $index, $bin, $seq );

    $fh_out = \*STDOUT if not $fh_out;

    # ---- Creating content index ----

    $seq_offset = 0;    # offset for reading sequence from FASTA file
    $offset     = 16;   # offset starting after header line which is 16 bytes

    while ( $entry = Maasha::Fasta::get_entry( $fh_in ) )
    {
        $seq_len      = length $entry->[ SEQ ];
        $seq_name_len = length $entry->[ SEQ_NAME ];

        $mask_index = mask_locate( $entry->[ SEQ ], $mask );

        $pack_len = ( $seq_len + ( 4 - ( $seq_len ) % 4 ) ) / 4;

        $rec_len = (
              4                                # Sequence length
            + 4                                # N blocks
            + 4 * $mask_index->{ "N_COUNT" }   # N begins
            + 4 * $mask_index->{ "N_COUNT" }   # N lengths
            + 4                                # M blocks
            + 4 * $mask_index->{ "M_COUNT" }   # M begins
            + 4 * $mask_index->{ "M_COUNT" }   # M lengths
            + 4                                # reserved
            + $pack_len                        # Packed DNA - 32 bit multiplum of 2 bit/base sequence in bytes
        );

        push @{ $index }, {
            SEQ_NAME     => $entry->[ SEQ_NAME ],
            SEQ_NAME_LEN => $seq_name_len,
            SEQ_BEG      => $seq_offset + $seq_name_len + 2,
            SEQ_LEN      => $seq_len,
            N_COUNT      => $mask_index->{ "N_COUNT" },
            N_BEGS       => $mask_index->{ "N_BEGS" },
            N_LENS       => $mask_index->{ "N_LENS" },
            M_COUNT      => $mask_index->{ "M_COUNT" },
            M_BEGS       => $mask_index->{ "M_BEGS" },
            M_LENS       => $mask_index->{ "M_LENS" },
            REC_LEN      => $rec_len,
        };

        $offset += (
            + 1              # 1 byte SEQ_NAME size
            + $seq_name_len  # SEQ_NAME depending on SEQ_NAME size
            + 4              # 32 bit offset position of sequence record
        );

        $seq_offset += $seq_name_len + 2 + $seq_len + 1;
    }

    # ---- Printing Header ----

    $bin = pack( "V4", oct "0x1A412743", "0", scalar @{ $index }, 0 ); # signature, version, sequence count and reserved

    print $fh_out $bin;

    # ---- Printing TOC ----

    undef $bin;

    foreach $entry ( @{ $index } )
    {
        $bin .= pack( "C", $entry->{ "SEQ_NAME_LEN" } );                           # 1 byte SEQ_NAME size
        $bin .= pack( qq(A$entry->{ "SEQ_NAME_LEN" }), $entry->{ "SEQ_NAME" } );   # SEQ_NAME depending on SEQ_NAME size
        $bin .= pack( "V", $offset );                                              # 32 bit offset position of sequence record

        $offset += $entry->{ "REC_LEN" };
    }

    print $fh_out $bin;

    # ---- Printing Records ----

    foreach $entry ( @{ $index } )
    {
        undef $bin;

        $bin .= pack( "V", $entry->{ "SEQ_LEN" } );
        $bin .= pack( "V", $entry->{ "N_COUNT" } );

        map { $bin .= pack( "V", $_ ) } @{ $entry->{ "N_BEGS" } };
        map { $bin .= pack( "V", $_ ) } @{ $entry->{ "N_LENS" } };

        $bin .= pack( "V", $entry->{ "M_COUNT" } );

        map { $bin .= pack( "V", $_ ) } @{ $entry->{ "M_BEGS" } };
        map { $bin .= pack( "V", $_ ) } @{ $entry->{ "M_LENS" } };

        $bin .= pack( "V", 0 );

        sysseek $fh_in, $entry->{ "SEQ_BEG" }, 0;
        sysread $fh_in, $seq, $entry->{ "SEQ_LEN" };

        $seq = uc $seq;
        $seq =~ tr/RYWSMKHDVBN/TTTTTTTTTTT/;

        $bin .= pack_dna( $seq );

        print $fh_out $bin;
    }

    close $fh_in;
    close $fh_out;
}


sub pack_dna
{
    # Martin A. Hansen, March 2008.

    # Packs a DNA sequence into a bit array, The DNA packed to two bits per base,
    # represented as so: T - 00, C - 01, A - 10, G - 11. The first base is
    # in the most significant 2-bit byte; the last base is in the least significant
    # 2 bits. For example, the sequence TCAG is represented as 00011011.
    # The packedDna field is padded with 0 bits as necessary to take an even
    # multiple of 32 bits in the file.

    my ( $dna,   # dna string to pack
       ) = @_;

    # Returns bit array

    my ( $bin );

    $dna .= "T" x ( 4 - ( length( $dna ) % 4 ) );

    $bin = dna2bin( $dna, length $dna );

    return $bin;
}


sub mask_locate
{
    # Martin A. Hansen, March 2008.

    # Locate N-blocks and M-blocks in a given sequence.
    # These blocks a continously streches of Ns and Ms in a string,
    # and the begins and lenghts of these blocks are saved in a 
    # hash along with the count of each block type.

    my ( $seq,   # Sequence
         $mask,  # preserve soft masking flag  -  OPTIONAL
       ) = @_;

    # Returns a hash.

    my ( $n_mask, $m_mask, $seq_len, $pos, $n_beg, $n_len, $m_beg, $m_len, @n_begs, @n_lens, @m_begs, @m_lens, %mask_hash );

    $seq =~ tr/atcgunRYWSMKHDVBrywsmkhdvb/MMMMMNNNNNNNNNNNNNNNNNNNNN/;

    $n_mask = 1;   # always mask Ns.
    $m_mask = $mask || 0;

    $seq_len = length $seq;

    $pos = 0;

    while ( $n_mask or $m_mask )
    {
        if ( $n_mask )
        {
            $n_beg = find_block_beg( $seq, "N", $pos, $seq_len );

            $n_mask = 0 if $n_beg < 0;
        }
        
        if ( $m_mask )
        {
            $m_beg = find_block_beg( $seq, "M", $pos, $seq_len );

            $m_mask = 0 if $m_beg < 0;
        }

        if ( $n_mask and $m_mask )
        {
            if ( $n_beg < $m_beg )
            {
                $n_len = find_block_len( $seq, "N", $n_beg, $seq_len );

                push @n_begs, $n_beg;
                push @n_lens, $n_len;

                $pos = $n_beg + $n_len;
            }
            else
            {
                $m_len = find_block_len( $seq, "M", $m_beg, $seq_len );

                push @m_begs, $m_beg;
                push @m_lens, $m_len;

                $pos = $m_beg + $m_len;
            }
        }
        elsif ( $n_mask )
        {
            $n_len = find_block_len( $seq, "N", $n_beg, $seq_len );

            push @n_begs, $n_beg;
            push @n_lens, $n_len;

            $pos = $n_beg + $n_len;
        }
        elsif ( $m_mask )
        {
            $m_len = find_block_len( $seq, "M", $m_beg, $seq_len );

            push @m_begs, $m_beg;
            push @m_lens, $m_len;

            $pos = $m_beg + $m_len;
        }
        else
        {
            last;
        }
    }

    %mask_hash = (
        N_COUNT      => scalar @n_begs,
        N_BEGS       => [ @n_begs ],
        N_LENS       => [ @n_lens ],
        M_COUNT      => scalar @m_begs,
        M_BEGS       => [ @m_begs ],
        M_LENS       => [ @m_lens ],
    );

    return wantarray ? %mask_hash : \%mask_hash;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
