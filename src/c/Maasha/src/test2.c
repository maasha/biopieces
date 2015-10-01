#include <stdio.h>

#define BUFFER 100 * 1024

int main( int argc, char *argv[] )
{
    int  count = 0;
    char line[ BUFFER ];
    FILE *fp;

    if ( ( fp = fopen( argv[ 1 ], "r" ) ) == NULL )
    {
        return 1;
    }

    while ( ( fgets( line, BUFFER, fp ) ) != NULL )
    {
        if ( line[ 0 ] == '>' ) {
            count++;
        }
    }

    printf( "count: %d\n", count );

    return 0;
}
