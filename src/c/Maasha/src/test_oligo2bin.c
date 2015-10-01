#include <stdio.h>
#include "common.h"
#include "seq.h"


int main()
{
    int bin;

              /*  123456789012345 */
    char *word = "GGGGGGGGGGGGGGG";
    
    bin = oligo2bin( word );

    printf( "bin->%d\n", bin );
    
    return 0;
}
