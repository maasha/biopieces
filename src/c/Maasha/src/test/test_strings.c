#include "common.h"
#include "strings.h"

static void test_chop();
static void test_chomp();
static void test_strchr_total();
static void test_match_substr();
static void test_match_substr_rev();


/*
 if ((foo_c = malloc(strlen(foo) + 1)) == NULL)
                    return errno;
*/


int main()
{
    fprintf( stderr, "Running all tests for strings.c\n" );

    test_chop();
    test_chomp();
    test_strchr_total();
    test_match_substr();
    test_match_substr_rev();

    fprintf( stderr, "Done\n\n" );

    return EXIT_SUCCESS;
}


static void test_chop()
{
    char test[] = "ABCDE";

    fprintf( stderr, "   Testing chop ... " );

    assert( chop( test ) == 4 );
    assert( chop( test ) == 3 );
    assert( chop( test ) == 2 );
    assert( chop( test ) == 1 );
    assert( chop( test ) == 0 );

    fprintf( stderr, "OK\n" );
}


static void test_chomp()
{
    char test[] = "AB\nCDE\n\n\n";

    fprintf( stderr, "   Testing chomp ... " );

    assert( chomp( test ) == 8 );
    assert( chomp( test ) == 7 );
    assert( chomp( test ) == 6 );
    assert( chomp( test ) == -1 );
    assert( chomp( test ) == -1 );

    fprintf( stderr, "OK\n" );
}


static void test_strchr_total()
{
    fprintf( stderr, "   Testing strchr_total ... " );

    char *str = "X-----X----X";

    assert( strchr_total( str, 'X' ) == 3 );
    assert( strchr_total( str, '-' ) == 9 );

    fprintf( stderr, "OK\n" );
}


static void test_match_substr()
{
    fprintf( stderr, "   Testing match_substr ... " );

    assert( match_substr( 0, "MARTIN", 6, "TXN", 3, 0 ) == -1 );
    assert( match_substr( 0, "MARTIN", 6, "TIN", 3, 0 ) == 3 );
    assert( match_substr( 0, "MARTIN", 6, "TXN", 3, 1 ) == 3 );
    assert( match_substr( 0, "MARTIN", 6, "MXR", 3, 0 ) == -1 );
    assert( match_substr( 0, "MARTIN", 6, "MXR", 3, 1 ) == 0 );
    assert( match_substr( 1, "MARTIN", 6, "MXR", 3, 1 ) == -1 );
    assert( match_substr( 5, "MARTIN", 6, "N", 1, 0 ) == 5 );
    assert( match_substr( 0, "M", 1, "M", 1, 0 ) == 0 );

    fprintf( stderr, "OK\n" );
}


static void test_match_substr_rev()
{
    fprintf( stderr, "   Testing match_substr_rev ... " );

    assert( match_substr_rev( 0, "MARTIN", 6, "TXN", 3, 0 ) == -1 );
    assert( match_substr_rev( 0, "MARTIN", 6, "TIN", 3, 0 ) == 3 );
    assert( match_substr_rev( 2, "MARTIN", 6, "TIN", 3, 0 ) == -1 );
    assert( match_substr_rev( 0, "MARTIN", 6, "MAR", 3, 0 ) == 0 );
    assert( match_substr_rev( 3, "MARTIN", 6, "MAR", 3, 0 ) == 0 );
    assert( match_substr_rev( 4, "MARTIN", 6, "MAR", 3, 0 ) == -1 );
    assert( match_substr_rev( 0, "MARTIN", 6, "TXN", 3, 1 ) == 3 );
    assert( match_substr_rev( 0, "MARTIN", 6, "MXR", 3, 1 ) == 0 );
    assert( match_substr_rev( 4, "MARTIN", 6, "MXR", 3, 1 ) == -1 );
    assert( match_substr_rev( 5, "MARTIN", 6, "M", 1, 0 ) == 0 );
    assert( match_substr_rev( 0, "M", 1, "M", 1, 0 ) == 0 );

    fprintf( stderr, "OK\n" );
}
