#include "common.h"
#include "barray.h"

#define BUFFER_SIZE 1024
#define BED_CHR_MAX 16
#define BED_QID_MAX 256
#define BARRAY_SIZE ( 1 << 16 )


static void usage()
{
    fprintf( stderr,
        "\n"
        "bed2fixedstep - collapse overlapping BED entries with only one\n"
        "chromosome using a score based on the last number following a _\n"
        "in the 'name' column. if no such number is found 1 is used.\n"
        "\n"
        "Usage: bed2fixedstep < <BED file(s)> > <fixedstep file>\n\n"
    );

    exit( EXIT_FAILURE );
}


long get_score( char *str )
{
    /* Martin A. Hansen, December 2008. */

    /* Extract the last decimal number after _ 
     * in a string and return that. If no number
     * was found return 1. */

    char *c;
    long  score = 1;

    if ( ( c = strrchr( str, '_' ) ) != NULL ) {
        score = strtol( &c[ 1 ], NULL , 10 );
    }

    return score;
}


int main( int argc, char *argv[] )
{
    char       buffer[ BUFFER_SIZE ];
    char       chr[ BED_CHR_MAX ];
    char       q_id[ BED_QID_MAX ];
    size_t     beg   = 0;
    size_t     end   = 0;
    uint       score = 0;
    size_t     pos   = 0;
    size_t     i     = 0;
    barray    *ba    = barray_new( BARRAY_SIZE );

    if ( isatty( fileno( stdin ) ) ) {
        usage();
    }
    
    while ( fgets( buffer, sizeof( buffer ), stdin ) )
    {
//        printf( "BUFFER: %s\n", buffer );

        if ( sscanf( buffer, "%s\t%zu\t%zu\t%s", chr, &beg, &end, q_id ) == 4 )
        {
//            printf( "chr: %s   beg: %zu   end: %zu   q_id: %s\n", chr, beg, end, q_id );

            score = ( uint ) get_score( q_id );

            barray_interval_inc( ba, beg, end - 1, score );
        }
    }

//    barray_print( ba );

    pos = 0;
    beg = 0;
    end = 0;

    while ( barray_interval_scan( ba, &pos, &beg, &end ) )
    {
//        printf( "chr: %s   pos: %zu   beg: %zu   end: %zu\n", chr, pos, beg, end );

        printf( "fixedStep chrom=%s start=%zu step=1\n", chr, beg + 1 );

        for ( i = beg; i <= end; i++ ) {
            printf( "%u\n", ba->array[ i ] );
        }
    }

    return EXIT_SUCCESS;
}

