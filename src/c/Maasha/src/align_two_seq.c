#include "common.h"
#include "mem.h"
#include "hash.h"


/*********************************** DECLARATIONS ************************************/


struct _search_space
{
    char         *q_seq;
    char         *s_seq;
    unsigned int  q_beg;
    unsigned int  s_beg;
    unsigned int  q_end;
    unsigned int  s_end;
};

typedef struct _search_space search_space;


struct _match
{
    struct _match *next;
    unsigned int   q_beg;
    unsigned int   s_beg;
    unsigned int   len;
    float          score;
};

typedef struct _match match;


struct _list
{
    struct _list *next;
    unsigned int  val;
};

typedef struct _list list;


/*********************************** FUNCTIONS ************************************/


search_space *search_space_new( char *q_seq, char *s_seq, unsigned int q_beg, unsigned int s_beg, unsigned int q_end, unsigned int s_end )
{
    search_space *new = NULL;

    new = mem_get( sizeof( search_space ) );

    assert( q_seq != NULL );
    assert( s_seq != NULL );
    assert( q_beg >= 0 );
    assert( s_beg >= 0 );
    assert( q_end > q_beg );
    assert( s_end > s_beg );

    new->q_seq = q_seq;
    new->s_seq = s_seq;
    new->q_beg = q_beg;
    new->s_beg = s_beg;
    new->q_end = q_end;
    new->s_end = s_end;

    return new;
}


match *match_new( unsigned int q_beg, unsigned int s_beg, unsigned int len )
{
    match *new = NULL;

    new = mem_get( sizeof( match ) );

    new->q_beg = q_beg;
    new->s_beg = s_beg;
    new->len   = len;
    new->next  = NULL;
    new->score = 0.0;

    return new;
}


void match_add( match **old_ppt, match **new_ppt )
{
    match *old = *old_ppt;
    match *new = *new_ppt;

    new->next = old->next;
    old->next = new;
}


void match_print( match *match_pt )
{
    printf( "q_beg: %d\ts_beg: %d\tlen: %d\tscore: %f\n", match_pt->q_beg, match_pt->s_beg, match_pt->len, match_pt->score );
}


void matches_print( match *matches )
{
    match *m = NULL;

    for ( m = matches; m != NULL; m = m->next ) {
        match_print( m );
    }
}


void match_expand_forward( match *match_pt, search_space *ss )
{
    while ( match_pt->q_beg + match_pt->len <= ss->q_end && 
            match_pt->s_beg + match_pt->len <= ss->s_end &&
            toupper( ss->q_seq[ match_pt->q_beg + match_pt->len ] ) == toupper( ss->s_seq[ match_pt->s_beg + match_pt->len ] ) )
    {
        match_pt->len++;
    }
}


void match_expand_backward( match *match_pt, search_space *ss )
{
    while ( match_pt->q_beg > ss->q_beg &&
            match_pt->s_beg > ss->q_beg &&
            toupper( ss->q_seq[ match_pt->q_beg ] ) == toupper( ss->s_seq[ match_pt->s_beg ] ) )
    {
        match_pt->q_beg--;
        match_pt->s_beg--;
        match_pt->len++;
    }
}


void match_expand( match *match_pt, search_space *ss )
{
    match_expand_forward( match_pt, ss );
    match_expand_backward( match_pt, ss );
}


bool match_redundant( match *matches, match *new )
{
    // FIXME replace with binary search scheme. (test if matches always are sorted).

    match *m = NULL;

    for ( m = matches; m != NULL; m = m->next )
    {
        if ( new->q_beg >= m->q_beg &&
             new->s_beg >= m->s_beg &&
             new->q_beg + new->len - 1 <= m->q_beg + m->len - 1 &&
             new->s_beg + new->len - 1 <= m->s_beg + m->len - 1
           )
        {
            return TRUE;
        }
    }

    return FALSE;
}


list *list_new()
{
    list *new = NULL;

    new = mem_get( sizeof( list ) );

    new->next = NULL;
    new->val  = 0;

    return new;
}


void list_add( list **old_ppt, list **new_ppt )
{
    list *old = *old_ppt;
    list *new = *new_ppt;

    new->next = old->next;
    old->next = new;
}


void list_print( list *list_pt )
{
    list *node = NULL;

    for ( node = list_pt; node != NULL; node = node->next ) {
        printf( "node->val: %d\n", node->val );
    }
}


void seq_index( hash **index_ppt, char *seq, unsigned int seq_beg, unsigned int seq_end, unsigned int word_size )
{
    hash         *index = *index_ppt;
    unsigned int  i     = 0;
    char         *word  = NULL;
    list         *old   = NULL;
    list         *new   = NULL;

    assert( 0 <= seq_beg );
    assert( seq_beg < seq_end );
    assert( word_size > 0 );

    word = mem_get_zero( sizeof( char ) * word_size + 1 );

    for ( i = seq_beg; i < seq_end - word_size + 2; i++ )
    {
        memcpy( word, &seq[ i ], word_size );

        new = list_new();

        new->val = i;

        if ( ( old = hash_get( index, word ) ) != NULL ) {
            list_add( &old, &new );
        } else {
            hash_add( index, word, new );
        }
    }

    free( word );
}


void index_print( hash *index )
{
    hash_elem *bucket   = NULL;
    list      *pos_list = NULL;
    list      *node     = NULL;
    size_t     i        = 0;

    printf( "\ntable_size: %zu mask: %zu elem_count: %zu\n", index->table_size, index->mask, index->nmemb );

    for ( i = 0; i < index->table_size; i++ )
    {
        bucket = index->table[ i ];

        while ( bucket != NULL  )
        {
            printf( "i: %zu   key: %s   val: ", i, bucket->key );

            pos_list = bucket->val;

            for ( node = pos_list; node != NULL; node = node->next ) {
                printf( "%d,", node->val );
            }

            printf( "\n" );

            bucket = bucket->next;
        }
    }
}


unsigned int matches_find_s( match **matches_ppt, hash *index, search_space *ss, unsigned int word_size )
{
    match        *matches     = *matches_ppt;
    unsigned int  s_pos       = 0;
    unsigned int  match_count = 0;
    char         *word        = NULL;
    list         *pos_list    = NULL;
    list         *node        = NULL;
    match        *new         = NULL;

    word = mem_get_zero( sizeof( char ) * word_size + 1 );

    for ( s_pos = ss->s_beg; s_pos < ss->s_end - word_size + 2; s_pos++ )
    {
        memcpy( word, &ss->s_seq[ s_pos ], word_size );

        if ( ( pos_list = hash_get( index, word ) ) != NULL )
        {
            for ( node = pos_list; node != NULL; node = node->next )
            {
                new = match_new( node->val, s_pos, word_size );

                if ( ! match_redundant( matches, new ) )
                {
                    match_expand( new, ss );

                    match_add( &matches, &new );

                    match_count++;
                }
            }
        }
    }

    printf( "her\n" ); // DEBUG
    matches_print( matches );
    index_print( index );


    free( word ); 

    return match_count;
}


unsigned int matches_find( match **matches_ppt, search_space *ss, unsigned int word_size )
{
    match        *matches     = *matches_ppt;
    hash         *index       = NULL;
    unsigned int  match_count = 0;

    assert( word_size > 0 );

    if ( ss->q_end - ss->q_beg < ss->s_end - ss->s_beg )
    {
        seq_index( &index, ss->q_seq, ss->q_beg, ss->q_end, word_size );

        match_count = matches_find_s( &matches, index, ss, word_size );
    }
    else
    {
        seq_index( &index, ss->s_seq, ss->s_beg, ss->s_end, word_size );

        // match_count = matches_find_q( &matches, index, q_seq, s_seq, q_beg, q_end, word_size );
    }

    // index_destroy( index );

    return match_count;
}


/*********************************** UNIT TESTS ************************************/


void test_search_space_new()
{
    fprintf( stderr, "   Testing search_space_new ... " );
    
    search_space *new = NULL;

    new = search_space_new( "ATCG", "GCTA", 0, 1, 2, 3 );

    assert( new->q_seq == "ATCG" );
    assert( new->s_seq == "GCTA" );
    assert( new->q_beg == 0 );
    assert( new->s_beg == 1 );
    assert( new->q_end == 2 );
    assert( new->s_end == 3 );

    fprintf( stderr, "done.\n" );
}


void test_match_new()
{
    fprintf( stderr, "   Testing match_new ... " );

    unsigned int q_beg = 1;
    unsigned int s_beg = 1;
    unsigned int len   = 2;
    match *new = NULL;

    new = match_new( q_beg, s_beg, len );

    assert( new->next  == NULL );
    assert( new->q_beg == 1 );
    assert( new->s_beg == 1 );
    assert( new->len   == 2 );
    assert( new->score == 0.0 );

    fprintf( stderr, "done.\n" );
}


void test_match_expand_forward()
{
    fprintf( stderr, "   Testing match_expand_forward ... " );

    search_space *new_ss    = NULL;
    match        *new_match = NULL;

    new_ss    = search_space_new( "ATCGG", "atcg", 0, 0, 4, 3 );
    new_match = match_new( 1, 1, 2 );

    match_expand_forward( new_match, new_ss );

    assert( new_match->q_beg == 1 );
    assert( new_match->s_beg == 1 );
    assert( new_match->len   == 3 );

    fprintf( stderr, "done.\n" );
}


void test_match_expand_backward()
{
    fprintf( stderr, "   Testing match_expand_backward ... " );

    search_space *new_ss    = NULL;
    match        *new_match = NULL;

    new_ss    = search_space_new( "ATCGG", "atcg", 0, 0, 4, 3 );
    new_match = match_new( 1, 1, 2 );

    match_expand_backward( new_match, new_ss );

    assert( new_match->q_beg == 0 );
    assert( new_match->s_beg == 0 );
    assert( new_match->len   == 3 );

    fprintf( stderr, "done.\n" );
}


void test_match_expand()
{
    fprintf( stderr, "   Testing match_expand ... " );

    search_space *new_ss    = NULL;
    match        *new_match = NULL;

    new_ss    = search_space_new( "ATCGG", "atcg", 0, 0, 4, 3 );
    new_match = match_new( 1, 1, 2 );

    match_expand( new_match, new_ss );

    assert( new_match->q_beg == 0 );
    assert( new_match->s_beg == 0 );
    assert( new_match->len   == 4 );

    fprintf( stderr, "done.\n" );
}


void test_match_redundant_duplicate()
{
    fprintf( stderr, "   Testing match_redundant_duplicate ... " );

    match *matches = NULL;
    match *new     = NULL;

    matches = match_new( 0, 1, 2 );
    new     = match_new( 0, 1, 2 );
    
    assert( match_redundant( matches, new ) == TRUE );

    fprintf( stderr, "done.\n" );
}


void test_match_redundant_upstream()
{
    fprintf( stderr, "   Testing match_redundant_upstream ... " );

    match *matches = NULL;
    match *new     = NULL;

    matches = match_new( 5, 5, 2 );
    new     = match_new( 4, 4, 3 );
    
    assert( match_redundant( matches, new ) == FALSE );

    fprintf( stderr, "done.\n" );
}


void test_match_redundant_downstream()
{
    fprintf( stderr, "   Testing match_redundant_downstream ... " );

    match *matches = NULL;
    match *new     = NULL;

    matches = match_new( 5, 5, 2 );
    new     = match_new( 6, 6, 2 );
    
    assert( match_redundant( matches, new ) == FALSE );

    fprintf( stderr, "done.\n" );
}


void test_list_new()
{
    fprintf( stderr, "   Testing list_new ... " );

    list *new = NULL;

    new = list_new();

    assert( new->next == NULL );
    assert( new->val  == 0 );

    fprintf( stderr, "done.\n" );
}


void test_list_add()
{
    fprintf( stderr, "   Testing list_add ... " );

    list *old = NULL;
    list *new = NULL;

    old = list_new();
    new = list_new();

    old->val = 10;
    new->val = 20;

    list_add( &old, &new );

    assert( old->val       == 10 );
    assert( old->next->val == 20 );

    fprintf( stderr, "done.\n" );
}


void test_seq_index()
{
    fprintf( stderr, "   Testing seq_index ... " );

    char         *seq       = "ATCGATCG";
    unsigned int  seq_beg   = 0;
    unsigned int  seq_end   = strlen( seq ) - 1;
    unsigned int  word_size = 2;
    hash         *index     = NULL;
    unsigned int  size      = 16;
    list         *node      = NULL;

    index = hash_new( size );

    seq_index( &index, seq, seq_beg, seq_end, word_size ); 

//    index_print( index );

    node = hash_get( index, "GA" );

    assert( node->val == 3 );

    fprintf( stderr, "done.\n" );
}


void test_matches_find_s()
{
    fprintf( stderr, "   Testing matches_find_s ... " );

    search_space *ss          = NULL;
    unsigned int  word_size   = 2;
    unsigned int  match_count = 0;
    match        *matches     = NULL;
    hash         *index       = NULL;
    unsigned int  size        = 16;

    ss      = search_space_new( "ATCG", "ATCG", 0, 0, 3, 3 );
//    matches = match_new( 0, 0, 0 ); // FIXME: dummy match
    matches = mem_get( sizeof( match ) );

    index = hash_new( size );

    seq_index( &index, ss->q_seq, ss->q_beg, ss->q_end, word_size ); 

    match_count = matches_find_s( &matches, index, ss, word_size );

    fprintf( stderr, "done.\n" );
}


void test_matches_find()
{
    fprintf( stderr, "   Testing matches_find ... " );

    search_space *ss          = NULL;
    unsigned int  word_size   = 2;
    unsigned int  match_count = 0;
    match        *matches     = NULL;

    ss = search_space_new( "ATCG", "ATCG", 0, 0, 3, 3 );

    match_count = matches_find( &matches, ss, word_size );

    fprintf( stderr, "done.\n" );
}


void test_all()
{
    fprintf( stderr, "Running all tests:\n" );

    test_search_space_new();

    test_match_new();
    test_match_expand_forward();
    test_match_expand_backward();
    test_match_expand();
    test_match_redundant_duplicate();
    test_match_redundant_upstream();
    test_match_redundant_downstream();

    test_list_new();
    test_list_add();

    test_seq_index();

    // test_matches_find_q();
    test_matches_find_s();
    test_matches_find();

    fprintf( stderr, "Done.\n\n" );
}


/*********************************** MAIN ************************************/


int main()
{
    test_all();

    return EXIT_SUCCESS;
}


/***********************************************************************/


