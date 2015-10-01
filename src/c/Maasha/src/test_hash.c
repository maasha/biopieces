#include <stdio.h>
#include "common.h"
#include "hash.h"


int main()
{
    struct hash *my_hash;
    int          pot;
    int          i;
    char        *dummy;

    pot = 16;

    my_hash = hash_new( pot );

    for ( i = 1; i <= ( 1 << pot ); i++ )
    {
        sprintf( dummy, "dummy_%d", i );

        hash_add( my_hash, dummy, "FOO" );
    }

    hash_collision_stats( my_hash );

//    if ( ( val = ( char * ) hash_get( my_hash, key ) ) != NULL ) {
//        printf( "Key: %s, Val: %s\n", key, val );
//    } else {
//        printf( "Key: %s, Val: Not Found\n", key );
//    }

    hash_destroy( my_hash );

    return 0;
}
