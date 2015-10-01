/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"

static void test_mem_get();
static void test_mem_get_zero();
static void test_mem_resize();
static void test_mem_resize_zero();
static void test_mem_clone();
static void test_mem_free();


int main()
{
    fprintf( stderr, "Running all tests for mem.c\n" );

    test_mem_get();
    test_mem_get_zero();
    test_mem_resize();
    test_mem_resize_zero();
    test_mem_clone();
    test_mem_free();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_mem_get()
{
    fprintf( stderr, "   Testing mem_get ... " );

    size_t  len = 1000000000;
    char   *pt  = mem_get( len );

    mem_free( ( void * ) &pt );

    fprintf( stderr, "OK\n" );
}


void test_mem_get_zero()
{
    fprintf( stderr, "   Testing mem_get_zero ... " );

    size_t  i    = 0;
    size_t  len  = 5555;
    char   *pt1  = mem_get_zero( sizeof( char ) * len );
    uint   *pt2  = mem_get_zero( sizeof( uint ) * len );

    for ( i = 0; i <= ( sizeof( char ) * len ); i++ ) {
        assert( pt1[ i ] == '\0' );
    }

    for ( i = 0; i <= ( sizeof( char ) * len ); i++ ) {
        assert( pt2[ i ] == '\0' );
    }

    mem_free( ( void * ) &pt1 );
    mem_free( ( void * ) &pt2 );

    fprintf( stderr, "OK\n" );
}


void test_mem_resize()
{
    fprintf( stderr, "   Testing mem_resize ... " );

    char *pt0 = "foo";
    char *pt1 = NULL;

    pt1 = mem_get( 3 + 1 );

    memcpy( pt1, pt0, 3 );

    pt1 = mem_resize( pt1, 1 );

    mem_free( ( void * ) &pt1 );

    fprintf( stderr, "OK\n" );
}


void test_mem_resize_zero()
{
    fprintf( stderr, "   Testing mem_resize_zero ... " );

    size_t i;
    size_t size_before = 10;
    size_t size_after  = 100000;

    char *pt = NULL;

    pt = mem_get( size_before );

    memset( pt, '1', size_before );

    pt = mem_resize_zero( pt, size_before, size_after );

    assert( strlen( pt ) == size_before );

    for ( i = size_before; i <= size_after; i++ ) {
        assert( pt[ i ] == '\0' );
    }

    mem_free( ( void * ) &pt );

    fprintf( stderr, "OK\n" );
}


void test_mem_clone()
{
    fprintf( stderr, "   Testing mem_clone ... " );

    char   *pt;
    char   *pt_clone;
    size_t  pt_size = 10000;
    size_t  i;

    pt = mem_get( pt_size );

    memset( pt, 'X', pt_size );

    pt_clone = mem_clone( pt, pt_size );

    assert( pt_clone != pt );
    assert( &pt_clone != &pt );

    for ( i = 0; i < pt_size; i++ ) {
        assert( pt[ i ] == pt_clone[ i ] );
    }

    mem_free( ( void * ) &pt );
    mem_free( ( void * ) &pt_clone );

    fprintf( stderr, "OK\n" );
}


void test_mem_free()
{
    fprintf( stderr, "   Testing mem_free ... " );

    uint   mem = 500000000;
    int   i    = 0;
    char *pt   = NULL;

    pt = mem_get( mem );

    for ( i = 0; i < mem; i++ )
    {
    
    }

    assert( pt != NULL );

    mem_free( &pt );

    assert( pt == NULL );

    fprintf( stderr, "OK\n" );
}


