/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "hash.h"

static void test_hash_new();
static void test_hash_key();
static void test_hash_add();
static void test_hash_get();
static void test_hash_elem_get();
static void test_hash_each();
static void test_hash_destroy();
static void test_hash_print();
static void test_hash_collision_stats();

int main()
{
    fprintf( stderr, "Running all tests for hash.c\n" );

    test_hash_new();
    test_hash_key();
    test_hash_add();
    test_hash_get();
    test_hash_elem_get();
    test_hash_each();
    test_hash_destroy();
    test_hash_print();
    test_hash_collision_stats();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_hash_new()
{
    fprintf( stderr, "   Testing hash_new ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 16;

    hash_pt = hash_new( size );

    assert( hash_pt->table_size == ( 1 << size ) );
    assert( hash_pt->mask       == ( 1 << size ) - 1 );
    assert( hash_pt->nmemb      == 0 );

    fprintf( stderr, "OK\n" );
}


void test_hash_key()
{
    fprintf( stderr, "   Testing hash_key ... " );

    char *s = "ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvxyz0123456789";
    uint  h = 0;

    h = hash_key( s );

    // printf( "key: %s   hashed key: %u\n", s, h );

    assert( h == 445021485 );

    fprintf( stderr, "OK\n" );
}


void test_hash_add()
{
    fprintf( stderr, "   Testing hash_add ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 16;
    char   *key1    = "key1";
    char   *val1    = "val1";

    hash_pt = hash_new( size );

    hash_add( hash_pt, key1, val1 );

    fprintf( stderr, "OK\n" );
}


void test_hash_get()
{
    fprintf( stderr, "   Testing hash_get ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 8;
    char   *key1    = "key1";
    char   *key2    = "key2";
    char   *val1    = "val1";
    char   *val2    = "val2";

    hash_pt = hash_new( size );

    hash_add( hash_pt, key1, val1 );
    hash_add( hash_pt, key2, val2 );

    assert( strcmp( val1, ( char * ) hash_get( hash_pt, key1 ) ) == 0 );
    assert( strcmp( val2, ( char * ) hash_get( hash_pt, key2 ) ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_hash_elem_get()
{
    fprintf( stderr, "   Testing hash_elem_get ... " );

    hash      *hash_pt = NULL;
    hash_elem *he      = NULL;
    size_t     size    = 8;
    char      *key1    = "key1";
    char      *key2    = "key2";
    char      *val1    = "val1";
    char      *val2    = "val2";

    hash_pt = hash_new( size );

    hash_add( hash_pt, key1, val1 );
    hash_add( hash_pt, key2, val2 );

    he = hash_elem_get( hash_pt, key1 );

    assert( strcmp( val1, ( char * ) he->val ) == 0 );

    he = hash_elem_get( hash_pt, key2 );

    assert( strcmp( val2, ( char * ) he->val ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_hash_each()
{
    fprintf( stderr, "   Testing hash_each ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 8;
    size_t  i       = 0;
    char   *key     = NULL;
    char   *val     = "val";
    char   *key0    = NULL;
    char   *val0    = NULL;

    key = mem_get_zero( 50 );

    hash_pt = hash_new( size );

    for ( i = 0; i < ( 1 << size ); i++ )
    {
        sprintf( key, "key_%zu", i );

        hash_add( hash_pt, key, val );
    }

    assert( hash_pt->index_table == 0 );
    assert( hash_pt->index_bucket == NULL );

    hash_print( hash_pt );

    while( hash_each( hash_pt, &key0, &val0 ) )
    {
        printf( "1: key0: %s   val0:   %s\n", key0, ( char * ) val0 );
        printf( "index_table: %zu   index_bucket: %p\n", hash_pt->index_table, hash_pt->index_bucket );

        hash_each( hash_pt, &key0, &val0 );
    }

    fprintf( stderr, "OK\n" );
}


void test_hash_destroy()
{
    fprintf( stderr, "   Testing hash_destroy ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 8;
    char   *key1    = "a";
    char   *key2    = "b";
    char   *val1    = "c";
    char   *val2    = "d";
    
    hash_pt = hash_new( size );

    hash_add( hash_pt, key1, val1 );
    hash_add( hash_pt, key2, val2 );

//    hash_print( hash_pt );

    hash_destroy( hash_pt );

    hash_pt = NULL;

    fprintf( stderr, "OK\n" );
}


void test_hash_print()
{
    fprintf( stderr, "   Testing hash_print ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 8;
    char   *key1    = "key1";
    char   *key2    = "key2";
    char   *val1    = "val1";
    char   *val2    = "val2";

    hash_pt = hash_new( size );

    hash_add( hash_pt, key1, val1 );
    hash_add( hash_pt, key2, val2 );

//    hash_print( hash_pt );

    fprintf( stderr, "OK\n" );
}


void test_hash_collision_stats()
{
    fprintf( stderr, "   Testing hash_collion_stats ... " );

    hash   *hash_pt = NULL;
    size_t  size    = 16;
    size_t  i       = 0;
    char   *key     = NULL;
    char   *val     = "val";

    key = mem_get_zero( 50 );

    hash_pt = hash_new( size );

    for ( i = 0; i < ( 1 << 8 ); i++ )
    {
        sprintf( key, "key_%zu", i );

        hash_add( hash_pt, key, val );
    }

//    hash_collision_stats( hash_pt );

    fprintf( stderr, "OK\n" );
}

