package Maasha::DumpFunc;

# Copyright (C) 2003 Martin A. Hansen.

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


# Routines to inspect objects and their inheritance.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Class::Inspector;
use vars qw ( @ISA @EXPORT );
use Exporter;

use Data::Dumper;

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub dump_func
{
    # Martin A. Hansen, August 2003.

    # given an object, the cognate functions are returned as a list

    my ( $obj,   # incomming object
       ) = @_;

    my ( $ref, $methods );

    $ref     = ref $obj;
    $methods = Class::Inspector->methods( $ref, 'full', 'public' );

#    @{ $methods } = grep /$ref/, @{ $methods };

    return wantarray ? @{ $methods } : $methods;
}


sub dump_test
{
    # Martin A. Hansen, August 2003.

    # given an object, returns the cognate function run with default values

    my ( $obj ,    # incomming object
       ) = @_;

    # returns a list of test lines to be printed

    my ( $methods, $method, $function, @lines );
    
    $methods = dump_func( $obj );
    
    foreach $method ( @{ $methods } )
    {
        $method   =~ /::(\w+)$/;
        $function = $1;
        next if not eval { $obj->$function };
        
        # push @lines, "Testing $function from $method --- Returns -> " . $obj->$function;
        print "TESTING $function FROM $method: RETURNS->" . $obj->$function . "\n";
    }

    return wantarray ? @lines : \@lines;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
