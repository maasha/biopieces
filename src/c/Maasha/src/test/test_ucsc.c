#include "common.h"
#include "filesys.h"
#include "list.h"
#include "ucsc.h"

static void test_bed_entry_new();
static void test_bed_entry_get();
static void test_bed_entries_get();
static void test_bed_entries_destroy();
static void test_bed_entries_sort();
static void test_bed_file_sort_beg();
static void test_bed_file_sort_strand_beg();
static void test_bed_file_sort_chr_beg();
static void test_bed_file_sort_chr_strand_beg();


int main()
{
    fprintf( stderr, "Running all tests for ucsc.c\n" );

    test_bed_entry_new();
    test_bed_entry_get();
    test_bed_entries_get();
    test_bed_entries_destroy();
    test_bed_entries_sort();
    test_bed_file_sort_beg();
    test_bed_file_sort_strand_beg();
    test_bed_file_sort_chr_beg();
    test_bed_file_sort_chr_strand_beg();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_bed_entry_new()
{
    fprintf( stderr, "   Testing bed_entry_new ... " );

    bed_entry *entry = NULL;
    
    entry = bed_entry_new( 3 );

    assert( entry->cols    == 3 );
    assert( entry->chr_beg == 0 );
    assert( entry->chr_end == 0 );

    fprintf( stderr, "OK\n" );
}


void test_bed_entry_get()
{
    fprintf( stderr, "   Testing bed_entry_get ... " );

    char      *path  = "test/test_files/test12.bed";
    FILE      *fp    = NULL;
    bed_entry *entry = NULL;

    fp = read_open( path );

    entry = bed_entry_new( 12 );

    while ( ( bed_entry_get( fp, &entry ) ) )
    {
//        bed_entry_put( entry, 3 );
    }

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_bed_entries_get()
{
    fprintf( stderr, "   Testing bed_entries_get ... " );

    char    *path    = "test/test_files/test12.bed";
    list_sl *entries = NULL;
    
    entries = bed_entries_get( path, 3 );

//    bed_entries_put( entries, 3 );

    fprintf( stderr, "BAD!!!\n" );
}


void test_bed_entries_destroy()
{
    fprintf( stderr, "   Testing bed_entries_destroy ... " );

    char    *path    = "test/test_files/test12.bed";
    list_sl *entries = NULL;
    
    entries = bed_entries_get( path, 3 );

//    bed_entries_destroy( &entries );

//    assert( entries == NULL );

    fprintf( stderr, "BAD!!!\n" );
}


void test_bed_entries_sort()
{
    fprintf( stderr, "   Testing bed_entries_sort ... " );

    char    *path    = "test/test_files/test12.bed";
    list_sl *entries = NULL;
    
    entries = bed_entries_get( path, 0 );

    list_sl_sort( &entries, cmp_bed_sort_chr_beg );
    list_sl_sort( &entries, cmp_bed_sort_chr_strand_beg );

//    bed_entries_put( entries, 0 );

    fprintf( stderr, "OK\n" );
}


void test_bed_file_sort_beg()
{
    fprintf( stderr, "   Testing bed_file_sort_beg ... " );

//    char    *path    = "test/test_files/test12.bed";

//    bed_file_sort_beg( path, 3 );

    fprintf( stderr, "OK\n" );
}


void test_bed_file_sort_strand_beg()
{
    fprintf( stderr, "   Testing bed_file_sort_strand_beg ... " );

//    char    *path    = "test/test_files/test12.bed";

//    bed_file_sort_strand_beg( path, 6 );

    fprintf( stderr, "OK\n" );
}


void test_bed_file_sort_chr_beg()
{
    fprintf( stderr, "   Testing bed_file_sort_chr_beg ... " );

//    char    *path    = "test/test_files/test12.bed";

//    bed_file_sort_chr_beg( path, 6 );

    fprintf( stderr, "OK\n" );
}


void test_bed_file_sort_chr_strand_beg()
{
    fprintf( stderr, "   Testing bed_file_sort_chr_strand_beg ... " );

//    char    *path    = "test/test_files/test12.bed";

//    bed_file_sort_chr_strand_beg( path, 6 );

    fprintf( stderr, "OK\n" );
}


