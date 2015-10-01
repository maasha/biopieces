package Maasha::NClist;

# Copyright (C) 2010 Martin A. Hansen.

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


# Nested Containment List (NCList): A new algorithm for accelerating
# interval query of genome alignment and interval databases
# http://bioinformatics.oxfordjournals.org/cgi/content/abstract/btl647v1

# Nested lists are composed of intervals defined by begin and end positions,
# and any interval that is contained within another interval is rooted to this.
# Thus, fast interval lookups can be performed using binary search.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;

use Maasha::Filesys;
use Data::Dumper;
use Time::HiRes;
use JSON::XS;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub nc_list_create
{
    # Martin A. Hansen, February 2010.

    # Creates a Nested Containment (NC) list from a stack of features.
    # The features consits of an AoA where beg and end specifies the
    # elements containing the begin and end position of a feature, and
    # index specifies a element used for nesting lists.

    my ( $features,   # list of features AoA
         $beg,        # feature element with begin position
         $end,        # feature element with end position
         $index,      # feature element with index position
       ) = @_;

    # Returns a list.

    my ( $nc_list );

    @{ $features } = sort { $a->[ $beg ] <=> $b->[ $beg ] or $b->[ $end ] <=> $a->[ $end ] } @{ $features };

    $nc_list = [ shift @{ $features } ];

    map { nc_list_add( $nc_list, $_, $end, $index ) } @{ $features };

    return wantarray ? @{ $nc_list } : $nc_list;
}


sub nc_list_add
{
    # Martin A. Hansen, February 2010.
    
    # Recursively construct a Nested Containment (NC) list by adding
    # a given feature to an existing NC list.

    my ( $nc_list,   # NC list
         $feat,      # feature (AoA)
         $end,       # feature element with end position
         $index      # feature element with index position
       ) = @_;

    # Returns nothing.

    if ( $feat->[ $end ] <= $nc_list->[ -1 ]->[ $end ] ) # feature is nested.
    {
        if ( defined $nc_list->[ -1 ]->[ $index ] ) {   # sublist exists so recurse to this.
            nc_list_add( $nc_list->[ -1 ]->[ $index ], $feat, $end, $index );
        } else {
            $nc_list->[ -1 ]->[ $index ] = [ $feat ];   # creating a new sublist.
        }
    }
    else
    {
        push @{ $nc_list }, $feat;
    }
}


sub nc_list_lookup
{
    # Martin A. Hansen, February 2010.
    
    # Given a Nested Containment (NC) list use binary search to locate
    # the NC list containing a given search position. The index of the NC
    # list containing the search position is returned. Extremely fast.

    my ( $nc_list,   # NC list
         $pos,       # search position
         $beg,       # feature element with begin position
         $end,       # feature element with end position
         $index,     # feature element with index position
       ) = @_;

    # Returns an integer.

    my ( $low, $high, $try );

    $low  = 0;
    $high = scalar @{ $nc_list };

    while ( $low < $high )
    {
        $try = int( ( $high + $low ) / 2 );

        if ( $pos < $nc_list->[ $try ]->[ $beg ] ) {
            $high = $try;
        } elsif ( $nc_list->[ $try ]->[ $end ] < $pos ) {
            $low = $try + 1;
        } else {
            last;
        }
    }

    return $try;
}


sub nc_list_count
{
    # Martin A. Hansen, February 2010.

    # Traverses a Nested Containment (NC) list recursively from a
    # given index begin to a given index end and counts all
    # features. The count is returned.

    my ( $nc_list,     # NC list
         $index_beg,   # index begin
         $index_end,   # index end
         $index,       # feature element with index position
       ) = @_;

    # Returns an integer.

    my ( $i, $count );

    for ( $i = $index_beg; $i <= $index_end; $i++ )
    {
        $count++;
    
        if ( defined $nc_list->[ $i ]->[ $index ] ) {   # sublist exists so recurse to this.
            $count += nc_list_count( $nc_list->[ $i ]->[ $index ], 0, scalar @{ $nc_list->[ $i ]->[ $index ] } - 1, $index );
        }
    }

    return $count;
}


sub nc_list_count_interval
{
    # Martin A. Hansen, February 2010.

    # Counts all features in a Nested Containment (NC) list within a
    # specified interval. The count is returned.

    my ( $nc_list,   # NC list
         $int_beg,   # interval begin
         $int_end,   # interval end
         $beg,       # feature element with begin position
         $end,       # feature element with end position
         $index,     # feature element with index position
       ) = @_;

    # Returns an integer.

    my ( $index_beg, $index_end, $count );

    $index_beg = nc_list_lookup( $nc_list, $int_beg, $beg, $end, $index );
    $index_end = nc_list_lookup( $nc_list, $int_end, $beg, $end, $index );

    $count = nc_list_count( $nc_list, $index_beg, $index_end, $index );

    return $count;
}


sub nc_list_get
{
    # Martin A. Hansen, February 2010.

    # Recursively retrieve all features from a Nested Containment (NC) list
    # from a specified index begin to a specified index end.

    # WARNING: The NC list is distroyed because the sublists are stripped.

    my ( $nc_list,     # NC list
         $index_beg,   # index begin
         $index_end,   # index end
         $index,       # feature element with index position
       ) = @_;

    # Returns a list.

    my ( $i, @features );

    for ( $i = $index_beg; $i <= $index_end; $i++ )
    {
        push @features, $nc_list->[ $i ];

        if ( defined $nc_list->[ $i ]->[ $index ] ) # sublist exists so recurse to this.
        {  
            push @features, nc_list_get( $nc_list->[ $i ]->[ $index ], 0, scalar @{ $nc_list->[ $i ]->[ $index ] } - 1, $index );

            delete $nc_list->[ $i ]->[ $index ];
        }
    }

    return wantarray ? @features : \@features;
}


sub nc_list_get_interval
{
    # Martin A. Hansen, February 2010.
    
    # Retrieve all features from a Nested Containment (NC) list from within
    # a specified interval.

    my ( $nc_list,   # NC list
         $int_beg,   # interval begin
         $int_end,   # interval end
         $beg,       # feature element with begin position
         $end,       # feature element with end position
         $index,     # feature element with index position
       ) = @_;

    # Returns a list.

    my ( $index_beg, $index_end, $features );

    $index_beg = nc_list_lookup( $nc_list, $int_beg, $beg, $end, $index );
    $index_end = nc_list_lookup( $nc_list, $int_end, $beg, $end, $index );

    $features = nc_list_get( $nc_list, $index_beg, $index_end, $index );

    return wantarray ? @{ $features } : $features;
}


sub nc_list_search
{
    # Martin A. Hansen, February 2010.

    # Recursively search a Nested Containment (NC) list for features matching
    # a given REGEX.

    my ( $nc_list,   # NC list
         $regex,     # regex to search for
         $index,     # feature element with index position
       ) = @_;

    # Returns a list.

    my ( $feature, @features );

    foreach $feature ( @{ $nc_list } )
    {
        push @features, $feature if grep { $_ =~ /$regex/i if defined $_ } @{ $feature };

        if ( defined $feature->[ $index ] ) # sublist exists so recurse to this.
        {  
            push @features, nc_list_search( $feature->[ $index ], $regex, $index );

            delete $feature->[ $index ];
        }
    }

    return wantarray ? @features : \@features;
}


sub nc_list_store
{
    # Martin A. Hansen, February 2010.

    # Store a Nested Containment (NC) list to a
    # given file.

    my ( $nc_list,   # NC list
         $file,      # path to file
       ) = @_;

    # Returns nothing.
    
    my ( $fh, $json );

    $json = JSON::XS::encode_json( $nc_list );

    $fh = Maasha::Filesys::file_write_open( $file );

    print $fh $json;

    close $fh;
}


sub nc_list_retrieve
{
    # Martin A. Hansen, February 2010.

    # Retrieves a Nested Containment (NC) list from a
    # JSON file.

    my ( $file,   # path to JSON file
       ) = @_;

    # Returns NC list.

    my ( $fh, $json, $nc_list );

    local $/ = undef;

    $fh = Maasha::Filesys::file_read_open( $file );

    $json = <$fh>;

    close $fh;

    $nc_list = JSON::XS::decode_json( $json );

    return wantarray ? @{ $nc_list } : $nc_list;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;

__END__

    my $t0 = Time::HiRes::gettimeofday();
    my $t1 = Time::HiRes::gettimeofday(); print STDERR "Time: " . ( $t1 - $t0 ) . "\n";
