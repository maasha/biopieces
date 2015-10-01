/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "filesys.h"
#include "mem.h"
#include "seq.h"
#include "fasta.h"

#define TEST_FILE1 "test/test_files/test.fna"
#define TEST_FILE2 "/Users/m.hansen/DATA/genomes/hg18/hg18.fna"
#define TEST_COUNT 10
#define TEST_SIZE  10

static void test_fasta_get_entry();
static void test_fasta_put_entry();


int main()
{
    fprintf( stderr, "Running all tests for fasta.c\n" );

    test_fasta_get_entry();
    test_fasta_put_entry();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_fasta_get_entry()
{
    fprintf( stderr, "   Testing fasta_get_entry ... " );

    FILE *fp            = NULL;
    seq_entry *entry    = NULL;
    size_t max_seq_name = MAX_SEQ_NAME;
    size_t max_seq      = MAX_SEQ;

    fp = read_open( TEST_FILE1 );

    entry = seq_new( max_seq_name, max_seq );

    while ( ( fasta_get_entry( fp, &entry ) != FALSE ) ) {
//        printf( "seq_name: %s seq_len: %zu\n", entry->seq_name, entry->seq_len );
    }

    seq_destroy( entry );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_fasta_put_entry()
{
    fprintf( stderr, "   Testing fasta_put_entry ... " );

    FILE *fp            = NULL;
    seq_entry *entry    = NULL;
    size_t max_seq_name = MAX_SEQ_NAME;
    size_t max_seq      = MAX_SEQ;

    fp = read_open( TEST_FILE1 );

    entry = seq_new( max_seq_name, max_seq );

    while ( ( fasta_get_entry( fp, &entry ) != FALSE ) ) {
//        fasta_put_entry( entry );
    }

    seq_destroy( entry );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


