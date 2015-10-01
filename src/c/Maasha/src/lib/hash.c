/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "hash.h"
#include "list.h"


hash *hash_new( size_t size )
{
    /* Martin A. Hansen, June 2008 */

    /* Initialize a new generic hash structure. */

    hash   *new_hash   = NULL;
    size_t  table_size = 0;

    new_hash = mem_get( sizeof( new_hash ) );

    table_size = 1 << size;   /* table_size = ( 2 ** size ) */

    new_hash->table_size   = table_size;
    new_hash->mask         = table_size - 1;
    new_hash->table        = mem_get( sizeof( hash_elem * ) * table_size );
    new_hash->nmemb        = 0;
    new_hash->index_table  = 0;
    new_hash->index_bucket = mem_get( sizeof( hash_elem ) );
    new_hash->index_bucket = NULL;

    return new_hash;
}


hash_elem *hash_elem_new()
{
    /* Martin A. Hansen, November 2008. */

    /* Initializes a new hash_elem structure. */

    hash_elem *new_elem = NULL;

    new_elem = mem_get( sizeof( hash_elem ) );

    new_elem->next = NULL;
    new_elem->key  = NULL;
    new_elem->val  = NULL;

    return new_elem;
}


void hash_add( hash *hash_pt, char *key, void *val )
{
    /* Martin A. Hansen, June 2008 */

    /* Add a new hash element consisting of a key/value pair to an existing hash. */

    hash_elem *old_elem   = NULL;
    hash_elem *new_elem   = NULL;
    size_t     hash_index = 0;

    if ( ( old_elem = hash_elem_get( hash_pt, key ) ) != NULL )
    {
        old_elem->val = val;
    }
    else
    {
        new_elem = hash_elem_new();

        hash_index = ( hash_key( key ) & hash_pt->mask );

        new_elem->key  = mem_clone( key, strlen( key ) );
        new_elem->val  = val;
        new_elem->next = hash_pt->table[ hash_index ];

        hash_pt->table[ hash_index ] = new_elem;
        hash_pt->nmemb++;
    }
}


void *hash_get( hash *hash_pt, char *key )
{
    /* Martin A. Hansen, June 2008 */

    /* Lookup a key in a given hash and return the value - or NULL if not found. */

    hash_elem *bucket;

    bucket = hash_pt->table[ ( hash_key( key ) & hash_pt->mask ) ];

    while ( bucket != NULL )
    {
        if ( strcmp( bucket->key, key ) == 0 ) {
            return bucket->val;
        }

        bucket = bucket->next;
    }

    return NULL;
}


hash_elem *hash_elem_get( hash *hash_pt, char *key )
{
    /* Martin A. Hansen, June 2008 */

    /* Lookup a key in a given hash and return the hash element - or NULL if not found. */

    hash_elem *bucket;

    bucket = hash_pt->table[ ( hash_key( key ) & hash_pt->mask ) ];

    while ( bucket != NULL )
    {
        if ( strcmp( bucket->key, key ) == 0 ) {
            return bucket;
        }

        bucket = bucket->next;
    }

    return NULL;
}


bool hash_each( hash *hash_pt, char **key_ppt, void *val )
{
    /* Martin A. Hansen, December 2008. */

    /* Get the next key/value pair from a hash table. */

    char *key = *key_ppt;

    printf( "\nhash_each INIT   -> i: %zu   he: %p\n", hash_pt->index_table, hash_pt->index_bucket );

    if ( hash_pt->index_bucket != NULL )
    {
        key = hash_pt->index_bucket->key;
        val = hash_pt->index_bucket->val;
    
        hash_pt->index_bucket = hash_pt->index_bucket->next;

        *key_ppt = key;

        printf( "\nhash_each BUCKET -> i: %zu   he: %p\n", hash_pt->index_table, hash_pt->index_bucket );
        return TRUE;
    }

    while ( hash_pt->index_table < hash_pt->table_size )
    {
        hash_pt->index_bucket = hash_pt->table[ hash_pt->index_table ];

        if ( hash_pt->index_bucket != NULL )
        {
            key = hash_pt->index_bucket->key;
            val = hash_pt->index_bucket->val;
        
            hash_pt->index_bucket = hash_pt->index_bucket->next;

            *key_ppt = key;

            printf( "hash_each TABLE table[ %zu ]\n", hash_pt->index_table );
            return TRUE;
        }

        hash_pt->index_table++;
    }

    printf( "\nhash_each FALSE -> i: %zu   he: %p\n", hash_pt->index_table, hash_pt->index_bucket );

    // RESET ITERATORS!

    return FALSE;
}


void hash_destroy( hash *hash_pt )
{
    /* Martin A. Hansen, June 2008 */

    /* Deallocate memory for hash and all hash elements. */

    size_t     i;
    hash_elem *bucket;

    for ( i = 0; i < hash_pt->table_size; i++ )
    {
        for ( bucket = hash_pt->table[ i ]; bucket != NULL; bucket = bucket->next )
        {
//            mem_free( bucket->key );
//            mem_free( bucket->val );
            mem_free( bucket );
        }
    }

    mem_free( hash_pt->table );
    mem_free( hash_pt );
}


uint hash_key( char *string )
{
    /* Martin A. Hansen, June 2008 */

    /* Hash function that generates a hash key, */
    /* based on the Jim Kent's stuff. */

    char *key    = string;
    uint  result = 0;
    int   c;

    while ( ( c = *key++ ) != '\0' ) {
        result += ( result << 3 ) + c;
    }

    return result;
}


void hash_print( hash *hash_pt )
{
    /* Martin A. Hansen, November 2008. */

    /* Debug function that prints hash meta data and
     * all hash elements. */

    hash_elem *bucket = NULL;
    size_t     i      = 0;

    printf( "table_size: %zu mask: %zu elem_count: %zu\n", hash_pt->table_size, hash_pt->mask, hash_pt->nmemb );

    for ( i = 0; i < hash_pt->table_size; i++ )
    {
        bucket = hash_pt->table[ i ];

        while ( bucket != NULL  )
        {
            printf( "i: %zu   key: %s   val: %s\n", i, bucket->key, ( char * ) bucket->val );

            bucket = bucket->next;
        }
    }
}


void hash_collision_stats( hash *hash_pt )
{
    /* Martin A. Hansen, June 2008 */

    /* Output some collision stats for a given hash. */

    /* Use with Biopieces: ... | plot_histogram -k Col -x */

    size_t     i      = 0;
    size_t     col    = 0;
    hash_elem *bucket = NULL;

    for ( i = 0; i < hash_pt->table_size; i++ )
    {
        col = 0;

        for ( bucket = hash_pt->table[ i ]; bucket != NULL; bucket = bucket->next ) {
            col++;
        }

        printf( "Col: %zu\n---\n", col );
    }
}
