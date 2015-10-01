/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"


void *mem_get( size_t size )
{
    /* Martin A. Hansen, May 2008 */

    /* Unit test done.*/

    /* Allocate a given chunk of memory to a pointer that is returned. */

    void *pt;

    assert( size > 0 );

    if ( ( pt = malloc( size ) ) == NULL )
    {
        fprintf( stderr, "ERROR: Could not allocate %zu byte(s): %s\n", size, strerror( errno ) );
        abort();
    } 

    return pt;
}


void *mem_get_zero( size_t size )
{
    /* Martin A. Hansen, May 2008 */

    /* Unit test done.*/

    /* Allocate a given chunk of zero'ed memory to a pointer that is returned. */

    void *pt;

    assert( size > 0 );

    pt = mem_get( size );

    bzero( pt, size );

    return pt;
}


void *mem_resize( void *pt, size_t size )
{
    /* Martin A. Hansen, May 2008 */

    /* Unit test done.*/

    /* Resize an allocated chunk of memory for a given pointer and new size. */

    void *pt_new;

    assert( size > 0 );

    if ( ( pt_new = realloc( pt, size ) ) == NULL )
    {
        fprintf( stderr, "ERROR: Could not re-allocate %zu byte(s)\n", size );
        abort();
    }

    return pt_new;
}


void *mem_resize_zero( void *pt, size_t old_size, size_t new_size )
{
    /* Martin A. Hansen, May 2008 */

    /* Unit test done.*/

    /* Resize an allocated chunk of memory for a given pointer and zero any extra memory. */
    
    void *pt_new;

    pt_new = mem_resize( pt, new_size );

    if ( new_size > old_size ) {
        bzero( ( ( void * ) pt_new ) + old_size, new_size - old_size );
    }

    return pt_new;
}


void *mem_clone( void *old_pt, size_t size )
{
    /* Martin A. Hansen, June 2008 */

    /* Unit test done.*/

    /* Clone a structure in memory and return a pointer to the clone. */

    void *new_pt;
    
    assert( size > 0 );

    new_pt = mem_get( size );

    memcpy( new_pt, old_pt, size );

    return new_pt;
}


void mem_free( void *pt )
{
    /* Martin A. Hansen, May 2008 */

    /* Free memory from a given pointer. */

    void **ppt = ( void ** ) pt;
    void *p = *ppt;

    if ( p != NULL )
    {
        free( p );

        p = NULL;
    }

    *ppt = NULL;
     pt  = NULL;
}

