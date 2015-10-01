/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "list.h"


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SINGLY LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


list_sl *list_sl_new()
{
    /* Martin A. Hansen, August 2008 */

    /* Initialize a new singly linked list. */

    list_sl *new_list = NULL;

    new_list = mem_get( sizeof( list_sl ) );

    new_list->first = NULL;

    return new_list;
}


node_sl *node_sl_new()
{
    /* Martin A. Hansen, September 2008 */

    /* Initialize a new singly linked list node. */

    node_sl *new_node = NULL;

    new_node = mem_get( sizeof( node_sl ) );

    new_node->next = NULL;
    new_node->val  = NULL;

    return new_node;
}


void list_sl_add_beg( list_sl **list_ppt, node_sl **node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node to the beginning of a singly linked list. */

    list_sl *list_pt = *list_ppt;
    node_sl *node_pt = *node_ppt;

    node_pt->next  = list_pt->first;
    list_pt->first = node_pt;
}


void list_sl_add_after( node_sl **node_ppt, node_sl **new_node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node after a given node of a singly linked list. */
    
    node_sl *node_pt     = *node_ppt;
    node_sl *new_node_pt = *new_node_ppt;

    new_node_pt->next = node_pt->next;
    node_pt->next     = new_node_pt;
}


void list_sl_remove_beg( list_sl **list_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Remove the first node of a singly linked list. */

    list_sl *list_pt  = *list_ppt;
    node_sl *old_node = NULL;

    old_node       = list_pt->first;
    list_pt->first = list_pt->first->next;

    mem_free( &old_node );
}


void list_sl_remove_after( node_sl **node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Remove the node next to this one in a singly linked list. */

    node_sl *node_pt  = *node_ppt;
    node_sl *old_node = NULL;

    old_node      = node_pt->next;
    node_pt->next = node_pt->next->next;

    mem_free( &old_node );
}


void list_sl_print( list_sl *list_pt )
{
    /* Martin A. Hansen, August 2008 */

    /* Debug function to print all elements from a singly linked list. */

    node_sl *node = NULL;

    for ( node = list_pt->first; node != NULL; node = node->next ) {
        node_sl_print( node );
    }
}


void node_sl_print( node_sl *node_pt )
{
    /* Martin A. Hansen, September 2008 */

    /* Debug funtion to print a singly linked list node. */

    printf( "node_sl->val: %s\n", ( char * ) node_pt->val );
}


void list_sl_sort( list_sl **list_ppt, int ( *compare )( const void *a, const void *b ) )
{
    /* Martin A. Hansen, September 2008 */

    /* Sort a singly linked list according to the compare function. */

    list_sl  *list       = *list_ppt;
    node_sl **node_array = NULL;        /* array of pointers to nodes */
    node_sl  *node       = NULL;
    node_sl  *old_node   = NULL;
    size_t    count      = 0;
    size_t    i          = 0;

    count = list_count( list );

    if ( count > 1 )
    {
        node_array = mem_get( count * sizeof( *node_array ) );
    
        for ( node = list->first, i = 0; node != NULL; node = node->next, i++ ) {
            node_array[ i ] = node;
        }

        qsort( node_array, count, sizeof( node_array[ 0 ] ), compare );

        list->first = NULL;

        node = node_array[ 0 ];

        list_sl_add_beg( &list, &node );

        old_node = node;

        for ( i = 1; i < count; i++ )
        {
            node = node_array[ i ];

            list_sl_add_after( &old_node, &node );

            old_node = node;
        }

        *list_ppt = list;

        mem_free( &node_array );
    }
}


void list_sl_destroy( list_sl **list_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Free memory for all nodes in and including the singly linked list. */

    list_sl *list_pt = *list_ppt;
    node_sl *next    = list_pt->first;
    node_sl *node    = NULL;

    while ( next != NULL )
    {
        node = next;
        next = node->next;

        mem_free( &node );
    }

    mem_free( &list_pt );

    *list_ppt = NULL;
}


void node_sl_destroy( node_sl **node_ppt )
{
    /* Martin A. Hansen, September 2008 */

    /* Free memory for singly linked list node and value. */

    node_sl *node = *node_ppt;

    mem_free( &node->val );
    mem_free( &node );

    *node_ppt = NULL;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DOUBLY LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


list_dl *list_dl_new()
{
    /* Martin A. Hansen, August 2008 */

    /* Initialize a new doubly linked list. */

    list_dl *new_list = NULL;

    new_list = mem_get( sizeof( list_dl ) );

    new_list->first = NULL;
    new_list->last  = NULL;

    return new_list;
}


node_dl *node_dl_new()
{
    /* Martin A. Hansen, September 2008 */

    /* Initialize a new doubly linked list node. */

    node_dl *new_node = NULL;

    new_node = mem_get( sizeof( node_dl ) );

    new_node->next = NULL;
    new_node->prev = NULL;
    new_node->val  = NULL;

    return new_node;
}


void list_dl_add_beg( list_dl **list_ppt, node_dl **node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node to the beginning of a doubly linked list. */

    list_dl *list_pt = *list_ppt;
    node_dl *node_pt = *node_ppt;

    if ( list_pt->first == NULL )
    {
        list_pt->first = node_pt;
        list_pt->last  = node_pt;
        node_pt->next  = NULL;
        node_pt->prev  = NULL;
    }
    else
    {
        list_dl_add_before( &list_pt, &list_pt->first, &node_pt );
    }
}


void list_dl_add_end( list_dl **list_ppt, node_dl **node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node to the end of a doubly linked list. */

    list_dl *list_pt = *list_ppt;
    node_dl *node_pt = *node_ppt;

    if ( list_pt->last == NULL ) {
        list_dl_add_beg( &list_pt, &node_pt );
    } else {
        list_dl_add_after( &list_pt, &list_pt->last, &node_pt );
    }
}


void list_dl_add_before( list_dl **list_ppt, node_dl **node_ppt, node_dl **new_node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node before a given node of a doubly linked list. */

    list_dl *list_pt     = *list_ppt;
    node_dl *node_pt     = *node_ppt;
    node_dl *new_node_pt = *new_node_ppt;

    new_node_pt->prev = node_pt->prev;
    new_node_pt->next = node_pt;

    if ( node_pt->prev == NULL ) {
        list_pt->first = new_node_pt;
    } else {
        node_pt->prev->next = new_node_pt;
    }

    node_pt->prev = new_node_pt;
}


void list_dl_add_after( list_dl **list_ppt, node_dl **node_ppt, node_dl **new_node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Add a new node after a given node of a doubly linked list. */

    list_dl *list_pt     = *list_ppt;
    node_dl *node_pt     = *node_ppt;
    node_dl *new_node_pt = *new_node_ppt;

    new_node_pt->prev = node_pt;
    new_node_pt->next = node_pt->next;

    if ( node_pt->next == NULL ) {
        list_pt->last = new_node_pt;
    } else {
        node_pt->next->prev = new_node_pt;
    }

    node_pt->next = new_node_pt;
}


void list_dl_remove( list_dl **list_ppt, node_dl **node_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Remove a node from a doubly linked list. */

    list_dl *list_pt = *list_ppt;
    node_dl *node_pt = *node_ppt;

    if ( node_pt->prev == NULL ) {
        list_pt->first = node_pt->next;
    } else {
        node_pt->prev->next = node_pt->next;
    }

    if ( node_pt->next == NULL ) {
        list_pt->last = node_pt->prev;
    } else {
        node_pt->next->prev = node_pt->prev;
    }

    mem_free( &node_pt );

//    *node_ppt = NULL;
}


void list_dl_print( list_dl *list_pt )
{
    /* Martin A. Hansen, August 2008 */

    /* Debug function to print all elements from a doubly linked list. */

    node_dl *node = NULL;

    for ( node = list_pt->first; node != NULL; node = node->next ) {
        node_dl_print( node );
    }
}


void node_dl_print( node_dl *node_pt )
{
    /* Martin A. Hansen, September 2008 */

    /* Debug funtion to print a doubly linked list node. */

    printf( "node_dl->val: %s\n", ( char * ) node_pt->val );
}


void list_dl_destroy( list_dl **list_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Free memory for all nodes in and including the doubly linked list. */

    list_dl *list_pt = *list_ppt;
    node_dl *next    = list_pt->first;
    node_dl *node    = NULL;

    while ( next != NULL )
    {
        node = next;
        next = node->next;

        mem_free( &node );
    }

    mem_free( &list_pt );

    *list_ppt = NULL;
}


void node_dl_destroy( node_dl **node_ppt )
{
    /* Martin A. Hansen, September 2008 */

    /* Free memory for doubly linked list node and value. */

    node_dl *node = *node_ppt;

    mem_free( &node->val );
    mem_free( &node );

    *node_ppt = NULL;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> GENERIC LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


size_t list_count( void *list_pt )
{
    /* Martin A. Hansen, September 2008 */

    /* Returns the number of nodes in a linked list. */

    list_sl *list  = ( list_sl * ) list_pt;
    node_sl *node  = NULL;
    size_t   count = 0;

    for ( node = list->first; node != NULL; node = node->next ) {
        count++;
    }

    return count;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ASSORTED SORTING FUNCTIOS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


int cmp_list_sl_char_asc( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for use with list_sl_sort(). */
    /* Sort in ascending order according to char node values. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    return strcmp( ( char * ) a_node->val, ( char * ) b_node->val );
}


int cmp_list_sl_char_desc( const void *a, const void *b )
{
    /* Martin A. Hansen, September 2008 */

    /* Compare function for use with list_sl_sort(). */
    /* Sort in descending order according to char node values. */

    node_sl *a_node = *( ( node_sl ** ) a );
    node_sl *b_node = *( ( node_sl ** ) b );

    return strcmp( ( char * ) b_node->val, ( char * ) a_node->val );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
