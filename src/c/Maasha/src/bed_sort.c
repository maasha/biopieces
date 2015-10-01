/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "list.h"
#include "ucsc.h"

static void usage()
{
    fprintf( stderr, 
        "\n"
        "bed_sort - sorts a BED file.\n"
        "\n"
        "Usage: bed_sort [options] <BED file>\n"
        "\n"
        "Options:\n"
        "   [-s <int> | --sort <int>]   # 1: chr AND chr_beg.\n"
        "                               # 2: chr AND strand AND chr_beg.\n"
        "                               # 3: chr_beg.\n"
        "                               # 4: strand AND chr_beg.\n"
        "   [-c <int> | --cols <int>]   # Number of columns to read (default all).\n"
        "   [-d <dir> | --dir <dir> ]   # Directory to use for file bound sorting.\n"
        "\n"
        "Examples:\n"
        "   bed_sort test.bed > test.bed.sort\n"
        "\n"
        );

    exit( EXIT_FAILURE );
}


static struct option longopts[] = {
    { "sort",  required_argument, NULL, 's' },
    { "cols",  required_argument, NULL, 'c' },
    { "dir",   required_argument, NULL, 'd' },
    { NULL,    0,                 NULL,  0  }
};


int main( int argc, char *argv[] )
{
    int      opt     = 0;
    int      sort    = 1;
    int      cols    = 0;
    char    *dir     = NULL;
    char    *file    = NULL;
    list_sl *entries = NULL;

    while ( ( opt = getopt_long( argc, argv, "n:l", longopts, NULL ) ) != -1 )
    {
        switch ( opt ) {
            case 's': sort = strtol( optarg, NULL, 0 ); break;
            case 'c': cols = strtol( optarg, NULL, 0 ); break;
            case 'd': dir  = optarg;                    break;          
            default:                                    break;
        }
    }

    fprintf( stderr, "sort: %d  cols: %d   dir: %s\n", sort, cols, dir );

    argc -= optind;
    argv += optind;

    if ( sort < 1 || sort > 4 )
    {
        fprintf( stderr, "ERROR: argument to --sort must be 1, 2, 3 or 4 - not: %d\n", sort );
        abort();
    }

    if ( cols != 0 && cols != 3 && cols != 4 && cols != 5 && cols != 6 && cols != 12 )
    {
        fprintf( stderr, "ERROR: argument to --cols must be 3, 4, 5, 6 or 12 - not: %d\n", cols );
        abort();
    }

    if ( ( sort == 2 || sort == 4 ) && ( cols > 0 && cols < 6 ) )
    {
        fprintf( stderr, "ERROR: cannot sort on strand with cols (%d) less than 6\n", cols );
        abort();
    }

    if ( dir != NULL )
    {
        fprintf( stderr, "ERROR: directory: %s does not exists\n", dir );
        abort();
    }

    if ( argc < 1 ) {
        usage();
    }

    file = argv[ argc - 1 ];

    entries = bed_entries_get( file, cols );

    switch ( sort )
    {
        case 1: list_sl_sort( &entries, cmp_bed_sort_chr_beg );        break;
        case 2: list_sl_sort( &entries, cmp_bed_sort_chr_strand_beg ); break;
        case 3: list_sl_sort( &entries, cmp_bed_sort_beg );            break;
        case 4: list_sl_sort( &entries, cmp_bed_sort_strand_beg );     break;
        default: break;
    }

    bed_entries_put( entries, cols );

    return EXIT_SUCCESS;
}
