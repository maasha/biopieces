package Maasha::NCBI;

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


# Stuff for interacting with NCBI Entrez


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use LWP::Simple;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Seq;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub get_entry
{
    # Martin A. Hansen, March 2007.

    # connects to the ncbi website and retrieves a genbank record,
    # which is returned.

    my ( $db,    # database <nucleotide|protein>
         $id,    # genbank id
         $type,  # retrieval type <gb|gp>
       ) = @_;

    # returns string

    my ( $content, @lines, $i, $seq );

    $content = get "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$db&id=$id&rettype=$type";

    return $content;
}


sub get_seq
{
    # Martin A. Hansen, March 2007.

    # connects to the ncbi website and retrieves a genbank record,
    # from which the sequence is parsed and returned.

    my ( $db,    # database <nucleotide|protein>
         $id,    # genbank id
         $type,  # retrieval type <gb|gp>
       ) = @_;

    # returns string

    my ( $content, @lines, $i, $seq );

    $content = get "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$db&id=$id&rettype=$type";

    @lines = split "\n", $content;

    $i = 0;

    while ( $lines[ $i ] !~ /^ORIGIN/ ) {
        $i++
    }

    $i++;

    while ( $lines[ $i ] !~ /^\/\// )
    {
        $lines[ $i ] =~ s/^\s*\d+//;

        $seq .= $lines[ $i ];

        $i++;
    }

    $seq =~ tr/ //d;

    return $seq;
}


sub soft_index_file
{
    # Martin A. Hansen, June 2008.

    # Create a index with line numbers of the different tables
    # in a soft file. The index is returned.

    my ( $file,   # file to index
       ) = @_;

    # Returns a list
    
    my ( $fh, $line, $i, $c, @index, $first );

    $fh = Maasha::Filesys::file_read_open( $file );

    $first = 1;

    $i     = 0;
    $c     = 0;

    while ( $line = <$fh> )
    {
        chomp $line;

        if ( $line =~ /^\^/ )
        {
            push @index, {
                SECTION  => $line, 
                LINE_BEG => $i,
            };

            if ( not $first )
            {
                $index[ $c - 1 ]{ "LINE_END" } = $i - 1;
            }
            else
            {
                $first = 0;
            }

            $c++;
        }
    
        $i++; 
    }

    $index[ $c - 1 ]{ "LINE_END" } = $i - 1;

    close $fh;

    return wantarray ? @index : \@index;
}


sub soft_get_platform
{
    # Martin A. Hansen, June 2008.

    # Given a filehandle to a SOFT file parses all the platform tables
    # which is returned.

    my ( $fh,    # filehandle
         $beg,   # line number where platform tables begin
         $end,   # line number where platform tables end
       ) = @_;

    # Returns hashref

    my ( $line, @lines, $i, $c, @fields, %key_hash, %id_hash );

    $i = 0;

    while ( $line = <$fh> )
    {
        chomp $line;

        push @lines, $line if $i >= $beg;
    
        last if $i == $end;

        $i++;
    }

    $i = 0;

    while ( $i < @lines )
    {
        if ( $lines[ $i ] =~ /^!platform_table_begin$/ )
        {
            @fields = split "\t", $lines[ $i + 1 ];

            for ( $c = 0; $c < @fields; $c++ ) {
                $key_hash{ $fields[ $c ] } = $c;
            }

            $c = $i + 2;

            while ( $lines[ $c ] !~ /^!platform_table_end$/ )
            {
                @fields = split "\t", $lines[ $c ];

                if ( defined $key_hash{ "SEQUENCE" } ) {
                    $id_hash{ $fields[ $key_hash{ "ID" } ] } = $fields[ $key_hash{ "SEQUENCE" } ];
                } else {
                    $id_hash{ $fields[ $key_hash{ "ID" } ] } = $fields[ $key_hash{ "ID" } ];
                }

                $c++;
            }

            $i = $c;
        }

        $i++;
    }

    return wantarray ? %id_hash : \%id_hash;
}


sub soft_get_sample
{
    # Martin A. Hansen, June 2008.

    # Given a filehandle to a SOFT file and a platform table 
    # parses sample records which are returned.

    my ( $fh,           # filehandle
         $plat_table,   # hashref with platform table
         $beg,          # line number where sample table begin
         $end,          # line number where sample table end
         $skip,         # flag indicating that this sample table should not be parsed.
       ) = @_;

    # Returns list of hashref

    my ( $line, @lines, $i, $c, $platform_id, @fields, %key_hash, $num, $sample_id, $sample_title, $id, $seq, $count, @records, $record );

    $i = 0;

    while ( $line = <$fh> )
    {
        if ( not $skip )
        {
            chomp $line;

            push @lines, $line if $i >= $beg;
        }

        last if $i == $end;

        $i++;
    }

    if ( $skip ) {
        return wantarray ? () : [];
    }

    $i = 0;

    $num = 1;

    while ( $i < @lines ) 
    {
        if ( $lines[ $i ] =~ /^\^SAMPLE = (.+)/ )
        {
            $sample_id = $1;
        }
        elsif ( $lines[ $i ] =~ /!Sample_platform_id = (.+)/ )
        {
            $platform_id = $1;
        }
        elsif ( $lines[ $i ] =~ /^!Sample_title = (.+)/ )
        {
            $sample_title = $1;
        }
        elsif ( $lines[ $i ] =~ /^!sample_table_begin/ )
        {
            undef %key_hash;

            @fields = split "\t", $lines[ $i + 1 ];

            for ( $c = 0; $c < @fields; $c++ )
            {
                $fields[ $c ] = "ID_REF" if $fields[ $c ] eq "SEQUENCE";
                $fields[ $c ] = "VALUE"  if $fields[ $c ] eq "COUNT";

                $key_hash{ $fields[ $c ] } = $c;
            }

            $c = $i + 2;

            while ( $lines[ $c ] !~ /^!sample_table_end$/ )
            {
                undef $record;

                @fields = split "\t", $lines[ $c ];
                $id    = $fields[ $key_hash{ "ID_REF" } ];
                $seq   = $plat_table->{ $id } || $id;
                $count = $fields[ $key_hash{ "VALUE" } ];

                $seq =~ tr/./N/;

                $record->{ "SAMPLE_TITLE" } = $sample_title;
                $record->{ "SEQ" }          = $seq;
                $record->{ "SEQ_NAME" }     = join( "_", $platform_id, $sample_id, $num, $count );
            
                push @records, $record;

                $c++;
                $num++;
            }

            $i = $c;
       
            $num = 1;
        }

        $i++;
    }

    return wantarray ? @records : \@records;
}


sub blast_index
{
    # Martin A. Hansen, Juli 2008.

    # Create a BLAST index of a given FASTA file
    # in a specified directory using a given name.

    my ( $file,         # path to FASTA file
         $src_dir,      # source directory with FASTA file
         $dst_dir,      # destination directory for BLAST index
         $index_type,   # protein or nucleotide
         $index_name,   # name of index
       ) = @_;

    # Returns nothing.

    my ( $type );

    if ( $index_type =~ /protein/i ) {
        $type = "T";
    } else {
        $type = "F";
    }

    Maasha::Filesys::dir_create_if_not_exists( $dst_dir );
    Maasha::Common::run( "formatdb", "-p $type -i $src_dir/$file -t $index_name -l /dev/null" );
    Maasha::Common::run( "mv", "$src_dir/*hr $dst_dir" );
    Maasha::Common::run( "mv", "$src_dir/*in $dst_dir" );
    Maasha::Common::run( "mv", "$src_dir/*sq $dst_dir" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
