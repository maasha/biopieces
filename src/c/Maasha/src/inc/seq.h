/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* Constants for allocating memory for sequence entries. */
#define MAX_SEQ_NAME      1024
#define MAX_SEQ      250000000

/* Macro to test if a given char is sequence (DNA, RNA, Protein, indels. brackets, etc ). */
#define isseq( x ) ( x > 32 && x < 127 ) ? 1 : 0

/* Macro to test if a given char is DNA. */
#define isDNA( c ) ( c == 'A' || c == 'a' || c == 'T' || c == 't' ||  c == 'C' || c == 'c' ||  c == 'G' || c == 'g' || c == 'N' || c == 'n' ) ? 1 : 0

/* Macro to test if a given char is RNA. */
#define isRNA( c ) ( c == 'A' || c == 'a' || c == 'U' || c == 'u' ||  c == 'C' || c == 'c' ||  c == 'G' || c == 'g' || c == 'N' || c == 'n' ) ? 1 : 0

/* Macros for converting DNA ASCII to binary. */
#define add_A( c )              /* add 00 to the rightmost two bits of bin (i.e. do nothing). */
#define add_T( c ) ( c |= 3 )   /* add 11 on the rightmost two bits of c. */
#define add_C( c ) ( c |= 1 )   /* add 01 on the rightmost two bits of c. */
#define add_G( c ) ( c |= 2 )   /* add 10 on the rightmost two bits of c. */


/* Definition of a sequence entry */
struct _seq_entry
{
    char   *seq_name;
    char   *seq;
    size_t  seq_len;
};

typedef struct _seq_entry seq_entry;

/* Byte array for fast convertion of binary blocks to DNA. */
/* Binary blocks holds four nucleotides encoded in 2 bits: */
/* A=00 T=11 C=01 G=10 */
char *bin2dna[256];

/* Initialize a new sequence entry. */
seq_entry *seq_new( size_t max_seq_name, size_t max_seq );

/* Destroy a sequence entry. */
void       seq_destroy( seq_entry *entry );

/* Uppercase sequence. */
void       seq_uppercase( char *seq );

/* Lowercase sequence. */
void       lowercase_seq( char *seq );

/* Reverse compliments DNA sequence. */
void       revcomp_dna( char *seq );

/* Reverse compliments RNA sequence. */
void       revcomp_rna( char *seq );

/* Reverse compliment nucleotide sequnce after guessing the sequence type. */
void       revcomp_nuc( char *seq );

/* Complement DNA sequence. (NB it is not reversed!). */
void       complement_dna( char *seq );

/* Complement RNA sequence. (NB it is not reversed!). */
void       complement_rna( char *seq );

/* Complement nucleotide sequence after guessing the sequence type. */
void       complement_nuc( char *seq );

/* Reverse sequence. */
void       reverse( char *seq );

/* Convert all non-nucleotide letters to Ns. */
void       seq2nuc_simple( char *seq );

/* Convert DNA into RNA by change t and T to u and U, respectively. */
void       dna2rna( char *seq );

/* Convert RNA into DNA by change u and U to t and T, respectively. */
void       rna2dna( char *seq );

/* Check if a sequence is DNA by inspecting the first 100 residues. */
bool       is_dna( char *seq );

/* Check if a sequence is RNA by inspecting the first 100 residues. */
bool       is_rna( char *seq );

/* Check if a sequence is protein by inspecting the first 100 residues. */
bool       is_protein( char *seq );

/* Guess if a sequence is DNA, RNA, or protein by inspecting the first 100 residues. */
char      *seq_guess_type( char *seq );

/* Check if a sequence contain N or n. */
bool       contain_N( char *seq );

/* Pack a nucleotide oligo (max length 15) into a binary/integer (good for hash keys). */
int        oligo2bin( char *oligo );

