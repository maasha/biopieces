/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

//#define FILE_BUFFER_SIZE 64 * 1024
#define FILE_BUFFER_SIZE 1

struct _file_buffer
{
    FILE   *fp;           /* file pointer */
    size_t  token_pos;    /* index pointing to last position where some token was found */
    size_t  token_len;    /* length of some found token */
    size_t  buffer_pos;   /* index indicating how much of the buffer is scanned */
    size_t  buffer_end;   /* end position of buffer */
    long    buffer_size;  /* default buffer size */
    char   *str;          /* the buffer string */
    bool    eof;          /* flag indicating that buffer reached EOF */
};

typedef struct _file_buffer file_buffer;

/* Read-open a file and return a file pointer. */
FILE   *read_open( char *file );

/* Write-open a file and return a file pointer. */
FILE   *write_open( char *file );

/* Append-open a file and return a file pointer. */
FILE   *append_open( char *file );

/* Close a stream defined by a file pointer. */
void    close_stream( FILE *fp );

/* Read in len number of bytes from the current position of a */
/* file pointer into a string that is allocated and null terminated. */
/* The number of read chars is returned. */
size_t  file_read( FILE *fp, char **string_ppt, size_t len );

/* Delete a file. */
void    file_unlink( char *file );

/* Rename a file. */
void    file_rename( char *old_name, char *new_name );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FILE BUFFER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Opens a file for reading and loads a new buffer.*/
/* The number of read chars is returned. */
size_t  buffer_new( char *file, file_buffer **buffer_ppt, size_t size );

/* Read in buffer->size bytes from file and appends to buffer string. */
/* The number of read chars is returned. */
size_t  buffer_read( file_buffer **buffer_ppt );

/* Get the next char from a file buffer, which is resized if necessary, until EOF.*/
char    buffer_getc( file_buffer *buffer );

/* Rewinds the file buffer one char, i.e. put one char back on the buffer. */
void    buffer_ungetc( file_buffer *buffer );

/* Get the next line that is terminated by \n or EOF from a file buffer. */
/* The number of read chars is returned. */
char   *buffer_gets( file_buffer *buffer );

/* Rewind the file buffer one line, i.e. put one line back on the buffer.  */
void    buffer_ungets( file_buffer *buffer );

/* Doubles buffer size until it is larger than len. */
void    buffer_new_size( file_buffer *buffer, long len );

/* Resize file buffer discarding any old buffer before offset, */
/* and merge remaining old buffer with a new chunk of buffer. */
bool    buffer_resize( file_buffer *buffer );

/* Moves file buffer of a given size num positions to the left. */
/* The size of the resulting string is returned. */
size_t  buffer_move( file_buffer *buffer, size_t size, size_t num );

/* Deallocates memory and close stream used by file buffer. */
void    buffer_destroy( file_buffer **buffer_ppt );

/* Debug function that prints the content of a file_buffer. */
void    buffer_print( file_buffer *buffer );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
