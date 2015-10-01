package Maasha::GFF;


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


# Routines for manipulation 'Generic Feature Format' - GFF version 3.
# Read more here:
# http://www.sequenceontology.org/resources/gff3.html


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Maasha::Common;

use vars qw( @ISA @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter );

use constant {
    seqid       => 0,
    source      => 1,
    type        => 2,
    start       => 3,
    end         => 4,
    score       => 5,
    strand      => 6,
    phase       => 7,
    attributes  => 8,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


my %ATTRIBUTES = (
    id            => 'ID',
    name          => 'Name',
    alias         => 'Alias',
    parent        => 'Parent',
    target        => 'Target',
    gap           => 'Gap',
    derives_from  => 'Derives_from',
    note          => 'Note',
    dbxref        => 'Dbxref',
    ontology_term => 'Ontology_term',
);


sub gff_entry_get
{
    # Martin A. Hansen, October 2009

    my ( $fh,    # file handle
       ) = @_;

    # Returns a 

    my ( $line, @fields );

    while ( $line = <$fh>)
    {
        chomp $line;

        next if $line =~ /^$|^#/;   # skip empty lines and lines starting with #

        @fields = split /\t/, $line;

        next if scalar @fields < 9;

        return wantarray ? @fields : \@fields;
    }
}


sub gff_entry_put
{
    # Martin A. Hansen, October 2009

    my ( $entry,   # GFF entry
         $fh,      # file handle
       ) = @_;

    $fh ||= \*STDOUT;

    print $fh join( "\t", @{ $entry } ), "\n";
}


sub gff_pragma_put
{
    # Martin A. Hansen, October 2009

    my ( $pragmas,   # list of GFF pragma lines
         $fh,        # file handle
       ) = @_;

    my ( $pragma );

    $fh ||= \*STDOUT;

    foreach $pragma ( @{ $pragmas } ) {
        print $fh "$pragma\n";
    }
}


sub gff2biopiece
{
    # Martin A. Hansen, October 2009

    my ( $entry,   # GFF entry
       ) = @_;

    # Returns a hashref.
    
    my ( %record, @atts, $att, $key, $val );

    %record = (
        'S_ID'   => $entry->[ seqid ],
        'SOURCE' => $entry->[ source ],
        'TYPE'   => $entry->[ type ],
        'S_BEG'  => $entry->[ start ] - 1,
        'S_END'  => $entry->[ end ]   - 1,
        'S_LEN'  => $entry->[ end ]   - $entry->[ start ] + 1,
        'SCORE'  => $entry->[ score ],
        'STRAND' => $entry->[ strand ],
        'PHASE'  => $entry->[ phase ],
    );

    @atts = split /;/, $entry->[ attributes ];

    foreach $att ( @atts )
    {
        ( $key, $val ) = split /=/, $att;

        $record{ 'ATT_' . uc $key } = $val;
    }

    return wantarray ? %record : \%record;
}


sub biopiece2gff
{
    # Martin A. Hansen, October 2009.

    # Converts a Biopiece record to a GFF entry (a list).

    my ( $record,   # Biopiece record
       ) = @_;
    
    # Returns a list.

    my ( @entry, $key, $tag, @atts );

    $entry[ seqid ]  = $record->{ 'S_ID' };
    $entry[ source ] = $record->{ 'SOURCE' } || $record->{ 'REC_TYPE' } || '.';
    $entry[ type ]   = $record->{ 'TYPE' }   || '.';
    $entry[ start ]  = $record->{ 'S_BEG' };
    $entry[ end ]    = $record->{ 'S_END' };
    $entry[ score ]  = $record->{ 'SCORE' };
    $entry[ strand ] = $record->{ 'STRAND' };
    $entry[ phase ]  = $record->{ 'PHASE' } || '.';

    if ( not exists $record->{ 'ATT_ID' } )
    {
        push @atts, "ID=$record->{ 'Q_ID' }" if exists $record->{ 'Q_ID' };
    }

    foreach $key ( %{ $record } )
    {
        if ( $key =~ /ATT_(.+)/ )
        {
            $tag = lc $1;

            if ( exists $ATTRIBUTES{ $tag } ) {
                $tag = $ATTRIBUTES{ $tag };
            }

            push @atts, "$tag=" . $record->{ $key };
        }
    }

    $entry[ attributes ] = join ";", @atts;

    return wantarray ? @entry : \@entry;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;
