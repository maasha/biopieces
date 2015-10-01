/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* Get a pointer with a given size of allocated memory. */
void *mem_get( size_t size );

/* Get a pointer with a given size of allocated and zero'ed memory. */
void *mem_get_zero( size_t size );

/* Resize allocated memory for a given pointer. */
void *mem_resize( void *pt, size_t size );

/* Resize allocated memory for a given pointer with extra memory zero'ed. */    
void *mem_resize_zero( void *pt, size_t old_size, size_t new_size );

/* Clone a structure in memory and return a pointer to the clone. */
void *mem_clone( void *old_pt, size_t size );

/* Free memory from a given pointer. */
/* Usage: mem_free( &pt ) */
void  mem_free( void *pt );
