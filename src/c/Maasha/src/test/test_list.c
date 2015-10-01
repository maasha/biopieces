/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "list.h"


static void test_list_sl_new();
static void test_node_sl_new();
static void test_list_sl_add_beg();
static void test_list_sl_add_after();
static void test_list_sl_remove_beg();
static void test_list_sl_remove_after();
static void test_list_sl_print();
static void test_list_sl_sort();
static void test_list_sl_destroy();
static void test_node_sl_destroy();

static void test_list_dl_new();
static void test_node_dl_new();
static void test_list_dl_add_beg();
static void test_list_dl_add_end();
static void test_list_dl_add_before();
static void test_list_dl_add_after();
static void test_list_dl_remove();
static void test_list_dl_print();
static void test_list_dl_destroy();
static void test_node_dl_destroy();

static void test_list_count();


int main()
{
    fprintf( stderr, "Running all tests for list.c\n" );

    test_list_sl_new();
    test_node_sl_new();
    test_list_sl_add_beg();
    test_list_sl_add_after();
    test_list_sl_remove_beg();
    test_list_sl_remove_after();
    test_list_sl_print();
    test_list_sl_sort();
    test_list_sl_destroy();
    test_node_sl_destroy();

    test_list_dl_new();
    test_node_dl_new();
    test_list_dl_add_beg();
    test_list_dl_add_end();
    test_list_dl_add_before();
    test_list_dl_add_after();
    test_list_dl_remove();
    test_list_dl_print();
    test_list_dl_destroy();
    test_node_dl_destroy();

    test_list_count();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SINGLY LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void test_list_sl_new()
{
    fprintf( stderr, "   Testing list_sl_new ... " );

    list_sl *list = NULL;

    list = list_sl_new();

    assert( list != NULL );
    assert( list->first == NULL );

    fprintf( stderr, "OK\n" );
}


void test_node_sl_new()
{
    fprintf( stderr, "   Testing node_sl_new ... " );

    node_sl *node = NULL;

    node = node_sl_new();

    assert( node != NULL );
    assert( node->next == NULL );
    assert( node->val  == NULL );

    fprintf( stderr, "OK\n" );
}


void test_list_sl_add_beg()
{
    fprintf( stderr, "   Testing list_sl_add_beg ... " );

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *list     = NULL;
    node_sl *node     = NULL;
    int      i        = 0;

    list = list_sl_new();

    for ( i = 0; i < 3; i++ )
    {
        node = node_sl_new();

        node->val = array[ i ];

        list_sl_add_beg( &list, &node );
    }

    i = 2;

    for ( node = list->first; node != NULL; node = node->next )
    {
        assert( strcmp( array[ i ], ( char * ) node->val ) == 0 );

        i--;
    }

    fprintf( stderr, "OK\n" );
}


void test_list_sl_add_after()
{
    fprintf( stderr, "   Testing list_sl_add_after ... " );

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *list     = NULL;
    node_sl *node     = NULL;
    node_sl *new_node = NULL;
    int      i        = 0;

    list     = list_sl_new();
    new_node = node_sl_new();

    new_node->val = array[ 0 ];

    list_sl_add_beg( &list, &new_node );

    node = new_node;

    for ( i = 1; i < 3; i++ )
    {
        new_node = node_sl_new();

        new_node->val = array[ i ];

        list_sl_add_after( &node, &new_node );

        node = new_node;
    }

    i = 0;

    for ( node = list->first; node != NULL; node = node->next )
    {
        assert( strcmp( array[ i ], ( char * ) node->val ) == 0 );

        i++;
    }

    fprintf( stderr, "OK\n" );
}


void test_list_sl_remove_beg()
{
    fprintf( stderr, "   Testing list_sl_remove_beg ... " );

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *list     = NULL;
    node_sl *node     = NULL;
    node_sl *new_node = NULL;
    int      i        = 0;

    list     = list_sl_new();
    new_node = node_sl_new();

    new_node->val = array[ 0 ];

    list_sl_add_beg( &list, &new_node );

    node = new_node;

    for ( i = 1; i < 3; i++ )
    {
        new_node = node_sl_new();

        new_node->val = array[ i ];

        list_sl_add_after( &node, &new_node );

        node = new_node;
    }

    i = 0;

    node = list->first;

    while ( node != NULL )
    {
        assert( strcmp( ( char * ) node->val, array[ i ] ) == 0 );

        list_sl_remove_beg( &list );
        
        node = list->first;

        i++;
    }

    fprintf( stderr, "OK\n" );
}


void test_list_sl_remove_after()
{
    fprintf( stderr, "   Testing list_sl_remove_after ... " );

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *list     = NULL;
    node_sl *node     = NULL;
    node_sl *new_node = NULL;
    int      i        = 0;

    list     = list_sl_new();
    new_node = node_sl_new();

    new_node->val = array[ 0 ];

    list_sl_add_beg( &list, &new_node );

    node = new_node;

    for ( i = 1; i < 3; i++ )
    {
        new_node = node_sl_new();

        new_node->val = array[ i ];

        list_sl_add_after( &node, &new_node );

        node = new_node;
    }

    assert( strcmp( ( char * ) list->first->next->val, "test2" ) == 0 );

    list_sl_remove_after( &list->first );

    assert( strcmp( ( char * ) list->first->next->val, "test3" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_list_sl_print()
{
    fprintf( stderr, "   Testing list_sl_print ... " );

    list_sl *list  = NULL;
    node_sl *node1 = NULL;
    node_sl *node2 = NULL;
    node_sl *node3 = NULL;

    list = list_sl_new();

    node1 = node_sl_new();
    node2 = node_sl_new();
    node3 = node_sl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_sl_add_beg( &list, &node1 );
    list_sl_add_beg( &list, &node2 );
    list_sl_add_beg( &list, &node3 );

    // list_sl_print( list );

    fprintf( stderr, "OK\n" );
}


void test_list_sl_sort()
{
    fprintf( stderr, "   Testing list_sl_sort ... " );

    /* Sorting a char list */

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *list     = NULL;
    node_sl *node     = NULL;
    int      i        = 0;

    list = list_sl_new();

    for ( i = 0; i < 3; i++ )
    {
        node = node_sl_new();

        node->val = array[ i ];

        list_sl_add_beg( &list, &node );
    }

    list_sl_sort( &list, cmp_list_sl_char_asc );
    list_sl_sort( &list, cmp_list_sl_char_desc );

//    /* Sorting a int list */
//
//    int int_array[ 5 ] = { 345, 23, 23, 1, 400 }; 
//    list_sl *int_list  = NULL;
//    node_sl *int_node  = NULL;
//
//    int_list = list_sl_new();
//
//    for ( i = 0; i < 5; i++ )
//    {
//        printf( "int: %d\n", int_array[ i ] );
//
//        int_node = node_sl_new();
//
//        node->val = int_array[ i ];
//    }

    fprintf( stderr, "OK\n" );
}


void test_list_sl_destroy()
{
    fprintf( stderr, "   Testing list_sl_destroy ... " );

    list_sl *list  = list_sl_new();
    node_sl *node1 = node_sl_new();
    node_sl *node2 = node_sl_new();
    node_sl *node3 = node_sl_new();

    node1->val = mem_get( 10 );
    node2->val = mem_get( 10 );
    node3->val = mem_get( 10 );

    list_sl_add_beg( &list, &node1 );
    list_sl_add_beg( &list, &node2 );
    list_sl_add_beg( &list, &node3 );

    list_sl_destroy( &list );

    assert( list == NULL );

    fprintf( stderr, "OK\n" );
}


void test_node_sl_destroy()
{
    fprintf( stderr, "   Testing node_sl_destroy ... " );

    node_sl *node = NULL;
    char    *str  = NULL;

    str  = mem_get( 1000000000 );

    node = node_sl_new();

    node->val = str;

    node_sl_destroy( &node );

    assert( node == NULL );

    fprintf( stderr, "OK\n" );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DOUBLY LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void test_list_dl_new()
{
    fprintf( stderr, "   Testing list_dl_new ... " );

    list_dl *list = NULL;

    list = list_dl_new();

    assert( list->first == NULL );
    assert( list->last  == NULL );

    fprintf( stderr, "OK\n" );
}


void test_node_dl_new()
{
    fprintf( stderr, "   Testing node_dl_new ... " );

    node_dl *node = NULL;

    node = node_dl_new();
    
    assert( node->next == NULL );
    assert( node->prev == NULL );
    assert( node->val  == NULL );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_add_beg()
{
    fprintf( stderr, "   Testing list_dl_add_beg ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );

    assert( strcmp( list->first->val, "TEST1" ) == 0 );

    list_dl_add_beg( &list, &node2 );

    assert( strcmp( list->first->val, "TEST2" ) == 0 );

    list_dl_add_beg( &list, &node3 );

    assert( strcmp( list->first->val, "TEST3" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_add_end()
{
    fprintf( stderr, "   Testing list_dl_add_end ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_end( &list, &node1 );

    assert( strcmp( list->last->val, "TEST1" ) == 0 );

    list_dl_add_end( &list, &node2 );

    assert( strcmp( list->last->val, "TEST2" ) == 0 );

    list_dl_add_end( &list, &node3 );

    assert( strcmp( list->last->val, "TEST3" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_add_before()
{
    fprintf( stderr, "   Testing list_dl_add_before ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );

    assert( strcmp( list->first->val, "TEST1" ) == 0 );

    list_dl_add_before( &list, &node1, &node2 );

    assert( strcmp( list->first->val, "TEST2" ) == 0 );

    list_dl_add_before( &list, &node1, &node3 );

    assert( strcmp( list->first->val, "TEST2" ) == 0 );

    list_dl_add_before( &list, &node2, &node3 );

    assert( strcmp( list->first->val, "TEST3" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_add_after()
{
    fprintf( stderr, "   Testing list_dl_add_after ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );

    assert( strcmp( list->first->val, "TEST1" ) == 0 );

    list_dl_add_after( &list, &node1, &node2 );

    assert( strcmp( list->last->val, "TEST2" ) == 0 );

    list_dl_add_after( &list, &node1, &node3 );

    assert( strcmp( list->last->val, "TEST2" ) == 0 );

    list_dl_add_after( &list, &node2, &node3 );

    assert( strcmp( list->last->val, "TEST3" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_remove()
{
    fprintf( stderr, "   Testing list_dl_remove ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );

    list_dl_add_after( &list, &node1, &node2 );
    list_dl_add_after( &list, &node2, &node3 );

    list_dl_remove( &list, &node3 );
    assert( strcmp( list->last->val, "TEST2" ) == 0 );

    list_dl_remove( &list, &node2 );
    assert( strcmp( list->last->val, "TEST1" ) == 0 );

    list_dl_remove( &list, &node1 );

    assert( list->first == NULL );
    assert( list->last  == NULL );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_print()
{
    fprintf( stderr, "   Testing list_dl_print ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );
    list_dl_add_beg( &list, &node2 );
    list_dl_add_beg( &list, &node3 );

    // list_dl_print( list );

    fprintf( stderr, "OK\n" );
}


void test_list_dl_destroy()
{
    fprintf( stderr, "   Testing list_dl_destroy ... " );

    list_dl *list  = list_dl_new();
    node_dl *node1 = node_dl_new();
    node_dl *node2 = node_dl_new();
    node_dl *node3 = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &list, &node1 );
    list_dl_add_beg( &list, &node2 );
    list_dl_add_beg( &list, &node3 );

//    list_dl_print( list );

    list_dl_destroy( &list );

    assert( list == NULL );

    fprintf( stderr, "OK\n" );
}


void test_node_dl_destroy()
{
    fprintf( stderr, "   Testing node_dl_destroy ... " );

    node_dl *node = NULL;
    char    *str  = NULL;

    str  = mem_get( 1000000000 );

    node = node_dl_new();

    node->val = str;

    node_dl_destroy( &node );

    assert( node == NULL );

    fprintf( stderr, "OK\n" );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> GENERIC LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


void test_list_count()
{
    fprintf( stderr, "   Testing list_count ... " );

    /* Singly linked list. */

    char    *array[3] = { "test1", "test2", "test3" };
    list_sl *sllist   = NULL;
    node_sl *node     = NULL;
    node_sl *new_node = NULL;
    int      i        = 0;

    sllist   = list_sl_new();
    new_node = node_sl_new();

    new_node->val = array[ 0 ];

    list_sl_add_beg( &sllist, &new_node );

    node = new_node;

    for ( i = 1; i < 3; i++ )
    {
        new_node = node_sl_new();

        new_node->val = array[ i ];

        list_sl_add_after( &node, &new_node );

        node = new_node;
    }

    assert( list_count( sllist ) == 3 );

    /* Doubly linked list. */

    list_dl *dllist = list_dl_new();
    node_dl *node1  = node_dl_new();
    node_dl *node2  = node_dl_new();
    node_dl *node3  = node_dl_new();

    node1->val = "TEST1";
    node2->val = "TEST2";
    node3->val = "TEST3";

    list_dl_add_beg( &dllist, &node1 );
    list_dl_add_beg( &dllist, &node2 );
    list_dl_add_beg( &dllist, &node3 );

    assert( list_count( dllist ) == 3 );

    fprintf( stderr, "OK\n" );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


