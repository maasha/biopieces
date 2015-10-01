package Maasha::UCSC::Wiggle;

# Copyright (C) 2007-2010 Martin A. Hansen.

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


# Routines for manipulation of wiggle data.

# http://genome.ucsc.edu/goldenPath/help/wiggle.html


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;

use Data::Dumper;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Matrix;
use Maasha::Calc;

use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
);


use constant {
    BITS            => 32,            # Number of bits in an integer
    SEQ_MAX         => 200_000_000,   # Maximum sequence size
    chrom           => 0,             # BED field names
    chromStart      => 1,
    chromEnd        => 2,
    name            => 3,
    score           => 4,
    strand          => 5,
    thickStart      => 6,
    thickEnd        => 7,
    itemRgb         => 8,
    blockCount      => 9,
    blockSizes      => 10,
    blockStarts     => 11,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FixedStep format <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub fixedstep_entry_get
{
    # Martin A. Hansen, December 2007.

    # Given a file handle to a PhastCons file get the
    # next entry which is all the lines after a "fixedStep"
    # line and until the next "fixedStep" line or EOF.

    my ( $fh,   # filehandle
       ) = @_;

    # Returns a list of lines

    my ( $entry, @lines );

    local $/ = "\nfixedStep ";

    $entry = <$fh>;

    return if not $entry;

    chomp $entry;

    @lines = split "\n", $entry;
    
    return if @lines == 0;

    $lines[ 0 ] =~ s/fixedStep?\s*//;
    $lines[ 0 ] = 'fixedStep ' . $lines[ 0 ];

    return wantarray ? @lines : \@lines;
}


sub fixedstep_entry_put
{
    # Martin A. Hansen, April 2008.

    # Outputs a block of fixedStep values.
    # Used for outputting wiggle data.

    my ( $entry,    # fixedStep entry
         $fh,       # filehandle - OPTIONAL
       ) = @_;

    # Returns nothing.

    $fh ||= \*STDOUT;

    print $fh join( "\n", @{ $entry } ), "\n";
}


sub fixedstep2biopiece
{
    # Martin A. Hansen, November 2008.

    # Converts a fixedstep entry to a Biopiece record.

    my ( $entry,   # fixedstep entry arrayref
       ) = @_;

    # Returns a hashref

    my ( $head, %record );

    $head = shift @{ $entry };

    if ( $head =~ /^fixedStep chrom=([^ ]+) start=(\d+) step=(\d+)$/ )
    {
        $record{ "REC_TYPE" } = "fixed_step";
        $record{ "CHR" }      = $1;
        $record{ "CHR_BEG" }  = $2 - 1;  # fixedStep is 1-based
        $record{ "STEP" }     = $3;
        $record{ "VALS" }     = join ";", @{ $entry };
    }
    else
    {
        Maasha::Common::error( qq(could not convert fixedStep entry to Biopiece record) );
    }

    return wantarray ? %record : \%record;
}


sub biopiece2fixedstep
{
    # Martin A. Hansen, November 2008.

    # Converts a Biopiece record to a fixedStep entry.
    
    my ( $record,    # Biopiece record
         $opt_key,   # Key from option hash
         $opt_step,  # Step from option hash
       ) = @_;

    # Returns a list

    my ( @entry, $chr, $beg, $step, $vals );

    $chr  = $record->{ 'CHR' }     || $record->{ 'S_ID' };
    $beg  = $record->{ 'CHR_BEG' } || $record->{ 'S_BEG' };
    $step = $record->{ 'STEP' }    || $opt_step;
    $vals = $record->{ 'VALS' };
    $vals =  $record->{ $opt_key } if $opt_key;

    if ( defined $chr and defined $beg and defined $step and defined $vals)
    {
        $beg += 1;   # fixedStep is 1-based

        push @entry, "fixedStep chrom=$chr start=$beg step=$step";

        map { push @entry, $_ } split ";", $vals;
    }

    unless ( @entry ) {
        return
    } else {
        return wantarray ? @entry : \@entry;
    }
}


sub fixedstep_calc
{
    # Martin A. Hansen, November 2008.

    # Calculates fixedstep entries for a given BED file.
    # Implemented using large Perl arrays to avoid sorting.
    # Returns path to the fixedstep file.

    my ( $bed_file,   # path to BED file
         $chr,        # chromosome name
         $log10,      # flag indicating that the score should be in log10 - OPTIONAL
       ) = @_;

    # Returns a string

    my ( $fixedstep_file, $fh_in, $fh_out, $array, $beg, $end, @block, $i );

    $fixedstep_file = "$bed_file.fixedstep";

    $fh_in = Maasha::Filesys::file_read_open( $bed_file );

    $array = fixedstep_calc_array( $fh_in );

    close $fh_in;

    $fh_out = Maasha::Filesys::file_write_open( $fixedstep_file );

    $beg = 0;

    while ( ( $beg, $end ) = fixedstep_scan( $array, $beg ) and $beg != -1 )
    {
        @block = "fixedStep chrom=$chr start=" . ( $beg + 1 ) . " step=1";

        for ( $i = $beg; $i < $end; $i++ )
        {
            if ( $log10 ) {
                push @block, sprintf "%.4f", Maasha::Calc::log10( $array->[ $i ] );
            } else {
                push @block, $array->[ $i ];
            }
        }

        fixedstep_entry_put( \@block, $fh_out );

        $beg = $end + 1;
    }

    close $fh_out;

    undef $array;

    return $fixedstep_file;
}


sub fixedstep_calc_array
{
    # Martin A. Hansen, November 2008.

    # Given a filehandle to a BED file for a single
    # chromosome fills an array with SCORE for the
    # begin/end positions of each BED entry.

    my ( $fh_in,   # filehandle to BED file
       ) = @_;

    # Returns a bytearray.

    my ( $bed, $score, @begs, @lens, $i, @array );

    while ( $bed = Maasha::UCSC::BED::bed_entry_get( $fh_in ) )
    {
        if ( defined $bed->[ score ] ) {
            $score = $bed->[ score ];
        } else {
            $score = 1;
        }

        if ( $bed->[ blockCount ] and $bed->[ blockCount ] > 1 )
        {
            @begs = split ",", $bed->[ blockStarts ];
            @lens = split ",", $bed->[ blockSizes ];

            for ( $i = 0; $i < @begs; $i++ ) {
                map { $array[ $_ ] += $score } ( $bed->[ chromStart ] + $begs[ $i ] .. $bed->[ chromStart ] + $begs[ $i ] + $lens[ $i ] - 1 );
            }
        }
        else
        {
            map { $array[ $_ ] += $score } ( $bed->[ chromStart ] .. $bed->[ chromEnd ] - 1 );
        }
    }

    return wantarray ? @array : \@array;
}


sub fixedstep_scan
{
    # Martin A. Hansen, November 2008.

    # Given a fixedstep array locates the next block of
    # non-zero elements from a given begin position.
    # A [ begin end ] tuple of the block posittion is returned 
    # if a block was found otherwise and empty tuple is returned.

    my ( $array,   # array to scan
         $beg,     # position to start scanning from
       ) = @_;

    # Returns an arrayref.

    my ( $end );

    while ( $beg < scalar @{ $array } and not $array->[ $beg ] ) { $beg++ }

    $end = $beg;

    while ( $array->[ $end ] ) { $end++ }

    if ( $end > $beg ) {
        return wantarray ? ( $beg, $end ) : [ $beg, $end ];
    } else {
        return wantarray ? () : [];
    }
}


sub fixedstep_index
{
    # Martin A. Hansen, June 2010.

    # Indexes a specified fixedstep file and saves the index
    # to a specified directory and index name.

    my ( $path,   # fixedstep file to index
         $dir,    # direcotory to place index
         $name,   # name of index
       ) = @_;

    # Returns nothing.

    my ( $index );

    $index = fixedstep_index_create( $path );
    fixedstep_index_store( "$dir/$name", $index );
}


sub fixedstep_index_create
{
    # Martin A. Hansen, June 2010.

    # Indexes a specified fixedStep file.
    # The index consists of a hash with chromosomes as keys,
    # and a list of { chr_beg, chr_end, index_beg, index_len }
    # hashes as values.

    my ( $path,   # path to fixedStep file
       ) = @_;

    # Returns a hashref

    my ( $fh, $pos, $line, $index_beg, $index_len, $chr, $step, $chr_beg, $chr_end, $len, %index );

    $fh = Maasha::Filesys::file_read_open( $path );

    $index_beg = 0;
    $index_len = 0;
    $chr_beg   = 0;
    $chr_end   = 0;
    $pos       = 0;

    while ( $line = <$fh> )
    {
        if ( $line =~ /^fixedStep chrom=([^ ]+) start=(\d+) step=(\d+)/ )
        {
            if ( $chr_end > $chr_beg )
            {
                $index_len = $pos - $index_beg;

                push @{ $index{ $chr } }, {
                    CHR_BEG   => $chr_beg,
                    CHR_END   => $chr_end - 1,
                    INDEX_BEG => $index_beg,
                    INDEX_LEN => $index_len,
                };
            }

            $chr     = $1;
            $chr_beg = $2 - 1;  #  fixedStep files are 1-based
            $step    = $3;
            $chr_end = $chr_beg;

            $index_beg = $pos + length $line;
        }
        else
        {
            $chr_end++;
        }

        $pos += length $line;
    }

    $index_len = $pos - $index_beg;

    push @{ $index{ $chr } }, {
        CHR_BEG   => $chr_beg,
        CHR_END   => $chr_end - 1,
        INDEX_BEG => $index_beg,
        INDEX_LEN => $index_len,
    };

    close $fh;

    return wantarray ? %index : \%index;
}


sub fixedstep_index_store
{
    # Martin A. Hansen, January 2008.

    # Writes a fixedStep index to binary file.

    my ( $path,   # full path to file
         $index,  # list with index
       ) = @_;

    # returns nothing

    Maasha::Filesys::file_store( $path, $index );
}


sub fixedstep_index_retrieve
{
    # Martin A. Hansen, January 2008.

    # Retrieves a fixedStep index from binary file.

    my ( $path,   # full path to file
       ) = @_;

    # returns list

    my $index;

    $index = Maasha::Filesys::file_retrieve( $path );

    return wantarray ? %{ $index } : $index;
}


sub fixedstep_index_lookup
{
    # Martin A. Hansen, January 2008.

    # Locate fixedStep entries from index based on
    # chr, chr_beg and chr_end.

    my ( $index,     # data structure
         $chr,       # chromosome
         $chr_beg,   # chromosome beg
         $chr_end,   # chromosome end
       ) = @_;

    # Returns a list
 
    my ( @subindex );

    if ( exists $index->{ $chr } ) {
        @subindex = grep { $_->{ 'CHR_END' } >= $chr_beg and $_->{ 'CHR_BEG' } <= $chr_end } @{ $index->{ $chr } };
    } else {
        Maasha::Common::error( qq(Chromosome "$chr" not found in index) );
    }

    return wantarray ? @subindex : \@subindex;                                                                                                                           
}


sub wiggle_upload_to_ucsc
{
    # Martin A. Hansen, May 2008.

    # Upload a wiggle file to the UCSC database.

    my ( $tmp_dir,    # temporary directory
         $wib_dir,    # wib directory
         $wig_file,   # file to upload,
         $options,    # argument hashref
       ) = @_;

    # Returns nothing.

    my ( $args );

#    $args = join " ", "-tmpDir=$tmp_dir", "-pathPrefix=$wib_dir", $options->{ "database" }, $options->{ 'table' }, $wig_file;

#    Maasha::Common::run( "hgLoadWiggle", "$args > /dev/null 2>&1" );

    if ( $options->{ 'verbose' } ) {
        `cd $tmp_dir && hgLoadWiggle -tmpDir=$tmp_dir -pathPrefix=$wib_dir $options->{ 'database' } $options->{ 'table' } $wig_file`;
    } else {
        `cd $tmp_dir && hgLoadWiggle -tmpDir=$tmp_dir -pathPrefix=$wib_dir $options->{ 'database' } $options->{ 'table' } $wig_file > /dev/null 2>&1`;
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;


__END__
