package Maasha::EMBL;

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


# Routines to parse EMBL records.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Storable qw( dclone );
use Maasha::Common;
use Maasha::Fasta;
use Maasha::Calc;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );


@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub get_embl_entry
{
    # Martin A. Hansen, June 2006.

    # Given a filehandle to an embl file,
    # fetches the next embl entry, and returns
    # this as a string with multiple lines.

    my ( $fh,    # filehandle to embl file
       ) = @_;

    # returns string
    
    my ( $entry );

    local $/ = "//\n";

    $entry = <$fh>;

    return $entry;
}


sub parse_embl_entry
{
    # Martin A. Hansen, June 2006.

    # given an embl entry extracts the keys
    # given in an argument hash. Special care
    # is taken to parse the feature table if
    # requested.

    my ( $entry,   # embl entry
         $args,    # argument hash
       ) = @_;

    # returns data structure

    my ( @lines, $i, %hash, $ft, $seq, $key, $val, $ref );

    @lines = split "\n", $entry;

    $i = 0;

    while ( $i < @lines )
    {
        if ( exists $args->{ "keys" } )
        {
            $args->{ "keys" }->{ "RN" } = 1 if grep { $_ =~ /^R/ } keys %{ $args->{ "keys" } };

            if ( $lines[ $i ] =~ /^(\w{2})\s+(.*)/ and exists $args->{ "keys" }->{ $1 } )
            {
                $key = $1;
                $val = $2;

                if ( $key =~ /RN|RX|RP|RG|RA|RT|RL/ ) {
                     add_ref( \%hash, \@lines, $i, $args->{ "keys" } ) if $key eq "RN";
                } elsif ( exists $hash{ $key } and $key eq "FT" ) {
                    $hash{ $key } .= "\n" . $val;
                } elsif ( exists $hash{ $1 } ) {
                    $hash{ $key } .= " " . $val;
                } else {
                    $hash{ $key } = $val;
                }
            }
            elsif ( $lines[ $i ] =~ /^\s+(.*)\s+\d+$/ and exists $args->{ "keys" }->{ "SEQ" } )
            {
                $seq .= $1;
            }
        }
        else
        {
            if ( $lines[ $i ] =~ /^(\w{2})\s+(.*)/ )
            {
                $key = $1;
                $val = $2;

                if ( $key =~ /RN|RX|RP|RG|RA|RT|RL/ ) {
                    add_ref( \%hash, \@lines, $i ) if $key eq "RN";
                } elsif ( exists $hash{ $1 } and $key eq "FT" ) {
                    $hash{ $key } .= "\n" . $val;
                } elsif ( exists $hash{ $key } ) {
                    $hash{ $key } .= " " . $val;
                } else {
                    $hash{ $key } = $val;
                }
            }
            elsif ( $lines[ $i ] =~ /^\s+(.*)\s+\d+$/ )
            {
                $seq .= $1;
            }
        }

        $i++;
    }

    if ( $seq )
    {
        $seq =~ tr/ //d; 
        $hash{ "SEQ" } = $seq;
    }

    if ( exists $hash{ "FT" } )
    {
        $ft = parse_feature_table( $hash{ "FT" }, $seq, $args );
        $hash{ "FT" } = $ft;
    }

    return wantarray ? %hash : \%hash;
}


sub add_ref
{
    # Martin A. Hansen, August 2009.

    # Add a EMBL reference.

    my ( $hash,    # Parsed EMBL data
         $lines,   # EMBL entry lines
         $i,       # line index
         $args,    # hashref with keys to save - OPTIONAL
       ) = @_;

    # Returns nothing.

    my ( %ref, $key, $val );

    if ( $args )
    {
        while ( $lines->[ $i ] =~ /^(\w{2})\s+(.*)/ )
        {
            $key = $1;
            $val = $2;

            last if $key eq "XX";

            if ( exists $args->{ $key } )
            {
                if ( exists $ref{ $key } ) {
                    $ref{ $key } .= " " . $val;
                } else {
                    $ref{ $key } = $val;
                }
            }

            $i++;
        }
    }
    else
    {
        while ( $lines->[ $i ] =~ /^(\w{2})\s+(.*)/ and $1 ne 'XX' )
        {
            if ( exists $ref{ $1 } ) {
                $ref{ $1 } .= " " . $2;
            } else {
                $ref{ $1 } = $2;
            }

            $i++;
        }
    }

    push @{ $hash->{ 'REF' } }, \%ref;
}


sub parse_feature_table
{
    # Martin A. Hansen, June 2006.

    # parses the feature table of a EMBL/GenBank/DDBJ entry.
    # parsing takes place in 4 steps. 1) the feature key is
    # located. 2) the locator is located taking into # consideration
    # that it may be split over multiple lines, which is dealt with
    # by counting the params that always are present in multiline
    # locators. 3) the locator is used to fetch the corresponding
    # sequence. 4) qualifier key/value pars are located again taking
    # into consideration multiline values, which are dealt with by
    # keeping track of the "-count (value-less qualifers are also
    # included). only feature keys and qualifers defined in the
    # argument hash are returned.

    my ( $ft,     # feature table
         $seq,    # entry sequence
         $args,   # argument hash
       ) = @_;

    # returns data structure

    my ( @lines, $key_regex, $i, $p, $q, %key_hash, $key, $locator, %qual_hash, $qual_name, $qual_val, $subseq );

    @lines = split "\n", $ft;

    $key_regex = "[A-Za-z0-9_']+";   # this regex should match every possible feature key (gene, misc_feature, 5'UTR ...)

    $i = 0;

    while ( $lines[ $i ] )
    {
        if ( $lines[ $i ] =~ /^($key_regex)\s+(.+)/ ) 
        {
            $key     = $1;
            $locator = $2;

            undef %qual_hash;

            # ---- getting locator

            $p = 1;

            if ( not balance_params( $locator ) )
            {
                while ( not balance_params( $locator ) )
                {
                    $locator .= $lines[ $i + $p ];
                    $p++;
                }
            }

            push @{ $qual_hash{ "_locator" } }, $locator;

            if ( $seq ) 
            {
                # ---- getting subsequence

                $subseq = parse_locator( $locator, $seq );

                push @{ $qual_hash{ "_seq" } }, $subseq;
            }

            # ----- getting qualifiers

            while ( defined( $lines[ $i + $p ] ) and not $lines[ $i + $p ] =~ /^$key_regex/ )
            {
                if ( $lines[ $i + $p ] =~ /^\// )
                {
                    if ( $lines[ $i + $p ] =~ /^\/([^=]+)=(.*)$/ )
                    {
                        $qual_name = $1;
                        $qual_val  = $2;
                    }
                    elsif ( $lines[ $i + $p ] =~ /^\/(.*)$/ )
                    {
                        $qual_name = $1;
                        $qual_val  = "";
                    }

                    # ----- getting qualifier value

                    $q = 1;

                    if ( not balance_quotes( $qual_val ) )
                    {
                        while ( not balance_quotes( $qual_val ) )
                        {
                            $qual_val .= " " . $lines[ $i + $p + $q ];
                            $q++; 
                        }
                    }
                    
                    $qual_val =~ s/^"(.*)"$/$1/;
                    $qual_val =~ tr/ //d if $qual_name =~ /translation/i;
                    
                    if ( exists $args->{ "quals" } ) {
                        push @{ $qual_hash{ $qual_name } }, $qual_val if exists $args->{ "quals" }->{ $qual_name };
                    } else {
                        push @{ $qual_hash{ $qual_name } }, $qual_val;
                    }
                }
                    
                $p += $q;
            }

            if ( scalar keys %qual_hash > 0 )
            {
                if ( exists $args->{ "feats" } ) { 
                    push @{ $key_hash{ $key } }, dclone \%qual_hash if exists $args->{ "feats" }->{ $key };
                } else {
                    push @{ $key_hash{ $key } }, dclone \%qual_hash;
                }
            }
        }

        $i += $p;
    }

    return wantarray ? %key_hash : \%key_hash;
}


sub parse_locator
{
    # Martin A. Hansen, June 2006.

    # uses recursion to parse a locator string from a feature
    # table and fetches the appropriate subsequence. the operators
    # join(), complement(), and order() are handled.
    # the locator string is broken into a comma separated lists, and
    # modified if the params donnot balance. otherwise the comma separated
    # list of ranges are stripped from operators, and the subsequence are
    # fetched and handled according to the operators.
    # SNP locators are also dealt with (single positions).

    my ( $locator,   # locator string
         $seq,       # nucleotide sequence
         $subseq,    # subsequence being joined
         $join,      # join sequences
         $comp,      # complement sequence or not
         $order,     # order sequences
       ) = @_;

    # returns string

    my ( @intervals, $interval, $beg, $end, $newseq );

    @intervals = split ",", $locator;

    if ( not balance_params( $intervals[ 0 ] ) )                          # locator includes a join/comp/order of several ranges
    {
        if ( $locator =~ /^join\((.*)\)$/ )
        {
            $join = 1;
            $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
        }
        elsif ( $locator =~ /^complement\((.*)\)$/ )
        {
            $comp = 1;
            $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
        
        }
        elsif ( $locator =~ /^order\((.*)\)$/ )
        {
            $order = 1;
            $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
        }
    }
    else
    {
        foreach $interval ( @intervals )
        {
            if ( $interval =~ /^join\((.*)\)$/ )
            {
                $join = 1;
                $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
            }
            elsif ( $interval =~ /^complement\((.*)\)$/ )
            {
                $comp = 1;
                $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
            
            }
            elsif ( $interval =~ /^order\((.*)\)$/ )
            {
                $order = 1;
                $subseq = parse_locator( $1, $seq, $subseq, $join, $comp, $order );
            }
            elsif ( $interval =~ /^[<>]?(\d+)[^\d]+(\d+)$/ )
            {
                $beg = $1;
                $end = $2;

                $newseq = substr $seq, $beg - 1, $end - $beg + 1;
    
                $newseq = Maasha::Seq::dna_revcomp( $newseq ) if $comp;

                if ( $order ) {
                    $subseq .= " " . $newseq;
                } else {
                    $subseq .= $newseq;
                }
            }
            elsif ( $interval =~ /^(\d+)$/ )
            {
                $beg = $1;

                $newseq = substr $seq, $beg - 1, 1 ;
    
                $newseq = Maasha::Seq::dna_revcomp( $newseq ) if $comp;

                if ( $order ) {
                    $subseq .= " " . $newseq;
                } else {
                    $subseq .= $newseq;
                }
            }
            else
            {
                warn qq(WARNING: Could not match locator -> $locator\n);
                # die qq(ERROR: Could not match locator -> $locator\n);
                $subseq .= "";
            }
        }
    }

    return $subseq;
}


sub balance_params
{
    # Martin A. Hansen, June 2006.

    # given a string checks if left and right params
    # balances. returns 1 if balanced, else 0.

    my ( $string,   # string to check
       ) = @_;

    # returns boolean

    my ( $param_count );

    $param_count  = 0;
    $param_count += $string =~ tr/(//;
    $param_count -= $string =~ tr/)//;

    if ( $param_count == 0 ) {
        return 1;
    } else {
        return 0;
    }
}


sub balance_quotes
{
    # Martin A. Hansen, June 2006.

    # given a string checks if the number of double quotes
    # balances. returns 1 if balanced, else 0.

    my ( $string,   # string to check
       ) = @_;

    # returns boolean

    my ( $quote_count );

    $quote_count = $string =~ tr/"//;

    if ( $quote_count % 2 == 0 ) {
        return 1;
    } else {
        return 0;
    }
}


sub embl2biopieces
{
    # Martin A. Hansen, July 2009.

    # Given a complete EMBL entry and an option hash,
    # configure the arguments for the EMBL parser so
    # only wanted information is retrieved and returned
    # as a Biopiece record.

    my ( $entry,     # EMBL entry to parse
         $options,   # Biopiece options
       ) = @_;

    # Returns a hashref.

    my ( %args, $data, $record, $key_record, $key, $feat, $feat2, $qual, $qual_val, @records, $no_seq );

    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;

    map { $args{ 'keys' }{ $_ } = 1 }  @{ $options->{ 'keys' } };
    map { $args{ 'feats' }{ $_ } = 1 } @{ $options->{ 'features' } };
    map { $args{ 'quals' }{ $_ } = 1 } @{ $options->{ 'qualifiers' } };

    if ( @{ $options->{ 'features' } } > 0 or @{ $options->{ 'qualifiers' } } > 0 ) {
        $args{ 'keys' }{ 'FT' } = 1;
    }

    if ( ( $args{ 'feats' } and $args{ 'feats' }{ 'SEQ' } ) or ( $args{ 'quals' } and $args{ 'quals' }{ 'SEQ' } ) )
    {
        $no_seq = 1 if not $args{ 'keys' }{ 'SEQ' };

        $args{ 'keys' }{ 'SEQ' } = 1;
        delete $args{ 'feats' }{ 'SEQ' } if $args{ 'feats' };
        delete $args{ 'quals' }{ 'SEQ' } if $args{ 'quals' };
    }

    $data = parse_embl_entry( $entry, \%args );

    # print Dumper( $data );

    foreach $key ( keys %{ $data } )
    {
        if ( $key eq 'SEQ' and $no_seq ) {
            next;
        }

        if ( $key eq 'REF' ) {
            $key_record->{ $key } = Dumper( $data->{ $key } );
        }

        if ( $key ne 'FT' and $key ne 'REF' ) {
            $key_record->{ $key } = $data->{ $key };
        }
    }

    if ( exists $data->{ 'FT' } )
    {
        $record->{ 'FT' } = Dumper( $data->{ 'FT' } );

        map { $record->{ $_ } = $key_record->{ $_ } } keys %{ $key_record };

        push @records, $record;
    }
    else
    {
        push @records, $key_record;
    }

    return wantarray ? @records : \@records;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
