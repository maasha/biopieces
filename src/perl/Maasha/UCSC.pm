package Maasha::UCSC;

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


# Stuff for interacting with UCSC genome browser


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use vars qw ( @ISA @EXPORT );

use Data::Dumper;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Calc;
use Maasha::Matrix;

use constant {
    CHR          => 0,
    CHR_BEG      => 1,
    CHR_END      => 2,
    Q_ID         => 3,
    SCORE        => 4,
    STRAND       => 5,
    THICK_BEG    => 6,
    THICK_END    => 7,
    COLOR        => 8,
    BLOCK_COUNT  => 9,
    BLOCK_LENS   => 10,
    Q_BEGS       => 11,
};

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TRACK FILE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub ucsc_config_entry_get
{
    # Martin A. Hansen, November 2008.

    # Given a filehandle to a UCSC Genome Browser
    # config file (.ra) get the next entry and
    # return as a hash. Entries are separated by blank
    # lines. # lines are skipped unless it is the lines:
    # # Track added ...
    # # Database ...

    my ( $fh,   # file hanlde
       ) = @_;

    # Returns a hashref.

    my ( $line, %record );

    while ( $line = <$fh> )
    {
        $line =~ tr/\n\r//d;

        if ( $line =~ /Track added by 'upload_to_ucsc' (\S+) (\S+)/) {
             $record{ 'date' } = $1;
             $record{ 'time' } = $2;
        } elsif ( $line =~ /^# date: (.+)/ ) {
            $record{ 'date' } = $1;
        } elsif ( $line =~ /^# time: (.+)/ ) {
            $record{ 'time' } = $1;
        } elsif ( $line =~ /^# (?:database:|Database) (.+)/ ) {
            $record{ 'database' } = $1;
        } elsif ( $line =~ /^#/ ) {
            # skip
        } elsif ( $line =~ /(\S+)\s+(.+)/ ) {
            $record{ $1 } = $2;
        }

        last if $line =~ /^$/ and exists $record{ "track" };
    }

    return undef if not exists $record{ "track" };

    return wantarray ? %record : \%record;
}


sub ucsc_config_entry_put
{
    # Martin A. Hansen, November 2008.

    # Outputs a Biopiece record (a hashref)
    # to a filehandle or STDOUT.

    my ( $record,    # hashref
         $fh_out,    # file handle
       ) = @_;

    # Returns nothing.

    my ( $date, $time );

    $fh_out ||= \*STDOUT;

    ( $date, $time ) = split " ", Maasha::Common::time_stamp();

    $record->{ "date" } ||= $date;
    $record->{ "time" } ||= $time;

    print $fh_out "\n# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n";

    map { print $fh_out "# $_: $record->{ $_ }\n" if exists $record->{ $_ } } qw( date time database );
    map { print $fh_out "$_ $record->{ $_ }\n" if exists $record->{ $_ } } qw( track
                                                                               name
                                                                               description
                                                                               itemRgb
                                                                               db
                                                                               offset
                                                                               url
                                                                               htmlUrl
                                                                               shortLabel
                                                                               longLabel
                                                                               group
                                                                               priority
                                                                               useScore
                                                                               visibility
                                                                               maxHeightPixels
                                                                               color
                                                                               mafTrack
                                                                               type );
}


sub ucsc_update_config
{
    # Martin A. Hansen, September 2007.

    # Update the /home/user/ucsc/my_tracks.ra file and executes makeCustomTracks.pl

    my ( $options,   # hashref
         $type,      # track type
       ) = @_;

    # Returns nothing.

    my ( $file, $entry, %new_entry, $fh_in, $fh_out, $was_found );

    $file = $ENV{ "HOME" } . "/ucsc/my_tracks.ra";

    Maasha::Filesys::file_copy( $file, "$file~" );   # create a backup

    %new_entry = (
        database   => $options->{ 'database' },
        track      => $options->{ 'table' },
        shortLabel => $options->{ 'short_label' },
        longLabel  => $options->{ 'long_label' },
        group      => $options->{ 'group' },
        priority   => $options->{ 'priority' },
        visibility => $options->{ 'visibility' },
        color      => $options->{ 'color' },
        type       => $type,
    );

    $new_entry{ 'useScore' }        = 1             if $options->{ 'use_score' };
    $new_entry{ 'mafTrack' }        = "multiz17way" if $type eq "type bed 6 +";
    $new_entry{ 'maxHeightPixels' } = "50:50:11"    if $type eq "wig 0";

    $fh_in  = Maasha::Filesys::file_read_open( "$file~" );
    $fh_out = Maasha::Filesys::file_write_open( $file );

    while ( $entry = ucsc_config_entry_get( $fh_in ) )
    {
        if ( $entry->{ 'database' } eq $new_entry{ 'database' } and $entry->{ 'track' } eq $new_entry{ 'track' } )
        {
            ucsc_config_entry_put( \%new_entry, $fh_out );

            $was_found = 1;
        }
        else
        {
            ucsc_config_entry_put( $entry, $fh_out );
        }
    }

    ucsc_config_entry_put( \%new_entry, $fh_out ) if not $was_found;
    
    close $fh_in;
    close $fh_out;

    Maasha::Common::run( "ucscMakeTracks.pl", "-b > /dev/null 2>&1" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PhastCons format <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub phastcons_index
{
    # Martin A. Hansen, July 2008

    # Create a fixedStep index for PhastCons data.

    my ( $file,   # file to index
         $dir,    # dir with file
       ) = @_;

    # Returns nothing.

    my ( $index );

    $index = fixedstep_index_create( "$dir/$file" );

    fixedstep_index_store( "$dir/$file.index", $index );
}


sub phastcons_parse_entry
{
    # Martin A. Hansen, December 2007.

    # Given a PhastCons entry converts this to a
    # list of super blocks.

#    $options->{ "min" }       ||= 10;
#    $options->{ "dist" }      ||= 25;
#    $options->{ "threshold" } ||= 0.8;
#    $options->{ "gap" }       ||= 5;

    my ( $lines,   # list of lines
         $args,    # argument hash
       ) = @_;

    # Returns

    my ( $info, $chr, $beg, $step, $i, $c, $j, @blocks, @super_blocks, @entries, $super_block, $block, @lens, @begs );

    $info = shift @{ $lines };
    
    if ( $info =~ /^chrom=([^ ]+) start=(\d+) step=(\d+)$/ )
    {
        $chr  = $1;
        $beg  = $2;
        $step = $3;

        die qq(ERROR: step size $step != 1 -> problem!\n) if $step != 1; # in an ideal world should would be fixed ...
    }

    $i = 0;

    while ( $i < @{ $lines } )
    {
        if ( $lines->[ $i ] >= $args->{ "threshold" } )
        {
            $c = $i + 1;

            while ( $c < @{ $lines } )
            {
                if ( $lines->[ $c ] < $args->{ "threshold" } )
                {
                    $j = $c + 1;

                    while ( $j < @{ $lines } and $lines->[ $j ] < $args->{ "threshold" } ) {
                        $j++;
                    } 

                    if ( $j - $c > $args->{ "gap" } )
                    {
                        if ( $c - $i >= $args->{ "min" } )
                        {
                            push @blocks, {
                                CHR     => $chr, 
                                CHR_BEG => $beg + $i - 1,
                                CHR_END => $beg + $c - 2,
                                CHR_LEN => $c - $i,
                            };
                        }

                        $i = $j;

                        last;
                    }

                    $c = $j
                }
                else
                {
                    $c++;
                }
            }

            if ( $c - $i >= $args->{ "min" } )
            {
                push @blocks, {
                    CHR     => $chr, 
                    CHR_BEG => $beg + $i - 1,
                    CHR_END => $beg + $c - 2,
                    CHR_LEN => $c - $i,
                };
            }

            $i = $c;
        }
        else
        {
            $i++;
        }
    }

    $i = 0;

    while ( $i < @blocks )
    {
        $c = $i + 1;

        while ( $c < @blocks and $blocks[ $c ]->{ "CHR_BEG" } - $blocks[ $c - 1 ]->{ "CHR_END" } <= $args->{ "dist" } )
        {
            $c++;
        }

        push @super_blocks, [ @blocks[ $i .. $c - 1 ] ];

        $i = $c;
    }

    foreach $super_block ( @super_blocks )
    {
        foreach $block ( @{ $super_block } )
        {
            push @begs, $block->{ "CHR_BEG" } - $super_block->[ 0 ]->{ "CHR_BEG" };
            push @lens, $block->{ "CHR_LEN" } - 1;
        }
    
        $lens[ -1 ]++;

        push @entries, {
            CHR         => $super_block->[ 0 ]->{ "CHR" },
            CHR_BEG     => $super_block->[ 0 ]->{ "CHR_BEG" },
            CHR_END     => $super_block->[ -1 ]->{ "CHR_END" },
            Q_ID        => "Q_ID",
            SCORE       => 100,
            STRAND      => "+",
            THICK_BEG   => $super_block->[ 0 ]->{ "CHR_BEG" },
            THICK_END   => $super_block->[ -1 ]->{ "CHR_END" } + 1,
            COLOR       => 0,
            BLOCK_COUNT => scalar @{ $super_block },
            BLOCK_LENS  => join( ",", @lens ),
            Q_BEGS      => join( ",", @begs ),
        };

        undef @begs;
        undef @lens;
    }

    return wantarray ? @entries : \@entries;
}


sub phastcons_normalize
{
    # Martin A. Hansen, January 2008.

    # Normalizes a list of lists with PhastCons scores,
    # in such a way that each list contains the same number
    # of PhastCons scores.

    my ( $AoA,    # AoA with PhastCons scores
       ) = @_;

    # Returns AoA.

    my ( $list, $max, $min, $mean, $diff );

    $min = 99999999;
    $max = 0;

    foreach $list ( @{ $AoA } )
    {
        $min = scalar @{ $list } if scalar @{ $list } < $min;
        $max = scalar @{ $list } if scalar @{ $list } > $max;
    }

    $mean = int( ( $min + $max ) / 2 );

#    print STDERR "min->$min   max->$max   mean->$mean\n";

    foreach $list ( @{ $AoA } )
    {
        $diff = scalar @{ $list } - $mean;

        phastcons_list_inflate( $list, abs( $diff ) ) if $diff < 0;
        phastcons_list_deflate( $list, $diff )        if $diff > 0;
    }

    return wantarray ? @{ $AoA } : $AoA;
}


sub phastcons_list_inflate
{
    # Martin A. Hansen, January 2008.

    # Inflates a list with a given number of elements 
    # in such a way that the extra elements are introduced
    # evenly over the entire length of the list. The value
    # of the extra elements is based on a mean of the
    # adjacent elements.

    my ( $list,   # list of elements
         $diff,   # number of elements to introduce
       ) = @_;

    # Returns nothing

    my ( $len, $space, $i, $pos );

    $len = scalar @{ $list };

    $space = $len / $diff;

    for ( $i = 0; $i < $diff; $i++ )
    {
        $pos = int( ( $space / 2 ) + $i * $space );

        splice @{ $list }, $pos, 0, ( $list->[ $pos - 1 ] + $list->[ $pos + 1 ] ) / 2;
        # splice @{ $list }, $pos, 0, "X";
    }

    die qq(ERROR: Bad inflate\n) if scalar @{ $list } != $len + $diff;
}


sub phastcons_list_deflate
{
    # Martin A. Hansen, January 2008.

    # Deflates a list by removing a given number of elements
    # evenly distributed over the entire list.

    my ( $list,   # list of elements
         $diff,   # number of elements to remove
       ) = @_;

    # Returns nothing

    my ( $len, $space, $i, $pos );

    $len = scalar @{ $list };

    $space = ( $len - $diff ) / $diff;

    for ( $i = 0; $i < $diff; $i++ )
    {
        $pos = int( ( $space / 2 ) + $i * $space );

        splice @{ $list }, $pos, 1;
    }

    die qq(ERROR: Dad deflate\n) if scalar @{ $list } != $len - $diff;
}


sub phastcons_mean
{
    # Martin A. Hansen, January 2008.

    # Given a normalized PhastCons matrix in an AoA,
    # calculate the mean for each column and return as a list.

    my ( $AoA,    # AoA with normalized PhastCons scores
       ) = @_;

    # Returns a list

    my ( @list );

    $AoA = Maasha::Matrix::matrix_flip( $AoA );

    map { push @list, Maasha::Calc::mean( $_ ) } @{ $AoA };

    return wantarray ? @list : \@list;
}


sub phastcons_median
{
    # Martin A. Hansen, January 2008.

    # Given a normalized PhastCons matrix in an AoA,
    # calculate the median for each column and return as a list.

    my ( $AoA,    # AoA with normalized PhastCons scores
       ) = @_;

    # Returns a list

    my ( @list );

    $AoA = Maasha::Matrix::matrix_flip( $AoA );

    map { push @list, Maasha::Calc::median( $_ ) } @{ $AoA };

    return wantarray ? @list : \@list;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MULTIPLE ALIGNMENT FILES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub maf_extract
{
    # Martin A. Hansen, April 2008.

    # Executes mafFrag to extract a subalignment from a multiz track
    # in the UCSC genome browser database.

    my ( $tmp_dir,    # temporary directory
         $database,   # genome database
         $table,      # table with the multiz track
         $chr,        # chromosome
         $beg,        # begin position
         $end,        # end position
         $strand,     # strand
       ) = @_;

    # Returns a list of record

    my ( $tmp_file, $align );

    $tmp_file = "$tmp_dir/maf_extract.maf";

    Maasha::Common::run( "mafFrag", "$database $table $chr $beg $end $strand $tmp_file" );

    $align = maf_parse( $tmp_file );

    unlink $tmp_file;

    return wantarray ? @{ $align } : $align;
}


sub maf_parse
{
    # Martin A. Hansen, April 2008.


    my ( $path,   # full path to MAF file
       ) = @_;

    # Returns a list of record.

    my ( $fh, $line, @fields, @align );

    $fh = Maasha::Filesys::file_read_open( $path );

    while ( $line = <$fh> )
    {
        chomp $line;

        if ( $line =~ /^s/ )
        {
            @fields = split / /, $line;

            push @align, {
                SEQ_NAME  => $fields[ 1 ],
                SEQ       => $fields[ -1 ],
                ALIGN     => 1,
                ALIGN_LEN => length $fields[ -1 ],
            }
        }
    }

    close $fh;

    return wantarray ? @align : \@align;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MySQL CONF <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub ucsc_get_user
{
    # Martin A. Hansen, May 2008

    # Fetches the MySQL database user name from the
    # .hg.conf file in the users home directory.

    # Returns a string.

    my ( $file, $fh, $line, $user );

    $file = "$ENV{ 'HOME' }/.hg.conf";

    return if not -f $file;

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $line = <$fh> )
    {
        chomp $line;

        if ( $line =~ /^db\.user=(.+)/ )
        {
            $user = $1;

            last;
        }
    }

    close $fh;

    return $user;
}


sub ucsc_get_password
{
    # Martin A. Hansen, May 2008

    # Fetches the MySQL database password from the
    # .hg.conf file in the users home directory.

    # Returns a string.

    my ( $file, $fh, $line, $password );

    $file = "$ENV{ 'HOME' }/.hg.conf";

    return if not -f $file;

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $line = <$fh> )
    {
        chomp $line;

        if ( $line =~ /^db\.password=(.+)/ )
        {
            $password = $1;

            last;
        }
    }

    close $fh;

    return $password;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


__END__

