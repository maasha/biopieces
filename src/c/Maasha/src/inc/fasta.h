/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#define FASTA_BUFFER 1024

/* Count all entries in a FASTA file given a file pointer. */
size_t fasta_count( FILE *fp );

/* Get next sequence entry from a FASTA file given a file pointer. */
bool fasta_get_entry( FILE *fp, seq_entry **entry_ppt );

/* Output a sequence entry in FASTA format. */
void fasta_put_entry( seq_entry *entry );

/* Get all sequence entries from a FASTA file in a list. */
//void fasta_get_entries( FILE *fp, struct list **entries );

/* Output all sequence entries from a list in FASTA format. */
//void fasta_put_entries( struct list *entries );
