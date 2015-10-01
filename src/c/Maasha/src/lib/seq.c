/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "seq.h"

/* Byte array for fast convertion of binary blocks to DNA. */
/* Binary blocks holds four nucleotides encoded in 2 bits: */
/* A=00 T=11 C=01 G=10 */
char *bin2dna[256] = {
    "AAAA", "AAAC", "AAAG", "AAAT", "AACA", "AACC", "AACG", "AACT",
    "AAGA", "AAGC", "AAGG", "AAGT", "AATA", "AATC", "AATG", "AATT",
    "ACAA", "ACAC", "ACAG", "ACAT", "ACCA", "ACCC", "ACCG", "ACCT",
    "ACGA", "ACGC", "ACGG", "ACGT", "ACTA", "ACTC", "ACTG", "ACTT",
    "AGAA", "AGAC", "AGAG", "AGAT", "AGCA", "AGCC", "AGCG", "AGCT",
    "AGGA", "AGGC", "AGGG", "AGGT", "AGTA", "AGTC", "AGTG", "AGTT",
    "ATAA", "ATAC", "ATAG", "ATAT", "ATCA", "ATCC", "ATCG", "ATCT",
    "ATGA", "ATGC", "ATGG", "ATGT", "ATTA", "ATTC", "ATTG", "ATTT",
    "CAAA", "CAAC", "CAAG", "CAAT", "CACA", "CACC", "CACG", "CACT",
    "CAGA", "CAGC", "CAGG", "CAGT", "CATA", "CATC", "CATG", "CATT",
    "CCAA", "CCAC", "CCAG", "CCAT", "CCCA", "CCCC", "CCCG", "CCCT",
    "CCGA", "CCGC", "CCGG", "CCGT", "CCTA", "CCTC", "CCTG", "CCTT",
    "CGAA", "CGAC", "CGAG", "CGAT", "CGCA", "CGCC", "CGCG", "CGCT",
    "CGGA", "CGGC", "CGGG", "CGGT", "CGTA", "CGTC", "CGTG", "CGTT",
    "CTAA", "CTAC", "CTAG", "CTAT", "CTCA", "CTCC", "CTCG", "CTCT",
    "CTGA", "CTGC", "CTGG", "CTGT", "CTTA", "CTTC", "CTTG", "CTTT",
    "GAAA", "GAAC", "GAAG", "GAAT", "GACA", "GACC", "GACG", "GACT",
    "GAGA", "GAGC", "GAGG", "GAGT", "GATA", "GATC", "GATG", "GATT",
    "GCAA", "GCAC", "GCAG", "GCAT", "GCCA", "GCCC", "GCCG", "GCCT",
    "GCGA", "GCGC", "GCGG", "GCGT", "GCTA", "GCTC", "GCTG", "GCTT",
    "GGAA", "GGAC", "GGAG", "GGAT", "GGCA", "GGCC", "GGCG", "GGCT",
    "GGGA", "GGGC", "GGGG", "GGGT", "GGTA", "GGTC", "GGTG", "GGTT",
    "GTAA", "GTAC", "GTAG", "GTAT", "GTCA", "GTCC", "GTCG", "GTCT",
    "GTGA", "GTGC", "GTGG", "GTGT", "GTTA", "GTTC", "GTTG", "GTTT",
    "TAAA", "TAAC", "TAAG", "TAAT", "TACA", "TACC", "TACG", "TACT",
    "TAGA", "TAGC", "TAGG", "TAGT", "TATA", "TATC", "TATG", "TATT",
    "TCAA", "TCAC", "TCAG", "TCAT", "TCCA", "TCCC", "TCCG", "TCCT",
    "TCGA", "TCGC", "TCGG", "TCGT", "TCTA", "TCTC", "TCTG", "TCTT",
    "TGAA", "TGAC", "TGAG", "TGAT", "TGCA", "TGCC", "TGCG", "TGCT",
    "TGGA", "TGGC", "TGGG", "TGGT", "TGTA", "TGTC", "TGTG", "TGTT",
    "TTAA", "TTAC", "TTAG", "TTAT", "TTCA", "TTCC", "TTCG", "TTCT",
    "TTGA", "TTGC", "TTGG", "TTGT", "TTTA", "TTTC", "TTTG", "TTTT"
};


seq_entry *seq_new( size_t max_seq_name, size_t max_seq )
{
    /* Martin A. Hansen, August 2008 */

    /* Initialize a new sequence entry. */

    seq_entry *entry = NULL;
    entry            = mem_get( sizeof( seq_entry ) );
    entry->seq_name  = mem_get( max_seq_name );
    entry->seq       = mem_get( max_seq );
    entry->seq_len   = 0;

    return entry;
}


void seq_destroy( seq_entry *entry )
{
    /* Martin A. Hansen, August 2008 */

    /* Destroy a sequence entry. */

    mem_free( &entry->seq_name );
    mem_free( &entry->seq );
    mem_free( &entry );
}


void seq_uppercase( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Uppercase a sequence in place. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ ) {
        seq[ i ] = toupper( seq[ i ] );
    }
}


void lowercase_seq( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Lowercase a sequence in place. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ ) {
        seq[ i ] = tolower( seq[ i ] );
    }
}


void revcomp_dna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Reverse complement a DNA sequence in place. */

    complement_dna( seq );
    reverse( seq );
}


void revcomp_rna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Reverse complement a RNA sequence in place. */

    complement_rna( seq );
    reverse( seq );
}


void revcomp_nuc( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Reverse complements a nucleotide sequence in place. */

    complement_nuc( seq );
    reverse( seq );
}


void complement_nuc( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Complements a nucleotide sequence, */
    /* after guess the type. */

    if ( is_dna( seq ) ) {
        complement_dna( seq );
    } else if ( is_rna( seq ) ) {
        complement_rna( seq );
    } else {
        abort();
    }
}


void complement_dna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Complements a DNA sequence including */
    /* ambiguity coded nucleotides. */;

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'a': seq[ i ] = 't'; break;
            case 'A': seq[ i ] = 'T'; break;
            case 'c': seq[ i ] = 'g'; break;
            case 'C': seq[ i ] = 'G'; break;
            case 'g': seq[ i ] = 'c'; break;
            case 'G': seq[ i ] = 'C'; break;
            case 't': seq[ i ] = 'a'; break;
            case 'u': seq[ i ] = 'a'; break;
            case 'T': seq[ i ] = 'A'; break;
            case 'U': seq[ i ] = 'A'; break;
            case 'm': seq[ i ] = 'k'; break;
            case 'M': seq[ i ] = 'K'; break;
            case 'r': seq[ i ] = 'y'; break;
            case 'R': seq[ i ] = 'Y'; break;
            case 'w': seq[ i ] = 'w'; break;
            case 'W': seq[ i ] = 'W'; break;
            case 's': seq[ i ] = 'S'; break;
            case 'S': seq[ i ] = 'S'; break;
            case 'y': seq[ i ] = 'r'; break;
            case 'Y': seq[ i ] = 'R'; break;
            case 'k': seq[ i ] = 'm'; break;
            case 'K': seq[ i ] = 'M'; break;
            case 'b': seq[ i ] = 'v'; break;
            case 'B': seq[ i ] = 'V'; break;
            case 'd': seq[ i ] = 'h'; break;
            case 'D': seq[ i ] = 'H'; break;
            case 'h': seq[ i ] = 'd'; break;
            case 'H': seq[ i ] = 'D'; break;
            case 'v': seq[ i ] = 'b'; break;
            case 'V': seq[ i ] = 'B'; break;
            case 'n': seq[ i ] = 'n'; break;
            case 'N': seq[ i ] = 'N'; break;
            default: break;
        }
    }
}


void complement_rna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Complements an RNA sequence including */
    /* ambiguity coded nucleotides. */;

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'a': seq[ i ] = 'u'; break;
            case 'A': seq[ i ] = 'U'; break;
            case 'c': seq[ i ] = 'g'; break;
            case 'C': seq[ i ] = 'G'; break;
            case 'g': seq[ i ] = 'c'; break;
            case 'G': seq[ i ] = 'C'; break;
            case 't': seq[ i ] = 'a'; break;
            case 'u': seq[ i ] = 'a'; break;
            case 'T': seq[ i ] = 'A'; break;
            case 'U': seq[ i ] = 'A'; break;
            case 'm': seq[ i ] = 'k'; break;
            case 'M': seq[ i ] = 'K'; break;
            case 'r': seq[ i ] = 'y'; break;
            case 'R': seq[ i ] = 'Y'; break;
            case 'w': seq[ i ] = 'w'; break;
            case 'W': seq[ i ] = 'W'; break;
            case 's': seq[ i ] = 'S'; break;
            case 'S': seq[ i ] = 'S'; break;
            case 'y': seq[ i ] = 'r'; break;
            case 'Y': seq[ i ] = 'R'; break;
            case 'k': seq[ i ] = 'm'; break;
            case 'K': seq[ i ] = 'M'; break;
            case 'b': seq[ i ] = 'v'; break;
            case 'B': seq[ i ] = 'V'; break;
            case 'd': seq[ i ] = 'h'; break;
            case 'D': seq[ i ] = 'H'; break;
            case 'h': seq[ i ] = 'd'; break;
            case 'H': seq[ i ] = 'D'; break;
            case 'v': seq[ i ] = 'b'; break;
            case 'V': seq[ i ] = 'B'; break;
            case 'n': seq[ i ] = 'n'; break;
            case 'N': seq[ i ] = 'N'; break;
            default: break;
        }
    }
}


void reverse( char *string )
{
    /* Martin A. Hansen, May 2008 */

    /* Reverses a string in place. */

    char   c;
    size_t i;
    size_t j;

    i = 0;
    j = strlen( string ) - 1;

    while ( i <= j )
    {
        c = string[ i ];

        string[ i ] = string[ j ];        
        string[ j ] = c;

        i++;
        j--;
    }
}


void seq2nuc_simple( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Uppercases all DNA letters, while transforming */
    /* all non-DNA letters in sequence to Ns. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'A': break;
            case 'T': break;
            case 'C': break;
            case 'G': break;
            case 'U': break;
            case 'N': break;
            case 'a': seq[ i ] = 'A'; break;
            case 't': seq[ i ] = 'T'; break;
            case 'c': seq[ i ] = 'C'; break;
            case 'g': seq[ i ] = 'G'; break;
            case 'u': seq[ i ] = 'U'; break;
            default:  seq[ i ] = 'N';
        }
    }
}


void dna2rna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Converts a DNA sequence to RNA by changing T and t to U and u. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 't': seq[ i ] = 'u'; break;
            case 'T': seq[ i ] = 'U'; break;
            default: break;
        }
    }
}


void rna2dna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Converts a RNA sequence to RNA by changing T and u to T and t. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'u': seq[ i ] = 't'; break;
            case 'U': seq[ i ] = 'T'; break;
            default: break;
        }
    }
}


bool is_dna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Determines if a given sequence is DNA, */
    /* from inspection of the first 100 residues. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'A': case 'a': break;
            case 'G': case 'g': break;
            case 'C': case 'c': break;
            case 'T': case 't': break;
            case 'R': case 'r': break;
            case 'Y': case 'y': break;
            case 'W': case 'w': break;
            case 'S': case 's': break;
            case 'M': case 'm': break;
            case 'K': case 'k': break;
            case 'H': case 'h': break;
            case 'D': case 'd': break;
            case 'V': case 'v': break;
            case 'B': case 'b': break;
            case 'N': case 'n': break;
            case '-': break;
            case '~': break;
            case '_': break;
            case '.': break;
            default: return FALSE;
        }

        if ( i == 100 ) {
            break;
        }
    }

    return TRUE;
}


bool is_rna( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Determines if a given sequence is RNA, */
    /* from inspection of the first 100 residues. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'A': case 'a': break;
            case 'G': case 'g': break;
            case 'C': case 'c': break;
            case 'U': case 'u': break;
            case 'R': case 'r': break;
            case 'Y': case 'y': break;
            case 'W': case 'w': break;
            case 'S': case 's': break;
            case 'M': case 'm': break;
            case 'K': case 'k': break;
            case 'H': case 'h': break;
            case 'D': case 'd': break;
            case 'V': case 'v': break;
            case 'B': case 'b': break;
            case 'N': case 'n': break;
            case '-': break;
            case '~': break;
            case '_': break;
            case '.': break;
            default: return FALSE;
        }

        if ( i == 100 ) {
            break;
        }
    }

    return TRUE;
}


bool is_protein( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Determines if a given sequence is protein, */
    /* from inspection of the first 100 residues. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'K': case 'k': break;
            case 'R': case 'r': break;
            case 'H': case 'h': break;
            case 'D': case 'd': break;
            case 'E': case 'e': break;
            case 'S': case 's': break;
            case 'T': case 't': break;
            case 'N': case 'n': break;
            case 'Q': case 'q': break;
            case 'A': case 'a': break;
            case 'V': case 'v': break;
            case 'I': case 'i': break;
            case 'L': case 'l': break;
            case 'M': case 'm': break;
            case 'F': case 'f': break;
            case 'Y': case 'y': break;
            case 'W': case 'w': break;
            case 'C': case 'c': break;
            case 'G': case 'g': break;
            case 'P': case 'p': break;
            case 'Z': case 'z': break;
            case 'B': case 'b': break;
            case 'X': case 'x': break;
            case '*': break;
            case '-': break;
            case '~': break;
            case '_': break;
            case '.': break;
            default: return FALSE;
        }

        if ( i == 100 ) {
            break;
        }
    }

    return TRUE;
}


char *seq_guess_type( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Guess the type of a given sequnce, */
    /* which is returned as a pointer to a string. */

    char *type;

    type = mem_get( 8 );

    if ( is_dna( seq ) ) {
        type = "DNA";
    } else if ( is_rna( seq ) ) {
        type = "RNA";
    } else if ( is_protein( seq ) ) {
        type = "PROTEIN";
    } else {
        abort();
    }

    return type;
}


bool contain_N( char *seq )
{
    /* Martin A. Hansen, May 2008 */

    /* Check if a sequence contain N or n residues. */

    size_t i;

    for ( i = 0; seq[ i ]; i++ )
    {
        switch ( seq[ i ] )
        {
            case 'N': case 'n': return TRUE;
            default: break;
        }
    }

    return FALSE;
}


int oligo2bin( char *oligo )
{
    /* Martin A. Hansen, August 2004 */

    /* Pack a max 15 nucleotide long oligo into a four byte integer. */
    
    int i;
    int bin; 
    
    if ( strlen( oligo ) > 15 ) {
        abort();
    }

    bin = 0;

    for ( i = 0; oligo[ i ]; i++ )
    {
        bin <<= 2;
        
        switch ( oligo[ i ] )
        {
            case 'A': case 'a': bin |= 0; break;
            case 'N': case 'n': bin |= 0; break;
            case 'T': case 't': bin |= 1; break;
            case 'U': case 'u': bin |= 1; break;
            case 'C': case 'c': bin |= 2; break;
            case 'G': case 'g': bin |= 3; break;
            default: abort();
        }
    }

    return bin;
}
