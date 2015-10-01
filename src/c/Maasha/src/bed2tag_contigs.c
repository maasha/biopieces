#include "common.h"
#include "mem.h"
#include "list.h"
#include "ucsc.h"
#include "hash.h"
#include "barray.h"

#define BED_COLS    5
#define HASH_SIZE   8
#define BARRAY_SIZE ( 1 << 16 )


static void usage()
{
    fprintf( stderr,
        "\n"
        "bed2tag_contigs assembles overlapping BED type entries into tag\n"
        "contigs if the clone count (assumed to be appended to the Q_ID field) of each\n"
        "entry is higher than the times the entry was mapped to the genome (this\n"
        "information is assumed to be the SCORE field). A tag contig score is calculated\n"
        "as the highest density of overlapping tags (assuming that these tags are\n"
        "uniquely mapping):\n"
        "\n"
        "   tags         ----------- Q_ID: ID_2\n"
        "                  ------------- Q_ID: ID_3\n"
        "                      --------------- Q_ID: ID_1\n"
        "                                 ------------ Q_ID: ID_2\n"
        "   tag contig   =============================\n"   
        "   scores       22555566666444411333322222222\n"
        "\n"
        "   tag contig score = 6\n"
        "\n"
        "Thus, tags are only assembled into tag contigs if their expression level is\n"
        "higher than their repetitiveness; a tag sequenced 10 times, i.e. with a clone\n"
        "count of 10, will only be considered if was found in the genome fewer than 10\n"
        "times, i.e. have a SCORE below 10.\n"
        "\n"
        "A forthrunning number prefixed with TC is added as Q_ID for the resulting tag\n"
        "contigs.\n"
        "\n"
        "Usage: bed2tag_contigs < <BED file(s)> > <BED file>\n\n"
    );

    exit( EXIT_FAILURE );
}


long get_score( char *str )
{
    /* Martin A. Hansen, December 2008. */

    /* Extract the last decimal number after _ 
     * in a string and return that. If no number
     * was found return 1. */

    char *c;
    long  score = 1;

    if ( ( c = strrchr( str, '_' ) ) != NULL ) {
        score = strtol( &c[ 1 ], NULL , 10 );
    }

    return score;
}


int main( int argc, char *argv[] )
{
    bed_entry *entry    = NULL;
    hash      *chr_hash = NULL;
    hash_elem *bucket   = NULL;
    barray    *ba       = NULL;
    uint       score    = 0;
    size_t     i        = 0;
    char      *chr      = NULL;
    size_t     beg      = 0;
    size_t     end      = 0;
    size_t     pos      = 0;
    uint       max      = 0;
    size_t     id       = 0;

    entry    = bed_entry_new( BED_COLS );
    chr_hash = hash_new( HASH_SIZE );

    if ( isatty( fileno( stdin ) ) ) {
        usage();
    }
    
    while ( ( bed_entry_get( stdin, &entry ) ) )
    {
//        bed_entry_put( entry, entry->cols );

        ba = ( barray * ) hash_get( chr_hash, entry->chr );

        if ( ba == NULL )
        {
            ba = barray_new( BARRAY_SIZE );

            hash_add( chr_hash, entry->chr, ba );
        }

        score = ( uint ) get_score( entry->q_id );

        if ( score >= entry->score && entry->score > 0 ) {
            barray_interval_inc( ba, entry->chr_beg, entry->chr_end - 1, ( uint ) ( score / entry->score ) );
        }
    }

//    barray_print( ba );

    for ( i = 0; i < chr_hash->table_size; i++ )
    {
        for ( bucket = chr_hash->table[ i ]; bucket != NULL; bucket = bucket->next )
        {
            chr = bucket->key;
            ba  = ( barray * ) bucket->val;
        
            pos = 0;

            while ( barray_interval_scan( ba, &pos, &beg, &end ) )
            {
                max = barray_interval_max( ba, beg, end );

//                printf( "chr: %s   pos: %zu   beg: %zu   end: %zu   max: %hd\n", chr, pos, beg, end, max );

                printf( "%s\t%zu\t%zu\t%s_%08zu\t%u\n", chr, beg, end + 1, chr, id, ( uint ) max );

                id++;
            }
        }
    }

    return EXIT_SUCCESS;
}
