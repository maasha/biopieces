#include <stdio.h>
#include "common.h"
#include "list.h"


int main()
{
    char string[] = "FOO\tBAR\tFOOBAR\n";

    struct list *fields;

    chomp( string );

    split( string, '\t', &fields ); 

    list_print( fields );

    return 0;
}
