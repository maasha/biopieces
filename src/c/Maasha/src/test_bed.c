#include "common.h"
#include "filesys.h"
#include "ucsc.h"


int main( int argc, char *argv[] )
{
    char              *file;
    FILE              *fp;
    struct bed_entry3 *bed;
    int                count;

    file = argv[ 1 ];

    fp = read_open( file );

    count = 0;

    bed_get_entry( fp, bed, 3 );

    printf( "Count: %d\n", count );

    close_stream( fp );

    return 0;
}
