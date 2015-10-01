#include <stdio.h>
#include "common.h"
#include "list.h"

int main()
{
//    struct list *list_pt;
//
//    char *string1 = "Hello";
//    char *string2 = "World";
//
//    list_add( &list_pt, string1 );
//    list_add( &list_pt, string2 );
//    
//    if ( list_exists( list_pt, "World" ) ) {
//        printf( "Found\n" );
//    } else {
//        printf( "Not Found\n" );
//    }
//
//    list_free( &list_pt );

    struct list_int *list_int_pt;

    int i = 4;
    int j = 12;

    list_add_int( &list_int_pt, i );
    list_add_int( &list_int_pt, j );

    if ( list_exists_int( list_int_pt, j ) ) {
        printf( "Found\n" );
    } else {
        printf( "Not Found\n" );
    }

    list_free( &list_int_pt );

    return 0;
}


