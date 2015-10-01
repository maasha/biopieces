/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */


#include "common.h"
#include "mem.h"
#include "filesys.h"
#include "list.h"
#include "strings.h"
#include "ucsc.h"


bed_entry *bed_entry_new( const int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Returns a new BED entry with memory allocated for */
    /* a given number of columns. */

    bed_entry *entry = mem_get( sizeof( bed_entry ) );

    entry->cols    = cols;
    entry->chr     = NULL;
    entry->chr_beg = 0;
    entry->chr_end = 0;

    entry->chr = mem_get( BED_CHR_MAX );

    if ( cols == 3 ) {
        return entry;
    }

    entry->q_id = mem_get( BED_QID_MAX );

    if ( cols == 4 ) {
        return entry;
    }

    entry->score = 0;

    if ( cols == 5 ) {
        return entry;
    }

    entry->strand = 0; 

    if ( cols == 6 ) {
        return entry;
    }

    entry->thick_beg  = 0;
    entry->thick_end  = 0;
    entry->itemrgb    = mem_get( BED_ITEMRGB_MAX );
    entry->blockcount = 0;
    entry->blocksizes = mem_get( BED_BLOCKSIZES_MAX );
    entry->q_begs     = mem_get( BED_QBEGS_MAX );

    return entry;
}


void bed_entry_destroy( bed_entry *entry )
{
    /* Martin A. Hansen, September 2008 */

    /* Free memory for a BED entry. */

    if ( entry->cols > 6 )
    {
        free( entry->itemrgb );
        free( entry->blocksizes );
        free( entry->q_begs );
        free( entry->q_id );
        free( entry->chr );
    }
    else if ( entry->cols > 3 )
    {
        free( entry->q_id );
        free( entry->chr );
    }
    else
    {
        free( entry->chr );
    }

    mem_free( &entry );
}


bool bed_entry_get( FILE *fp, bed_entry **entry_ppt )
{
    /* Martin A. Hansen, September 2008 */

    /* Get next BED entry from a file stream. */

    bed_entry *entry = *entry_ppt;
    char       buffer[ BED_BUFFER ];

    if ( fgets( buffer, sizeof( buffer ), fp ) != NULL )
    {
        if ( entry->cols == 3 )
        {
            sscanf(
                    buffer,
                    "%s\t%u\t%u",
                    entry->chr, 
                    &entry->chr_beg, 
                    &entry->chr_end
            );

            return TRUE;
        }

        if ( entry->cols == 4 )
        {
            sscanf(
                    buffer,
                    "%s\t%u\t%u\t%s",
                    entry->chr, 
                    &entry->chr_beg, 
                    &entry->chr_end,
                    entry->q_id
            );

            return TRUE;
        }

        if ( entry->cols == 5 )
        {
            sscanf(
                    buffer,
                    "%s\t%u\t%u\t%s\t%i",
                    entry->chr, 
                    &entry->chr_beg, 
                    &entry->chr_end,
                    entry->q_id, 
                    &entry->score
            );

            return TRUE;
        }

        if ( entry->cols == 6 )
        {
            sscanf(
                    buffer,
                    "%s\t%u\t%u\t%s\t%i\t%c",
                    entry->chr, 
                    &entry->chr_beg, 
                    &entry->chr_end,
                    entry->q_id, 
                    &entry->score,
                    &entry->strand
            );

            return TRUE;
        }

        if ( entry->cols == 12 )
        {
            sscanf(
                    buffer,
                    "%s\t%u\t%u\t%s\t%i\t%c\t%u\t%u\t%s\t%u\t%s\t%s",
                    entry->chr, 
                    &entry->chr_beg, 
                    &entry->chr_end,
                    entry->q_id, 
                    &entry->score,
                    &entry->strand,
                    &entry->thick_beg,
                    &entry->thick_end,
                    entry->itemrgb,
                    &entry->blockcount,
                    entry->blocksizes,
                    entry->q_begs
            );

            return TRUE;
        }
    }

    return FALSE;
}


list_sl *bed_entries_get( char *path, const int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Get a singly linked list with all BED entries (of a given number of coluns */
    /* from a specified file. */

    list_sl   *list     = list_sl_new();
    node_sl   *node     = node_sl_new();
    node_sl   *old_node = NULL;
    bed_entry *entry    = NULL;
    FILE      *fp       = NULL;
    
    entry = bed_entry_new( cols );

    fp = read_open( path );

    if ( ( bed_entry_get( fp, &entry ) ) )
    {
        node->val = mem_clone( entry, sizeof( bed_entry ) );
    
        list_sl_add_beg( &list, &node );

        old_node = node;
    }

    while ( ( bed_entry_get( fp, &entry ) ) )
    {
        node = node_sl_new();

        node->val = mem_clone( entry, sizeof( bed_entry ) );

        list_sl_add_after( &old_node, &node );

        old_node = node;
    }

    close_stream( fp );

    return list;
}

 
void bed_entry_put( bed_entry *entry, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Output a given number of columns from a BED entry to stdout. */

    if ( ! cols ) {
        cols = entry->cols;
    } 

    if ( cols == 3 )
    {
        printf(
            "%s\t%u\t%u\n",
            entry->chr,
            entry->chr_beg,
            entry->chr_end
        );
    }
    else if ( cols == 4 )
    {
        printf(
            "%s\t%u\t%u\t%s\n",
            entry->chr,
            entry->chr_beg,
            entry->chr_end,
            entry->q_id 
        );
    }
    else if ( cols == 5 )
    {
        printf(
            "%s\t%u\t%u\t%s\t%i\n",
            entry->chr,
            entry->chr_beg,
            entry->chr_end,
            entry->q_id,
            entry->score
        );
    }
    else if ( cols == 6 )
    {
        printf(
            "%s\t%u\t%u\t%s\t%i\t%c\n",
            entry->chr,
            entry->chr_beg,
            entry->chr_end,
            entry->q_id,
            entry->score,
            entry->strand
        );
    }
    else if ( cols == 12 )
    {
        printf(
            "%s\t%u\t%u\t%s\t%i\t%c\t%u\t%u\t%s\t%u\t%s\t%s\n",
            entry->chr,
            entry->chr_beg,
            entry->chr_end,
            entry->q_id,
            entry->score,
            entry->strand,
            entry->thick_beg,
            entry->thick_end,
            entry->itemrgb,
            entry->blockcount,
            entry->blocksizes,
            entry->q_begs
        );
    }
    else
    {
        fprintf( stderr, "ERROR: Wrong number of columns in bed_entry_put: %d\n", cols );

        abort();
    }
}


void bed_entries_put( list_sl *entries, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Output a given number of columns from all BED entries */
    /* in a singly linked list. */

    node_sl *node = NULL;

    for ( node = entries->first; node != NULL; node = node->next ) {
        bed_entry_put( ( bed_entry * ) node->val, cols );
    }
}


void bed_entries_destroy( list_sl **entries_ppt )
{
    /* Martin A. Hansen, September 2008 */

    /* Free memory for all BED entries and list nodes. */

    list_sl *entries = *entries_ppt;
    node_sl *node    = NULL;
    node_sl *next    = NULL;

    next = entries->first;

    while ( next != NULL )
    {
        node = next;

        bed_entry_destroy( ( bed_entry * ) node->val );

        next = node->next;

        mem_free( &node );
    }

    mem_free( &entries );

    *entries_ppt = NULL;
}


void bed_file_sort_beg( char *path, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Given a path to a BED file, read the given number of cols */
    /* according to the begin position. The result is written to stdout. */

    list_sl *entries = NULL;

    entries = bed_entries_get( path, cols );

    list_sl_sort( &entries, cmp_bed_sort_beg );

    bed_entries_put( entries, cols );

    bed_entries_destroy( &entries );
}


void bed_file_sort_strand_beg( char *path, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Given a path to a BED file, read the given number of cols */
    /* according to the strand AND begin position. The result is written to stdout. */

    assert( cols >= 6 );

    list_sl *entries = NULL;

    entries = bed_entries_get( path, cols );

    list_sl_sort( &entries, cmp_bed_sort_strand_beg );

    bed_entries_put( entries, cols );

    bed_entries_destroy( &entries );
}


void bed_file_sort_chr_beg( char *path, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Given a path to a BED file, read the given number of cols */
    /* according to the chromosome AND begin position. The result is written to stdout. */

    list_sl *entries = NULL;

    entries = bed_entries_get( path, cols );

    list_sl_sort( &entries, cmp_bed_sort_chr_beg );

    bed_entries_put( entries, cols );

    bed_entries_destroy( &entries );
}


void bed_file_sort_chr_strand_beg( char *path, int cols )
{
    /* Martin A. Hansen, September 2008 */

    /* Given a path to a BED file, read the given number of cols */
    /* according to the chromosome AND strand AND begin position. The result is written to stdout. */

    assert( cols >= 6 );

    list_sl *entries = NULL;

    entries = bed_entries_get( path, cols );

    list_sl_sort( &entries, cmp_bed_sort_chr_strand_beg );

    bed_entries_put( entries, cols );

    bed_entries_destroy( &entries );
}


int cmp_bed_sort_beg( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for sorting a singly linked list of BED entries */
    /* according to begin position. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    bed_entry *a_entry = ( bed_entry * ) a_node->val;
    bed_entry *b_entry = ( bed_entry * ) b_node->val;

    if ( a_entry->chr_beg < b_entry->chr_beg ) {
        return -1;
    } else if ( a_entry->chr_beg > b_entry->chr_beg ) {
        return 1;
    } else {
        return 0;
    }
}


int cmp_bed_sort_strand_beg( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for sorting a singly linked list of BED entries */
    /* according to strand AND begin position. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    bed_entry *a_entry = ( bed_entry * ) a_node->val;
    bed_entry *b_entry = ( bed_entry * ) b_node->val;

    if ( a_entry->strand < b_entry->strand ) {
        return -1;
    } else if ( a_entry->strand > b_entry->strand ) {
        return 1;
    } else if ( a_entry->chr_beg < b_entry->chr_beg ) {
        return -1;
    } else if ( a_entry->chr_beg > b_entry->chr_beg ) {
        return 1;
    } else {
        return 0;
    }
}


int cmp_bed_sort_chr_beg( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for sorting a singly linked list of BED entries */
    /* according to chromosome name AND begin position. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    bed_entry *a_entry = ( bed_entry * ) a_node->val;
    bed_entry *b_entry = ( bed_entry * ) b_node->val;

    int diff = 0;

    diff = strcmp( a_entry->chr, b_entry->chr );

    if ( diff < 0 ) {
        return -1;
    } else if ( diff > 0 ) {
        return 1;
    } else if ( a_entry->chr_beg < b_entry->chr_beg ) {
        return -1;
    } else if ( a_entry->chr_beg > b_entry->chr_beg ) {
        return 1;
    } else {
        return 0;
    }
}


int cmp_bed_sort_chr_strand_beg( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for sorting a singly linked list of BED entries */
    /* according to chromosome name AND strand AND begin position. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    bed_entry *a_entry = ( bed_entry * ) a_node->val;
    bed_entry *b_entry = ( bed_entry * ) b_node->val;

    int diff = 0;

    diff = strcmp( a_entry->chr, b_entry->chr );

    if ( diff < 0 ) {
        return -1;
    } else if ( diff > 0 ) {
        return 1;
    } else if ( a_entry->strand < b_entry->strand ) {
        return -1;
    } else if ( a_entry->strand > b_entry->strand ) {
        return 1;
    } else if ( a_entry->chr_beg < b_entry->chr_beg ) {
        return -1;
    } else if ( a_entry->chr_beg > b_entry->chr_beg ) {
        return 1;
    } else {
        return 0;
    }
}

