#include "common.h"
#include "filesys.h"
#include "hash.h"

bool get_record( struct file_buffer *buffer, struct hash *record );
void put_record( struct hash *record );

int main( int argc, char *argv[] )
{
    int                 count;
    char               *file;
    struct file_buffer *buffer = NULL;
    struct hash        *record = NULL;

    file = argv[ 1 ];

    buffer = read_open_buffer( file );

    record = hash_new( 5 );

    count = 0;

    while ( ( get_record( buffer, record ) ) != FALSE )
    {
        put_record( record );

        count++;
    }

    fprintf( stderr, "Count: %d\n", count );

    hash_destroy( record );

    buffer_destroy( buffer );

    return 0;
}


bool get_record( struct file_buffer *buffer, struct hash *record )
{
    /* Martin A. Hansen, June 2008 */

    /* Get next record from the stream. */

    char *line = NULL;
    char *val  = NULL;
    char  key[ 256 ];
    int   len;
    int   i;
    bool  key_ok;

    while ( ( line = buffer_gets( buffer ) ) )
    {
        key_ok = FALSE;

        //printf( "LINE->%s<-", line );

        if ( strcmp( line, "---\n" ) == 0 )
        {
//            printf( "found\n" );
            
            return TRUE;
        }
        else
        {
            len = strlen( line );

            i = 0;

            while ( i < len )
            {
                if ( i < len - 1 && line[ i ] == ':' && line[ i + 1 ] == ' ' )
                {
                    key_ok = TRUE;

                    key[ i ] = '\0';

                    i += 2;

                    break;
                }

                key[ i ] = line[ i ];
            
                i++;
            }

            if ( ! key_ok ) {
                die( "Could not locate key." );
            }

            val = mem_get( len - i );

            memcpy( val, &line[ i ], len - i - 1 );

            val[ len - i ] = '\0';

//            printf( "key: ->%s<- val: ->%s<-\n", key, val );

            hash_add( record, key, val );
        }
    }

    return FALSE;
}


void put_record( struct hash *record )
{
    /* Martin A. Hansen, June 2008 */

    /* Output a record to the stream. */

    int              i;
    struct hash_elem *bucket;

    for ( i = 0; i < record->table_size; i++ )
    {
        for ( bucket = record->table[ i ]; bucket != NULL; bucket = bucket->next ) {
            printf( "%s: %s\n", ( char * ) bucket->key, ( char * ) bucket->val );
        }
    }

    printf( "---\n" );
}



