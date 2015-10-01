package Maasha::BGB::Session;

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


# Routines for session handling of the Biopieces Browser.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Digest::MD5;
use JSON;
use Maasha::Common;
use Maasha::Filesys;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub session_new
{
    # Martin A. Hansen, December 2009.
  
    # Create a new session id which is md5 hashed.

    # Returns a string.

    my ( $sid );

    $sid = Digest::MD5::md5_hex( Maasha::Common::get_sessionid() );

    return $sid;
}


sub session_restore
{
    # Martin A. Hansen, December 2009.
    
    # Parses a tab seperated session file and returns the data
    # as a hash with user as key, and the rest of the columns as
    # a hash.

    my ( $file,   # session file
       ) = @_;

    # Returns a hashref.

    my ( $fh, $json, $json_text, $session );

    local $/ = undef;

    $fh = Maasha::Filesys::file_read_open( $file );

    $json_text = <$fh>;

    close $fh;

    $json = new JSON;

    $session = $json->decode( $json_text );

    return wantarray ? %{ $session } : $session;
}


sub session_store
{
    # Martin A. Hansen, December 2009.

    # Stores a session hash to file.

    my ( $file,      # file to store in.
         $session,   # session to store.
       ) = @_;

    # Returns nothing.

    my ( $json, $json_text, $fh );

    $json = new JSON;

    $json_text = $json->pretty->encode( $session );

    $fh = Maasha::Filesys::file_write_open( $file );

    print $fh $json_text;

    close $fh;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;

__END__
