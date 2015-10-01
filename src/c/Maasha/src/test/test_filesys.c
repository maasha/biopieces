/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "filesys.h"

//#define TEST_FILE "/Users/m.hansen/DATA/genomes/hg18/hg18.fna"
#define TEST_FILE "test/test_files/test.fna"
#define TEST_SIZE 1

static void test_read_open();
static void test_write_open();
static void test_append_open();
static void test_close_stream();
static void test_file_read();
static void test_file_unlink();
static void test_file_rename();
static void test_buffer_new();
static void test_buffer_read();
static void test_buffer_getc();
static void test_buffer_ungetc();
static void test_buffer_gets();
static void test_buffer_ungets();
static void test_buffer_new_size();
static void test_buffer_resize();
static void test_buffer_move();
static void test_buffer_destroy();
static void test_buffer_print();


int main()
{
    fprintf( stderr, "Running all tests for filesys.c\n" );

    test_read_open();
    test_write_open();
    test_append_open();
    test_close_stream();
    test_file_read();
    test_file_unlink();
    test_file_rename();
    test_buffer_new();
    test_buffer_read();
    test_buffer_getc();
    test_buffer_ungetc();
    test_buffer_gets();
    test_buffer_ungets();
    test_buffer_new_size();
    test_buffer_resize();
    test_buffer_move();
    test_buffer_destroy();
    test_buffer_print();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


void test_read_open()
{
    fprintf( stderr, "   Testing read_open ... " );

    FILE *fp;

    // fp = read_open( "/tmp/asdf" );
    // fp = read_open( "/private/etc/ssh_host_rsa_key" );
    fp = read_open( "/dev/null" );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_write_open()
{
    fprintf( stderr, "   Testing write_open ... " );

    FILE *fp;

    // fp = write_open( "/tmp/asdf" );
    // fp = write_open( "/private/etc/ssh_host_rsa_key" );
    fp = write_open( "/dev/null" );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_append_open()
{
    fprintf( stderr, "   Testing append_open ... " );

    FILE *fp;

    //fp = append_open( "/tmp/asdf" );
    //fp = append_open( "/private/etc/ssh_host_rsa_key" );
    fp = append_open( "/dev/null" );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_close_stream()
{
    fprintf( stderr, "   Testing close_stream ... " );

    FILE *fp;

    fp = read_open( "/dev/null" );

    close_stream( fp );

    fprintf( stderr, "OK\n" );
}


void test_file_read()
{
    fprintf( stderr, "   Testing file_read ... " );

    char *file   = "/tmp/test_file_read";
    char *str1   = "MARTIN";
    char *str2   = NULL;
    FILE *fp1    = NULL;
    FILE *fp2    = NULL;
    size_t len   = strlen( str1 );
    size_t num   = 0;

    fp1 = write_open( file );
    fprintf( fp1, str1 );
    close_stream( fp1 );

    fp2 = read_open( file );

    num = file_read( fp2, &str2, len );

    close_stream( fp2 );

    assert( num == len );
    assert( strcmp( str1, str2 ) == 0 );

    fprintf( stderr, "OK\n" );
}


void test_file_unlink()
{
    fprintf( stderr, "   Testing file_unlink ... " );

    char *test_file = "/tmp/test";
    FILE *fp;

    fp = write_open( test_file );

    close_stream( fp );

    //file_unlink( "" );
    //file_unlink( "/dev/null" );
    //file_unlink( "/tmp/" );
    //file_unlink( "/private/etc/ssh_host_rsa_key" );
    file_unlink( test_file );

    fprintf( stderr, "OK\n" );
}


void test_file_rename()
{
    fprintf( stderr, "   Testing file_rename ... " );

    char *file_before = "/tmp/before";
    char *file_after  = "/tmp/after";

    FILE *fp;
    
    fp = write_open( file_before );

    close_stream( fp );

    //file_rename( file_after, file_after );
    file_rename( file_before, file_before );
    file_rename( file_before, file_after );

    //file_unlink( file_before );
    file_unlink( file_after );

    fprintf( stderr, "OK\n" );
}


void test_buffer_new()
{
    fprintf( stderr, "   Testing buffer_new ... " );

    char        *file   = "/tmp/test_buffer_new";
    char        *str    = "MARTIN";
    FILE        *fp     = NULL;
    size_t       size   = 10;
    size_t       num    = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );
    fprintf( fp, str );
    close_stream( fp );

    num = buffer_new( file, &buffer, size );

    assert( num == strlen( str ) );
    assert( buffer->token_pos   == 0 );
    assert( buffer->buffer_pos  == 0 );
    assert( buffer->buffer_end  == 6 );
    assert( buffer->buffer_size == size );
    assert( buffer->eof         == TRUE );
    assert( strcmp( str, buffer->str ) == 0 );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_read()
{
    fprintf( stderr, "   Testing buffer_read ... " );

    char        *file   = "/tmp/test_buffer_read";
    char        *str    = "MARTIN";
    FILE        *fp     = NULL;
    size_t       size   = 2;
    size_t       num    = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );
    fprintf( fp, str );
    close_stream( fp );

    num = buffer_new( file, &buffer, size );

    assert( num == 2 );
    assert( buffer->token_pos   == 0 );
    assert( buffer->buffer_pos  == 0 );
    assert( buffer->buffer_end  == 2 );
    assert( buffer->buffer_size == size );
    assert( buffer->eof         == FALSE );
    assert( strcmp( buffer->str, "MA" ) == 0 );

    buffer->buffer_pos += 2;

    num = buffer_read( &buffer );

    assert( num == 2 );
    assert( buffer->token_pos   == 0 );
    assert( buffer->buffer_pos  == 2 );
    assert( buffer->buffer_end  == 4 );
    assert( buffer->buffer_size == size );
    assert( buffer->eof         == FALSE );
    assert( strcmp( buffer->str, "MART" ) == 0 );

    buffer->buffer_pos += 2;

    num = buffer_read( &buffer );

    assert( num == 2 );
    assert( buffer->token_pos   == 0 );
    assert( buffer->buffer_pos  == 4 );
    assert( buffer->buffer_end  == 6 );
    assert( buffer->buffer_size == size );
    assert( buffer->eof         == FALSE );
    assert( strcmp( buffer->str, "MARTIN" ) == 0 );

    buffer->buffer_pos += 2;

    num = buffer_read( &buffer );

    assert( num == 0 );
    assert( buffer->token_pos   == 0 );
    assert( buffer->buffer_pos  == 6 );
    assert( buffer->buffer_end  == 6 );
    assert( buffer->buffer_size == size );
    assert( buffer->eof         == TRUE );
    assert( strcmp( buffer->str, "MARTIN" ) == 0 );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );
    fprintf( stderr, "OK\n" );
}


void test_buffer_getc()
{
    fprintf( stderr, "   Testing buffer_getc ... " );

    char        *file   = "/tmp/test_buffer_getc";
    char        *str    = "MARTIN";
    FILE        *fp     = NULL;
    size_t       size   = strlen( str );
    size_t       i      = 0;
    char         c      = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );
    fprintf( fp, str );
    close_stream( fp );

    buffer_new( file, &buffer, size );

    for ( i = 0; str[ i ]; i++ )
    {
        c = buffer_getc( buffer );

        assert( str[ i ] == c );
    }

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_ungetc()
{
    fprintf( stderr, "   Testing buffer_ungetc ... " );

    char        *file   = "/tmp/test_buffer_ungetc";
    char        *str    = "MARTIN";
    FILE        *fp     = NULL;
    char         c      = '\0';
    size_t       i      = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );

    fprintf( fp, str );

    close_stream( fp );

    buffer_new( file, &buffer, TEST_SIZE );

    c = buffer_getc( buffer );

    assert( c == 'M' );

    buffer_ungetc( buffer );

    i = 0;

    while ( ( c = buffer_getc( buffer ) ) != EOF )
    {
        assert( c == str[ i ] );

        i++;
    }

    assert( c == EOF );

    buffer_ungetc( buffer );

    c = buffer_getc( buffer );

    assert( c == 'N' );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_gets()
{
    fprintf( stderr, "   Testing buffer_gets ... " );

    char        *file   = "/tmp/test_buffer_gets";
    char        *out    = "MARTIN\nASSER\nHANSEN\n";
    FILE        *fp     = NULL;
    char        *str    = NULL;
    size_t       size   = 1;
    size_t          i   = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );
    fprintf( fp, out );
    close_stream( fp );

    buffer_new( file, &buffer, size );

    i = 0;

    while( ( str = buffer_gets( buffer ) ) != NULL )
    {
        if ( i == 0 ) {
            assert( strcmp( str, "MARTIN\n" ) == 0 );
        } else if ( i == 1 ) {
            assert( strcmp( str, "ASSER\n" ) == 0 );
        } else if ( i == 2 ) {
            assert( strcmp( str, "HANSEN\n" ) == 0 );
        }

        i++;
    }

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_ungets()
{
    fprintf( stderr, "   Testing buffer_ungets ... " );

    char        *file   = "/tmp/test_buffer_ungets";
    char        *out    = "MARTIN\nASSER\nHANSEN\n";
    FILE        *fp     = NULL;
    size_t       size   = 1;
    char        *str1   = NULL;
    char        *str2   = NULL;
    file_buffer *buffer = NULL;

    fp = write_open( file );

    fprintf( fp, out );

    close_stream( fp );

    buffer_new( file, &buffer, size );

    str1 = buffer_gets( buffer );

    buffer_ungets( buffer );

    str2 = buffer_gets( buffer );

    assert( strcmp( str1, str2 ) == 0 );

    while ( ( str1 = buffer_gets( buffer ) ) != NULL )
    {
    }
    
    buffer_ungets( buffer );

    str1 = buffer_gets( buffer );

    assert( ( strcmp( str1, "HANSEN\n" ) ) == 0 );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_new_size()
{
    fprintf( stderr, "   Testing buffer_new_size ... " );
    
    char        *file     = "/tmp/test_buffer_new_size";
    char        *str      = "X";
    size_t       size     = 1;
    FILE        *fp       = NULL;
    file_buffer *buffer   = NULL;

    fp = write_open( file );
    fprintf( fp, str );
    close_stream( fp );

    buffer_new( file, &buffer, size );

    buffer_new_size( buffer, 201048577 );

    assert( buffer->buffer_size == 268435456 );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_resize()
{
    fprintf( stderr, "   Testing buffer_resize ... " );

    char        *file   = "/tmp/test_buffer_resize";
    char        *str    = "ABC";
    FILE        *fp     = NULL;
    size_t       size   = 1;
    size_t       i      = 0;
    char         c      = 0;
    file_buffer *buffer = NULL;

    fp = write_open( file );
    fprintf( fp, str );
    close_stream( fp );

    buffer_new( file, &buffer, size );

    i = 0;

    while ( ( c = buffer_getc( buffer ) ) != EOF )
    {
        assert( c == str[ i ] );
        i++;
    }

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_move()
{
    fprintf( stderr, "   Testing buffer_move ... " );

    char        *file     = "/tmp/test_buffer_move";
    char        *str      = "ABCDEFG";
    size_t       size     = strlen( str );
    size_t       new_size = 0;
    size_t       move     = 3;
    FILE        *fp       = NULL;
    file_buffer *buffer   = NULL;

    fp = write_open( file );

    fprintf( fp, str );

    close_stream( fp );

    buffer_new( file, &buffer, size );

    new_size = buffer_move( buffer, size, move );

    assert( new_size == strlen( buffer->str ) );
    assert( strcmp( buffer->str, "DEFG" ) == 0 );

    new_size = buffer_move( buffer, new_size, move );

    assert( new_size == strlen( buffer->str ) );
    assert( strcmp( buffer->str, "G" ) == 0 );

    buffer_destroy( &buffer );

    buffer = NULL;

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_destroy()
{
    fprintf( stderr, "   Testing buffer_destroy ... " );

    char        *file   = "/tmp/test_buffer_destroy";
    char        *str    = "X";
    FILE        *fp     = NULL;
    file_buffer *buffer = NULL;

    fp = write_open( file );

    fprintf( fp, str );

    close_stream( fp );

    buffer_new( file, &buffer, TEST_SIZE );

    buffer_destroy( &buffer );

    file_unlink( file );

    fprintf( stderr, "OK\n" );
}


void test_buffer_print()
{
    fprintf( stderr, "   Testing buffer_print ... " );

    file_buffer *buffer = NULL;

    buffer_new( TEST_FILE, &buffer, TEST_SIZE );

//    buffer_print( buffer );

    buffer_destroy( &buffer );

    buffer = NULL;

    fprintf( stderr, "OK\n" );
}

