package Maasha::DB;

# Copyright (C) 2009 Martin A. Hansen.

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


# Routines for manipulating DBM files.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Common;
use DB_File;
use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub db_open
{
    # Martin A. Hansen, December 2009.

    # Ties a hash to a DBM file and returns the hash.

    my ( $path,   # path to DBM file
       ) = @_;

    # Returns a hash.

    my ( %hash );

    tie( %hash, 'DB_File', $path ) or Maasha::Common::error( qq(Could not tie-open file: "$path": $!) );

    return wantarray ? %hash : \%hash;
}


sub db_close
{
    # Martin A. Hansen, December 2009.

    # Unties a hash tied to a DBM file.

    my ( $db,   # hashref
       ) = @_;

    # Returns nothing.

    untie %{ $db };
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;

