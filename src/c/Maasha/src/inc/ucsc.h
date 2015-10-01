/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#define BED_BUFFER         2048
#define BED_CHR_MAX          16
#define BED_QID_MAX         256
#define BED_ITEMRGB_MAX      16
#define BED_BLOCKSIZES_MAX  256
#define BED_QBEGS_MAX       256

/* Structure of a BED entry with the 12 BED elements. */
/* http://genome.ucsc.edu/FAQ/FAQformat#format1 */
struct _bed_entry
{
    int    cols;       /* Number of BED elements used. */
    char  *chr;        /* Chromosome name. */
    uint   chr_beg;    /* Chromosome begin position. */
    uint   chr_end;    /* Chromosome end position. */
    char  *q_id;       /* Query ID. */
    int    score;      /* Score. */
    char   strand;     /* Strand. */
    uint   thick_beg;  /* Begin position of thick drawing. */
    uint   thick_end;  /* End position of thick drawing. */
    char  *itemrgb;    /* RGB color (255,255,255).*/
    uint   blockcount; /* Number of blocks (exons). */
    char  *blocksizes; /* Comma separated string of blocks sizes. */
    char  *q_begs;     /* Comma separated string of block begins. */
};

typedef struct _bed_entry bed_entry;

/* Returns a new BED entry with memory allocated for */
/* a given number of columns. */
bed_entry *bed_entry_new( const int cols );

/* Free memory for a BED entry. */
void bed_entry_destroy( bed_entry *entry );

/* Get next BED entry from a file stream. */
bool bed_entry_get( FILE *fp, bed_entry **entry_ppt );

/* Get a singly linked list with all BED entries (of a given number of coluns */
/* from a specified file. */
list_sl *bed_entries_get( char *path, const int cols );

/* Output a given number of columns from a BED entry to stdout. */
void bed_entry_put( bed_entry *entry, int cols );

/* Output a given number of columns from all BED entries */
/* in a singly linked list. */
void bed_entries_put( list_sl *entries, int cols );

/* Free memory for all BED entries and list nodes. */
void bed_entries_destroy( list_sl **entries_ppt );

/* Given a path to a BED file, read the given number of cols */
/* according to the begin position. The result is written to stdout. */
void bed_file_sort_beg( char *path, int cols );

/* Given a path to a BED file, read the given number of cols */
/* according to the strand AND begin position. The result is written to stdout. */
void bed_file_sort_strand_beg( char *path, int cols );

/* Given a path to a BED file, read the given number of cols */
/* according to the chromosome AND begin position. The result is written to stdout. */
void bed_file_sort_chr_beg( char *path, int cols );

/* Given a path to a BED file, read the given number of cols */
/* according to the chromosome AND strand AND begin position. The result is written to stdout. */
void bed_file_sort_chr_strand_beg( char *path, int cols );

/* Compare function for sorting a singly linked list of BED entries */
/* according to begin position. */
int cmp_bed_sort_beg( const void *a, const void *b );

/* Compare function for sorting a singly linked list of BED entries */
/* according to strand AND begin position. */
int cmp_bed_sort_strand_beg( const void *a, const void *b );

/* Compare function for sorting a singly linked list of BED entries */
/* according to chromosome name AND begin position. */
int cmp_bed_sort_chr_beg( const void *a, const void *b );

/* Compare function for sorting a singly linked list of BED entries */
/* according to chromosome name AND strand AND begin position. */
int cmp_bed_sort_chr_strand_beg( const void *a, const void *b );


