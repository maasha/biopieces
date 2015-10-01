#include <stdio.h>
#include "common.h"
#include "seq.h"

int main()
{
    char seq[] = "ACGACATCGGACTGACactgactgacatgcactg";

    printf( "seq type: %s\n", seq_guess_type( seq ) );

    printf( "before revcomp: %s\n", seq );

    revcomp_nuc( seq );

    printf( "after revcomp:  %s\n", seq );

    return 0;
}
