package Maasha::Blast;

# Copyright (C) 2007-2009 Martin A. Hansen.

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


# Routines to run BLAST and parse results.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Storable qw( dclone );
use Data::Dumper;
use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# The blast report structured like this:
#
#    for the first entry:
#
#    1  -  blast program name
#    2  -  blast reference
#    3  -  query sequence name and length
#    4  -  subject database
#    5  -  sequences producing significant alignments
#    6  -  one or more HSP for each subject sequence
#    7  -  blast statistics
#
#    for subsequent entries:
#
#    3  -  query sequence name and length
#    5  -  sequences producing significant alignments
#    6  -  one or more HSP for each subject sequence
#    7  -  blast statistics
#
# ________________________
#
# info
# query
# parems
# subject
#     hit1
#         hsp1
#         hsp2
#         hsp3
#     hit2
#         hsp1
#     hit3
#         hsp1
#         hsp2
# stats    
# ________________________


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SUBROUTINES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub xml_parse_blast
{
    # Martin A. Hansen, March 2007.

    # determines if the results is from ncbi blast or blastcl3
    # and parses the results in accordance.

    my ( $fh,
       ) = @_;

    # returns list

    my ( $results, $line,$doctype );

    while ( $line = <$fh> )
    {
        chomp $line;

        if ( $line =~ /^<!DOCTYPE/ )
        {
            $doctype = $line;
            last;
        }
    }

    if ( $doctype eq '<!DOCTYPE BlastOutput PUBLIC "-//NCBI//NCBI BlastOutput/EN" "NCBI_BlastOutput.dtd">' )
    {
        print STDERR qq(Parsing blastcl3 results ...\n);
        $results = xml_parse_blast_blastcl3( $fh );
    }
    elsif ( $doctype eq '<!DOCTYPE BlastOutput PUBLIC "-//NCBI//NCBI BlastOutput/EN" "http://www.ncbi.nlm.nih.gov/dtd/NCBI_BlastOutput.dtd">' )
    {
        print STDERR qq(Parsing NCBI blast results ...\n);
        $results = xml_parse_blast_ncbi( $fh );
    }
    else
    {
        die qq(ERROR: Could not determine doctype\n);
    }

    return wantarray ? @{ $results } : $results;
}


sub xml_parse_blast_ncbi
{
    # Martin A. Hansen, February 2007.

    my ( $fh,
       ) = @_;

    my ( $blast_record, $line, @blast_query, @blast_subject, $query, $subject, @results );

    while ( $blast_record = xml_get_blast_record( $fh ) and scalar @{ $blast_record } > 0 )
    {
        foreach $line ( @{ $blast_record } )
        {
            if ( $line =~ /<Iteration_query-ID>|<Iteration_query-def>|<Iteration_query-len>/ )
            {
                push @blast_query, $line;
            }
            elsif ( @blast_query )
            {
                push @blast_subject, $line;

                if ( $line =~ /<\/Iteration_hits>/ )
                {
                    $query   = xml_parse_blast_query( \@blast_query );
                    $subject = xml_parse_blast_subject( \@blast_subject );

                    push @results, {
                        "QUERY"   => $query,
                        "SUBJECT" => $subject,
                    };

                    undef @blast_query;
                    undef @blast_subject;
                }
            }
        }
    }

    return wantarray ? @results : \@results;
}


sub xml_parse_blast_blastcl3
{
    # Martin A. Hansen, February 2007.

    my ( $fh,
       ) = @_;

    my ( $blast_record, $line, @blast_query, @blast_subject, $query, $subject, @results );

    while ( $blast_record = xml_get_blast_record( $fh ) and scalar @{ $blast_record } > 0 )
    {
        foreach $line ( @{ $blast_record } )
        {
            if ( $line =~ /<BlastOutput_query-ID>|<BlastOutput_query-def>|<BlastOutput_query-len>/ )
            {
                push @blast_query, $line;
            }
            elsif ( @blast_query )
            {
                push @blast_subject, $line;

                if ( $line =~ /<\/Iteration_hits>/ )
                {
                    $query   = xml_parse_blast_query( \@blast_query );
                    $subject = xml_parse_blast_subject( \@blast_subject );

                    push @results, {
                        "QUERY"   => $query,
                        "SUBJECT" => $subject,
                    };

                    undef @blast_query;
                    undef @blast_subject;
                }
            }
        }
    }

    return wantarray ? @results : \@results;
}


sub xml_get_blast_record
{
    # Martin A. Hansen, March 2007.

    my ( $fh,   # file handle to BLAST file in XML format
       ) = @_;

    # returns list of lines

    my ( $line, @blast_record );

    while ( $line = <$fh> )
    {
        chomp $line;

        push @blast_record, $line;

        last if $line =~ /<\/BlastOutput>/;
    }

    return wantarray ? @blast_record : \@blast_record;
}


sub xml_parse_blast_query
{
    my ( $lines,
       ) = @_;

    my ( $line, %hash );

    foreach $line ( @{ $lines } )
    {
        if ( $line =~ /<Iteration_query-ID>([^<]+)/ ) {
            $hash{ "Q_ID" } = $1;
        } elsif ( $line =~ /<Iteration_query-def>([^<]+)/ ) {
            $hash{ "Q_DEF" } = $1;
        } elsif ( $line =~ /<Iteration_query-len>([^<]+)/ ) {
            $hash{ "Q_LEN" } = $1;
        }
    }

    return wantarray ? %hash : \%hash;
}


sub xml_parse_blast_subject
{
    # Martin A. Hansen, March 2007.

    my ( $lines,   #
       ) = @_;

    # returns

    my ( $line, @blast_hit, @blast_hsps, $hit, $hsps, @hits );

    foreach $line ( @{ $lines } )
    {
        if ( $line =~ /<Hit_id>|<Hit_def>|<Hit_accession>|<Hit_len>|<Hit_num>/ )
        {
            push @blast_hit, $line;
        }
        elsif ( @blast_hit )
        {
            push @blast_hsps, $line;

            if ( $line =~ /<\/Hit_hsps>/ )
            {
                $hit  = xml_parse_blast_hit( \@blast_hit );
                $hsps = xml_parse_blast_hsps( \@blast_hsps );

                $hit->{ "HSPS" } = $hsps;

                push @hits, $hit;

                undef @blast_hit;
                undef @blast_hsps;
            }
        }
    }

    return wantarray ? @hits : \@hits;
}


sub xml_parse_blast_hit
{
    my ( $lines
       ) = @_;

    my ( $line, %hash );

    foreach $line ( @{ $lines } )
    {
        if ( $line =~ /<Hit_num>([^<]+)/ ) {
            $hash{ "S_NUM" } = $1;
        } elsif ( $line =~ /<Hit_id>([^<]+)/ ) {
            $hash{ "S_ID" } = $1;
        } elsif ( $line =~ /<Hit_def>([^<]+)/ ) {
            $hash{ "S_DEF" } = $1;
        } elsif ( $line =~ /<Hit_accession>([^<]+)/ ) {
            $hash{ "S_ACC" } = $1;
        } elsif ( $line =~ /<Hit_len>([^<]+)/ ) {
            $hash{ "S_LEN" } = $1;
        }
    }

    return wantarray ? %hash : \%hash;
}


sub xml_parse_blast_hsps
{
    # Martin A. Hansen, March 2007.

    my ( $blast_hits,   #
       ) = @_;

    # returns

    my ( $line, %hash, @hsps );

    foreach $line ( @{ $blast_hits } )
    {
        if ( $line =~ /<Hsp_num>([^<]+)/ ) {
            $hash{ "NUM" } = $1;
        } elsif ( $line =~ /<Hsp_evalue>([^<]+)/ ) {
            $hash{ "E_VAL" } = $1;
        } elsif ( $line =~ /<Hsp_query-from>([^<]+)/ ) {
            $hash{ "Q_BEG" } = $1 - 1;
        } elsif ( $line =~ /<Hsp_query-to>([^<]+)/ ) {
            $hash{ "Q_END" } = $1 - 1;
        } elsif ( $line =~ /<Hsp_hit-from>([^<]+)/ ) {
            $hash{ "S_BEG" } = $1 - 1;
        } elsif ( $line =~ /<Hsp_hit-to>([^<]+)/ ) {
            $hash{ "S_END" } = $1 - 1;
        } elsif ( $line =~ /<Hsp_query-frame>([^<]+)/ ) {
            $hash{ "Q_FRAME" } = $1;
        } elsif ( $line =~ /<Hsp_hit-frame>([^<]+)/ ) {
            $hash{ "S_FRAME" } = $1;
        } elsif ( $line =~ /<Hsp_qseq>([^<]+)/ ) {
            $hash{ "Q_ALIGN" } = $1;
        } elsif ( $line =~ /<Hsp_hseq>([^<]+)/ ) {
            $hash{ "S_ALIGN" } = $1;
        } elsif ( $line =~ /<Hsp_midline>([^<]+)/ ) {
            $hash{ "MIDLINE" } = $1;
        } elsif ( $line =~ /<\/Hsp>/ ) {
            push @hsps, dclone \%hash;
        }
    }

    return wantarray ? @hsps : \@hsps;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__
