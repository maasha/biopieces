/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "filesys.h"
#include "seq.h"
#include "fasta.h"

#define add_A( c )            /* add 00 to the rightmost two bits of bin (i.e. do nothing). */
#define add_T( c ) ( c |= 3 ) /* add 11 on the rightmost two bits of c. */
#define add_C( c ) ( c |= 1 ) /* add 01 on the rightmost two bits of c. */
#define add_G( c ) ( c |= 2 ) /* add 10 on the rightmost two bits of c. */
 
static uint mask_create( int oligo_size );
static void oligo_count( char *path, uint **array_ppt, uint nmer, uint mask );
static void oligo_count_output( char *path, uint *array, uint nmer, uint mask, bool log10_flag );
static void fixedstep_put_entry( char *chr, int beg, int step_size, uint *block_array, int block_size, bool log10_flag );


static void usage()
{
    fprintf( stderr, 
        "\n"
        "repeat-O-matic determines the repetiveness of a genome by determining\n"
        "the number of identical n-mers for each position in the genome.\n"
        "\n"
        "The output is a fixedStep file ala the phastCons files from the UCSC\n"
        "Genome browser.\n"
        "\n"
        "Usage: repeat-O-matic [options] <FASTA file>\n"
        "\n"
        "Options:\n"
        "   [-n <int> | --nmer <int>]   # nmer size between 1 and 15 (Default 15).\n"
        "   [-1       | --log10]        # output log10 (Default no).\n"
        "\n"
        "Examples:\n"
        "   repeat-O-matic -n 14 -l hg18.fna > hg18.fixedStep\n"
        "\n"
        "Copyright (C) 2008, Martin A. Hansen\n"
        "\n"
        );

    exit( EXIT_FAILURE );
}


int main( int argc, char *argv[] )
{
    int   opt        = 0;
    uint  nmer       = 15;
    bool  log10_flag = FALSE;
    char *path       = NULL;
    uint  mask       = 0;
    uint *array      = NULL;

    static struct option longopts[] = {
        { "nmer",  required_argument, NULL, 'n' },
        { "log10", no_argument,       NULL, 'l' },
        { NULL,    0,                 NULL,  0 }
    };

    while ( ( opt = getopt_long( argc, argv, "n:l", longopts, NULL ) ) != -1 )
    {
        switch ( opt ) {
            case 'n': nmer  = strtol( optarg, NULL, 0 ); break;
            case 'l': log10_flag = TRUE;                 break;
            default:                                     break;
        }
    }

    argc -= optind;
    argv += optind;

    if ( nmer < 1 || nmer > 15 )
    {
        fprintf( stderr, "ERROR: nmer must be between 1 and 15 inclusive - not %d\n", nmer );
        abort();
    }

    if ( argc < 1 ) {
        usage();
    }

    path = argv[ argc - 1 ];

    mask = mask_create( nmer );

    oligo_count( path, &array, nmer, mask );

    oligo_count_output( path, array, nmer, mask, log10_flag );

    return EXIT_SUCCESS;
}


uint mask_create( int oligo_size )
{
    /* Martin A. Hansen, June 2008 */

    /* Create a bit mask for binary encoded oligos less than 32 bits. */

    uint i    = 0;
    uint mask = 0;

    for ( i = 0; i < oligo_size; i++ )
    {
        mask <<= 2;

        mask |= 3; /* add 11 to mask */
    }

    return mask;
}


void oligo_count( char *path, uint **array_ppt, uint nmer, uint mask )
{
    /* Martin A. Hansen, June 2008 */

    /* Count the occurence of all oligos of a fixed size in a FASTA file. */

    uint       *array      = *array_ppt;
    uint        array_size = 0;
    uint        i          = 0;
    uint        j          = 0;
    uint        bin        = 0;
    seq_entry  *entry      = NULL;
    FILE       *fp         = NULL;

    array_size = ( 1 << ( nmer * 2 ) );
    array = mem_get_zero( sizeof( uint ) * array_size );

    fp = read_open( path );

    entry = seq_new( MAX_SEQ_NAME, MAX_SEQ );

    while ( ( fasta_get_entry( fp, &entry ) ) != 0 )
    {
        fprintf( stderr, "Counting oligos in: %s ... ", entry->seq_name );

        /* ---- Sense strand ---- */    

        bin = 0;
        j   = 0;

        for ( i = 0; entry->seq[ i ]; i++ )
        {
            bin <<= 2;

            switch( entry->seq[ i ] )
            {
                case 'A': case 'a': add_A( bin ); j++; break;
                case 'T': case 't': add_T( bin ); j++; break;
                case 'C': case 'c': add_C( bin ); j++; break;
                case 'G': case 'g': add_G( bin ); j++; break;
                default: bin = 0; j = 0; break;
            }

            if ( j >= nmer )
            {
                array[ ( bin & mask ) ]++;
/*                
                printf( "\n" );
                printf( "mask          : %s\n", bits2string( mask ) );
                printf( "bin           : %s\n", bits2string( bin ) );
                printf( "bin     & mask: %s\n", bits2string( bin & mask ) );
*/
            }
        }

        /* ---- Anti-sense strand ---- */    

        revcomp_dna( entry->seq );

        bin = 0;
        j   = 0;

        for ( i = 0; entry->seq[ i ]; i++ )
        {
            bin <<= 2;

            switch( entry->seq[ i ] )
            {
                case 'A': case 'a': add_A( bin ); j++; break;
                case 'T': case 't': add_T( bin ); j++; break;
                case 'C': case 'c': add_C( bin ); j++; break;
                case 'G': case 'g': add_G( bin ); j++; break;
                default: bin = 0; j = 0; break;
            }

            if ( j >= nmer )
            {
                array[ ( bin & mask ) ]++;
/*                
                printf( "\n" );
                printf( "mask          : %s\n", bits2string( mask ) );
                printf( "bin           : %s\n", bits2string( bin ) );
                printf( "bin     & mask: %s\n", bits2string( bin & mask ) );
*/
            }
        }

        fprintf( stderr, "done.\n" );
    }

    close_stream( fp );

    free( entry->seq_name );
    free( entry->seq );
    entry = NULL;

    *array_ppt = array;
}


void oligo_count_output( char *path, uint *array, uint nmer, uint mask, bool log10_flag )
{
    /* Martin A. Hansen, June 2008 */

    /* Output oligo count for each sequence position. */

    uint       i;
    uint       j;
    uint       bin;
    int        count;
    uint      *block;
    uint       block_pos;
    uint       block_beg;
    uint       block_size;
    uint       chr_pos;
    seq_entry *entry;
    FILE      *fp;

    entry = seq_new( MAX_SEQ_NAME, MAX_SEQ );

    fp = read_open( path );

    while ( ( fasta_get_entry( fp, &entry ) ) != 0 )
    {
        fprintf( stderr, "Writing results for: %s ... ", entry->seq_name );

        bin        = 0;
        j          = 0;
        block_pos  = 0;
        block_size = sizeof( uint ) * ( entry->seq_len + nmer );
        block      = mem_get_zero( block_size );

        for ( i = 0; entry->seq[ i ]; i++ )
        {
            bin <<= 2;

            switch( entry->seq[ i ] )
            {
                case 'A': case 'a': add_A( bin ); j++; break;
                case 'T': case 't': add_T( bin ); j++; break;
                case 'C': case 'c': add_C( bin ); j++; break;
                case 'G': case 'g': add_G( bin ); j++; break;
                default: bin = 0; j = 0; break;
            }

            if ( j >= nmer )
            {
                count = array[ ( bin & mask ) ];

                if ( count > 1 )
                {
                    chr_pos = i - nmer + 1;

                    if ( block_pos == 0 )
                    {
                        block_beg = chr_pos;

                        block[ block_pos ] = count;

                        block_pos++;
                    }
                    else
                    {
                        if ( chr_pos > block_beg + block_pos )
                        {
                            fixedstep_put_entry( entry->seq_name, block_beg, 1, block, block_pos, log10_flag );

                            block_pos = 0;

                            memset( block, '\0', block_pos );
                        }
                        else
                        {
                            block[ block_pos ] = count;

                            block_pos++;
                        }
                    }
                }
            }
        }

        if ( block_pos > 0 )
        {
            fixedstep_put_entry( entry->seq_name, block_beg, 1, block, block_pos, log10_flag );

            free( block );
            block = NULL;
        }

        fprintf( stderr, "done.\n" );
    }

    free( entry->seq_name );
    free( entry->seq );
    entry = NULL;

    close_stream( fp );
}


void fixedstep_put_entry( char *chr, int beg, int step_size, uint *block_array, int block_size, bool log10_flag )
{
    /* Martin A. Hansen, June 2008 */

    /* Outputs a block of fixedStep values. */

    int i;

    if ( log10_flag )
    {
        if ( block_size > 0 )
        {
            beg += 1; /* fixedStep format is 1 based. */

            printf( "fixedStep chrom=%s start=%d step=%d\n", chr, beg, step_size );

            for ( i = 0; i < block_size; i++ ) {
                printf( "%lf\n", log10( block_array[ i ] ) );
            }
        }
    }
    else
    {
        if ( block_size > 0 )
        {
            beg += 1; /* fixedStep format is 1 based. */

            printf( "fixedStep chrom=%s start=%d step=%d\n", chr, beg, step_size );

            for ( i = 0; i < block_size; i++ ) {
                printf( "%i\n", block_array[ i ] );
            }
        }
    }
}


