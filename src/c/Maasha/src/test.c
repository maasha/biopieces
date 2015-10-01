#include <stdio.h>
#include <stdlib.h>


int main()
{
    char   str[] = "ABCDEFGHIJKLMNOPQRSTUVXYZ";
    int    i     = 0;
    char  *pt1   = NULL;
    int    size  = 4;
    char   word[ size ];


    for ( i = size, pt1 = &str[ size ]; i < 10; i++, *( pt1++ ) )
    {
        printf( "char: %s\n", pt1 );
//        printf( "word: %s\n", &pt[ i ] );
    }

    return EXIT_SUCCESS;
}


//double average( int num, ... )
//{
//    /* Martin A. Hansen, July 2008 */
//
//    /* Example of varable length argument list usage. */
//
//    /* Requires '#include <stdarg.h>' */
//
//    double sum = 0;
//    int    x   = 0;
//
//    va_list arguments;
//
//    va_start( arguments, num );
//
//    for ( x = 0; x < num; x++ )
//    {
//        sum += va_arg( arguments, double );
//    }
//
//    va_end( arguments );
//
//    return sum / num;
//}


//int main( int argc, char *argv[] )
//{
//    char             *file;
//    FILE             *fp;
//    struct seq_entry *entry = NULL;
//    int               count;
//
//    count = 0;
//
//    file = argv[ 1 ];
//
//    fp = read_open( file );
//
//    while ( ( fasta_get_entry( fp, entry ) ) != FALSE )
//    {
//        printf( "seq_name: %s\n", entry->seq_name );
//
////        mem_free( entry->seq_name );
////        mem_free( entry->seq );
////        entry = NULL;
//        
//        count++;
//    }
//
//    printf( "count: %d\n", count );
//
//    close_stream( fp );
//
//    return 0;
//}
