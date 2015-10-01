package Maasha::BGB::Track;

# Copyright (C) 2009 Martin A. Hansen.

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


# Routines for creating Biopieces Browser tracks.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Time::HiRes;
use Maasha::Common;
use Maasha::Calc;
use Maasha::Filesys;
use Maasha::KISS;
use Maasha::Biopieces;
use Maasha::Seq;
use Maasha::BGB::Wiggle;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    S_ID             => 0,
    S_BEG            => 1,
    S_END            => 2,
    Q_ID             => 3,
    SCORE            => 4,
    STRAND           => 5,
    HITS             => 6,
    ALIGN            => 7,
    BLOCK_COUNT      => 8,
    BLOCK_BEGS       => 9,
    BLOCK_LENS       => 10,
    BLOCK_TYPE       => 11,
};

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub track_grid
{
    # Martin A. Hansen, March 2010.
 
    # Create a grid of vertical lines for the browser image.

    my ( $cookie,   # browser cookie
       ) = @_;

    # Returns a list.

    my ( @grid, $i );

    for ( $i = 0; $i < $cookie->{ 'IMG_WIDTH' }; $i += 20 )
    {
        push @grid, {
            type       => 'grid',
            line_width => 1,
            color      => [ 0.82, 0.89, 1 ],
            x1         => $i,
            y1         => 0,
            x2         => $i,
            y2         => $cookie->{ 'TRACK_OFFSET' },
        };
    }

    return wantarray ? @grid : \@grid;
}


sub track_ruler
{
    # Martin A. Hansen, November 2009.
 
    # Create a track with a ruler of tics and positions for
    # the browser window.

    my ( $cookie,   # browser cookie
       ) = @_;

    # Returns a list.

    my ( $beg, $end, $factor, $step, $i, $txt, $x, @ruler );

    $beg    = $cookie->{ 'NAV_START' };
    $end    = $cookie->{ 'NAV_END' };
    $factor = $cookie->{ 'IMG_WIDTH' } / ( $end - $beg );
    
    $step = 10;

    while ( ( $end - $beg ) / $step > 20 ) {
        $step *= 5;
    }

    $i = 0;

    while ( $i <= $beg ) {
        $i += $step;
    }

    while ( $i < $end )
    {
        $txt = "|" . Maasha::Calc::commify( $i );
        $x   = sprintf( "%.0f", ( ( $i - $beg ) * $factor ) + 2 );

        if ( $x > 0 and $x + ( $cookie->{ 'RULER_FONT_SIZE' } * length $txt ) < $cookie->{ 'IMG_WIDTH' } )
        {
            push @ruler, {
                type      => 'text',
                txt       => $txt,
                font_size => $cookie->{ 'RULER_FONT_SIZE' },
                color     => $cookie->{ 'RULER_COLOR' },
                x1        => $x,
                y1        => $cookie->{ 'TRACK_OFFSET' },
            };
        }

        $i += $step;
    }

    $cookie->{ 'TRACK_OFFSET' } += $cookie->{ 'TRACK_SPACE' };

    return wantarray ? @ruler : \@ruler;
}


sub track_seq
{
    # Martin A. Hansen, November 2009.
 
    # Create a sequence track by extracting the appropriate
    # stretch of sequence from the sequence file.

    my ( $cookie,   # browser cookie
       ) = @_;

    # Returns a list.

    my ( $file, $fh, $seq, @chars, $factor, $x_offset, $i, @seq_list );

    if ( $cookie->{ 'NAV_END' } - $cookie->{ 'NAV_START' } + 1 <= 220 )  # only add sequence if less than or equal to 220.
    {
        $file = path_seq( $cookie );
        $fh   = Maasha::Filesys::file_read_open( $file );
        $seq  = Maasha::Filesys::file_read( $fh, $cookie->{ 'NAV_START' }, $cookie->{ 'NAV_END' } - $cookie->{ 'NAV_START' } + 1 );
        close $fh;

        @chars = split //, $seq;

        $factor = $cookie->{ 'IMG_WIDTH' } / @chars;

        $x_offset = sprintf( "%.0f", ( $factor / 2 ) - ( $cookie->{ 'SEQ_FONT_SIZE' } / 2 ) );
        $x_offset = 0 if $x_offset < 0;

        for ( $i = 0; $i < @chars; $i++ )
        {
            push @seq_list, {
                type      => 'text',
                txt       => $chars[ $i ],
                font_size => $cookie->{ 'SEQ_FONT_SIZE' },
                color     => $cookie->{ 'SEQ_COLOR' },
                x1        => sprintf( "%.0f", $x_offset + $i * $factor ),
                y1        => $cookie->{ 'TRACK_OFFSET' },
            };
        }

        $cookie->{ 'TRACK_OFFSET' } += $cookie->{ 'TRACK_SPACE' };

        return wantarray ? @seq_list : \@seq_list;
    }
    else
    {
        return;
    }
}


sub track_feature
{
    # Martin A. Hansen, November 2009.

    my ( $track,    # path to track data
         $cookie,   # cookie hash
       ) = @_;

    # Returns a list.

    my ( $data_wig, $data_kiss, $track_pretty, $track_name, $features, $color );

    $track_name = ( split "/", $track )[ -1 ];

    $track_pretty = $track_name;
    $track_pretty =~ s/^\d+_//;
    $track_pretty =~ s/_/ /g;

    if ( track_hide( $cookie, $track_name ) ) {
        $color = [ 0.6, 0.6, 0.6 ];
    } else {
        $color = $cookie->{ 'SEQ_COLOR' };
    }

    push @{ $features }, {
        type      => 'track_name',
        track     => $track_name,
        txt       => $track_pretty,
        font_size => $cookie->{ 'SEQ_FONT_SIZE' },
        color     => $color,
        x1        => 0,
        y1        => $cookie->{ 'TRACK_OFFSET' },
    };

    $cookie->{ 'TRACK_OFFSET' } += 10;

    if ( not track_hide( $cookie, $track_name ) )
    {
        if ( -f "$track/track_data.wig" )
        {
            $data_wig = Maasha::BGB::Wiggle::wiggle_retrieve( "$track/track_data.wig", $cookie->{ 'NAV_START' }, $cookie->{ 'NAV_END' } ); 

            push @{ $features }, track_wiggle( $cookie, $cookie->{ 'NAV_START' }, $cookie->{ 'NAV_END' }, $data_wig );
        }
        elsif ( -f "$track/track_data.kiss" )
        {
            $data_kiss = Maasha::KISS::kiss_retrieve( "$track/track_data.kiss", $cookie->{ 'NAV_START' }, $cookie->{ 'NAV_END' } );

            push @{ $features }, track_linear( $cookie, $cookie->{ 'NAV_START' }, $cookie->{ 'NAV_END' }, $data_kiss );
        }
        else
        {
            Maasha::Common::error( "Unknown track data type" );
        }
    }

    return wantarray ? @{ $features } : $features;
}


sub track_wiggle
{
    # Martin A. Hansen, February 2010.

    # Create a wiggle track.

    my ( $cookie,    # hashref with image draw metrics
         $beg,       # base window beg
         $end,       # base window end
         $vals,      # wiggle values
       ) = @_;

    # Returns a list.

    my ( $i, $max_val, $min_val, $factor, $factor_height, $x1, $y1, $x2, $y2, $block_max, $mean, @features );

    $cookie->{ 'TRACK_OFFSET' } += 10;

    $factor = $cookie->{ 'IMG_WIDTH' } / ( $end - $beg );

    ( $min_val, $max_val ) = Maasha::Calc::minmax( $vals );

    if ( $max_val == 0 ) {
        $factor_height = $cookie->{ 'WIGGLE_HEIGHT' } / 1;
    } else {
        $factor_height = $cookie->{ 'WIGGLE_HEIGHT' } / $max_val;
    }

    $block_max = 0;

    $x1 = 0;
    $y1 = $cookie->{ 'TRACK_OFFSET' } + $cookie->{ 'WIGGLE_HEIGHT' };

    for ( $i = 0; $i < scalar @{ $vals }; $i++ )
    {
        $block_max = Maasha::Calc::max( $block_max, $vals->[ $i ] );

        $x2 = int( $i * $factor );

        if ( $x2 > $x1 )
        {
            $y2 = $cookie->{ 'TRACK_OFFSET' } + $cookie->{ 'WIGGLE_HEIGHT' } - sprintf( "%.0f", $block_max * $factor_height );

            push @features, {
                type       => 'wiggle',
                color      => $cookie->{ 'FEAT_COLOR' },
                line_width => 1,
                x1         => $x1,
                y1         => $y1,
                x2         => $x2,
                y2         => $y2,
            };

            $x1 = $x2;
            $y1 = $y2;

            $block_max = 0;
        }
    }

    $y2 = $cookie->{ 'TRACK_OFFSET' } + $cookie->{ 'WIGGLE_HEIGHT' };

    push @features, {
        type       => 'wiggle',
        color      => $cookie->{ 'FEAT_COLOR' },
        line_width => 1,
        x1         => $x1,
        y1         => $y1,
        x2         => $x2,
        y2         => $y2,
    };

    unshift @features, {
        type      => 'text',
        txt       => "  min: " . Maasha::Calc::commify( $min_val ) . " max: " . Maasha::Calc::commify( $max_val ),
        font_size => $cookie->{ 'SEQ_FONT_SIZE' } - 2,
        color     => $cookie->{ 'SEQ_COLOR' },
        x1        => 0,
        y1        => $cookie->{ 'TRACK_OFFSET' } - 5,
    };

    $cookie->{ 'TRACK_OFFSET' } += $cookie->{ 'WIGGLE_HEIGHT' } + $cookie->{ 'TRACK_SPACE' };

    return wantarray ? @features : \@features;
}


sub track_linear
{
    # Martin A. Hansen, November 2009.

    # Create a linear feature track where the granularity depends
    # on the lenght of the features and the browser window width.

    my ( $cookie,    # hashref with image draw metrics
         $beg,       # base window beg
         $end,       # base window end
         $entries,   # list of unsorted KISS entries 
       ) = @_;

    # Returns a list.
    
    my ( $factor, $entry, $y_step, @ladder, $y_max, $w, $x1, $y1, $x2, $y2, $feature, @features );

    $factor = $cookie->{ 'IMG_WIDTH' } / ( $end - $beg );
    $y_step = 0;
    $y_max  = 0;

    foreach $entry ( @{ $entries } )
    {
        $w = sprintf( "%.0f", ( $entry->[ S_END ] - $entry->[ S_BEG ] + 1 ) * $factor );

        if ( $w >= 1 )
        {
            $x1 = sprintf( "%.0f", ( $entry->[ S_BEG ] - $beg ) * $factor );
            $x2 = $x1 + $w;
            $x1 = 0 if $x1 < 0;
            $x2 = $cookie->{ 'IMG_WIDTH' } if $x2 > $cookie->{ 'IMG_WIDTH' };

            for ( $y_step = 0; $y_step < @ladder; $y_step++ ) {
                last if $x1 >= $ladder[ $y_step ] + 1; 
            }

            $y1 = $cookie->{ 'TRACK_OFFSET' } + ( ( 1.1 + $cookie->{ 'FEAT_WIDTH' } ) * $y_step );
            $y2 = $y1 + $cookie->{ 'FEAT_WIDTH' };

            $feature = {
                line_width => $cookie->{ 'FEAT_WIDTH' },
                color      => $cookie->{ 'FEAT_COLOR' },
                title      => "Q_ID: $entry->[ Q_ID ] S_BEG: $entry->[ S_BEG ] S_END: $entry->[ S_END ]",
                q_id       => $entry->[ Q_ID ],
                s_beg      => $entry->[ S_BEG ],
                s_end      => $entry->[ S_END ],
                strand     => $entry->[ STRAND ],
                x1         => $x1,
                y1         => $y1,
                x2         => $x2,
                y2         => $y2,
            };

            if ( $entry->[ STRAND ] eq '+' or $entry->[ STRAND ] eq '-' ) {
                $feature->{ 'type' } = 'arrow';
            } else {
                $feature->{ 'type' } = 'rect';
            }

            push @features, $feature;

            $y_max = Maasha::Calc::max( $y_max, $y_step * ( 1.1 + $cookie->{ 'FEAT_WIDTH' } ) );

            push @features, feature_align( $entry, $beg, $y1, $factor, $cookie->{ 'FEAT_WIDTH' } ) if $entry->[ ALIGN ] ne '.';

            # $ladder[ $y_step ] = $x1 + $w;
            $ladder[ $y_step ] =  sprintf( "%.0f", ( $entry->[ S_BEG ] - $beg ) * $factor ) + $w;
        }
    }

    $cookie->{ 'TRACK_OFFSET' } += $y_max + $cookie->{ 'TRACK_SPACE' };

    return wantarray ? @features : \@features;
}


sub feature_align
{
    # Martin A. Hansen, November 2009.
    
    # Add to feature track alignment info if the granularity is
    # sufficient.
    # TODO: The printing of chars is imprecise.

    my ( $entry,         # Partial KISS entry
         $beg,           # base window beg
         $y_offset,      # y axis draw offset
         $factor,        # scale factor
         $feat_height,   # hight of feature in pixels
       ) = @_;

    # Returns a list.

    my ( $w, $align, $pos, $nt_before, $nt_after, $x1, @features );

    $w = sprintf( "%.0f", 1 * $factor );

    if ( $w >= 1 )
    {
        foreach $align ( split /,/, $entry->[ ALIGN ] )
        {
            if ( $align =~ /(\d+):([ATCGRYKMSWBDHVN-])>([ATCGRYKMSWBDHVN-])/ )
            {
                $pos       = $1;
                $nt_before = $2;
                $nt_after  = $3;
            }
            else
            {
                Maasha::Common::error( qq(BAD align descriptor: "$align") );
            }

            $x1 = sprintf( "%.0f", ( $entry->[ S_BEG ] + $pos - $beg ) * $factor );

            push @features, {
                type       => 'rect',
                line_width => $feat_height,
                color      => [ 1, 0, 0 ],
                title      => $align,
                x1         => $x1,
                y1         => $y_offset,
                x2         => $x1 + $w,
                y2         => $y_offset + $feat_height,
            };

            if ( $w > $feat_height )
            {
                push @features, {
                    type       => 'text',
                    font_size  => $feat_height + 2,
                    color      => [ 0, 0, 0 ],
                    txt        => $nt_after,
                    x1         => $x1 + sprintf( "%.0f", ( $w / 2 ) ) - $feat_height / 2,
                    y1         => $y_offset + $feat_height,
                };
            }
        }
    }

    return wantarray ? @features : \@features;
}


sub track_feature_histogram
{
    # Martin A. Hansen, November 2009.
    
    # Create a feature track as a histogram using information
    # from the index only thus avoiding to load features from the
    # file.

    my ( $cookie,   # hashref with image draw metrics
         $min,      # minimum base position
         $max,      # maximum base position
         $blocks,   # list of blocks
       ) = @_;

    # Returns a list.

    my ( $hist_height, $bucket_width, $bucket_count, $min_bucket, $factor, $factor_heigth, $max_height, $block, $bucket_beg, $bucket_end, $i, @buckets, $h, $x, @hist );

    return if $max <= $min;

    $hist_height  = 100;   # pixels
    $bucket_width = 5;
    $bucket_count = $cookie->{ 'IMG_WIDTH' } / $bucket_width;
    $factor       = ( $cookie->{ 'IMG_WIDTH' } / $bucket_width ) / ( $max - $min );

    $min_bucket = 999999999;
    $max_height = 0;

    foreach $block ( @{ $blocks } )
    {
        $bucket_beg = int( $block->{ 'BEG' } * $factor );
        $bucket_end = int( $block->{ 'END' } * $factor );

        $min_bucket = Maasha::Calc::min( $min_bucket, $bucket_beg );

        for ( $i = $bucket_beg; $i < $bucket_end; $i++ )
        {
            $buckets[ $i ] += $block->{ 'COUNT' };

            $max_height = Maasha::Calc::max( $max_height, $buckets[ $i ] );
        }
    }

    if ( $max_height > 0 )
    {
        $factor_heigth = $hist_height / $max_height;

        $x = 0;

        for ( $i = $min_bucket; $i < @buckets; $i++ )
        {
            if ( defined $buckets[ $i ] )
            {
                $h = sprintf( "%.0f", $buckets[ $i ] * $factor_heigth );

                if ( $h >= 1 )
                {
                    push @hist, {
                        type       => 'line',
                        line_width => $bucket_width,
                        color      => $cookie->{ 'FEAT_COLOR' },
                        title      => "Features: $buckets[ $i ]",
                        x1         => $x,
                        y1         => $cookie->{ 'TRACK_OFFSET' } + $hist_height,
                        x2         => $x,
                        y2         => $cookie->{ 'TRACK_OFFSET' } + $hist_height - $h,
                    };
                }
            }

            $x += $bucket_width;
        }
    }

    $cookie->{ 'TRACK_OFFSET' } += $hist_height + $cookie->{ 'TRACK_SPACE' };

    return wantarray ? @hist : \@hist;
}


sub dna_get
{
    # Martin A. Hansen, November 2009.

    # Returns the sequence from the contig in the beg/end interval
    # contained in the cookie.

    my ( $cookie,   # cookie hash
       ) = @_;

    # Returns a string.

    my ( $path, $fh, $beg, $end, $len, $dna );

    $path = path_seq( $cookie );

    $beg = $cookie->{ 'S_BEG' };
    $end = $cookie->{ 'S_END' };
    $beg =~ tr/,//d;
    $end =~ tr/,//d;
    $len = $end - $beg + 1;


    $fh = Maasha::Filesys::file_read_open( $path );

    $dna = Maasha::Filesys::file_read( $fh, $beg, $len );

    $dna = Maasha::Seq::dna_revcomp( $dna ) if $cookie->{ 'STRAND' } eq '-';
    
    Maasha::Seq::wrap( \$dna, 100 );

    close $fh;

    return $dna;
}


sub path_seq
{
    # Martin A. Hansen, November 2009.

    # Returns the path to the sequence file for a specified
    # contig as written in the cookie.

    my ( $cookie,   # cookie hash
       ) = @_;

    # Returns a string.

    my ( $path );

    die qq(ERROR: no USER in cookie.\n)     if not $cookie->{ 'USER' };
    die qq(ERROR: no CLADE in cookie.\n)    if not $cookie->{ 'CLADE' };
    die qq(ERROR: no GENOME in cookie.\n)   if not $cookie->{ 'GENOME' };
    die qq(ERROR: no ASSEMBLY in cookie.\n) if not $cookie->{ 'ASSEMBLY' };
    die qq(ERROR: no CONTIG in cookie.\n)   if not $cookie->{ 'CONTIG' };

    $path = join( "/",
        $cookie->{ 'DATA_DIR' },
        "Users",
        $cookie->{ 'USER' },
        $cookie->{ 'CLADE' },
        $cookie->{ 'GENOME' },
        $cookie->{ 'ASSEMBLY' },
        $cookie->{ 'CONTIG' },
        "Sequence",
        "sequence.txt"
    );
    
    die qq(ERROR: no such file: "$path".\n) if not -e $path;

    return $path;
}


sub search_tracks
{
    # Martin A. Hansen, December 2009.

    # Uses grep to search all tracks in all contigs
    # for a given pattern and return a list of KISS entries.

    my ( $cookie,   # cookie hash
       ) = @_;

    # Returns a list.

    my ( $search_track, $search_term, $contig, @tracks, $track, $file, $line, $out_file, $fh, $entry, @entries, $track_name );

    if ( $cookie->{ 'SEARCH' } =~ /^(.+)\s+track:\s*(.+)/i )
    {
        $search_term  = $1;
        $search_track = $2;

        $search_track =~ tr/ /_/;
    }
    else
    {
        $search_term = $cookie->{ 'SEARCH' };
    }

    foreach $contig ( @{ $cookie->{ 'LIST_CONTIG' } } )
    {
        $cookie->{ 'CONTIG' } = $contig;

        push @tracks, list_track_dir( $cookie->{ 'USER' }, $cookie->{ 'CLADE' }, $cookie->{ 'GENOME' }, $cookie->{ 'ASSEMBLY' }, $cookie->{ 'CONTIG' } );
    }

    foreach $track ( @tracks )
    {
        if ( $search_track )
        {
            $track_name = ( split "/", $track )[ -1 ];

            next if $track_name !~ /$search_track/i;
        }

        $file = "$track/track_data.kiss";
      
        if ( -f $file )
        {
            $fh = Maasha::Filesys::file_read_open( $file );

            while ( $line = <$fh> )
            {
                chomp $line;

                if ( $line =~ /$search_term/i )
                {
                    $entry = Maasha::KISS::kiss_entry_parse( $line );
                    $entry = Maasha::KISS::kiss2biopiece( $entry );
                    push @entries, $entry;
                }
            }

            close $fh;
        }
    }

    return wantarray ? @entries : \@entries;
}


sub list_user_dir
{
    # Martin A. Hansen, December 2009.

    # List all users directories in the ~/Data/Users
    # directory with full path.

    # Returns a list.

    my ( @dirs, @users );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users" );

    @users = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @users : \@users;
}


sub list_users
{
    # Martin A. Hansen, December 2009.

    # List all users in ~/Data/Users

    # Returns a list.
    
    my ( @dirs, $dir, @users );

    @dirs = list_user_dir();

    foreach $dir ( @dirs ) {
        push @users, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @users : \@users;
}


sub list_clade_dir
{
    # Martin A. Hansen, December 2009.

    # List all clades for a given user in ~/Data/Users

    my ( $user,   # user for which to return clades
       ) = @_;

    # Returns a list.

    my ( @dirs, @clades );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users/$user" );

    @clades = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @clades : \@clades;
}


sub list_clades
{
    # Martin A. Hansen, December 2009.

    # List all clades for a given user in ~/Data/Users

    my ( $user,   # user for which to return clades
       ) = @_;

    # Returns a list.
    
    my ( @dirs, $dir, @clades );

    @dirs = list_clade_dir( $user );

    foreach $dir ( @dirs ) {
        push @clades, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @clades : \@clades;
}


sub list_genome_dir
{
    # Martin A. Hansen, December 2009.

    # List all genomes for a given user and clade in ~/Data/Users

    my ( $user,    # user for which to return genomes
         $clade,   # clade for which to return genomes
       ) = @_;

    # Returns a list.

    my ( @dirs, @genomes );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users/$user/$clade" );

    @genomes = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @genomes : \@genomes;
}


sub list_genomes
{
    # Martin A. Hansen, December 2009.

    # List all genomes for a given user and clade in ~/Data/Users

    my ( $user,    # user for which to return genomes
         $clade,   # clade for which to return genomes
       ) = @_;

    # Returns a list.
    
    my ( @dirs, $dir, @genomes );

    @dirs = list_genome_dir( $user, $clade );

    foreach $dir ( @dirs ) {
        push @genomes, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @genomes : \@genomes;
}


sub list_assembly_dir
{
    # Martin A. Hansen, December 2009.

    # List all assemblies for a given user and clade and genome in ~/Data/Users

    my ( $user,     # user for which to return assemblies
         $clade,    # clade for which to return assemblies
         $genome,   # genome for which to return assemblies
       ) = @_;

    # Returns a list.

    my ( @dirs, @assemblies );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    if ( $user and $clade and $genome ) {
        @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users/$user/$clade/$genome" );
    }

    @assemblies = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @assemblies : \@assemblies;
}


sub list_assemblies
{
    # Martin A. Hansen, December 2009.

    # List all assemblies for a given user and clade and genome in ~/Data/Users

    my ( $user,     # user for which to return assemblies
         $clade,    # clade for which to return assemblies
         $genome,   # genome for which to return assemblies
       ) = @_;

    # Returns a list.
    
    my ( @dirs, $dir, @assemblies );

    @dirs = list_assembly_dir( $user, $clade, $genome );

    foreach $dir ( @dirs ) {
        push @assemblies, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @assemblies : \@assemblies;
}


sub list_contig_dir
{
    # Martin A. Hansen, December 2009.

    # List all assemblies for a given user->clade->genome->assembly in ~/Data/Users

    my ( $user,       # user for which to return contigs
         $clade,      # clade for which to return contigs
         $genome,     # genome for which to return contigs
         $assembly,   # assembly for which to return contigs
       ) = @_;

    # Returns a list.

    my ( @dirs, @contigs );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    if ( $user and $clade and $genome and $assembly ) {
        @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users/$user/$clade/$genome/$assembly" );
    }

    @contigs = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @contigs : \@contigs;
}


sub list_contigs
{
    # Martin A. Hansen, December 2009.

    # List all contigs for a given user->clade->genome->assembly in ~/Data/Users

    my ( $user,       # user for which to return contigs
         $clade,      # clade for which to return contigs
         $genome,     # genome for which to return contigs
         $assembly,   # assembly for which to return contigs
       ) = @_;

    # Returns a list.
    
    my ( @dirs, $dir, @contigs );

    @dirs = list_contig_dir( $user, $clade, $genome, $assembly );

    foreach $dir ( @dirs ) {
        push @contigs, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @contigs : \@contigs;
}


sub list_track_dir
{
    # Martin A. Hansen, December 2009.

    # List all tracks for a given user->clade->genome->assembly->contig in ~/Data/Users

    my ( $user,       # user for which to return tracks
         $clade,      # clade for which to return tracks
         $genome,     # genome for which to return tracks
         $assembly,   # assembly for which to return tracks
         $contig,     # contig for which to return tracks
       ) = @_;

    # Returns a list.

    my ( @dirs, @tracks );

    Maasha::Common::error( 'BP_WWW not set in environment' ) if not $ENV{ 'BP_WWW' };

    if ( -d "$ENV{ 'BP_WWW' }/Data/Users/$user/$clade/$genome/$assembly/$contig/Tracks" ) {
        @dirs = Maasha::Filesys::ls_dirs( "$ENV{ 'BP_WWW' }/Data/Users/$user/$clade/$genome/$assembly/$contig/Tracks" );
    }

    @tracks = grep { $_ !~ /\/\.\.?$/ } @dirs;

    return wantarray ? @tracks : \@tracks;
}


sub list_tracks
{
    # Martin A. Hansen, December 2009.

    # List all tracks for a given user->clade->genome->assembly->contig in ~/Data/Users

    my ( $user,       # user for which to return tracks
         $clade,      # clade for which to return tracks
         $genome,     # genome for which to return tracks
         $assembly,   # assembly for which to return tracks
         $contig,     # contig for which to return tracks
       ) = @_;

    # Returns a list.
    
    my ( @dirs, $dir, @tracks );

    @dirs = list_track_dir( $user, $clade, $genome, $assembly, $contig );

    foreach $dir ( @dirs ) {
        push @tracks, ( split "/", $dir )[ -1 ];
    }

    return wantarray ? @tracks : \@tracks;
}


sub max_track
{
    # Martin A. Hansen, December 2009.
    
    # Traverses all contigs for a given user->clade->genome->assembly and
    # returns the maximum track's prefix value eg. 20 for 20_Genbank.

    my ( $user,
         $clade,
         $genome,
         $assembly
       ) = @_;

    # Returns an integer
    
    my ( @contigs, $contig, @tracks, $max );

    @contigs = list_contigs( $user, $clade, $genome, $assembly );

    foreach $contig ( @contigs ) {
        push @tracks, list_tracks( $user, $clade, $genome, $assembly, $contig );
    }

    @tracks = sort @tracks;

    if ( scalar @tracks > 0 and $tracks[ -1 ] =~ /^(\d+)/ ) {
        $max = $1;
    } else {
        $max = 0;
    }

    return $max;
}


sub track_hide
{
    # Martin A. Hansen, March 2010.

    # Check cookie information to see if a given track
    # should be hidden or not.

    my ( $cookie,   # cookie hash
         $track,    # track name
       ) = @_;

    # Returns boolean.

    my ( $clade, $genome, $assembly );

    $clade    = $cookie->{ 'CLADE' };
    $genome   = $cookie->{ 'GENOME' };
    $assembly = $cookie->{ 'ASSEMBLY' };

    if ( exists $cookie->{ 'TRACK_STATUS' }->{ $clade }->{ $genome }->{ $assembly }->{ $track } and
                $cookie->{ 'TRACK_STATUS' }->{ $clade }->{ $genome }->{ $assembly }->{ $track } )
    {
        return 1;
    }

    return 0;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;

__END__


sub search_tracks_nc
{
    # Martin A. Hansen, December 2009.

    # Uses grep to search all tracks in all contigs
    # for a given pattern and return a list of KISS entries.

    my ( $cookie,   # cookie hash
       ) = @_;

    # Returns a list.

    my ( $search_track, $search_term, $contig, @tracks, $track, $file, @features, $track_name, $nc_list );

    if ( $cookie->{ 'SEARCH' } =~ /^(.+)\s+track:\s*(.+)/i )
    {
        $search_term  = $1;
        $search_track = $2;

        $search_track =~ tr/ /_/;
    }
    else
    {
        $search_term = $cookie->{ 'SEARCH' };
    }

    foreach $contig ( @{ $cookie->{ 'LIST_CONTIG' } } )
    {
        $cookie->{ 'CONTIG' } = $contig;

        push @tracks, list_track_dir( $cookie->{ 'USER' }, $cookie->{ 'CLADE' }, $cookie->{ 'GENOME' }, $cookie->{ 'ASSEMBLY' }, $cookie->{ 'CONTIG' } );
    }

    foreach $track ( @tracks )
    {
        if ( $search_track )
        {
            $track_name = ( split "/", $track )[ -1 ];

            next if $track_name !~ /$search_track/i;
        }

        $file = "$track/track_data.kiss.json";
      
        if ( -f $file )
        {
            $nc_list  = Maasha::NClist::nc_list_retrieve( $file );
            push @features, Maasha::NClist::nc_list_search( $nc_list, $search_term, 12 );
        }
    }

    return wantarray ? @features : \@features;
}



sub track_feature
{
    # Martin A. Hansen, November 2009.

    # Create a track with features. If there are more than $cookie->FEAT_MAX 
    # features the track created will be a histogram, else linear.

    my ( $track,    # path to kiss file with track data
         $cookie,   # cookie hash
       ) = @_;

    # Returns a list.

    my ( $index, $count, $track_name, $start, $end, $entries, $features );

    $start = $cookie->{ 'NAV_START' };
    $end   = $cookie->{ 'NAV_END' };

    $index = Maasha::KISS::kiss_index_retrieve( "$track/track_data.kiss.index" );
    $count = Maasha::KISS::kiss_index_count( $index, $start, $end );

    $track_name = ( split "/", $track )[ -1 ];
    $track_name =~ s/^\d+_//;
    $track_name =~ s/_/ /g;

    $features = [ {
        type      => 'text',
        txt       => $track_name,
        font_size => $cookie->{ 'SEQ_FONT_SIZE' },
        color     => $cookie->{ 'SEQ_COLOR' },
        x1        => 0,
        y1        => $cookie->{ 'TRACK_OFFSET' },
    } ];

    $cookie->{ 'TRACK_OFFSET' } += 10;

    if ( $count > $cookie->{ 'FEAT_MAX' } )
    {
        $entries  = Maasha::KISS::kiss_index_get_blocks( $index, $start, $end );
        push @{ $features }, track_feature_histogram( $cookie, $start, $end, $entries );
    }  
    else
    {
        $entries  = Maasha::KISS::kiss_index_get_entries( "$track/track_data.kiss", $index, $start, $end );
        push @{ $features }, track_feature_linear( $cookie, $start, $end, $entries );
    }  

    return wantarray ? @{ $features } : $features;
}


my $t0 = Time::HiRes::gettimeofday();
my $t1 = Time::HiRes::gettimeofday(); print STDERR "Time: " . ( $t1 - $t0 ) . "\n";
