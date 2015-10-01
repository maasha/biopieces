package Maasha::Config;

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


# This module contains configuration details for the usual system setup, etc.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> GLOBALS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


my ( $HOME, $PATH, $BP_DATA, $BP_TMP, $BP_DIR );

$HOME     = $ENV{ "HOME" };     
$PATH     = $ENV{ "PATH" };     
$BP_DIR   = $ENV{ "BP_DIR" };
$BP_DATA  = $ENV{ "BP_DATA" }; 
$BP_TMP   = $ENV{ "BP_TMP" };  

warn qq(WARNING: HOME not set in env\n)     if not defined $HOME;
warn qq(WARNING: PATH not set in env\n)     if not defined $PATH;
warn qq(WARNING: BP_DIR not set in env\n)   if not defined $BP_DIR;
warn qq(WARNING: BP_DATA not set in env\n)  if not defined $BP_DATA;
warn qq(WARNING: BP_TMP not set in env\n)   if not defined $BP_TMP;


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub get_exe
{
    # Martin A. Hansen, April 2007.

    # finds a given exe in path and returns
    # the full path to the exe.

    my ( $exe,
       ) = @_;

    # returns string

    my ( $dir, $ok );

    foreach $dir ( split /:/, $PATH ) {
        return "$dir/$exe" if -x "$dir/$exe" and not -d "$dir/$exe";
    }

    Maasha::Common::error( qq(Could not find executable \'$exe\') );
}


sub genome_fasta
{
    # Martin A. Hansen, November 2007.

    # Returns the full path to the FASTA file for
    # a given genome.

    my ( $genome,   # requested genome
       ) = @_;

    # Returns string.

    my $genome_file = "$BP_DATA/genomes/$genome/$genome.fna";

    if ( not -f $genome_file ) {
        Maasha::Common::error( qq(Genome file "$genome_file" for genome "$genome" not found) );
    }

    return $genome_file;
}


sub genome_fasta_index
{
    # Martin A. Hansen, December 2007.

    # Returns the full path to the FASTA file index for
    # a given genome.

    my ( $genome,   # requested genome
       ) = @_;

    # Returns string.

    my $index = "$BP_DATA/genomes/$genome/$genome.fna.index";

    if ( not -f $index ) {
        Maasha::Common::error( qq(Index file "$index" for genome -> $genome not found) );
    }

    return $index;
}


sub genome_blast
{
    # Martin A. Hansen, November 2007.

    # Returns the BLAST database path for a given genome.

    my ( $genome,      # requested genome
       ) = @_;

    # Returns string.

    my $file = "$BP_DATA/genomes/$genome/blast/$genome.fna";

    return $file;
}


sub genome_blat_ooc
{
    # Martin A. Hansen, November 2007.

    # Returns the ooc file of a given tile size
    # for a given genome.

    my ( $genome,      # requested genome
         $tile_size,   # blat tile size
       ) = @_;

    # Returns string.

    my $ooc_file = "$BP_DATA/genomes/$genome/blat/$tile_size.ooc";

    Maasha::Common::error( qq(ooc file "$ooc_file" not found for genome -> $genome) ) if not -f $ooc_file;

    return $ooc_file;
}


sub genome_vmatch
{
    # Martin A. Hansen, November 2007.

    # Returns a list of Vmatch index names for a given genome.

    my ( $genome,   # requested genome
       ) = @_;

    # Returns a list.

    my ( @chrs );

    @chrs = chromosomes( $genome );

    map { $_ = "$BP_DATA/genomes/$genome/vmatch/$_" } @chrs;

    # needs robustness check

    return wantarray ? @chrs : \@chrs;
}


sub genomes
{
    # Martin A. Hansen, February 2008.

    # Returns a list of available genomes in the,
    # genomes.conf file.

    # Returns a list.

    my ( %genome_hash, $fh, $line, @genomes, $org );

    $fh = Maasha::Common::read_open( "$BP_DIR/conf/genomes.conf" );

    while ( $line = <$fh> )
    {
        chomp $line;

        next if $line eq "//";

        ( $org, undef ) = split "\t", $line;

        $genome_hash{ $org } = 1;
    }

    close $fh;

    @genomes = sort keys %genome_hash;

    return wantarray ? @genomes : \@genomes;
}


sub chromosomes
{
    # Martin A. Hansen, November 2007.

    # Returns a list of chromosome files for a given genome
    # read from the genomes.conf file.

    my ( $genome,   # requested genome
       ) = @_;

    # Returns a list.

    my ( $fh_in, $line, $org, $chr, %genome_hash, @chrs );

    $fh_in = Maasha::Common::read_open( "$BP_DIR/bp_conf/genomes.conf" );

    while ( $line = <$fh_in> )
    {
        chomp $line;

        next if $line eq "//";

        ( $org, $chr ) = split "\t", $line;

        push @{ $genome_hash{ $org } }, $chr;
    }

    close $fh_in;

    if ( exists $genome_hash{ $genome } ) {
        @chrs = @{ $genome_hash{ $genome } };
    } else {
        Maasha::Common::error( qq(Genome -> $genome not found in genome hash) );
    }

    return wantarray ? @chrs : \@chrs;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;
