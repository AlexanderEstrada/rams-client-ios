//
//  Bozorth.h
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#ifndef Bozorth3_Bozorth_h
#define Bozorth3_Bozorth_h

#include <stdlib.h>

#ifndef MAX
#define	MAX(a,b) (((a)>(b))?(a):(b))
#endif

/**************************************************************************/
/* Math-Related Macros, Definitions & Prototypes */
/**************************************************************************/

/* This macro adjusts angles to the range (-180,180] */
#define IANGLE180(deg)		( ( (deg) > 180 ) ? ( (deg) - 360 ) : ( (deg) <= -180 ? ( (deg) + 360 ) : (deg) ) )
#define SENSE(a,b)		( (a) < (b) ? (-1) : ( ( (a) == (b) ) ? 0 : 1 ) )
#define SENSE_NEG_POS(a,b)	( (a) < (b) ? (-1) : 1 )

#define SQUARED(n)		( (n) * (n) )

#ifdef ROUND_USING_LIBRARY
#define ROUND(f) (roundf(f))
#else
#define ROUND(f) ( ( (f) < 0.0F ) ? ( (int) ( (f) - 0.5F ) ) : ( (int) ( (f) + 0.5F ) ) )
#endif

/* PI is used in: bozorth3.c, comp.c */
#ifdef M_PI
#define PI		M_PI
#define PI_SINGLE	( (float) PI )
#else
#define PI		3.14159
#define PI_SINGLE	3.14159F
#endif

#define FPNULL ((FILE *) NULL)
#define CNULL  ((char *) NULL)

#define PROGRAM				"bozorth3"

#define MAX_LINE_LENGTH 1024

#define SCOREFILE_EXTENSION		".scr"

#define MAX_FILELIST_LENGTH		10000

#define DEFAULT_BOZORTH_MINUTIAE	150
#define MAX_BOZORTH_MINUTIAE		200
#define MIN_BOZORTH_MINUTIAE		0
#define MIN_COMPUTABLE_BOZORTH_MINUTIAE	10

#define DEFAULT_MAX_MATCH_SCORE		400
#define ZERO_MATCH_SCORE		0

#define DEFAULT_SCORE_LINE_FORMAT	"s"

#define DM	125
#define FD	5625
#define FDD	500
#define TK	0.05F
#define TXS	121
#define CTXS	121801
#define MSTR	3
#define MMSTR	8
#define WWIM	10

#define QQ_SIZE 4000

#define QQ_OVERFLOW_SCORE QQ_SIZE

/**************************************************************************/
/**************************************************************************/
/* MACROS DEFINITIONS */
/**************************************************************************/
#define INT_SET(dst,count,value) { \
int * int_set_dst   = (dst); \
int   int_set_count = (count); \
int   int_set_value = (value); \
while ( int_set_count-- > 0 ) \
*int_set_dst++ = int_set_value; \
}

/* The code that calls it assumed dst gets bumped, so don't assign to a local variable */
#define INT_COPY(dst,src,count) { \
int * int_copy_src = (src); \
int int_copy_count = (count); \
while ( int_copy_count-- > 0 ) \
*dst++ = *int_copy_src++; \
}

struct minutiae_struct {
	int col[4];
};

/* Used by custom quicksort */
#define BZ_STACKSIZE    1000
struct cell {
	int		index;	/* pointer to an array of pointers to index arrays */
	int		item;	/* pointer to an item array */
};

/**************************************************************************/
/* In BZ_IO : Supports the loading and manipulation of XYT and XYTQ data */
/**************************************************************************/
#define MAX_FILE_MINUTIAE       1000 /* bz_load() */

struct xyt_struct {
	int nrows;
	int xcol[     MAX_BOZORTH_MINUTIAE ];
	int ycol[     MAX_BOZORTH_MINUTIAE ];
	int thetacol[ MAX_BOZORTH_MINUTIAE ];
};

struct xytq_struct {
    int nrows;
    int xcol[     MAX_FILE_MINUTIAE ];
    int ycol[     MAX_FILE_MINUTIAE ];
    int thetacol[ MAX_FILE_MINUTIAE ];
    int qualitycol[ MAX_FILE_MINUTIAE ];
};


#define XYT_NULL ( (struct xyt_struct *) NULL ) /* bz_load() */
#define XYTQ_NULL ( (struct xytq_struct *) NULL ) /* bz_load() */


/** bz_array */
#define STATIC     static
/* #define BAD_BOUNDS 1 */

#define COLP_SIZE_1 20000
#define COLP_SIZE_2 5

#define COLS_SIZE_2 6
#define SCOLS_SIZE_1 20000
#define FCOLS_SIZE_1 20000

#define SCOLPT_SIZE 20000
#define FCOLPT_SIZE 20000

#define SC_SIZE 20000

#define RQ_SIZE 20000
#define TQ_SIZE 20000
#define ZZ_SIZE 20000

#define RX_SIZE 100
#define MM_SIZE 100
#define NN_SIZE 20

#define RK_SIZE 20000

#define RR_SIZE     100
#define AVN_SIZE      5
#define AVV_SIZE_1 2000
#define AVV_SIZE_2    5
#define CT_SIZE    2000
#define GCT_SIZE   2000
#define CTT_SIZE   2000

#ifdef BAD_BOUNDS
#define CTP_SIZE_1 2000
#define CTP_SIZE_2 1000
#else
#define CTP_SIZE_1 2000
#define CTP_SIZE_2 2500
#endif

#define RF_SIZE_1 100
#define RF_SIZE_2  10

#define CF_SIZE_1 100
#define CF_SIZE_2  10

#define Y_SIZE 20000

#define YL_SIZE_1    2
#define YL_SIZE_2 2000

#define YY_SIZE_1 1000
#define YY_SIZE_2    2
#define YY_SIZE_3 2000

#ifdef BAD_BOUNDS
#define SCT_SIZE_1 1000
#define SCT_SIZE_2 1000
#else
#define SCT_SIZE_1 2500
#define SCT_SIZE_2 1000
#endif

#define CP_SIZE 20000
#define RP_SIZE 20000

#define ROT_SIZE_1 20000
#define ROT_SIZE_2 5

#endif
