/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* Including standard libraries */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <math.h>
#include <assert.h>
#include <errno.h>
#include <getopt.h>

typedef unsigned int uint;
typedef unsigned char uchar;
typedef unsigned short ushort;
typedef long long llong;
typedef char boolean;

#ifndef bool
#define bool boolean
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

/* Macros for determining min or max of two given values. */
#define MAX( a, b ) a < b ? b : a
#define MIN( a, b ) a > b ? b : a

/* Macros for abs and int functions. */
#define ABS( x ) ( ( x ) < 0 ) ? -( x ) : ( x )
#define INT( x ) ( int ) x

/* Neat debug macro. */
#define DEBUG_EXIT 0

#ifndef die
#define die assert( DEBUG_EXIT )
#endif


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MISC <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Function that prints "pong" to stderr. */
void maasha_ping();

// /* Return a binary number as a string of 1's and 0's. */
// char *bits2string( uint bin );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


