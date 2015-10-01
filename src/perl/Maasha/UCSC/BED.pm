package Maasha::UCSC::BED;

# Copyright (C) 2007-2008 Martin A. Hansen.

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


# Routines for interaction with Browser Extensible DATA (BED) entries and files.

# Read about the BED format here: http://genome.ucsc.edu/FAQ/FAQformat#format1


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;

use Data::Dumper;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Calc;

use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
);

use constant {
    chrom       => 0,   # BED field names
    chromStart  => 1,
    chromEnd    => 2,
    name        => 3,
    score       => 4,
    strand      => 5,
    thickStart  => 6,
    thickEnd    => 7,
    itemRgb     => 8,
    blockCount  => 9,
    blockSizes  => 10,
    blockStarts => 11,
    CHR         => 0,    # Biopieces field names
    CHR_BEG     => 1,
    CHR_END     => 2,
    Q_ID        => 3,
    SCORE       => 4,
    STRAND      => 5,
    THICK_BEG   => 6,
    THICK_END   => 7,
    COLOR       => 8,
    BLOCK_COUNT => 9,
    BLOCK_LENS  => 10,
    Q_BEGS      => 11,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BED format <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# Hash for converting BED keys to Biopieces keys.

my %BED2BIOPIECES = (
    chrom       => "CHR",
    chromStart  => "CHR_BEG",
    chromEnd    => "CHR_END",
    name        => "Q_ID",
    score       => "SCORE",
    strand      => "STRAND",
    thickStart  => "THICK_BEG",
    thickEnd    => "THICK_END",
    itemRgb     => "COLOR",
    blockCount  => "BLOCK_COUNT",
    blockSizes  => "BLOCK_LENS",
    blockStarts => "Q_BEGS",
);


# Hash for converting biopieces keys to BED keys.

my %BIOPIECES2BED = (
    CHR         => "chrom",
    CHR_BEG     => "chromStart",
    CHR_END     => "chromEnd",
    Q_ID        => "name",
    SCORE       => "score",
    STRAND      => "strand",
    THICK_BEG   => "thickStart",
    THICK_END   => "thickEnd",
    COLOR       => "itemRgb",
    BLOCK_COUNT => "blockCount",
    BLOCK_LENS  => "blockSizes",
    Q_BEGS      => "blockStarts",
);


sub bed_entry_get
{
    # Martin A. Hansen, September 2008.

    # Reads a BED entry given a filehandle.

    my ( $fh,     # file handle
         $cols,   # columns to read               - OPTIONAL (3,4,5,6,8,9 or 12)
         $check,  # check integrity of BED values - OPTIONAL
       ) = @_;

    # Returns a list.

    my ( $line, @entry );

    $line = <$fh>;

    return if not defined $line;

    $line =~ tr/\n\r//d;    # some people have carriage returns in their BED files -> Grrrr

    if ( not defined $cols ) {
        $cols = 1 + $line =~ tr/\t//;
    }

    @entry = split "\t", $line, $cols + 1;

    pop @entry if scalar @entry > $cols;

    bed_entry_check( \@entry ) if $check;

    return wantarray ? @entry : \@entry;
}


sub bed_entry_put
{
    # Martin A. Hansen, September 2008.

    # Writes a BED entry array to file.

    my ( $entry,   # list
         $fh,      # file handle                   - OPTIONAL
         $cols,    # number of columns in BED file - OPTIONAL (3,4,5,6,8,9 or 12)
         $check,   # check integrity of BED values - OPTIONAL
       ) = @_;

    # Returns nothing.

    if ( $cols and $cols < scalar @{ $entry } ) {
        @{ $entry } = @{ $entry }[ 0 .. $cols - 1 ];
    }

    bed_entry_check( $entry ) if $check;

    $fh = \*STDOUT if not defined $fh;

    print $fh join( "\t", @{ $entry } ), "\n";
}



sub bed_entry_check
{
    # Martin A. Hansen, November 2008.

    # Checks a BED entry for integrity and
    # raises an error if there is a problem.

    my ( $bed,   # array ref
       ) = @_;

    # Returns nothing.

    my ( $entry, $cols, @block_sizes, @block_starts );

    $entry = join "\t", @{ $bed };
    $cols  = scalar @{ $bed };

    if ( $cols < 3 ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - must contain at least 3 columns - not $cols) );
    }

    if ( $cols > 12 ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - must contains no more than 12 columns - not $cols) );
    }

    if ( $bed->[ chrom ] =~ /\s/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - no white space allowed in chrom field: "$bed->[ chrom ]") );
    }

    if ( $bed->[ chromStart ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - chromStart must be a whole number - not "$bed->[ chromStart ]") );
    }

    if ( $bed->[ chromEnd ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - chromEnd must be a whole number - not "$bed->[ chromEnd ]") );
    }

    if ( $bed->[ chromEnd ] < $bed->[ chromStart ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - chromEnd must be greater than chromStart - not "$bed->[ chromStart ] > $bed->[ chromEnd ]") );
    }

    return if $cols == 3;

    if ( $bed->[ name ] =~ /\s/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - no white space allowed in name field: "$bed->[ name ]") );
    }

    return if $cols == 4;

    if ( $bed->[ score ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - score must be a whole number - not "$bed->[ score ]") );
    }

    # if ( $bed->[ score ] < 0 or $bed->[ score ] > 1000 ) { # disabled - too restrictive !
    if ( $bed->[ score ] < 0 ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - score must be between 0 and 1000 - not "$bed->[ score ]") );
    }

    return if $cols == 5;

    if ( $bed->[ strand ] ne '+' and $bed->[ strand ] ne '-' ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - strand must be + or - not "$bed->[ strand ]") );
    }

    return if $cols == 6;

    if ( $bed->[ thickStart ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickStart must be a whole number - not "$bed->[ thickStart ]") );
    }

    if ( $bed->[ thickEnd ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickEnd must be a whole number - not "$bed->[ thickEnd ]") );
    }

    if ( $bed->[ thickEnd ] < $bed->[ thickStart ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickEnd must be greater than thickStart - not "$bed->[ thickStart ] > $bed->[ thickEnd ]") );
    }

    if ( $bed->[ thickStart ] < $bed->[ chromStart ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickStart must be greater than chromStart - not "$bed->[ thickStart ] < $bed->[ chromStart ]") );
    }

    if ( $bed->[ thickStart ] > $bed->[ chromEnd ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickStart must be less than chromEnd - not "$bed->[ thickStart ] > $bed->[ chromEnd ]") );
    }

    if ( $bed->[ thickEnd ] < $bed->[ chromStart ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickEnd must be greater than chromStart - not "$bed->[ thickEnd ] < $bed->[ chromStart ]") );
    }

    if ( $bed->[ thickEnd ] > $bed->[ chromEnd ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - thickEnd must be less than chromEnd - not "$bed->[ thickEnd ] > $bed->[ chromEnd ]") );
    }

    return if $cols == 8;

    if ( $bed->[ itemRgb ] !~ /^(0|\d{1,3},\d{1,3},\d{1,3},?)$/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - itemRgb must be 0 or in the form of 255,0,0 - not "$bed->[ itemRgb ]") );
    }

    return if $cols == 9;

    if ( $bed->[ blockCount ] =~ /\D/ ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - blockCount must be a whole number - not "$bed->[ blockCount ]") );
    }

    @block_sizes = split ",", $bed->[ blockSizes ];

    if ( grep /\D/, @block_sizes ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - blockSizes must be whole numbers - not "$bed->[ blockSizes ]") );
    }

    if ( $bed->[ blockCount ] != scalar @block_sizes ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - blockSizes "$bed->[ blockSizes ]" must match blockCount "$bed->[ blockCount ]") );
    }

    @block_starts = split ",", $bed->[ blockStarts ];

    if ( grep /\D/, @block_starts ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - blockStarts must be whole numbers - not "$bed->[ blockStarts ]") );
    }

    if ( $bed->[ blockCount ] != scalar @block_starts ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - blockStarts "$bed->[ blockStarts ]" must match blockCount "$bed->[ blockCount ]") );
    }

    if ( $bed->[ chromStart ] + $block_starts[ -1 ] + $block_sizes[ -1 ] != $bed->[ chromEnd ] ) {
        Maasha::Common::error( qq(Bad BED entry "$entry" - chromStart + blockStarts[last] + blockSizes[last] must equal chromEnd: ) .
                               qq($bed->[ chromStart ] + $block_starts[ -1 ] + $block_sizes[ -1 ] != $bed->[ chromEnd ]) );
    }
}


sub bed_sort
{
    # Martin A. hansen, November 2008.

    # Sorts a given BED file according to a given
    # sorting scheme:
    # 1: chr AND chr_beg.
    # 2: chr AND strand AND chr_beg.
    # 3: chr_beg.
    # 4: strand AND chr_beg.

    # Currently 'bed_sort' is used for sorting = a standalone c program
    # that uses qsort (unstable sort).

    my ( $file_in,  # path to BED file.
         $scheme,   # sort scheme
         $cols,     # number of columns in BED file
       ) = @_;

    # Returns nothing.

    my ( $file_out );
    
    $file_out = "$file_in.sort";
    
    Maasha::Common::run( "bed_sort", "--sort $scheme --cols $cols $file_in > $file_out" );

    if ( Maasha::Filesys::file_size( $file_in ) !=  Maasha::Filesys::file_size( $file_out ) ) {
        Maasha::Common::error( qq(bed_sort of file "$file_in" failed) );
    }

    rename $file_out, $file_in;
}


sub bed_file_split_on_chr
{
    # Martin A. Hansen, November 2008.

    # Given a path to a BED file splits
    # this file into one file per chromosome
    # in a temporary directory. Returns a hash
    # with chromosome name as key and the corresponding
    # file as value.

    my ( $file,   # path to BED file
         $dir,    # working directory
         $cols,   # number of BED columns to read - OPTIONAL
       ) = @_;

    # Returns a hashref
    
    my ( $fh_in, $fh_out, $entry, %fh_hash, %file_hash );

    $fh_in = Maasha::Filesys::file_read_open( $file );

    while ( $entry = bed_entry_get( $fh_in, $cols ) ) 
    {
        if ( not exists $file_hash{ $entry->[ chrom ] } )
        {
            $fh_hash{ $entry->[ chrom ] }   = Maasha::Filesys::file_write_open( "$dir/$entry->[ chrom ]" );
            $file_hash{ $entry->[ chrom ] } = "$dir/$entry->[ chrom ]";
        }

        $fh_out = $fh_hash{ $entry->[ chrom ] };
    
        Maasha::UCSC::BED::bed_entry_put( $entry, $fh_out, $cols );
    }

    map { close $_ } keys %fh_hash;

    return wantarray ? %file_hash : \%file_hash;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BIOPIECES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub bed2biopiece
{
    # Martin A. Hansen, November 2008.

    # Converts a BED entry given as an arrayref
    # to a Biopiece record which is returned as
    # a hashref.

    # IMPORTANT! The BED_END and THICK_END positions
    # will be the exact position in contrary to the
    # UCSC scheme.
    
    my ( $bed_entry,   # BED entry as arrayref
       ) = @_;

    # Returns a hashref

    my ( $cols, %bp_record );

    $cols = scalar @{ $bed_entry };
    
    if ( not defined $bed_entry->[ chrom ] and
         not defined $bed_entry->[ chromStart ] and
         not defined $bed_entry->[ chromEnd ] )
    {
        return 0;
    }

    $bp_record{ "REC_TYPE" } = "BED";
    $bp_record{ "BED_COLS" } = $cols;
    $bp_record{ "CHR" }      = $bed_entry->[ chrom ];
    $bp_record{ "CHR_BEG" }  = $bed_entry->[ chromStart ];
    $bp_record{ "CHR_END" }  = $bed_entry->[ chromEnd ] - 1;
    $bp_record{ "BED_LEN" }  = $bed_entry->[ chromEnd ] - $bed_entry->[ chromStart ];

    return wantarray ? %bp_record : \%bp_record if $cols == 3;

    $bp_record{ "Q_ID" } = $bed_entry->[ name ];

    return wantarray ? %bp_record : \%bp_record if $cols == 4;

    $bp_record{ "SCORE" } = $bed_entry->[ score ];

    return wantarray ? %bp_record : \%bp_record if $cols == 5;

    $bp_record{ "STRAND" } = $bed_entry->[ strand ];

    return wantarray ? %bp_record : \%bp_record if $cols == 6;

    $bp_record{ "THICK_BEG" }   = $bed_entry->[ thickStart ];
    $bp_record{ "THICK_END" }   = $bed_entry->[ thickEnd ] - 1;

    return wantarray ? %bp_record : \%bp_record if $cols == 8;

    $bp_record{ "COLOR" }       = $bed_entry->[ itemRgb ];

    return wantarray ? %bp_record : \%bp_record if $cols == 9;

    $bp_record{ "BLOCK_COUNT" } = $bed_entry->[ blockCount ];
    $bp_record{ "BLOCK_LENS" }  = $bed_entry->[ blockSizes ];
    $bp_record{ "Q_BEGS" }      = $bed_entry->[ blockStarts ];

    return wantarray ? %bp_record : \%bp_record;
}


sub biopiece2bed
{
    # Martin A. Hansen, November 2008.

    # Converts a Biopieces record given as a hashref
    # to a BED record which is returned as
    # an arrayref. As much as possible of the Biopiece
    # record is converted and undef is returned if 
    # convertion failed.

    # IMPORTANT! The chromEnd and thickEnd positions
    # will be the inexact position used in the
    # UCSC scheme (+1 to all ends).
    
    my ( $bp_record,   # hashref
         $cols,        # number of columns in BED entry - OPTIONAL (but faster)
       ) = @_;

    # Returns arrayref.

    my ( @bed_entry, @begs );

    $cols ||= 12;   # max number of columns possible

    $bed_entry[ chrom ] = $bp_record->{ "CHR" }  ||
                          $bp_record->{ "S_ID" } ||
                          return undef;

    if ( defined $bp_record->{ "CHR_BEG" } ) {
        $bed_entry[ chromStart ] = $bp_record->{ "CHR_BEG" };
    } elsif ( defined $bp_record->{ "S_BEG" } ) {
        $bed_entry[ chromStart ] = $bp_record->{ "S_BEG" };
    } else {
        return undef;
    }

    if ( defined $bp_record->{ "CHR_END" } ) {
        $bed_entry[ chromEnd ] = $bp_record->{ "CHR_END" } + 1;
    } elsif ( defined $bp_record->{ "S_END" }) {
        $bed_entry[ chromEnd ] = $bp_record->{ "S_END" } + 1;
    } else {
        return undef;
    }

    return wantarray ? @bed_entry : \@bed_entry if $cols == 3;

    $bed_entry[ name ] = $bp_record->{ "Q_ID" } || return wantarray ? @bed_entry : \@bed_entry;

    return wantarray ? @bed_entry : \@bed_entry if $cols == 4;

    if ( exists $bp_record->{ "SCORE" } ) {
        $bed_entry[ score ] = $bp_record->{ "SCORE" };
    } elsif ( exists $bp_record->{ "BIT_SCORE" } ) {
        $bed_entry[ score ] = $bp_record->{ "BIT_SCORE" };
    } else {
        return wantarray ? @bed_entry : \@bed_entry;
    }

    return wantarray ? @bed_entry : \@bed_entry if $cols == 5;

    if ( exists $bp_record->{ "STRAND" } ) {
        $bed_entry[ strand ] = $bp_record->{ "STRAND" };
    } else {
        return wantarray ? @bed_entry : \@bed_entry;
    }

    return wantarray ? @bed_entry : \@bed_entry if $cols == 6;

    if ( defined $bp_record->{ "THICK_BEG" }   and
         defined $bp_record->{ "THICK_END" } )
    {
        $bed_entry[ thickStart ] = $bp_record->{ "THICK_BEG" };
        $bed_entry[ thickEnd ]   = $bp_record->{ "THICK_END" } + 1;
    }
    elsif ( defined $bp_record->{ "BLOCK_COUNT" } )
    {
        $bed_entry[ thickStart ] = $bed_entry[ chromStart ];
        $bed_entry[ thickEnd ]   = $bed_entry[ chromEnd ];
    }

    return wantarray ? @bed_entry : \@bed_entry if $cols == 8;

    if ( defined $bp_record->{ "COLOR" } )
    {
        $bed_entry[ itemRgb ] = $bp_record->{ "COLOR" };
    }
    elsif ( defined $bp_record->{ "BLOCK_COUNT" } )
    {
        $bed_entry[ itemRgb ] = 0;
    }

    return wantarray ? @bed_entry : \@bed_entry if $cols == 9;

    if ( defined $bp_record->{ "BLOCK_COUNT" } and
         defined $bp_record->{ "BLOCK_LENS" }  and
         defined $bp_record->{ "S_BEGS" } )
    {
        @begs = split ",", $bp_record->{ "S_BEGS" };
        map { $_ -= $bed_entry[ chromStart ] } @begs;

        $bed_entry[ blockCount ]  = $bp_record->{ "BLOCK_COUNT" };
        $bed_entry[ blockSizes ]  = $bp_record->{ "BLOCK_LENS" };
        $bed_entry[ blockStarts ] = join ",", @begs;
        # $bed_entry[ thickEnd ]    = $bp_record->{ "THICK_END" } + 1;
    }
    elsif ( defined $bp_record->{ "BLOCK_COUNT" } and
            defined $bp_record->{ "BLOCK_LENS" }  and
            defined $bp_record->{ "Q_BEGS" } )
    {
        $bed_entry[ blockCount ]  = $bp_record->{ "BLOCK_COUNT" };
        $bed_entry[ blockSizes ]  = $bp_record->{ "BLOCK_LENS" };
        $bed_entry[ blockStarts ] = $bp_record->{ "Q_BEGS" };
        # $bed_entry[ thickEnd  ]   = $bp_record->{ "THICK_END" } + 1;
    }

    return wantarray ? @bed_entry : \@bed_entry;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TAG CONTIGS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub tag_contigs_assemble
{
    # Martin A. Hansen, November 2008.

    # Returns a path to a BED file with tab contigs.

    my ( $bed_file,   # path to BED file
         $chr,        # chromosome
         $strand,     # strand
         $dir,        # working directory
       ) = @_;
         
    # Returns a string

    my ( $fh_in, $fh_out, $array, $new_file, $pos, $id, $beg, $end, $score, $entry );

    $fh_in = Maasha::Filesys::file_read_open( $bed_file );

    $array = tag_contigs_assemble_array( $fh_in );

    close $fh_in;

    $new_file = "$bed_file.tag_contigs";

    $fh_out = Maasha::Filesys::file_write_open( $new_file );

    $pos = 0;
    $id  = 0;

    while ( ( $beg, $end, $score ) = tag_contigs_scan( $array, $pos ) and $beg )
    {
        $entry->[ chrom ]      = $chr;
        $entry->[ chromStart ] = $beg;
        $entry->[ chromEnd ]   = $end;
        $entry->[ name ]       = sprintf( "TC%06d", $id );
        $entry->[ score ]      = $score;
        $entry->[ strand ]     = $strand;

        bed_entry_put( $entry, $fh_out );

        $pos = $end;
        $id++;
    }

    close $fh_out;

    return $new_file;
}


sub tag_contigs_assemble_array
{
    # Martin A. Hansen, November 2008.

    # Given a BED file with entries from only one
    # chromosome assembles tag contigs from these
    # ignoring strand information. Only tags with
    # a score higher than the clone count over
    # genomic loci (the score field) is included
    # in the tag contigs.

    #       -----------              tags
    #          -------------
    #               ----------
    #                     ----------
    #       ========================  tag contig


    my ( $fh,   # file handle to BED file
       ) = @_;

    # Returns an arrayref.

    my ( $entry, $clones, $score, @array );

    while ( $entry = bed_entry_get( $fh ) )
    {
        if ( $entry->[ name ] =~ /_(\d+)$/ )
        {
            $clones = $1;

            if ( $entry->[ score ] )
            {
                $score = int( $clones / $entry->[ score ] );

                map { $array[ $_ ] += $score } $entry->[ chromStart ] .. $entry->[ chromEnd ] - 1 if $score >= 1;
            } 
        }
    }

    return wantarray ? @array : \@array;
}


sub tag_contigs_scan
{
    # Martin A. Hansen, November 2008.
    
    # Scans an array with tag contigs and locates
    # the next contig from a given position. The
    # score of the tag contig is determined as the
    # maximum value of the tag contig. If a tag contig
    # is found a triple is returned with beg, end and score
    # otherwise an empty list is returned.

    my ( $array,   # array to scan
         $beg,     # position to start scanning from
       ) = @_;

    # Returns an arrayref.

    my ( $end, $score );

    $score = 0;

    while ( $beg < scalar @{ $array } and not $array->[ $beg ] ) { $beg++ }

    $end = $beg;

    while ( $array->[ $end ] )
    {
        $score = Maasha::Calc::max( $score, $array->[ $end ] );
    
        $end++
    }

    if ( $score > 0 ) {
        return wantarray ? ( $beg, $end, $score ) : [ $beg, $end, $score ];
    } else {
        return wantarray ? () : [];
    }
}


sub bed_upload_to_ucsc
{
    # Martin A. Hansen, September 2007.

    # Upload a BED file to the UCSC database.

    my ( $tmp_dir,   # temporary directory
         $file,      # file to upload,
         $options,   # argument hashref
         $append,    # flag indicating table should be appended
       ) = @_;

    # Returns nothing.

    my ( $args, $table, $sql_file, $fh_out, $fh_in );

    if ( $append ) {
        $args = join " ", $options->{ "database" }, $options->{ "table" }, "-tmpDir=$tmp_dir", "-oldTable", $file;
    } else {
        $args = join " ", $options->{ "database" }, $options->{ "table" }, "-tmpDir=$tmp_dir", $file;
    }

    if ( $options->{ "table" } =~ /rnaSecStr/ )
    {
        $table = $options->{ "table" };

        print qq(uploading secondary structure table:"$table"\n) if $options->{ "verbose" };

        $sql_file = "$tmp_dir/upload_RNA_SS.sql";

        $fh_out   = Maasha::Filesys::file_write_open( $sql_file );

        print $fh_out qq(
CREATE TABLE $table (
    bin smallint not null,              # Bin number for browser speedup
    chrom varchar(255) not null,        # Chromosome or FPC contig
    chromStart int unsigned not null,   # Start position in chromosome
    chromEnd int unsigned not null,     # End position in chromosome
    name varchar(255) not null,         # Name of item
    score int unsigned not null,        # Score from 0-1000
    strand char(1) not null,            # + or -
    size int unsigned not null,         # Size of element.
    secStr longblob not null,           # Parentheses and '.'s which define the secondary structure
    conf longblob not null,             # Confidence of secondary-structure annotation per position (0.0-1.0).
    #Indices
    INDEX(name(16)),
    INDEX(chrom(8), bin),
    INDEX(chrom(8), chromStart)
);
        );

        close $fh_out;

        Maasha::Common::run( "hgLoadBed", "-notItemRgb -sqlTable=$sql_file $options->{ 'database' } $options->{ 'table' } -tmpDir=$tmp_dir $file > /dev/null 2>&1" );

        unlink $sql_file;
    }
    else
    {
        Maasha::Common::run( "hgLoadBed", "$args > /dev/null 2>&1" );
    }
}


sub bed_analyze
{
    # Martin A. Hansen, March 2008.

    # Given a bed record, analysis this to give information
    # about intron/exon sizes.

    my ( $entry,   # BED entry
       ) = @_;

    # Returns hashref.

    my ( $i, @begs, @lens, $exon_max, $exon_min, $exon_len, $exon_tot, $intron_max, $intron_min, $intron_len, $intron_tot );

    $exon_max   = 0;
    $exon_min   = 9999999999;
    $intron_max = 0;
    $intron_min = 9999999999;

    $entry->{ "EXONS" }   = $entry->{ "BLOCK_COUNT" };

    @begs = split /,/, $entry->{ "Q_BEGS" };
    @lens = split /,/, $entry->{ "BLOCK_LENS" };

    for ( $i = 0; $i < $entry->{ "BLOCK_COUNT" }; $i++ )
    {
        $exon_len = $lens[ $i ];

        $entry->{ "EXON_LEN_$i" } = $exon_len;

        $exon_max = $exon_len if $exon_len > $exon_max;
        $exon_min = $exon_len if $exon_len < $exon_min;

        $exon_tot += $exon_len;
    }

    $entry->{ "EXON_LEN_-1" }   = $exon_len;
    $entry->{ "EXON_MAX_LEN" }  = $exon_max;
    $entry->{ "EXON_MIN_LEN" }  = $exon_min;
    $entry->{ "EXON_MEAN_LEN" } = int( $exon_tot / $entry->{ "EXONS" } );

    $entry->{ "INTRONS" } = $entry->{ "BLOCK_COUNT" } - 1;
    $entry->{ "INTRONS" } = 0 if $entry->{ "INTRONS" } < 0;

    if ( $entry->{ "INTRONS" } )
    {
        for ( $i = 1; $i < $entry->{ "BLOCK_COUNT" }; $i++ )
        {
            $intron_len = $begs[ $i ] - ( $begs[ $i - 1 ] + $lens[ $i - 1 ] );

            $entry->{ "INTRON_LEN_" . ( $i - 1 ) } = $intron_len;

            $intron_max = $intron_len if $intron_len > $intron_max;
            $intron_min = $intron_len if $intron_len < $intron_min;

            $intron_tot += $intron_len;
        }

        $entry->{ "INTRON_LEN_-1" }   = $intron_len;
        $entry->{ "INTRON_MAX_LEN" }  = $intron_max;
        $entry->{ "INTRON_MIN_LEN" }  = $intron_min;
        $entry->{ "INTRON_MEAN_LEN" } = int( $intron_tot / $entry->{ "INTRONS" } );
    }

    return wantarray ? %{ $entry } : $entry;
}


sub bed_merge_entries
{
    # Martin A. Hansen, February 2008.

    # Merge a list of given BED entries in one big entry.

    my ( $entries,     # list of BED entries to be merged
       ) = @_;

    # Returns hash.

    my ( $i, @q_ids, @q_begs, @blocksizes, @new_q_begs, @new_blocksizes, %new_entry );

    @{ $entries } = sort { $a->{ "CHR_BEG" } <=> $b->{ "CHR_BEG" } } @{ $entries };

    for ( $i = 0; $i < @{ $entries }; $i++ )
    {
        Maasha::Common::error( qq(Attempted merge of BED entries from different chromosomes) ) if $entries->[ 0 ]->{ "CHR" }    ne $entries->[ $i ]->{ "CHR" };
        Maasha::Common::error( qq(Attempted merge of BED entries from different strands) )     if $entries->[ 0 ]->{ "STRAND" } ne $entries->[ $i ]->{ "STRAND" };

        push @q_ids, $entries->[ $i ]->{ "Q_ID" } || sprintf( "ID%06d", $i );

        if ( exists $entries->[ $i ]->{ "Q_BEGS" } )
        {
            @q_begs     = split ",", $entries->[ $i ]->{ "Q_BEGS" };
            @blocksizes = split ",", $entries->[ $i ]->{ "BLOCK_LENS" };
        }
        else
        {
            @q_begs     = 0;
            @blocksizes = $entries->[ $i ]->{ "CHR_END" } - $entries->[ $i ]->{ "CHR_BEG" } + 1;
        }

        map { $_ += $entries->[ $i ]->{ "CHR_BEG" } } @q_begs;

        push @new_q_begs, @q_begs;
        push @new_blocksizes, @blocksizes;
    }

    map { $_ -= $entries->[ 0 ]->{ "CHR_BEG" } } @new_q_begs;

    %new_entry = (
        CHR          => $entries->[ 0 ]->{ "CHR" },
        CHR_BEG      => $entries->[ 0 ]->{ "CHR_BEG" },
        CHR_END      => $entries->[ -1 ]->{ "CHR_END" },
        REC_TYPE     => "BED",
        BED_LEN      => $entries->[ -1 ]->{ "CHR_END" } - $entries->[ 0 ]->{ "CHR_BEG" } + 1,
        BED_COLS     => 12,
        Q_ID         => join( ":", @q_ids ),
        SCORE        => 999,
        STRAND       => $entries->[ 0 ]->{ "STRAND" }     || "+",
        THICK_BEG    => $entries->[ 0 ]->{ "THICK_BEG" }  || $entries->[ 0 ]->{ "CHR_BEG" },
        THICK_END    => $entries->[ -1 ]->{ "THICK_END" } || $entries->[ -1 ]->{ "CHR_END" },
        COLOR        => 0,
        BLOCK_COUNT  => scalar @new_q_begs,
        BLOCK_LENS   => join( ",", @new_blocksizes ),
        Q_BEGS       => join( ",", @new_q_begs ),
    );

    return wantarray ? %new_entry : \%new_entry;
}


sub bed_split_entry
{
    # Martin A. Hansen, February 2008.

    # Splits a given BED entry into a list of blocks,
    # which are returned. A list of 6 column BED entry is returned.

    my ( $entry,    # BED entry hashref
       ) = @_;

    # Returns a list.

    my ( @q_begs, @blocksizes, $block, @blocks, $i );

    if ( exists $entry->{ "BLOCK_COUNT" } )
    {
        @q_begs     = split ",", $entry->{ "Q_BEGS" };
        @blocksizes = split ",", $entry->{ "BLOCK_LENS" };
        
        for ( $i = 0; $i < @q_begs; $i++ )
        {
            undef $block;

            $block->{ "CHR" }      = $entry->{ "CHR" };
            $block->{ "CHR_BEG" }  = $entry->{ "CHR_BEG" } + $q_begs[ $i ];
            $block->{ "CHR_END" }  = $entry->{ "CHR_BEG" } + $q_begs[ $i ] + $blocksizes[ $i ] - 1;
            $block->{ "Q_ID" }     = $entry->{ "Q_ID" } . sprintf( "_%03d", $i );
            $block->{ "SCORE" }    = $entry->{ "SCORE" };
            $block->{ "STRAND" }   = $entry->{ "STRAND" };
            $block->{ "BED_LEN" }  = $block->{ "CHR_END" } - $block->{ "CHR_BEG" } + 1,
            $block->{ "BED_COLS" } = 6;
            $block->{ "REC_TYPE" } = "BED";

            push @blocks, $block;
        }
    }
    else
    {
        @blocks = @{ $entry };
    }

    return wantarray ? @blocks : \@blocks;
}


sub bed_overlap
{
    # Martin A. Hansen, February 2008.

    # Checks if two BED entries overlap and
    # return 1 if so - else 0;

    my ( $entry1,      # hashref
         $entry2,      # hashref
         $no_strand,   # don't check strand flag - OPTIONAL
       ) = @_;

    # Return bolean.

    return 0 if $entry1->{ "CHR" }    ne $entry2->{ "CHR" };
    return 0 if $entry1->{ "STRAND" } ne $entry2->{ "STRAND" };

    if ( $entry1->{ "CHR_END" } < $entry2->{ "CHR_BEG" } or $entry1->{ "CHR_BEG" } > $entry2->{ "CHR_END" } ) {
        return 0;
    } else {
        return 1;
    }
}                                                                                                                                                                    
                                                                                                                                                                     



# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;


__END__
