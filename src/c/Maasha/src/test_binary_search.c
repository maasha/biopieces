#include <stdio.h>
#include "common.h"

int main()
{
    int size = 10;
    int val  = 40;
    int array[ 10 ] = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };

    if ( binary_search_array( array, size, val ) ) {
        printf( "val->%d found in array\n", val );
    } else {
        printf( "val->%d NOT found in array\n", val );
    }

    return 0;
}
