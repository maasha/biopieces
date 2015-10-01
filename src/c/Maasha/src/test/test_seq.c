#include "common.h"
#include "mem.h"
#include "seq.h"

static void test_seq_new();
static void test_seq_uppercase();
static void test_seq_destroy();


int main()
{
    fprintf( stderr, "Running all tests for seq.c\n" );

    test_seq_new();
    test_seq_uppercase();
    test_seq_destroy();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_seq_new()
{
    fprintf( stderr, "   Testing seq_new ... " );

    seq_entry *entry        = NULL;
    size_t     max_seq_name = MAX_SEQ_NAME;
    size_t     max_seq      = MAX_SEQ;

    entry = seq_new( max_seq_name, max_seq );

    assert( entry->seq_name != NULL );
    assert( entry->seq      != NULL );
    assert( entry->seq_len  == 0 );

    seq_destroy( entry );

    fprintf( stderr, "OK\n" );
}


void test_seq_uppercase()
{
    fprintf( stderr, "   Testing seq_uppercase ... " );

    char   seq[] = "atcg";

    seq_uppercase( seq );

    assert( strcmp( seq, "ATCG" ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_seq_destroy()
{
    fprintf( stderr, "   Testing seq_destroy ... " );

    seq_entry *entry        = NULL;
    size_t     max_seq_name = MAX_SEQ_NAME;
    size_t     max_seq      = MAX_SEQ;

    entry = seq_new( max_seq_name, max_seq );

    assert( entry->seq_name != NULL );
    assert( entry->seq      != NULL );
    assert( entry->seq_len  == 0 );

    seq_destroy( entry );

    fprintf( stderr, "OK\n" );
}


