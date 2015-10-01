#include "common.h"
#include "filesys.h"
#include "seq.h"
#include "fasta.h"


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAIN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


int main( int argc, char *argv[] )
{
    int i;
    int count;
    int total;
    FILE *fp;

    count = 0;
    total = 0;

    for ( i = 1; argv[ i ]; i++ )
    {
        fp = read_open( argv[ i ] );

        count = fasta_count( fp );

        close_stream( fp );

        printf( "%s: %d\n", argv[ i ], count );

        total += count;
    }

    if ( total > count ) {
        printf( "total: %d\n", total );
    }

    return 0;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
