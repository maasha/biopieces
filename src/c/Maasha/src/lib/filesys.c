/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "filesys.h"


FILE *read_open( char *file )
{
    /* Martin A. Hansen, November 2005 */

    /* Unit test done. */

    /* Given a file name, read-opens the file, */
    /* and returns a file pointer. */
    
    FILE *fp;

    if ( ( fp = fopen( file, "r" ) ) == NULL )
    {
        fprintf( stderr, "ERROR: Could not read-open file '%s': %s\n", file, strerror( errno ) );
        abort();
    }

    return fp;
}


FILE *write_open( char *file )
{
    /* Martin A. Hansen, November 2005 */

    /* Unit test done. */

    /* Given a file name, write-opens the file, */
    /* and returns a file pointer. */
    
    FILE *fp;

    if ( ( fp = fopen( file, "w" ) ) == NULL )
    {
        fprintf( stderr, "ERROR: Could not write-open file '%s': %s\n", file, strerror( errno ) );
        abort();
    }

    return fp;
}


FILE *append_open( char *file )
{
    /* Martin A. Hansen, November 2005 */

    /* Unit test done. */

    /* Given a file name, append-opens the file, */
    /* and returns a file pointer. */
    
    FILE *fp;

    if ( ( fp = fopen( file, "a" ) ) == NULL )
    {
        fprintf( stderr, "ERROR: Could not append-open file '%s': %s\n", file, strerror( errno ) );
        abort();
    }

    return fp;
}


void close_stream( FILE *fp )
{
    /* Martin A. Hansen, May 2008 */

    /* Unit test done. */

    /* Closes a stream or file associated with a given file pointer. */

    if ( ( fclose( fp ) ) != 0 )
    {
        fprintf( stderr, "ERROR: Could not close stream: %s\n", strerror( errno ) );    
        abort();
    }
}


size_t file_read( FILE *fp, char **string_ppt, size_t len )
{
    /* Martin A. Hansen, June 2008 */

    /* Read in len number of bytes from the current position of a */
    /* file pointer into a string that is allocated and null terminated. */
    /* The number of read chars is returned. */

    char   *string = *string_ppt;
    size_t  num    = 0;

    assert( len > 0 );

    string = mem_get( len + 1 );

    num = fread( string, 1, len, fp );

    if ( ferror( fp ) != 0 )
    {
        fprintf( stderr, "ERROR: file_read failed\n" );
        abort();
    }

    string[ num ] = '\0';

    *string_ppt = string;

    return num;
}


void file_unlink( char *file )
{
    /* Martin A. Hansen, June 2008 */

    /* Unit test done. */

    /* Delete a file. */

    if ( unlink( file ) == -1 )
    {
        fprintf( stderr, "ERROR: Could not unlink file '%s': %s\n", file, strerror( errno ) );    
        abort();
    }
}


void file_rename( char *old_name, char *new_name )
{
    /* Martin A. Hansen, June 2008 */

    /* Unit test done. */

    /* Rename a file. */

    if ( rename( old_name, new_name ) != 0 )
    {
        fprintf( stderr, "ERROR: Could not rename file '%s' -> '%s': %s\n", old_name, new_name, strerror( errno ) );

        abort();
    }
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FILE BUFFER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


size_t buffer_new( char *file, file_buffer **buffer_ppt, size_t size )
{
    /* Martin A. Hansen, June 2008 */

    /* Opens a file for reading and loads a new buffer.*/
    /* The number of read chars is returned. */

    file_buffer *buffer = *buffer_ppt;
    FILE        *fp     = NULL;
    size_t       num    = 0;

    buffer = mem_get( sizeof( file_buffer ) );

    fp = read_open( file );

    buffer->fp          = fp;
    buffer->str         = NULL;
    buffer->token_pos   = 0;
    buffer->token_len   = 0;
    buffer->buffer_pos  = 0;
    buffer->buffer_end  = 0;
    buffer->buffer_size = size;
    buffer->eof         = FALSE;

    num = buffer_read( &buffer );

    *buffer_ppt = buffer;

    return num;
}


size_t buffer_read( file_buffer **buffer_ppt )
{
    /* Martin A. Hansen, June 2008 */

    /* Read in buffer->buffer_size bytes from file and appends to buffer string. */
 
    file_buffer *buffer  = *buffer_ppt;
    char        *str     = NULL;
    size_t       str_len = 0;
    size_t       new_end = 0;
    size_t       num     = 0;

    num = file_read( buffer->fp, &str, buffer->buffer_size );

    if ( num != 0 )
    {
        str_len = num;
        new_end = buffer->buffer_end + str_len;

        buffer->str = mem_resize( buffer->str, new_end );

        memcpy( &buffer->str[ buffer->buffer_end ], str, str_len );

        buffer->str[ new_end ] = '\0';
        buffer->buffer_end     = new_end;

        mem_free( &str );
    }

    buffer->eof = feof( buffer->fp ) ? TRUE : FALSE;

    *buffer_ppt = buffer;

    return num;
}


char buffer_getc( file_buffer *buffer )
{
    /* Martin A. Hansen, June 2008 */

    /* Get the next char from a file buffer, which is resized if necessary, until EOF.*/

    while ( 1 )
    {
        if ( buffer->buffer_pos == buffer->buffer_end )
        {
            if ( buffer->eof )
            {
                return EOF;
            }
            else
            {
                buffer->token_pos = buffer->buffer_pos;
                buffer_new_size( buffer, buffer->buffer_pos );  // MOVE THIS TO buffer_resize !!!!! ??????

                if ( ( buffer_resize( buffer ) == FALSE ) ) {
                    return EOF;
                }
            }
        }
    
        return buffer->str[ buffer->buffer_pos++ ];
    }
}


void buffer_ungetc( file_buffer *buffer )
{
    /* Martin A. Hansen, August 2008. */

    /* Rewinds the file buffer one char, */
    /* i.e. put one char back on the buffer. */

    assert( buffer->buffer_pos > 0 );

    buffer->buffer_pos--;
}


char *buffer_gets( file_buffer *buffer )
{
    /* Martin A. Hansen, June 2008 */

    /* Get the next line that is terminated by \n or EOF from a file buffer. */

    char   *pt        = NULL;
    char   *line      = NULL;
    size_t  line_size = 0;

    while ( 1 )
    {
        if ( ( pt = memchr( &buffer->str[ buffer->buffer_pos ], '\n', buffer->buffer_end + 1 - buffer->buffer_pos ) ) != NULL )
        {
            line_size = pt - &buffer->str[ buffer->buffer_pos ] + 1;

            line = mem_get( line_size + 1 );

            memcpy( line, &buffer->str[ buffer->buffer_pos ], line_size );

            line[ line_size ] = '\0';

            buffer->token_len   = line_size;
            buffer->buffer_pos += line_size;

            buffer_new_size( buffer, line_size );

            return line;
        }
        else
        {
            if ( buffer->eof )
            {
                if ( buffer->buffer_pos < buffer->buffer_end )
                {
                    line_size = buffer->buffer_end - buffer->buffer_pos + 1;

                    line = mem_get( line_size + 1 );

                    memcpy( line, &buffer->str[ buffer->buffer_pos ], line_size );

                    line[ line_size ] = '\0';

                    buffer->token_len   = line_size;
                    buffer->buffer_pos += line_size;

                    return line;
                }
                else
                {
                    return NULL;
                }
            }
            else
            {
                buffer_resize( buffer );
            }
        }
    }
}


void buffer_ungets( file_buffer *buffer )
{
    /* Martin A. Hansen, August 2008 */

    /* Rewind the file buffer one line, */
    /* i.e. put one line back on the buffer. */

    assert( buffer->buffer_pos >= buffer->token_len );

    buffer->buffer_pos -= buffer->token_len;
}


void buffer_new_size( file_buffer *buffer, long len )
{
    /* Martin A. Hansen, June 2008 */

    /* Doubles buffer size until it is larger than len. */

    while ( buffer->buffer_size <= len )
    {
        buffer->buffer_size <<= 1;

        if ( buffer->buffer_size <= 0 )
        {
            fprintf( stderr, "ERROR: buffer_new_size failed.\n" );
            abort();
        }
    }
}


bool buffer_resize( file_buffer *buffer )
{
    /* Martin A. Hansen, June 2008 */

    /* Resize file buffer. */

    size_t num = 0;

    if ( buffer->token_pos != 0 ) {
        buffer_move( buffer, buffer->buffer_pos, buffer->token_pos );
    }

    num = buffer_read( &buffer );

    if ( num == 0 ) {
        return FALSE;
    } else {
        return TRUE;
    }
}


size_t buffer_move( file_buffer *buffer, size_t size, size_t num )
{
    /* Martin A. Hansen, August 2008 */

    /* Moves file buffer of a given size num positions to the left. */
    /* The size of the resulting string is returned. */

    size_t len = 0;

    assert( size > 0 );
    assert( num > 0 );
    assert( num <= size );

    memmove( buffer->str, &buffer->str[ num ], size );

    len = size - num;

    buffer->buffer_end = len;
    buffer->buffer_pos = 0;
    buffer->token_pos  = 0;

    return len;
}


void buffer_destroy( file_buffer **buffer_ppt )
{
    /* Martin A. Hansen, June 2008 */

    /* Deallocates memory and close stream used by file buffer. */

    file_buffer *buffer = *buffer_ppt;

    assert( buffer != NULL );

    close_stream( buffer->fp );

    mem_free( &buffer->str );
    mem_free( &buffer );

    buffer = NULL;
}


void buffer_print( file_buffer *buffer )
{
    /* Martin A. Hansen, June 2008 */

    /* Debug function that prints the content of a file_buffer. */

    printf( "\nbuffer: {\n" );
    printf( "   token_pos    : %zu\n",    buffer->token_pos );
    printf( "   token_len    : %zu\n",    buffer->token_len );
    printf( "   buffer_pos   : %zu\n",    buffer->buffer_pos );
    printf( "   buffer_end   : %zu\n",    buffer->buffer_end );
    printf( "   buffer_size  : %ld\n",    buffer->buffer_size );
    printf( "   str          : ->%s<-\n", buffer->str );
    printf( "   eof          : %d\n",     buffer->eof );

    if ( buffer->str != NULL ) {
        printf( "   _str_len_    : %zu\n", strlen( buffer->str ) );
    }

    printf( "}\n" );
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
