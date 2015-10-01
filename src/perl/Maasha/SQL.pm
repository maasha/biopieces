package Maasha::SQL;

# Copyright (C) 2006 Martin A. Hansen.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# http://www.gnu.org/copyleft/gpl.html


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DESCRIPTION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# Routines for manipulation of MySQL via the DBI module.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use warnings;

use DBI;
use Data::Dumper;
use Time::HiRes;
use Maasha::Common;

use vars qw( @ISA @EXPORT );
use Exporter;

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub create_database
{
    my ( $database,
         $user,
         $password,
       ) = @_;

    system( "mysqladmin create $database --user=$user --password=$password" ) == 0 or
    die qq(ERROR: Could not create database "$database"!\n);

    return;
}        


sub delete_database
{
    my ( $database,
         $user,
         $password,
       ) = @_;

    die qq(ERROR: Protected database: "$database!\n" ) if $database =~/^(mysql|information_schema)$/i;
    system( "mysqladmin drop $database --force --user=$user --password=$password > /dev/null 2>&1"  ) == 0 or
    die qq(ERROR: Could not drop database "$database"!\n);

    return;
}        


sub database_exists
{
    # Martin A. Hansen, May 2008.

    # Checks if a given database exists. Returns 1 if so,
    # otherwise 0.

    my ( $database,   # MySQL database
         $user,       # MySQL username
         $pass,       # MySQL password
       ) = @_;
    
    # Return boolean.

    my ( @databases );

    @databases = list_databases( $user, $pass );

    if ( grep /^$database$/i, @databases ) {
        return 1;
    } else {
        return 0;
    }
}   


sub list_databases
{
    # Martin A. Hansen, May 2008.

    # Returns a list of databases available.

    my ( $user,   # MySQL username
         $pass,   # MySQL password
       ) = @_;

    # Returns a list. 

    my ( @databases );

    @databases = Maasha::Common::run_and_return( "mysqlshow", "--user=$user --password=$pass" );

    splice @databases, 0, 3;

    pop @databases;

    map { s/^\|\s+([^\s]+)\s+\|$/$1/ } @databases;

    return wantarray ? @databases : \@databases;
}


sub request
{
    my ( $dbh,
         $sql,
       ) = @_;

    my ( $sth, $errstr );

    if ( not $sth = $dbh->prepare( $sql ) ) 
    {
            $errstr = $DBI::errstr;

            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL PREPARE ERROR" );
    }
    
    if ( not $sth->execute )
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL EXECUTE ERROR" );
    }

    return;
}


sub query_hash
{
    # Niels Larsen, April 2003.

    # Executes a given sql query and returns the result as a hash
    # or hash reference. The keys are set to the values of the given
    # key. 

    my ( $dbh,   # Database handle
         $sql,   # SQL string
         $key,   # Key string, like "id", "name", .. 
       ) = @_;

    # Returns a hash.

    my ( $sth, $hash, $errstr );
    
    if ( not $sth = $dbh->prepare( $sql ) ) 
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL PREPARE ERROR" );
    }
    
    if ( not $sth->execute )
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL EXECUTE ERROR" );
    }
    
    if ( $hash = $sth->fetchall_hashref( $key ) )
    {
            return wantarray ? %{ $hash } : $hash;
    }
    else
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "DATABASE RETRIEVE ERROR" );
    }

    return;
}


sub query_array
{
    # Niels Larsen, April 2003.

    # Executes a given sql query and returns the result as a table
    # or table reference. 

    my ( $dbh,   # Database handle
         $sql,   # SQL string
         $out,   # Output specification, see DBI documentation. 
         ) = @_;

    # Returns a list.

    my ( $sth, $table, $errstr, @status );
    if ( not $sth = $dbh->prepare( $sql ) ) 
    {
            $errstr = $DBI::errstr;

            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL PREPARE ERROR" );
    }
    
    if ( not $sth->execute )
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "SQL EXECUTE ERROR" );
    }

    if ( $table = $sth->fetchall_arrayref( $out ) )
    {
            return wantarray ? @{ $table } : $table;
    }
    else
    {
            $errstr = $DBI::errstr;
        
            disconnect( $dbh );
            die qq(ERROR: $errstr, "DATABASE RETRIEVE ERROR" );
    }
}


sub query_hashref_list
{
    # Martin A. Hansen, May 2008.

    # Executes a SQL query and return the result
    # as a list of hashrefs.

    my ( $dbh,   # database handle
         $sql,   # sql query
       ) = @_;

    # Returns datastructure.

    my $table = $dbh->selectall_arrayref( $sql, { Slice => {} } );

    return wantarray ? @{ $table } : $table;
}


sub delete_table
{
    my ( $dbh,
         $table,
         ) = @_;

    request( $dbh, "drop table $table" );
}


sub list_tables
{
    my ( $dbh,
         ) = @_;

    my ( @list );

    @list = query_array( $dbh, "show tables" );

    if ( @list ) { 
        @list = map { $_->[0] } @list;
    } else { 
        @list = ();
    }

    return wantarray ? @list : \@list;
}


sub table_exists
{
    my ( $dbh,
         $name,
         ) = @_;

    if ( grep /^$name$/, list_tables( $dbh ) ) {
        return 1;
    } else {
        return;
    }
}


sub connect
{
    # Martin A. Hansen, May 2008.

    # Given a database, user and password,
    # obtains a database handle if the databse exists.

    my ( $database,   # MySQL database
         $user,       # MySQL user
         $pass,       # MySQL password
         ) = @_;

    # Returns object.

    my ( $dbh );

    Maasha::Common::error( qq(Database "$database" does not exist) ) if not database_exists( $database, $user, $pass );

    $dbh = DBI->connect(
        "dbi:mysql:$database", 
        $user,
        $pass,
        {
            RaiseError => 0, 
            PrintError => 0,
            AutoCommit => 0,
            ShowErrorStatement => 1,
        }
    );

    if ( $dbh ) {
        return $dbh;
    } else {
        Maasha::Common::error( qq($DBI::errstr) );
    }
}


sub disconnect
{
    my ( $dbh,
         ) = @_;

    if ( not $dbh->disconnect )
    {
        die qq(ERROR: $DBI::errstr );
    }        
}


sub update_field
{
    # Martin A. Hansen, April 2003.

    # updates the content of a single table cell

    my ( $dbh,     # database handle
         $table,   # table name
         $column,  # column where updating
         $old_val, # the old cell content
         $new_val, # the new cell content
       ) = @_;

    my ( $sql, $count, $count_sql );

    $count_sql = qq( SELECT $column FROM $table WHERE $column="$old_val"; );

    $count = scalar query_array( $dbh, $count_sql );

    if ( $count > 1 )
    {
        warn qq(WARNING: More than one entry found "$count_sql"\n);
    }
    elsif ( $count == 0 )
    {
        disconnect( $dbh );
        die qq(ERROR: entry not found "$count_sql"\n);
    }
    else
    {
        $sql = qq( UPDATE $table SET $column="$new_val" WHERE $column="$old_val"; );
        request( $dbh, $sql );
    }

    return;
}


sub delete_row
{
    # Martin A. Hansen, April 2003.

    # deletes a record form a table

    my ( $dbh,     # database handle
         $table,   # table name
         $field,   # field e.g. rec no
         $pattern, # specific pattern
       ) = @_;

    my $sql;

    $sql = qq(DELETE FROM $table WHERE $field = "$pattern";);

    request( $dbh, $sql );

    return;
}


sub add_row
{
    # Martin A. Hansen, April 2003.

    # adds a record to a table;

    my ( $dbh,    # database handle
         $table,  # table name
         $fields, # row to be inserted
       ) = @_;
    
    my ( $sql, $field, @fields, $quote_sql );

    foreach $field ( @{ $fields } )
    {
        if ( $field eq "NULL" or $field eq '' ) {
            push @fields, "NULL";
        } else {
            push @fields, $dbh->quote( $field );
        }
    }

    $sql = "INSERT INTO $table VALUES ( " . join( ", ", @fields ) . " );";

    request( $dbh, $sql );

    return;
}


sub add_column
{
    # Martin A. Hansen, April 2003.

    # inserts a column in a table

    my ( $dbh,    # database handle
         $table,  # table name
         $column, # name of column
         $type,   # variable type
         $index,  # enable index
       ) = @_;

    my $sql;

    if ( $index ) {
        $sql = "ALTER TABLE $table ADD COLUMN ( $column $type, INDEX $column" . "_index ( $column ) );";
    } else {
        $sql = "ALTER TABLE $table ADD COLUMN ( $column $type );";
    }
    
    request( $dbh, $sql );
    
    return;
}


sub del_column
{
    # Martin A. Hansen, April 2003.

    # deletes a column from a table

    my ( $dbh,    # databse handle
         $table,  # table name
         $column, # column to be deleted
    ) = @_;

    my $sql;

    $sql = "ALTER TABLE $table DROP COLUMN $column;";

    request( $dbh, $sql );

    return;
}


sub bulk_load_file
{
    # Martin A. Hansen, January 2004.

    # loads , seperated file in to sql table

    my ( $dbh,       # database handle object
         $path,      # filename with path
         $table,     # table to load data into
         $delimiter, # column delimiter - OPTIONAL
       ) = @_;

    # returns database handle object

    my $sql;

    $delimiter ||= "\t";

    $sql = qq( LOAD DATA LOCAL INFILE "$path" INTO TABLE $table FIELDS TERMINATED BY '$delimiter' );

    request( $dbh, $sql );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
