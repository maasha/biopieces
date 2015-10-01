/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "list.h"
#include "mem.h"


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MISC <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


void maasha_ping()
{
    /* Martin A. Hansen, Septermber 2008 */

    /* Function that prints "pong" to stderr. */

    fprintf( stderr, "pong\n" );
}


char *bits2string( uint bin )
{
    /* Martin A. Hansen, June 2008 */
    
    /* Return a binary number as a string of 1's and 0's. */

    int   i;
    uint  j;
    char *string;
    
    string = mem_get( ( sizeof( uint ) * 8 ) + 1 );

    j = 1;
                                                                                                                                
    for ( i = 0; i < sizeof( uint ) * 8; i++ )                                                                          
    {                                                                                                                           
                                                                                                                                
        if ( ( bin & j ) != 0 ) {                                                                                               
            string[ 31 - i ] = '1';                                                                                             
        } else {                                                                                                                
            string[ 31 - i ] = '0';                                                                                             
        }                                                                                                                       
                                                                                                                                
        j <<= 1;                                                                                                                
    }                                                                                                                           
                                                                                                                                
    string[ i ] = '\0';                                                                                                         
                                                                                                                                
    return string;                                                                                                              
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
