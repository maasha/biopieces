/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STRUCTURE DECLARATIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Singly linked list node. */
struct _node_sl
{
    struct _node_sl *next;   /* Pointer to next node - NULL if last. */
    void            *val;    /* Pointer to data value. */
};

typedef struct _node_sl node_sl;

/* Singly linked list. */
struct _list_sl
{
    node_sl *first;   /* Pointer to first node - NULL for empty list. */
};

typedef struct _list_sl list_sl;

/* Doubly linked list node. */
struct _node_dl
{
    struct _node_dl *next;  /* Pointer to next node     - NULL if last. */
    struct _node_dl *prev;  /* Pointer to previous node - NULL if last. */
    void            *val;   /* Pointer to data value. */
};

typedef struct _node_dl node_dl;

/* Doubly linked list. */
struct _list_dl
{
    node_dl *first;  /* Pointer to first node - NULL for empty list. */
    node_dl *last;   /* Pointer to last node  - NULL for empty list. */
};

typedef struct _list_dl list_dl;


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTION DECLARATIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SINGLY LINLED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Initialize a new singly linked list. */
list_sl *list_sl_new();

/* Initialize a new singly linked list node. */
node_sl *node_sl_new();

/* Add a new node to the beginning of a singly linked list. */
void     list_sl_add_beg( list_sl **list_ppt, node_sl **node_ppt );

/* Add a new node after a given node of a singly linked list. */
void     list_sl_add_after( node_sl **node_ppt, node_sl **new_node_ppt );

/* Remove the first node of a singly linked list. */
void     list_sl_remove_beg( list_sl **list_ppt );

/* Remove the node next to this one in a singly linked list. */
void     list_sl_remove_after( node_sl **node_ppt );

/* Debug function to print all elements from a singly linked list. */
void     list_sl_print( list_sl *list_pt );

/* Debug funtion to print a singly linked list node. */
void     node_sl_print( node_sl *node_pt );

/* Sort a singly linked list according to the compare function. */
void     list_sl_sort( list_sl **list_ppt, int ( *compare )( const void *a, const void *b ) );

/* Free memory for all nodes in and including the singly linked list. */
void     list_sl_destroy( list_sl **list_ppt );

/* Free memory for singly linked list node and value. */
void     node_sl_destroy( node_sl **node_ppt );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DOUBLY LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Initialize a new doubly linked list. */
list_dl *list_dl_new();

/* Initialize a new doubly linked list node. */
node_dl *node_dl_new();

/* Add a new node to the beginning of a doubly linked list. */
void     list_dl_add_beg( list_dl **list_ppt, node_dl **node_ppt );

/* Add a new node to the end of a doubly linked list. */
void     list_dl_add_end( list_dl **list_ppt, node_dl **node_ppt );

/* Add a new node before a given node of a doubly linked list. */
void     list_dl_add_before( list_dl **list_ppt, node_dl **node_ppt, node_dl **new_node_ppt );

/* Add a new node after a given node of a doubly linked list. */
void     list_dl_add_after( list_dl **list_ppt, node_dl **node_ppt, node_dl **new_node_ppt );

/* Remove a node from a doubly linked list. */
void     list_dl_remove( list_dl **list_ppt, node_dl **node_ppt );

/* Debug function to print all elements from a doubly linked list. */
void     list_dl_print( list_dl *list_pt );

/* Debug funtion to print a doubly linked list node. */
void     node_dl_print( node_dl *node_pt );

/* Free memory for all nodes in and including the doubly linked list. */
void     list_dl_destroy( list_dl **list_ppt );

/* Free memory for doubly linked list node and value. */
void     node_dl_destroy( node_dl **node_ppt );

/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> GENERIC LINKED LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Returns the number of nodes in a linked list. */
size_t list_count( void *list_pt );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ASSORTED SORTING FUNCTIOS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/* Sort in ascending order according to char node values. */
int cmp_list_sl_char_asc( const void *a, const void *b );

/* Sort in descending order according to char node values. */
int cmp_list_sl_char_desc( const void *a, const void *b );


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


