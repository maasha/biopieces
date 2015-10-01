package Maasha::BWA;

# Copyright (C) 2006-2009 Martin A. Hansen.

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


# Routines for manipulation of bowtie indexes and results.

# http://maq.sourceforge.net/bwa-man.shtml


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub bwa_index
{
    # Martin A. Hansen, September 2009.

    # Create a BWA index for fast sequence mapping.

    my ( $src_file,   # filename of source file
         $dst_dir,    # destination dir to store index
         $base_name,  # base name of index
         $verbose,    # verbose flag
       ) = @_;

    Maasha::Filesys::dir_create_if_not_exists( $dst_dir );

    if ( $verbose ) {
        Maasha::Common::run( "bwa", "index -p $dst_dir/$base_name $src_file" );
    } else {
        Maasha::Common::run( "bwa", "index -p $dst_dir/$base_name $src_file > /dev/null 2>&1" );
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;
