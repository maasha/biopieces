#include "common.h"
#include "filesys.h"


int main( int argc, char *argv[] )
{
    struct file_buffer *buffer;
    char               *line;
    char                c;

    buffer = read_open_buffer( argv[ 1 ] );

    while ( ( line = buffer_gets( buffer ) ) ) {
        printf( "LINE->%s<-", line );
    }

/*
    while ( ( c = buffer_getc( buffer ) ) )
    {
        if ( c == '\n' ) {
            printf( "CHAR->\\n\n" );
        } else {
            printf( "CHAR->%c\n", c );
        }
    }
*/     
    buffer_destroy( buffer );

    return 0;
}



/*
#define SUBSTR_SIZE 15

int main()
{
    char *string="foobarfoobarfoobarfoobarfoobarfoobarfoobarfoobar";
    char substr[ SUBSTR_SIZE + 1 ];
    int i;
    int j;

    for ( i = 0; i < strlen( string ) - SUBSTR_SIZE + 1; i++ )
    {
        for ( j = 0; j < SUBSTR_SIZE; j++ ) {
            substr[ j ] = string[ i + j ];
        } 

        substr[ j ] = '\0';
    
        printf( "substr->%s\n", substr ); 
    }gg
    
    return 0;
}

*/
