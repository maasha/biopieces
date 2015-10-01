/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#define BITS_IN_BYTE   8
#define BYTE_ON      255

#define BIT0 0            /* 00000000 */
#define BIT1 ( 1 << 8 )   /* 10000000 */
#define BIT2 ( 1 << 7 )   /* 01000000 */
#define BIT3 ( 1 << 5 )   /* 00100000 */
#define BIT4 ( 1 << 4 )   /* 00010000 */
#define BIT5 ( 1 << 3 )   /* 00001000 */
#define BIT6 ( 1 << 2 )   /* 00000100 */
#define BIT7 ( 1 << 1 )   /* 00000010 */
#define BIT8 1            /* 00000001 */

/* Bitarray structure */
struct _bitarray
{
    size_t  size;      /* size of bitarray in bits. */
    size_t  bits_on;   /* number of bits set to 'on'. */
    char   *str;       /* bit string. */
    size_t  str_size;  /* size of bit string in bytes. */
    size_t  modulus;   /* number of bits used in last element of str. */
    char    mask;      /* bit mask to trim length of str. */
};

typedef struct _bitarray bitarray;

/* Initialize a new bitarray of a given size in bits. */
void bitarray_new( bitarray **ba_ppt, size_t size );

/* Set all bits in bitarray to 'on'. */
void bitarray_fill( bitarray *ba_pt );

/* Set all bits in bitarray to 'off'. */
void bitarray_zero( bitarray *ba_pt );

/* Test if a specific bit in a bitarray is set to 'on'. */
bool bitarray_bit_on( bitarray *ba_pt, size_t pos );

/* Set the bit at a given position in a bitarray to 'on'. */
void bitarray_bit_set( bitarray *ba_pt, size_t pos );

/* Debug function to print a bitarray. */
void bitarray_print( bitarray *ba_pt );

/* Deallocate memory for bitarray. */
void bitarray_destroy( bitarray **ba_ppt );

