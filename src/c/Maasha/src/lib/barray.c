/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "barray.h"
 
#define SIZE_BLOCK 10000000

barray *barray_new( size_t nmemb )
{
    /* Martin A. Hansen, November 2008. */

    /* Initialize a new zeroed byte array
     * with nmemb number of elements. */

    barray *ba = NULL;

    ba        = mem_get( sizeof( barray ) );
    ba->array = mem_get_zero( nmemb * sizeof( ba->array ) );
    ba->nmemb = nmemb;
    ba->end   = 0;

    return ba;
}


size_t barray_new_size( size_t nmemb_old )
{
    /* Martin A. Hansen, November 2008. */

    /* Returns a new larger byte array size. */

    size_t nmemb_new = 1;

    while ( nmemb_new < nmemb_old ) {
        nmemb_new += SIZE_BLOCK;
    }

//    fprintf( stderr, "New size: %zu\n", nmemb_new );

    return nmemb_new;
}


void barray_resize( barray *ba, size_t nmemb_new )
{
    /* Martin A. Hansen, November 2008. */

    /* Reallocate a byte array, any new elements will be zeroed. */

    size_t size_old = ba->nmemb * sizeof( ba->array );
    size_t size_new = nmemb_new * sizeof( ba->array );

    ba->array = ( uint * ) mem_resize_zero( ( void * ) ba->array, size_old, size_new );
    ba->nmemb = nmemb_new;
}


void barray_print( barray *ba )
{
    /* Martin A. Hansen, November 2008. */

    /* Debug function to print the content of a byte array. */

    uint i;

    printf( "\nba->nmemb: %zu   ba->end: %zu\n", ba->nmemb, ba->end );

    for ( i = 0; i < ba->nmemb; i++ ) {
        printf( "%d: %d\n", i, ba->array[ i ] );
    }
}


void barray_interval_inc( barray *ba, size_t beg, size_t end, uint score )
{
    /* Martin A. Hansen, November 2008. */

    /* Increments a given interval of a byte array with a given score.
     * Resizes the byte array if needed. */

    assert( beg >= 0 );
    assert( end >= 0 );
    assert( end >= beg );
    assert( score > 0 );

    if ( end > ba->nmemb ) {
        barray_resize( ba, barray_new_size( end ) );
    }

    size_t i = 0;

    for ( i = beg; i <= end; i++ ) {
        ba->array[ i ] += score;
    }

    ba->end = MAX( ba->end, end );
}


bool barray_interval_scan( barray *ba, size_t *pos_pt, size_t *beg_pt, size_t *end_pt )
{
    /* Martin A. Hansen, November 2008. */

    /* Scan a byte array from a given position
     * for the next interval of non-zero values. */

    size_t pos = *pos_pt;
    size_t beg = *beg_pt;
    size_t end = *end_pt;

    if ( pos > ba->end || ba->end == 0 ) {
        return FALSE;
    }

    while ( pos < ba->end && ba->array[ pos ] == 0 ) {
        pos++;
    }

    beg = pos;

    while ( pos <= ba->end && ba->array[ pos ] != 0 ) {
        pos++;
    }

    end = pos;


    if ( end >= beg )
    {
        *pos_pt = pos;
        *beg_pt = beg;
        *end_pt = end - 1;

        return TRUE;
    }

    return FALSE;
}


uint barray_interval_max( barray *ba, size_t beg, size_t end )
{
    /* Martin A. Hansen, December 2008. */

    /* Locate the max value in an interval within a byte array. */ 

    size_t i   = 0;
    uint   max = 0;

    for ( i = beg; i <= end; i++ ) {
        max = MAX( max, ba->array[ i ] );
    }

    return max;
}


void barray_destroy( barray **ba_ppt )
{
    /* Martin A. Hansen, November 2008. */

    /* Deallocates a byte array and set it to NULL. */

    barray *ba = *ba_ppt;

    mem_free( ba->array );
    mem_free( ba );

    ba      = NULL;
    *ba_ppt = NULL;
}
