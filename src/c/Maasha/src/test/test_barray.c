/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "barray.h"

static void test_barray_new();
static void test_barray_new_size();
static void test_barray_resize();
static void test_barray_print();
static void test_barray_interval_inc();
static void test_barray_interval_scan();
static void test_barray_interval_max();
static void test_barray_destroy();


int main()
{
    fprintf( stderr, "Running all tests for barray.c\n" );

    test_barray_new();
    test_barray_new_size();
    test_barray_resize();
    test_barray_print();
    test_barray_interval_inc();
    test_barray_interval_scan();
    test_barray_interval_max();
    test_barray_destroy();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_barray_new()
{
    fprintf( stderr, "   Testing barray_new ... " );

    size_t  nmemb = 10;
    barray *ba    = NULL;

    ba = barray_new( nmemb );
//    barray_print( ba );

    fprintf( stderr, "OK\n" );
}


void test_barray_new_size()
{
    fprintf( stderr, "   Testing barray_new_size ... " );

    size_t  nmemb_old = 1100000;
    size_t  nmemb_new = 0;

    nmemb_new = barray_new_size( nmemb_old );

//    printf( "old: %zu   new: %zu\n", nmemb_old, nmemb_new );

    fprintf( stderr, "OK\n" );
}


void test_barray_resize()
{
    fprintf( stderr, "   Testing barray_resize ... " );

    size_t  nmemb_old = 10;
    size_t  nmemb_new = 20;
    barray *ba        = NULL;

    ba = barray_new( nmemb_old );

    barray_resize( ba, nmemb_new );

//    barray_print( ba );

    fprintf( stderr, "OK\n" );
}


void test_barray_print()
{
    fprintf( stderr, "   Testing barray_print ... " );

    size_t  nmemb = 10;
    barray *ba    = NULL;

    ba = barray_new( nmemb );

//    barray_print( ba );

    fprintf( stderr, "OK\n" );
}


void test_barray_interval_inc()
{
    fprintf( stderr, "   Testing barray_interval_inc ... " );

    size_t  nmemb = 10;
    barray *ba    = NULL;

    ba = barray_new( nmemb );

    barray_interval_inc( ba, 0, 0, 3 );
    barray_interval_inc( ba, 0, 3, 3 );
    barray_interval_inc( ba, 9, 9, 3 );

//    barray_print( ba );

    fprintf( stderr, "OK\n" );
}


void test_barray_interval_scan()
{
    fprintf( stderr, "   Testing barray_interval_scan ... " );

    size_t  nmemb = 10;
    size_t  pos   = 0;
    size_t  beg   = 0;
    size_t  end   = 0;
    barray *ba    = NULL;

    ba = barray_new( nmemb );

/*    
    barray_interval_inc( ba, 1, 2, 1 );
    barray_interval_inc( ba, 4, 5, 1 );

    barray_interval_inc( ba, 0, 0, 3 );
    barray_interval_inc( ba, 0, 3, 3 );
    barray_interval_inc( ba, 9, 9, 3 );
    barray_interval_inc( ba, 11, 11, 3 );
    barray_interval_inc( ba, 19, 29, 3 );
    barray_interval_inc( ba, 25, 35, 2 );
*/

//    barray_print( ba );

    while ( barray_interval_scan( ba, &pos, &beg, &end ) ) {
//        printf( "beg: %zu   end: %zu\n", beg, end );
    }

    fprintf( stderr, "OK\n" );
}


void test_barray_interval_max()
{
    fprintf( stderr, "   Testing barray_interval_max ... " );

    size_t  nmemb = 100;
    size_t  pos   = 0;
    size_t  beg   = 0;
    size_t  end   = 0;
    uint    max   = 0;
    barray *ba    = NULL;

    ba = barray_new( nmemb );

    barray_interval_inc( ba, 1, 2, 1 );
    barray_interval_inc( ba, 4, 5, 1 );
    barray_interval_inc( ba, 0, 0, 3 );
    barray_interval_inc( ba, 0, 3, 3 );
    barray_interval_inc( ba, 9, 9, 3 );
    barray_interval_inc( ba, 11, 11, 3 );
    barray_interval_inc( ba, 19, 29, 3 );
    barray_interval_inc( ba, 25, 35, 2 );
    barray_interval_inc( ba, 35, 35, 10 );

    while ( barray_interval_scan( ba, &pos, &beg, &end ) )
    {
        max = barray_interval_max( ba, beg, end );

//        printf( "beg: %zu   end: %zu   max: %hd\n", beg, end, max );
    }

//    barray_print( ba );

    fprintf( stderr, "OK\n" );
}


void test_barray_destroy()
{
    fprintf( stderr, "   Testing barray_destroy ... " );

    size_t  nmemb = 10;
    barray *ba    = NULL;

    ba = barray_new( nmemb );

    barray_destroy( &ba );

    assert( ba == NULL );

    fprintf( stderr, "OK\n" );
}

