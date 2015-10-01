package Maasha::UCSC::PSL;

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


# Routines for interaction with PSL entries and files.

# Read more about the PSL format here: http://genome.ucsc.edu/goldenPath/help/hgTracksHelp.html#PSL


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;

use Data::Dumper;
use Maasha::Common;
use Maasha::Filesys;

use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
);

use constant {
    matches     => 0,   # PSL field names
    misMatches  => 1,
    repMatches  => 2,
    nCount      => 3,
    qNumInsert  => 4,
    qBaseInsert => 5,
    tNumInsert  => 6,
    tBaseInsert => 7,
    strand      => 8,
    qName       => 9,
    qSize       => 10,
    qStart      => 11,
    qEnd        => 12,
    tName       => 13,
    tSize       => 14,
    tStart      => 15,
    tEnd        => 16,
    blockCount  => 17,
    blockSizes  => 18,
    qStarts     => 19,
    tStarts     => 20,
    MATCHES     => 0,    # Biopieces field names
    MISMATCHES  => 1,
    REPMATCHES  => 2,
    NCOUNT      => 3,
    QNUMINSERT  => 4,
    QBASEINSERT => 5,
    SNUMINSERT  => 6,
    SBASEINSERT => 7,
    STRAND      => 8,
    Q_ID        => 9,
    Q_LEN       => 10,
    Q_BEG       => 11,
    Q_END       => 12,
    S_ID        => 13,
    S_LEN       => 14,
    S_BEG       => 15,
    S_END       => 16,
    BLOCK_COUNT => 17,
    BLOCK_LENS  => 18,
    Q_BEGS      => 19,
    S_BEGS      => 20,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PSL format <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub psl_entry_get
{
    # Martin A. Hansen, August 2008.

    # Reads PSL next entry from a PSL file and returns an array ref.

    my ( $fh,   # file handle of PSL filefull path to PSL file
       ) = @_;

    # Returns hashref.

    my ( $line, @fields );

    while ( $line = <$fh> )
    {
        next if $line !~ /^\d/;

        chomp $line;

        @fields = split "\t", $line;

        return wantarray ? @fields : \@fields;   # 21 fields
    }

    return undef;
}


sub psl2biopiece
{
    # Martin A. Hansen, November 2008

    # Converts PSL record keys to Biopiece record keys.

    my ( $psl,   # hashref
       ) = @_;

    # returns hashref

    my %record;

    %record = (
        REC_TYPE     => "PSL",
        BLOCK_LENS   => $psl->[ blockSizes ],
        SNUMINSERT   => $psl->[ tNumInsert ],
        Q_END        => $psl->[ qEnd ] - 1,
        SBASEINSERT  => $psl->[ tBaseInsert ],
        S_END        => $psl->[ tEnd ] - 1,
        QBASEINSERT  => $psl->[ qBaseInsert ],
        REPMATCHES   => $psl->[ repMatches ],
        QNUMINSERT   => $psl->[ qNumInsert ],
        MISMATCHES   => $psl->[ misMatches ],
        BLOCK_COUNT  => $psl->[ blockCount ],
        Q_LEN        => $psl->[ qSize ],
        S_ID         => $psl->[ tName ],
        STRAND       => $psl->[ strand ],
        Q_ID         => $psl->[ qName ],
        MATCHES      => $psl->[ matches ],
        S_LEN        => $psl->[ tSize ],
        NCOUNT       => $psl->[ nCount ],
        Q_BEGS       => $psl->[ qStarts ],
        S_BEGS       => $psl->[ tStarts ],
        S_BEG        => $psl->[ tStart ],
        Q_BEG        => $psl->[ qStart ],
    );

    $record{ "SCORE" } = $record{ "MATCHES" } + int( $record{ "REPMATCHES" } / 2 ) - $record{ "MISMATCHES" } - $record{ "QNUMINSERT" } - $record{ "SNUMINSERT" };
    $record{ "SPAN" }  = $record{ "Q_END" } - $record{ "Q_BEG" };

    return wantarray ? %record : \%record;
}


sub psl_calc_score
{
    # Martin A. Hansen, November 2008.

    # Calculates the score for a PSL entry according to:
    # http://genome.ucsc.edu/FAQ/FAQblat#blat4

    my ( $psl_entry,   # array ref
       ) = @_;

    # Returns a float

    my ( $score );

    $score = $psl_entry->[ MATCHES ] +
             int( $psl_entry->[ REPMATCHES ] / 2 ) - 
             $psl_entry->[ MISMATCHES ] - 
             $psl_entry->[ QNUMINSERT ] - 
             $psl_entry->[ SNUMINSERT ];

    return $score;
}


sub psl_put_header
{
    # Martin A. Hansen, September 2007.

    # Write a PSL header to file.

    my ( $fh,  # file handle  - OPTIONAL
       ) = @_;

    # Returns nothing.

    $fh = \*STDOUT if not $fh;

    print $fh qq(psLayout version 3
match   mis-    rep.    N's     Q gap   Q gap   T gap   T gap   strand  Q               Q       Q       Q       T               T       T       T       block   blockSizes      qStart        match   match           count   bases   count   bases           name            size    start   end     name            size    start   end     count
--------------------------------------------------------------------------------------------------------------------------------------------------------------- 
);
}


sub psl_put_entry
{
    # Martin A. Hansen, September 2007.

    # Write a PSL entry to file.

    my ( $record,       # hashref
         $fh,           # file handle  -  OPTIONAL
       ) = @_;

    # Returns nothing.

    $fh = \*STDOUT if not $fh;

    my @output;

    push @output, $record->{ "MATCHES" };
    push @output, $record->{ "MISMATCHES" };
    push @output, $record->{ "REPMATCHES" };
    push @output, $record->{ "NCOUNT" };
    push @output, $record->{ "QNUMINSERT" };
    push @output, $record->{ "QBASEINSERT" };
    push @output, $record->{ "SNUMINSERT" };
    push @output, $record->{ "SBASEINSERT" };
    push @output, $record->{ "STRAND" };
    push @output, $record->{ "Q_ID" };
    push @output, $record->{ "Q_LEN" };
    push @output, $record->{ "Q_BEG" };
    push @output, $record->{ "Q_END" } + 1;
    push @output, $record->{ "S_ID" };
    push @output, $record->{ "S_LEN" };
    push @output, $record->{ "S_BEG" };
    push @output, $record->{ "S_END" } + 1;
    push @output, $record->{ "BLOCK_COUNT" };
    push @output, $record->{ "BLOCK_LENS" };
    push @output, $record->{ "Q_BEGS" };
    push @output, $record->{ "S_BEGS" };

    print $fh join( "\t", @output ), "\n";
}


sub psl_upload_to_ucsc
{
    # Martin A. Hansen, September 2007.

    # Upload a PSL file to the UCSC database.

    my ( $file,      # file to upload,
         $options,   # argument hashref
         $append,    # flag indicating table should be appended
       ) = @_;

    # Returns nothing.

    my ( $args );

    if ( $append ) {
        $args = join " ", $options->{ "database" }, "-table=$options->{ 'table' }", "-clientLoad", "-append", $file;
    } else {
        $args = join " ", $options->{ "database" }, "-table=$options->{ 'table' }", "-clientLoad", $file;
    }

    Maasha::Common::run( "hgLoadPsl", "$args > /dev/null 2>&1" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


1;


__END__
