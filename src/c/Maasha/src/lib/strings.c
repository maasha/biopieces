/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "strings.h"


size_t chop( char *string )
{
    /* Martin A. Hansen, June 2008 */

    /* Remove the last char from a string. */
    /* Returns the length of the chopped string.*/

    assert( string != NULL );
    assert( string[ 0 ] != '\0' );

    size_t len;

    len = strlen( string );

    string[ len - 1 ] = '\0';

    return len - 1;
}


size_t chomp( char *string )
{
    /* Martin A. Hansen, June 2008 */

    /* Removes the last char from a string if the char is a newline. */
    /* Returns the length of the chomped string or -1 is no newline was found. */

    size_t len;

    assert( string != NULL );
    assert( string[ 0 ] != '\0' );

    len = strlen( string );

    if ( string[ len - 1 ] == '\n' )
    {
        string[ len - 1 ] = '\0';

        return len - 1;
    }
    else
    {
        return -1;
    }
}


size_t strchr_total( const char *string, const char c )
{
    /* Martin A. Hansen, September 2008 */

    /* Returns the total number of a given char in a given string. */

    int count[ 256 ] = { 0 };   /* Integer array spanning the ASCII alphabet */
    int i;

    for ( i = 0; i < strlen( string ); i++ ) {
        count[ ( int ) string[ i ] ]++;
    }

    return count[ ( int ) c ];
}


size_t match_substr( size_t pos, char *str, size_t str_len, char *substr, size_t substr_len, size_t mismatch )
{
    /* Martin A. Hansen, August 2008 */

    /* Locate a substr in a str starting at pos allowing for a given number of mismatches. */
    /* Returns position of match begin or -1 if not found. */

    size_t i;
    size_t j;
    size_t count;

    assert( pos >= 0 );
    assert( pos < str_len );
    assert( str != NULL );
    assert( substr != NULL );
    assert( str_len > 0 );
    assert( substr_len > 0 );
    assert( strlen( str ) == str_len );
    assert( strlen( substr ) == substr_len );
    assert( mismatch >= 0 );
    assert( mismatch < substr_len );
    assert( substr_len <= str_len );
    assert( str[ str_len ] == '\0' );
    assert( substr[ substr_len ] == '\0' );

    for ( i = pos; i < str_len - substr_len + 1; i++ )
    {
        count = 0;

        for ( j = 0; j < substr_len; j++ )
        {
            if ( str[ i + j ] != substr[ j ] )
            {
                count++;

                if ( count > mismatch ) {
                    break;
                }
            }
        }

        if ( count <= mismatch ) {
            return i;
        }
    }

    return -1;
}


size_t match_substr_rev( size_t pos, char *str, size_t str_len, char *substr, size_t substr_len, size_t mismatch )
{
    /* Martin A. Hansen, August 2008 */

    /* Locate a substr in a str backwards starting at the end of */
    /* str minus pos allowing for a given number of mismatches. */
    /* Returns position of match begin or -1 if not found. */

    size_t i;
    size_t j;
    size_t count;

    assert( pos >= 0 );
    assert( pos < str_len );
    assert( str != NULL );
    assert( substr != NULL );
    assert( str_len > 0 );
    assert( substr_len > 0 );
    assert( strlen( str ) == str_len );
    assert( strlen( substr ) == substr_len );
    assert( mismatch >= 0 );
    assert( mismatch < substr_len );
    assert( substr_len <= str_len );
    assert( str[ str_len ] == '\0' );
    assert( substr[ substr_len ] == '\0' );

    for ( i = str_len - pos - 1; i >= substr_len - 1; i-- )
    {
        count = 0;
    
        for ( j = substr_len - 1; j > 0; j-- )
        {
            if ( str[ i - ( substr_len - j - 1 ) ] != substr[ j ] )
            {
                /* printf( "i:%ld  j:%ld  count:%ld  str:%c  substr:%c\n", i, j, count, str[ i - ( substr_len - j - 1 ) ], substr[ j ] ); // DEBUG */
                count++;

                if ( count > mismatch ) {
                    break;
                }
            }
        }

        if ( count <= mismatch ) {
            return i - substr_len + 1;
        }
    }

    return -1;
}


