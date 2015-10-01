#include "common.h"
#include "CUnit/Basic.h"

int init_suite( void )
{
    return 0;
}

int clean_suite( void )
{
    return 0;
}

void test_def_TRUE()
{
    assert( TRUE == 1 );
}

void test_def_FALSE()
{
    assert( FALSE == 0 );
}

int main()
{
    CU_pSuite pSuite = NULL;

    /* initialize the CUnit test registry */
    if ( CUE_SUCCESS != CU_initialize_registry() ) {
        return CU_get_error();
    }

    /* add a suite to the registry */
    pSuite = CU_add_suite( "Testing Common", init_suite, clean_suite );

    if ( NULL == pSuite ) {
        CU_cleanup_registry();
        return CU_get_error();
    }

    /* add the tests to the suite */
    /* NOTE - ORDER IS IMPORTANT */
    if ( ( NULL == CU_add_test( pSuite, "test of def_TRUE()", test_def_TRUE ) ) ||
         ( NULL == CU_add_test( pSuite, "test of def_TRUE()", test_def_TRUE ) )
       )
    {
        CU_cleanup_registry();
        return CU_get_error();
    }



    /* Run all tests using the CUnit Basic interface */
    CU_basic_set_mode(CU_BRM_VERBOSE);
    CU_basic_run_tests();
    CU_cleanup_registry();
    return CU_get_error();
}
