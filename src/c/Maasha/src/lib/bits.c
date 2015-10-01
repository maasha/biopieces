/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "bits.h"


static int mask_array[ 8 ] = {
    BIT1,   /* 10000000 */
    BIT2,   /* 01000000 */
    BIT3,   /* 00100000 */
    BIT4,   /* 00010000 */
    BIT5,   /* 00001000 */
    BIT6,   /* 00000100 */
    BIT7,   /* 00000010 */
    BIT8,   /* 00000001 */
};


void bitarray_new( bitarray **ba_ppt, size_t size )
{
    /* Martin A. Hansen, August 2008. */

    /* Initialize a new bitarray of a given size in bits. */

    bitarray *ba_pt   = *ba_ppt;
    size_t    str_size = 0;
    size_t    modulus = 0;

    assert( size > 0 );

    ba_pt = mem_get( sizeof( bitarray ) );

    str_size = size / BITS_IN_BYTE;
    modulus = size % BITS_IN_BYTE;

    if ( modulus != 0 ) {
        str_size++;
    }

    ba_pt->size    = size;
    ba_pt->str_size = str_size;
    ba_pt->str     = mem_get_zero( str_size + 1 );
    ba_pt->bits_on = 0;

    *ba_ppt = ba_pt;
}


void bitarray_fill( bitarray *ba_pt )
{
    /* Martin A. Hansen, August 2008. */

    /* Set all bits in bitarray to 'on'. */

    memset( ba_pt->str, BYTE_ON, ba_pt->str_size );

    ba_pt->bits_on = ba_pt->size;
}


void bitarray_zero( bitarray *ba_pt )
{
    /* Martin A. Hansen, August 2008. */

    /* Set all bits in bitarray to 'off'. */

    bzero( ba_pt->str, ba_pt->str_size );

    ba_pt->bits_on = 0;
}


bool bitarray_bit_on( bitarray *ba_pt, size_t pos )
{
    /* Martin A. Hansen, August 2008. */

    /* Test if a specific bit in a bitarray is set to 'on'. */

    /* if pos == 0:                         */
    /* ruler:    01234567 89012345 67890123 */
    /* bitarray: 00100100 10001000 00010001 */
    /* pos:      x                          */
    /* BIT1:     10000000                   */
    /* AND (&):  00000000                   */

    /* if pos > 0 && modulus > 0:           */
    /* ruler:    01234567 89012345 67890123 */
    /* bitarray: 00100100 10001000 00010001 */
    /* pos:                           x     */
    /* BIT4 (modulus 3):           00010000 */
    /* AND (&):                    00010000 */

    assert( pos <= ba_pt->size );

    size_t str_pos = 0;
    size_t modulus = 0;

    modulus = pos % BITS_IN_BYTE;
    str_pos = pos ? ( pos / BITS_IN_BYTE ) : 0;

    if ( modulus != 0 ) {
        str_pos++;
    }

    if ( ba_pt->str[ str_pos ] & mask_array[ modulus ] ) {
        return TRUE;
    } else {
        return FALSE;
    }
}


void bitarray_bit_set( bitarray *ba_pt, size_t pos )
{
    /* Martin A. Hansen, August 2008. */

    /* Set the bit at a given position in a bitarray to 'on'. */

    /* if pos == 0:                         */
    /* ruler:    01234567 89012345 67890123 */
    /* bitarray: 00100100 10001000 00010001 */
    /* pos:      x                          */
    /* BIT1:     10000000                   */
    /* OR (|):   10100100                   */

    /* if pos > 0 && modulus > 0:           */
    /* ruler:    01234567 89012345 67890123 */
    /* bitarray: 00100100 10001000 00010001 */
    /* pos:                            x    */
    /* BIT5 (modulus 4):           00001000 */
    /* OR (|):                     00011001 */

    assert( pos <= ba_pt->size );

    size_t str_pos = 0;
    size_t modulus = 0;

    modulus = pos % BITS_IN_BYTE;
    str_pos = pos ? ( pos / BITS_IN_BYTE ) : 0;

    if ( modulus != 0 ) {
        str_pos++;
    }

    ba_pt->str[ str_pos ] |= mask_array[ modulus ]; 
}


void bitarray_print( bitarray *ba_pt )
{
    /* Martin A. Hansen, August 2008. */

    /* Debug function to print a bitarray. */

    char   *str = NULL;
    size_t  i   = 0;

    str = mem_get_zero( ba_pt->size + 1 );

    for ( i = 0; i < ba_pt->size; i++ )
    {
        if ( bitarray_bit_on( ba_pt, i ) ) {
            str[ i ] = '1';
        } else {
            str[ i ] = '0';
        }
    }

    printf( "\n" );
    printf( "ba_pt->str:       %s\n",   str );
    printf( "ba_pt->str (raw): %s\n",   ba_pt->str );
    printf( "ba_pt->size:      %zu\n",  ba_pt->size );
    printf( "ba_pt->str_size:   %zu\n",  ba_pt->str_size );
    printf( "ba_pt->bits_on:   %zu\n",  ba_pt->bits_on );
    printf( "ba_pt->modulus:   %zu\n",  ba_pt->modulus );

    mem_free( &str );
}


void bitarray_destroy( bitarray **ba_ppt )
{
    /* Martin A. Hansen, August 2008. */

    /* Deallocate memory for bitarray. */

    bitarray *ba_pt = *ba_ppt;

    mem_free( &ba_pt->str );

    *ba_ppt = NULL;
}
