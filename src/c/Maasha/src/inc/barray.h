/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STRUCTURE DECLARATIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


struct _barray
{
    uint   *array;   /* Unsigned integer array. */
    size_t  nmemb;   /* Number of elements in array. */
    size_t  end;     /* Last position used. */
};

typedef struct _barray barray;


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTION DECLARATIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Initialize a new zeroed byte array
 * with nmemb number of elements. */
barray *barray_new( size_t nmemb );

/* Returns a new larger byte array size. */
size_t barray_new_size( size_t nmemb_old );

/* Reallocate a byte array, any new elements will be zeroed. */
void barray_resize( barray *ba, size_t nmemb_new );

/* Debug function to print the content of a byte array. */
void barray_print( barray *ba );

/* Increments a given interval of a byte array with a given score.
 * Resizes the byte array if needed. */
void barray_interval_inc( barray *ba, size_t beg, size_t end, uint score );

/* Scan a byte array from a given position
 * for the next interval of non-zero values. */
bool barray_interval_scan( barray *ba, size_t *pos_pt, size_t *beg_pt, size_t *end_pt );

/* Locate the max value in an interval within a byte array. */ 
uint barray_interval_max( barray *ba, size_t beg, size_t end );

/* Deallocates a byte array and set it to NULL. */
void barray_destroy( barray **ba_ppt );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


