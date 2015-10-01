/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "filesys.h"
#include "seq.h"
#include "fasta.h"
#include "list.h"

#define BLOCK_SIZE_NT     4                                /* one block holds 4 nucleotides. */
#define BITS_IN_NT        2                                /* two bits holds 1 nucleotide. */
#define BITS_IN_BYTE      8                                /* number of bits in one byte. */
#define BLOCK_SPACE_MAX   64                               /* maximum space between two blocks. */
#define BLOCK_MASK        ( ( BLOCK_SPACE_MAX << 1 ) - 1 ) /* mask for printing block space. */
#define COUNT_ARRAY_NMEMB ( 1 << 30 )                      /* number of objects in the unsigned int count array. */
#define CUTOFF            1                                /* minimum number of motifs in output. */
 
/* Structure that will hold one tetra nucleotide block. */
struct _bitblock
{
    uchar bin;   /* Tetra nucleotide binary encoded. */
    bool hasN;   /* Flag indicating any N's in the block. */
};

typedef struct _bitblock bitblock;

/* Function declarations. */
void      run_scan( int argc, char *argv[] );
void      print_usage();
void      scan_file( char *file, seq_entry *entry, uint *count_array );
void      rescan_file( char *file, seq_entry *entry, uint *count_array, size_t cutoff );
uint     *count_array_new( size_t nmemb );
void      scan_seq( char *seq, size_t seq_len, uint *count_array );
void      rescan_seq( char *seq, size_t seq_len, uint *count_array, size_t cutoff );
void      scan_list( list_sl *list, uint *count_array );
void      rescan_list( list_sl *list, uint *count_array, size_t pos, size_t cutoff, uint *output_array );
bitblock *bitblock_new();
uint      blocks2motif( uchar bin1, uchar bin2, ushort dist );
void      count_array_print( uint *count_array, size_t nmemb, size_t cutoff );
void      bitblock_list_print( list_sl *list );
void      bitblock_print( bitblock *out );

/* Unit test declarations. */
static void run_tests();
static void test_count_array_new();
static void test_bitblock_new();
static void test_bitblock_print();
static void test_bitblock_list_print();
static void test_scan_seq();
static void test_blocks2motif();


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAIN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


int main( int argc, char *argv[] )
{
    run_tests();

    if ( argc == 1 ) {
        print_usage();
    }

    run_scan( argc, argv );

    return EXIT_SUCCESS;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void print_usage()
{
    /* Martin A. Hansen, September 2008 */

    /* Print usage and exit if no files in argument. */

    fprintf( stderr, "Usage: bipartite_scam <FASTA file(s)> > result.csv\n" );

    exit( EXIT_SUCCESS );
}


void run_scan( int argc, char *argv[] )
{
    /* Martin A. Hansen, September 2008 */

    /* For each file in argv scan the file for */
    /* bipartite motifs and output the motifs */
    /* and their count. */

    char      *file        = NULL;
    int        i           = 0;
    seq_entry *entry       = NULL;
    uint      *count_array = NULL;
//    size_t    new_nmemb    = 0;

    count_array = count_array_new( COUNT_ARRAY_NMEMB );

    entry = seq_new( MAX_SEQ_NAME, MAX_SEQ );

    for ( i = 1; i < argc; i++ )
    {
        file = argv[ i ];

        fprintf( stderr, "Scanning file: %s\n", file );
        scan_file( file, entry, count_array );
        fprintf( stderr, "done.\n" );
    }

//    fprintf( stderr, "Printing motifs: ... " );
//    count_array_print( count_array, COUNT_ARRAY_NMEMB, CUTOFF );
//    fprintf( stderr, "done.\n" );

    file = argv[ 1 ];

    fprintf( stderr, "Rescanning file: %s\n", file );
    rescan_file( file, entry, count_array, CUTOFF );
    fprintf( stderr, "done.\n" );

    seq_destroy( entry );

    mem_free( &count_array );
}


uint *count_array_new( size_t nmemb )
{
    /* Martin A. Hansen, September 2008 */

    /* Initialize a new zeroed uint array of nmemb objects. */

    uint *array = NULL;

    assert( nmemb > 0 );

    array = mem_get_zero( nmemb * sizeof( uint ) );

    return array;
}


void scan_file( char *file, seq_entry *entry, uint *count_array )
{
    /* Martin A. Hansen, September 2008 */
    
    /* Scan all FASTA entries of a file. */

    FILE *fp = read_open( file );

    while ( fasta_get_entry( fp, &entry ) == TRUE )
    {
        fprintf( stderr, "   Scanning: %s (%zu nt) ... ", entry->seq_name, entry->seq_len );
    
        scan_seq( entry->seq, entry->seq_len, count_array );

        fprintf( stderr, "done.\n" );
    }

    close_stream( fp );
}


void rescan_file( char *file, seq_entry *entry, uint *count_array, size_t cutoff )
{
    /* Martin A. Hansen, September 2008 */
    
    /* Rescan all FASTA entries of a file. */

    FILE *fp = read_open( file );

    while ( fasta_get_entry( fp, &entry ) == TRUE )
    {
        fprintf( stderr, "   Rescanning: %s (%zu nt) ... ", entry->seq_name, entry->seq_len );
    
        printf( "SEQ_NAME: %s\n", entry->seq_name );

        rescan_seq( entry->seq, entry->seq_len, count_array, cutoff );

        fprintf( stderr, "done.\n" );
    }

    close_stream( fp );
}


void scan_seq( char *seq, size_t seq_len, uint *count_array )
{
    /* Martin A. Hansen, September 2008 */

    /* Run a sliding window over a given sequence. The window */
    /* consists of a list where new blocks of 4 nucleotides */
    /* are pushed onto one end while at the same time old */
    /* blocks are popped from the other end. The number of */
    /* in the list is determined by the maximum seperator. */
    /* Everytime we have a full window, the window is scanned */
    /* for motifs. */
 
    bitblock *block      = NULL;
    size_t    b_count    = 0;
    ushort    n_count    = 0;
    size_t    i          = 0;
    uchar     bin        = 0;
    bool      first_node = TRUE;
    node_sl *new_node    = NULL;
    node_sl *old_node    = NULL;
    list_sl *list        = list_sl_new();

    for ( i = 0; seq[ i ]; i++ )
    {
        bin <<= BITS_IN_NT;

        switch( seq[ i ] )
        {
            case 'A': case 'a': add_A( bin ); break;
            case 'T': case 't': add_T( bin ); break;
            case 'C': case 'c': add_C( bin ); break;
            case 'G': case 'g': add_G( bin ); break;
            default: n_count = BLOCK_SIZE_NT; break;
        }

        if ( i > BLOCK_SIZE_NT - 2 )
        {
            b_count++;

            block      = bitblock_new();
            block->bin = bin;

            if ( n_count > 0 )
            {
                 block->hasN = TRUE;
                 n_count--;
            }

            new_node      = node_sl_new();
            new_node->val = block;

            if ( first_node ) {
                list_sl_add_beg( &list, &new_node );
            } else {
                list_sl_add_after( &old_node, &new_node );
            }

            old_node = new_node;

            first_node = FALSE;

            if ( b_count > BLOCK_SPACE_MAX + BLOCK_SIZE_NT )
            {
                // bitblock_list_print( list );   /* DEBUG */

                scan_list( list, count_array );

                mem_free( &list->first->val );

                list_sl_remove_beg( &list );
            }
        }
    }

    /* if the list is shorter than BLOCK_SPACE_MAX + BLOCK_SIZE_NT */
    if ( b_count <= BLOCK_SPACE_MAX + BLOCK_SIZE_NT )
    {
        // bitblock_list_print( list );  /* DEBUG */

        scan_list( list, count_array );
    }

    list_sl_destroy( &list );
}


void rescan_seq( char *seq, size_t seq_len, uint *count_array, size_t cutoff )
{
    /* Martin A. Hansen, September 2008 */

    /* Run a sliding window over a given sequence. The window */
    /* consists of a list where new blocks of 4 nucleotides */
    /* are pushed onto one end while at the same time old */
    /* blocks are popped from the other end. The number of */
    /* in the list is determined by the maximum seperator. */
    /* Everytime we have a full window, the window is scanned */
    /* for motifs. */
 
    bitblock *block      = NULL;
    size_t    b_count    = 0;
    ushort    n_count    = 0;
    size_t    i          = 0;
    uchar     bin        = 0;
    bool      first_node = TRUE;
    node_sl *new_node    = NULL;
    node_sl *old_node    = NULL;
    list_sl *list        = list_sl_new();
    uint *output_array   = NULL;

    output_array         = mem_get_zero( sizeof( uint ) * ( seq_len + 1 ) );

    for ( i = 0; seq[ i ]; i++ )
    {
        bin <<= BITS_IN_NT;

        switch( seq[ i ] )
        {
            case 'A': case 'a': add_A( bin ); break;
            case 'T': case 't': add_T( bin ); break;
            case 'C': case 'c': add_C( bin ); break;
            case 'G': case 'g': add_G( bin ); break;
            default: n_count = BLOCK_SIZE_NT; break;
        }

        if ( i > BLOCK_SIZE_NT - 2 )
        {
            b_count++;

            block      = bitblock_new();
            block->bin = bin;

            if ( n_count > 0 )
            {
                 block->hasN = TRUE;
                 n_count--;
            }

            new_node      = node_sl_new();
            new_node->val = block;

            if ( first_node ) {
                list_sl_add_beg( &list, &new_node );
            } else {
                list_sl_add_after( &old_node, &new_node );
            }

            old_node = new_node;

            first_node = FALSE;

            if ( b_count > BLOCK_SPACE_MAX + BLOCK_SIZE_NT )
            {
                // bitblock_list_print( list );   /* DEBUG */

                rescan_list( list, count_array, i, cutoff, output_array );

                mem_free( &list->first->val );

                list_sl_remove_beg( &list );
            }
        }
    }

    /* if the list is shorter than BLOCK_SPACE_MAX + BLOCK_SIZE_NT */
    if ( b_count <= BLOCK_SPACE_MAX + BLOCK_SIZE_NT )
    {
        // bitblock_list_print( list );  /* DEBUG */

        rescan_list( list, count_array, i, cutoff, output_array );
    }

    list_sl_destroy( &list );

    for ( i = 0; i < seq_len; i++ ) {
        printf( "%zu\t%u\n", i, output_array[ i ] );
    }

    free( output_array );
}


void scan_list( list_sl *list, uint *count_array )
{
    /* Martin A. Hansen, September 2008 */

    /* Scan a list of blocks for biparite motifs by creating */
    /* a binary motif consisting of two blocks of 4 nucleotides */
    /* along with the distance separating them. Motifs containing */
    /* N's are skipped. */

    node_sl  *first_node = NULL;
    node_sl  *next_node  = NULL;
    bitblock *block1     = NULL;
    bitblock *block2     = NULL;
    int       i          = 0;
    ushort    dist       = 0;
    uint      motif_bin  = 0;

//    bitblock_list_print( list );

    first_node = list->first;

    block1 = ( bitblock * ) first_node->val;

    if ( ! block1->hasN )
    {
        next_node = first_node->next;

        for ( i = 0; i < BLOCK_SIZE_NT - 1; i++ ) {
            next_node = next_node->next;
        }

        for ( next_node = next_node; next_node != NULL; next_node = next_node->next )
        {
            block2 = ( bitblock * ) next_node->val;
        
            if ( ! block2->hasN )
            {
                motif_bin = blocks2motif( block1->bin, block2->bin, dist );

                // bitblock_list_print( list ); /* DEBUG */

                count_array[ motif_bin ]++;
            }

            dist++;
        }
    }
}


void rescan_list( list_sl *list, uint *count_array, size_t pos, size_t cutoff, uint *output_array )
{
    /* Martin A. Hansen, September 2008 */

    /* Scan a list of blocks for biparite motifs by creating */
    /* a binary motif consisting of two blocks of 4 nucleotides */
    /* along with the distance separating them. Motifs containing */
    /* N's are skipped. */

    node_sl  *first_node = NULL;
    node_sl  *next_node  = NULL;
    bitblock *block1     = NULL;
    bitblock *block2     = NULL;
    int       i          = 0;
    int       k          = 0;
    ushort    dist       = 0;
    uint      motif_bin  = 0;
    uint      j          = 0;
    uint      count      = 0;

//    bitblock_list_print( list );

    first_node = list->first;

    block1 = ( bitblock * ) first_node->val;

    if ( ! block1->hasN )
    {
        next_node = first_node->next;

        for ( i = 0; i < BLOCK_SIZE_NT - 1; i++ )
        {
            next_node = next_node->next;

            j++;
        }

        for ( next_node = next_node; next_node != NULL; next_node = next_node->next )
        {
            block2 = ( bitblock * ) next_node->val;
        
            if ( ! block2->hasN )
            {
                motif_bin = blocks2motif( block1->bin, block2->bin, dist );

                // bitblock_list_print( list ); /* DEBUG */

                count = count_array[ motif_bin ];

                if ( count > cutoff )
                {
                    // printf( "%zu\t%u\t%u\n", pos + j, motif_bin, count );

                    for ( k = 0; k < BLOCK_SIZE_NT - 1; k++ )
                    {
                        output_array[ pos - j + k - BLOCK_SIZE_NT ]    += count;
                        output_array[ pos + k - dist - BLOCK_SIZE_NT ] += count;
                    }
                }
            }

            dist++;

            j++;
        }
    }
}


bitblock *bitblock_new()
{
    /* Martin A. Hansen, September 2008 */

    /* Initializes a new empty bitblock. */

    bitblock *new_block = NULL;

    new_block = mem_get( sizeof( bitblock ) );

    new_block->bin  = 0;
    new_block->hasN = FALSE;

    return new_block;
}


uint blocks2motif( uchar bin1, uchar bin2, ushort dist )
{
    /* Martin A. Hansen, September 2008 */

    /* Given two binary encoded tetra nuceotide blocks, */
    /* and the distance separating this, create a binary */
    /* bipartite motif. */

    uint motif = 0;

    motif |= bin1;

    motif <<= sizeof( uchar ) * BITS_IN_BYTE;

    motif |= bin2;

    motif <<= sizeof( uchar ) * BITS_IN_BYTE;

    motif |= dist;

    return motif;
}


void count_array_print( uint *count_array, size_t nmemb, size_t cutoff )
{
    /* Martin A. Hansen, Seqptember 2008. */

    /* Print all bipartite motifs in count_array as */
    /* tabular output. */

    uint i     = 0;
    uint motif = 0;
    uint count = 0;

    for ( i = 0; i < nmemb; i++ )
    {
        motif = i;
        count = count_array[ i ];

        if ( count >= cutoff ) {
            printf( "%u\t%u\n", motif, count );
        }
    }
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> UNIT TESTS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void run_tests()
{
    fprintf( stderr, "Running tests\n" );

    test_count_array_new();
    test_bitblock_new();
    test_bitblock_print();
    test_bitblock_list_print();
    test_scan_seq();
    test_blocks2motif();

    fprintf( stderr, "All tests OK\n" );
}


void test_count_array_new()
{
    fprintf( stderr, "   Running test_count_array_new ... " );

    size_t  i     = 0;
    size_t  nmemb = 128; 
    uint   *array = NULL;

    array = count_array_new( nmemb );

    for ( i = 0; i < nmemb; i++ ) {
        assert( array[ i ] == 0 );
    }

    mem_free( &array );

    fprintf( stderr, "done.\n" );
}


void test_bitblock_new()
{
    fprintf( stderr, "   Running test_bitblock_new ... " );

    bitblock *new_block = bitblock_new();

    assert( new_block->bin  == 0 );
    assert( new_block->hasN == FALSE );

    fprintf( stderr, "done.\n" );
}


void test_bitblock_print()
{
    fprintf( stderr, "   Running test_bitblock_print ... " );

    bitblock *new_block = bitblock_new();

    new_block->bin  = 7;
    new_block->hasN = TRUE;

//    bitblock_print( new_block );

    fprintf( stderr, "done.\n");
}


void test_bitblock_list_print()
{
    fprintf( stderr, "   Running test_bitblock_list_print ... " );

    list_sl  *list   = list_sl_new();
    node_sl  *node1  = node_sl_new();
    node_sl  *node2  = node_sl_new();
    node_sl  *node3  = node_sl_new();
    bitblock *block1 = bitblock_new();
    bitblock *block2 = bitblock_new();
    bitblock *block3 = bitblock_new();

    block1->bin  = 0;
    block1->hasN = TRUE;
    block2->bin  = 1;
    block2->hasN = TRUE;
    block3->bin  = 2;
    block3->hasN = TRUE;

    node1->val  = block1;
    node2->val  = block2;
    node3->val  = block3;

    list_sl_add_beg( &list, &node1 );
    list_sl_add_beg( &list, &node2 );
    list_sl_add_beg( &list, &node3 );

    // bitblock_list_print( list );

    fprintf( stderr, "done.\n" );
}


void test_scan_seq()
{
    fprintf( stderr, "   Running test_scan_seq ... " );

    //char   *seq       = "AAAANTCGGCTNGGGG";
    //char   *seq         = "AAAATCGGCTGGGG";
    char   *seq         = "AAAAAAAAAAAAAAG";
    size_t  seq_len     = strlen( seq );
    size_t  nmemb       = 1 << 5;
    
    uint   *count_array = count_array_new( nmemb );

    scan_seq( seq, seq_len, count_array );

    // count_array_print( count_array, nmemb, 1 );   /* DEBUG */

    fprintf( stderr, "done.\n" );
}


static void test_blocks2motif()
{
    fprintf( stderr, "   Running test_blocks2motif ... " );

    uchar  bin1  = 4;
    uchar  bin2  = 3;
    ushort dist  = 256;
    uint   motif = 0;

    motif = blocks2motif( bin1, bin2, dist );

//    printf( "motif: %d\n", motif );

    fprintf( stderr, "done.\n");
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


