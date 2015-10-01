/* Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved */

/* Remove the last char from a string. Returns the length of the chopped string.*/
size_t chop( char *string );

/* Removes the last char from a string if the char is a newline. */
/* Returns the length of the chomped string or -1 is no newline was found. */
size_t chomp( char *string );

/* Returns the total number of a given char in a given string. */
size_t strchr_total( const char *string, const char c );

/* Locate a substr in a str starting at pos allowing for a given number of mismatches. */
/* Returns position of match begin or -1 if not found. */
size_t match_substr( size_t pos, char *str, size_t str_len, char *substr, size_t substr_len, size_t mismatch );

/* Locate a substr in a str backwards starting at the end of */
/* str minus pos allowing for a given number of mismatches. */
/* Returns position of match begin or -1 if not found. */
size_t match_substr_rev( size_t pos, char *str, size_t str_len, char *substr, size_t substr_len, size_t mismatch );
