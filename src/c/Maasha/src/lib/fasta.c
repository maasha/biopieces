/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

#include "common.h"
#include "mem.h"
#include "filesys.h"
#include "seq.h"
#include "fasta.h"
#include "list.h"
#include "strings.h"


size_t fasta_count( FILE *fp )
{
    /* Martin A. Hansen, May 2008 */

    /* Counts all entries in a FASTA file given a file pointer. */

    char   buffer[ FASTA_BUFFER ];
    size_t count;

    count = 0;

    while ( ( fgets( buffer, sizeof( buffer ), fp ) ) != NULL )
    {
        if ( buffer[ 0 ] == '>' ) {
            count++;
        }
    }

    return count;
}


bool fasta_get_entry( FILE *fp, seq_entry **entry_ppt )
{
    /* Martin A. Hansen, August 2008 */

    /* Get next sequence entry from a FASTA file given a file pointer. */

    seq_entry *entry = *entry_ppt;

    entry->seq_len = 0;

    char  c;
    char *pt;

    while ( ( c = fgetc( fp ) ) && c != '>' && c != EOF ) {
    }

    if ( ( ferror( fp ) != 0 ) ) {
        fprintf( stderr, "ERROR: Could not read from file: %s\n", strerror( errno ) );
    } else if ( ( feof( fp ) != 0 ) ) {
        return FALSE;
    }

    pt = entry->seq_name;

    while ( ( c = fgetc( fp ) ) && c != '\n' ) {
        *( pt++ ) = c;
    }

    *( pt ) = '\0';

    pt = entry->seq;

    while ( ( c = fgetc( fp ) ) && c != '>' && c != EOF )
    {
        if ( isseq( c ) )
        {
            *( pt++ ) = c;
            entry->seq_len++;
        }
    }

    *( pt ) = '\0';

    if ( c == '>' ) {
        ungetc( c, fp );
    }

    *entry_ppt = entry;

    return TRUE;
}


void fasta_put_entry( seq_entry *entry )
{
    /* Martin A. Hansen, May 2008 */

    /* Output a sequence entry in FASTA format. */
    printf( ">%s\n%s\n", entry->seq_name, entry->seq );
}


//void fasta_get_entries( FILE *fp, struct list **entries )
//{
//    /* Martin A. Hansen, May 2008 */
//
//    /* Given a file pointer to a FASTA file retreives all */
//    /* sequence entries and insert those in a list. */
//
//    struct seq_entry *entry;
//
//    while ( 1 )
//    {
//        entry = mem_get( sizeof( entry ) );
//
//        if ( ! fasta_get_entry( fp, entry ) ) {
//            break;
//        }                                                                                                                       
//
//        list_add( entries, entry );                                                                                             
//    }                                                                                                                           
//
//    list_reverse( entries );                                                                                                    
//}                                                                                                                               
                                                                                                                                
                                                                                                                                
//void fasta_put_entries( struct list *entries )                                                                                  
//{                                                                                                                               
//    /* Martin A. Hansen, May 2008 */                                                                                            
//
//    /* Output a list of sequence entries as FASTA records. */                                                                   
//
//    struct list *elem;                                                                                                          
//
//    for ( elem = entries; elem != NULL; elem = elem->next ) {                                                                   
//        fasta_put_entry( elem->val );                                                                                           
//    }                                                                                                                           
//}
