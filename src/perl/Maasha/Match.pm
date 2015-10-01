package Maasha::Match;

# Copyright (C) 2007 Martin A. Hansen.

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


# Routines to match sequences


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Storable qw( dclone );
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Fasta;
use Maasha::Seq;
use Maasha::Biopieces;
use vars qw ( @ISA @EXPORT );

use constant {
    SEQ_NAME => 0,
    SEQ      => 1,
};

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub match_mummer
{
    # Martin A. Hansen, June 2007.

    # Match sequences using MUMmer.

    my ( $entries1,   # FASTA entries
         $entries2,   # FASTA entries
         $options,    # additional MUMmer options - OPTIONAL
         $tmp_dir,    # temporary directory
       ) = @_;

    # Returns a list.

    my ( @args, $arg, $file_in1, $file_in2, $cmd, $file_out, $fh, $line, $result, @results );

    $tmp_dir ||= $ENV{ "BP_TMP" };

    $options->{ "word_size" } ||= 20;
    $options->{ "direction" } ||= "both";

    push @args, "-c";
    push @args, "-L";
    push @args, "-F";
    push @args, "-l $options->{ 'word_size' }";
    push @args, "-maxmatch";
    push @args, "-n" if not Maasha::Seq::seq_guess_type( $entries1->[ 0 ]->[ 1 ] ) eq "PROTEIN";
    push @args, "-b" if $options->{ "direction" } =~ /^b/;
    push @args, "-r" if $options->{ "direction" } =~ /^r/;

    $arg = join " ", @args;

    $file_in1 = "$tmp_dir/muscle1.tmp";
    $file_in2 = "$tmp_dir/muscle2.tmp";
    $file_out = "$tmp_dir/muscle3.tmp";

    map { $_->[ 0 ] =~ tr/ /_/ } @{ $entries1 };
    map { $_->[ 0 ] =~ tr/ /_/ } @{ $entries2 };

    Maasha::Fasta::put_entries( $entries1, $file_in1 );
    Maasha::Fasta::put_entries( $entries2, $file_in2 );

    Maasha::Common::run( "mummer", "$arg $file_in1 $file_in2 > $file_out 2>/dev/null" );

    $fh = Maasha::Filesys::file_read_open( $file_out );

    while ( $line = <$fh> )
    {
        chomp $line;
        
        if ( $line =~ /^> (.+)Reverse\s+Len = (\d+)$/ )
        {
            $result->{ "Q_ID" }  = $1;
            $result->{ "Q_LEN" } = $2;
            $result->{ "DIR" }   = "reverse";
        }
        elsif ( $line =~ /^> (.+)Len = (\d+)$/ )
        {
            $result->{ "Q_ID" }  = $1;
            $result->{ "Q_LEN" } = $2;
            $result->{ "DIR" }   = "forward";
        }
        elsif ( $line =~ /^\s*(.\S+)\s+(\d+)\s+(\d+)\s+(\d+)$/ )
        {
            $result->{ "S_ID" }    = $1;
            $result->{ "S_BEG" }   = $2 - 1;
            $result->{ "Q_BEG" }   = $3 - 1;
            $result->{ "HIT_LEN" } = $4;
            $result->{ "S_END" }   = $result->{ "S_BEG" } + $result->{ "HIT_LEN" } - 1;
            $result->{ "Q_END" }   = $result->{ "Q_BEG" } + $result->{ "HIT_LEN" } - 1;

            push @results, dclone $result;
        }
    }

    unlink $file_in1;
    unlink $file_in2;
    unlink $file_out;

    return wantarray ? @results : \@results;
}


sub vmatch_index
{
    # Martin A. Hansen, July 2008.

    # Use mkvtree to create a vmatch index of a given file

    my ( $file,      # FASTA file to index
         $src_dir,   # source directory with FASTA file
         $dst_dir,   # distination directory for Vmatch index
         $tmp_dir,   # temp directory - OPTIONAL
       ) = @_;

    # Returns nothing.

    my ( $fh, $entry, $tmp_file );

    Maasha::Filesys::dir_create_if_not_exists( $dst_dir );

#    if ( Maasha::Common::file_size( $file ) < 200_000_000 )
#    {
#        &Maasha::Common::run( "mkvtree", "-db $src_dir/$file -dna -pl -allout -indexname $dst_dir/$file > /dev/null 3>&1" );
#    }
#    else
#    {
        $fh = Maasha::Filesys::file_read_open( "$src_dir/$file" );

        while ( $entry = Maasha::Fasta::get_entry( $fh ) )
        {
            $tmp_file = $entry->[ SEQ_NAME ] . ".fna";

            Maasha::Fasta::put_entries( [ $entry ], "$tmp_dir/$tmp_file" );

            Maasha::Common::run( "mkvtree", "-db $tmp_dir/$tmp_file -dna -pl -allout -indexname $dst_dir/$tmp_file > /dev/null 3>&1" );

            unlink "$tmp_dir/$tmp_file";
        }

        close $fh;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
