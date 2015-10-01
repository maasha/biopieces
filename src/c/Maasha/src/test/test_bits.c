/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "bits.h"

static void test_bitarray_new();
// static void test_bitarray_fill();
// static void test_bitarray_zero();
// static void test_bitarray_bit_on();
// static void test_bitarray_bit_set();
// static void test_bitarray_print();
// static void test_bitarray_destroy();


int main()
{
    fprintf( stderr, "Running all tests for bits.c\n" );

    test_bitarray_new();
//    test_bitarray_fill();
//    test_bitarray_zero();
//    test_bitarray_bit_on();
//    test_bitarray_bit_set();
//    test_bitarray_print();
//    test_bitarray_destroy();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_bitarray_new()
{
    fprintf( stderr, "   Testing bitarray_new ... " );

    bitarray *ba   = NULL;
    size_t    size = 6;

    bitarray_new( &ba, size );

    bitarray_print( ba );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}

/*
void test_bitarray_fill()
{
    fprintf( stderr, "   Testing bitarray_fill ... " );

    bitarray *ba   = NULL;
    size_t    size = 2;

    bitarray_new( &ba, size );

    assert( bitarray_bit_on( ba, size - 1 ) == FALSE );

    bitarray_print( ba );
    bitarray_fill( ba );
    bitarray_print( ba );

    assert( bitarray_bit_on( ba, size - 1 ) == TRUE );

//    bitarray_print( ba );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}


void test_bitarray_zero()
{
    fprintf( stderr, "   Testing bitarray_zero ... " );

    bitarray *ba   = NULL;
    size_t    size = 26;

    bitarray_new( &ba, size );
    bitarray_fill( ba );

//    assert( bitarray_bit_on( ba, size ) == TRUE );

    bitarray_zero( ba );

//    assert( bitarray_bit_on( ba, size ) == FALSE );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}


void test_bitarray_bit_on()
{
    fprintf( stderr, "   Testing bitarray_bit_on ... " );

    bitarray *ba   = NULL;
    size_t    size = 26;

    bitarray_new( &ba, size );

    assert( bitarray_bit_on( ba, 20 ) == FALSE );
    assert( bitarray_bit_on( ba, 0 )  == FALSE );
    assert( bitarray_bit_on( ba, 8 )  == FALSE );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}


void test_bitarray_bit_set()
{
    fprintf( stderr, "   Testing bitarray_bit_set ... " );

    bitarray *ba   = NULL;
    size_t    size = 26;

    bitarray_new( &ba, size );

    bitarray_bit_set( ba, 20 );
    assert( bitarray_bit_on( ba, 20 ) == TRUE );

    bitarray_bit_set( ba, 0 );
    //assert( bitarray_bit_on( ba, 0 ) == TRUE );

    bitarray_bit_set( ba, 8 );
    //assert( bitarray_bit_on( ba, 8 ) == TRUE );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}


void test_bitarray_print()
{
    fprintf( stderr, "   Testing bitarray_print ... " );

    bitarray *ba   = NULL;
    size_t    size = 6;

    bitarray_new( &ba, size );
    bitarray_print( ba );

    bitarray_destroy( &ba );

    fprintf( stderr, "OK\n" );
}


void test_bitarray_destroy()
{
    fprintf( stderr, "   Testing bitarray_destroy ... " );

    bitarray *ba   = NULL;
    size_t    size = 26;

    bitarray_new( &ba, size );

    bitarray_destroy( &ba );

    assert( ba == NULL );

    fprintf( stderr, "OK\n" );
}

*/
