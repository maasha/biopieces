/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "filesys.h"
#include "seq.h"

#define BITS_IN_BYTE      8                                /* number of bits in one byte. */
#define BLOCK_SPACE_MAX   64                               /* maximum space between two blocks. */
#define BLOCK_MASK        ( ( BLOCK_SPACE_MAX << 1 ) - 1 ) /* mask for printing block space. */
 
/* Function declarations. */
void      run_decode( int argc, char *argv[] );
void      print_usage();
void      motif_print( uint motif, uint count );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAIN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


int main( int argc, char *argv[] )
{
    if ( argc == 1 ) {
        print_usage();
    }

    run_decode( argc, argv );

    return EXIT_SUCCESS;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void print_usage()
{
    /* Martin A. Hansen, September 2008 */

    /* Print usage and exit. */

    fprintf( stderr,
        "Usage: bipartite_decode <bipartite file(s)> > result.tab\n"        
    );

    exit( EXIT_SUCCESS );
}


void run_decode( int argc, char *argv[] )
{
    /* Martin A. Hansen, September 2008 */

    /* For each file in argv decode the file of */
    /* bipartite motifs and output the motifs */
    /* and their count. */

    FILE *fp    = NULL;
    int   i     = 0;
    uint  motif = 0;
    uint  count = 0;

    for ( i = 1; i < argc; i++ )
    {
        fp = read_open( argv[ i ] );

        while ( fscanf( fp, "%u\t%u\n", &motif, &count ) )
        {
            assert( ferror( fp ) == 0 );

            motif_print( motif, count );

            if ( feof( fp ) ) {
                break;
            }
        }

        close_stream( fp );
    }
}


void motif_print( uint motif, uint count )
{
    /* Martin A. Hansen, September 2008 */

    /* Converts a binary encoded bipartite motif */
    /* into DNA and output the motif, distance and */
    /* count seperated by tabs: */
    /* BLOCK1 \t BLOCK2 \t DIST \t COUNT */

    uchar  bin1      = 0;
    uchar  bin2      = 0;
    ushort dist      = 0;
    uint   motif_cpy = motif;

    dist = ( ushort ) motif & BLOCK_MASK;

    motif >>= sizeof( uchar ) * BITS_IN_BYTE;

    bin2 = ( uchar ) motif;

    motif >>= sizeof( uchar ) * BITS_IN_BYTE;

    bin1 = ( uchar ) motif;

    printf( "%u\t%s\t%s\t%d\t%d\n", motif_cpy, bin2dna[ bin1 ], bin2dna[ bin2 ], dist, count );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


