/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* Structure of a generic hash element. */
struct _hash_elem
{
    struct _hash_elem *next;   /* Hash elements constitue a sigly linked list. */
    char              *key;    /* Hash key. */
    void              *val;    /* Hash val. */
};

typedef struct _hash_elem hash_elem;

/* Structure of a generic hash. */
struct _hash
{
    hash_elem **table;          /* Hash table. */
    size_t      mask;           /* Mask to trim hashed keys. */
    size_t      table_size;     /* Size of hash table. */
    size_t      nmemb;          /* Number of elements in hash table. */
    size_t      index_table;    /* Index for iterating hash table. */
    hash_elem  *index_bucket;   /* Index for iterating buckets. */
};

typedef struct _hash hash;

/* Initialize a new generic hash structure. */
hash *hash_new( size_t size );

/* Initializes a new hash_elem structure. */
hash_elem *hash_elem_new();

/* Hash function that generates a hash key. */
uint hash_key( char *string );

/* Add a new hash element consisting of a key/value pair to an existing hash. */
void hash_add( hash *hash_pt, char *key, void *val );

/* Lookup a key in a given hash and return the value - or NULL if not found. */
void *hash_get( hash *hash_pt, char *key );

/* Lookup a key in a given hash and return the hash element - or NULL if not found. */
hash_elem *hash_elem_get( hash *hash_pt, char *key );

/* Get the next key/value pair from a hash table. */
bool hash_each( hash *hash_pt, char **key_ppt, void *val );

/* Deallocate memory for hash and all hash elements. */
void hash_destroy( hash *hash_pt );

/* Debug function that prints hash meta data and all hash elements. */
void hash_print( hash *hash_pt );

/* Output some collision stats for a given hash. */
void hash_collision_stats( hash *hash_pt );


