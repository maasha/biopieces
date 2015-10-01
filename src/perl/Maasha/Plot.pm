package Maasha::Plot;

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


# Routines to plot stuff with Gnuplot and SVG.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use SVG;
use IPC::Open2;
use Maasha::Common;
use Maasha::Filesys;
use Maasha::Seq;
use vars qw ( @ISA @EXPORT );

use constant {
    WIDTH  => 800,
    HEIGHT => 600,
    MARGIN => 40,
};

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LINEPLOTS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub lineplot_simple
{
    # Martin A. Hansen, January 2008.

    # Plots a simple lineplot using Gnuplot.

    my ( $data,       # data table - each column will be plottet as one line.
         $options,    # options hash
         $tmp_dir,    # temporary directory
       ) = @_;

    # Returns list.

    my ( $tmp_file, $pid, $fh_in, $fh_out, $cmd, $i, $line, @lines, $xtic_space, @plot_cmd, $title );

    $tmp_dir ||= $ENV{ 'BP_TMP' };

    $tmp_file = "$tmp_dir/lineplot_simple.tab";

    $fh_out = Maasha::Filesys::file_write_open( $tmp_file );

    map { print $fh_out join( "\t", @{ $_ } ), "\n" } @{ $data };

    close $fh_out;

    $options->{ "terminal" } ||= "dumb";

    $cmd  = "gnuplot -persist";

    $pid = open2( $fh_out, $fh_in, $cmd );

    # $fh_in = \*STDERR;

    print $fh_in "set terminal $options->{ 'terminal' }\n";
    print $fh_in "set title \"$options->{ 'title' }\"\n"   if $options->{ "title" };
    print $fh_in "set xlabel \"$options->{ 'xlabel' }\"\n" if $options->{ "xlabel" };
    print $fh_in "set ylabel \"$options->{ 'ylabel' }\"\n" if $options->{ "ylabel" };
    print $fh_in "set logscale y\n"                        if $options->{ "logscale_y" };
    print $fh_in "set grid\n"                              if not $options->{ "terminal" } eq "dumb";
    print $fh_in "set autoscale\n";
    print $fh_in "set xtics rotate by -90\n";

    for ( $i = 1; $i < scalar @{ $data->[ 0 ] } + 1; $i++ )
    {
        $title = $options->{ 'keys' }->[ $i - 1 ] || $options->{ 'list' } || "";
        push @plot_cmd, qq("$tmp_file" using $i with lines title "$title"); 
    }

    print $fh_in "plot " . join( ", ", @plot_cmd ) . "\n";

    close $fh_in;

    while ( $line = <$fh_out> )
    {
        chomp $line;

        push @lines, $line;
    }

    close $fh_out;

    waitpid $pid, 0;

    unlink $tmp_file;

    return wantarray ? @lines : \@lines;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HISTOGRAMS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 

sub histogram_simple
{
    # Martin A. Hansen, August 2007.

    # Plots a simple histogram using Gnuplot.

    my ( $data,       # list of [ xlabel, data value ] tuples 
         $options,    # options hash
       ) = @_;

    # Returns list.

    my ( $pid, $fh_in, $fh_out, $cmd, $i, $line, @lines );

    $options->{ "terminal" } ||= "dumb";

    $cmd  = "gnuplot -persist";

    $pid = open2( $fh_out, $fh_in, $cmd );

#    $fh_in = \*STDERR;

    # print $fh_in "set terminal $options->{ 'terminal' } 10 \n"; # adsjust fontsize to 10 - find some other way to do this, because it don't work with SVG.
    print $fh_in "set terminal $options->{ 'terminal' }\n";
    print $fh_in "set title \"$options->{ 'title' }\"\n"   if $options->{ "title" };
    print $fh_in "set xlabel \"$options->{ 'xlabel' }\"\n" if $options->{ "xlabel" };
    print $fh_in "set ylabel \"$options->{ 'ylabel' }\"\n" if $options->{ "ylabel" };
    print $fh_in "set logscale y\n"                        if $options->{ "logscale_y" };
    print $fh_in "set autoscale\n";
    print $fh_in "unset key\n";
    print $fh_in "set style fill solid\n";
    print $fh_in "set style histogram title offset character 0, 0, 0\n";
    print $fh_in "set style data histograms\n";
    print $fh_in "set xtics border in scale 0 nomirror rotate by -90 offset character 0, 0, 0\n";
    print $fh_in "plot '-' using 2:xticlabels(1)\n";

    for ( $i = 0; $i < @{ $data }; $i++ )
    {
        print $fh_in join( "\t", "\"$data->[ $i ]->[ 0 ]\"", $data->[ $i ]->[ 1 ] ), "\n";
    }

    close $fh_in;

    while ( $line = <$fh_out> )
    {
        chomp $line;

        push @lines, $line;
    }

    close $fh_out;

    waitpid $pid, 0;

    return wantarray ? @lines : \@lines;
}


sub histogram_lendist
{
    # Martin A. Hansen, August 2007.

    # Plots a histogram using Gnuplot.

    my ( $data,       # list of [ xlabel, data value ] tuples 
         $options,    # options hash
       ) = @_;

    # Returns list.

    my ( $pid, $fh_in, $fh_out, $cmd, $i, $line, @lines, $xtic_space );

    $options->{ "terminal" } ||= "dumb";

    if ( $data->[ -1 ]->[ 0 ] <= 10 ) { # FIXME: some day figure the formula for this!
        $xtic_space = 1;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 100 ) {
        $xtic_space = 5;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 250 ) {
        $xtic_space = 10;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 500 ) {
        $xtic_space = 20;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 1000 ) {
        $xtic_space = 50;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 2500 ) {
        $xtic_space = 100;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 5000 ) {
        $xtic_space = 250;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 10000 ) {
        $xtic_space = 500;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 50000 ) {
        $xtic_space = 1000;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 100000 ) {
        $xtic_space = 5000;
    } elsif ( $data->[ -1 ]->[ 0 ] <= 1000000 ) {
        $xtic_space = 50000;
    }

    $cmd  = "gnuplot -persist";

    $pid = open2( $fh_out, $fh_in, $cmd );

    print $fh_in "set terminal $options->{ 'terminal' }\n";
    print $fh_in "set title \"$options->{ 'title' }\"\n"   if $options->{ "title" };
    print $fh_in "set xlabel \"$options->{ 'xlabel' }\"\n" if $options->{ "xlabel" };
    print $fh_in "set ylabel \"$options->{ 'ylabel' }\"\n" if $options->{ "ylabel" };
    print $fh_in "set logscale y\n"                        if $options->{ "logscale_y" };
    print $fh_in "set autoscale\n";
    print $fh_in "unset key\n";
    print $fh_in "set style fill solid\n";
    print $fh_in "set style histogram clustered gap 1 title offset character 0, 0, 0\n";
    print $fh_in "set style data histograms\n";
    print $fh_in "set xtics 0,$xtic_space border out nomirror\n";

    print $fh_in "plot '-' using 1\n";

    for ( $i = 0; $i < @{ $data }; $i++ )
    {
        $data->[ $i ]->[ 0 ] = "." if $data->[ $i ]->[ 0 ] % 10 != 0;

        print $fh_in join( "\t", $data->[ $i ]->[ 1 ] ), "\n";
    }

    close $fh_in;

    while ( $line = <$fh_out> )
    {
        chomp $line;

        push @lines, $line;
    }

    close $fh_out;

    waitpid $pid, 0;

    return wantarray ? @lines : \@lines;
}


sub histogram_chrdist
{
    # Martin A. Hansen, August 2007.

    # Plots a histogram using Gnuplot.

    my ( $data,       # list of [ xlabel, data value ] tuples 
         $options,    # options hash
       ) = @_;

    # Returns list.

    my ( $pid, $fh_in, $fh_out, $cmd, $i, $line, @lines );

    $options->{ "terminal" } ||= "dumb";

    $cmd  = "gnuplot -persist";

    $pid = open2( $fh_out, $fh_in, $cmd );

    print $fh_in "set terminal $options->{ 'terminal' }\n";
    print $fh_in "set title \"$options->{ 'title' }\"\n"   if $options->{ "title" };
    print $fh_in "set xlabel \"$options->{ 'xlabel' }\"\n" if $options->{ "xlabel" };
    print $fh_in "set ylabel \"$options->{ 'ylabel' }\"\n" if $options->{ "ylabel" };
    print $fh_in "set logscale y\n"                        if $options->{ "logscale_y" };
    print $fh_in "set autoscale\n";
    print $fh_in "unset key\n";
    print $fh_in "set style fill solid\n";
    print $fh_in "set style histogram title offset character 0, 0, 0\n";
    print $fh_in "set style data histograms\n";
    print $fh_in "set xtics border in scale 0 nomirror rotate by -90 offset character 0, 0, 0\n";

    print $fh_in "plot '-' using 2:xticlabels(1)\n";

    for ( $i = 0; $i < @{ $data }; $i++ ) {
        print $fh_in join( "\t", "\"$data->[ $i ]->[ 0 ]\"", $data->[ $i ]->[ 1 ] ), "\n";
    }

    close $fh_in;

    while ( $line = <$fh_out> )
    {
        chomp $line;

        push @lines, $line;
    }

    close $fh_out;

    waitpid $pid, 0;

    return wantarray ? @lines : \@lines;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> KARYOGRAM <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 

sub karyogram
{
    # Martin A. Hansen, August 2007.

    # Plot hits on a karyogram for a given genome.

    my ( $data,      # list of [ chr, beg, end ] triples
         $options,   # hashref with options
       ) = @_;

    # Returns string

    my ( $karyo_file, $svg, $features, $karyo );

    if ( $options->{ "genome" } eq "hg18" )
    {
        $karyo_file = $ENV{ 'BP_DIR' } . "/bp_data/human_cytobands.txt";
    }
    elsif( $options->{ "genome" } eq "mm9" )
    {
        $karyo_file = $ENV{ 'BP_DIR' } . "/bp_data/mouse_cytobands.txt";
    }

    $karyo = parse_karyo_data( $karyo_file );

    $svg = init_svg();

    chromosome_layout( $svg, $karyo, $data );

    return $svg->xmlify;
}


sub parse_karyo_data
{
    # X       q26.1   129700001       130200000       gneg

    # color: /etc/X11/rgb.txt

    my ( $file,
       ) = @_;

    my ( $fh, $chr, $line, $name, $beg, $end, $color, %features, %color_hash );

    %color_hash = (
        acen    => "DarkGrey",
        gneg    => "white",
        gpos100 => "black",
        gpos75  => "DarkGrey",
        gpos66  => "DarkGrey",
        gpos50  => "grey",
        gpos33  => "LightGrey",
        gpos25  => "LightGrey",
        gvar    => "LightGrey",
        stalk    => "DarkGrey",
#        gpos75  => "rgb(169,169,169)",
#        gpos66  => "gray66",
#        gpos66  => "#8e8e8e",
#        gpos50  => "gray50",
#        gpos33  => "#e3e3e3",
#        gpos33  => "gray33",
#        gpos25  => "gray25",
#        stalk   => "rgb(169,169,169)",
#        stalk    => "gray66",
    );

    $fh = Maasha::Filesys::file_read_open( $file );

    while ( $line = <$fh> )
    {
        chomp $line;

        next if $line =~ /^#/;

        # ( $chr, $name, $beg, $end, $color ) = split "\t", $line;
        ( $chr, $beg, $end, $name, $color ) = split "\t", $line;
        
#        if ( $color =~ /^gpos(\d+)/ ) {
#            $color = color_intensity( $1 );
#        } elsif ( exists $color_hash{ $color } ) {
            $color = $color_hash{ $color };
#        } else {
#            die qq(ERROR: Unknown color->$color\n);
#        }

        if ( exists $features{ $chr } )
        {
            push @{ $features{ $chr } }, [ $name, $beg, $end, $color ];    
        }
        else
        {
            $features{ $chr } = [ [ $name, $beg, $end, $color ] ];
        }
    }

    close $fh;

    return wantarray ? %features : \%features;
}


sub color_intensity
{
    # Martin A. Hansen, September 2007.

    # Converts a gray scale intensity in percent to rgb.

    my ( $percent,   # color intensity
       ) = @_;

    # Returns string
    
    my ( $num, $hex );

    $num = int( $percent * 256 / 100 );

    $num--;

    $hex = sprintf "%x", $num;

    return "#$hex$hex$hex";

#    return "rgb($num,$num,$num)";
}


sub init_svg
{
    # Martin A. Hansen, September 2005.

    # initializes svg image.

    # returns an image object

    my $svg = SVG->new(
        width  => WIDTH,
        height => HEIGHT,
        style  => {
            'stroke-width' => 1,
            stroke => "black",
            font  => 'Helvetica',
        },
    );

    return $svg;
}


sub chromosome_layout
{
    # Martin A. Hansen, January 2004 - August 2007.

    # Plots all chromosomes in a single

    my ( $svg,          # image object
         $karyo_list,   # hashref with karyo data
         $feat_list,    # hashref with features
       ) = @_;
    
    # returns an image object

    my ( $layout_obj, $i, $x, $y, $max, $factor, $chr_len, $chr_width, $chr_cent, $chr, $feat, $karyo, @list, $A, $B );
    
    $layout_obj = $svg->group(
        id => "chr_layout",
    );

    $max       = $karyo_list->{ "chr1" }->[ -1 ]->[ 2 ];
    $factor    = ( HEIGHT / 2 ) / $max;
    $chr_width = ( HEIGHT / 4 ) / 13;

    foreach $karyo ( keys %{ $karyo_list } ) {
        map { $_->[ 1 ] *= $factor; $_->[ 2 ] *= $factor } @{ $karyo_list->{ $karyo } };
    }

    foreach $feat ( keys %{ $feat_list } ) {
        map { $_->[ 0 ] *= $factor; $_->[ 1 ] *= $factor } @{ $feat_list->{ $feat } };
    }

    @list = sort { $A = $a; $B = $b; $A =~ s/chr//; $B =~ s/chr//; $A <=> $B } keys %{ $karyo_list };

    splice @list, 0, 2;
    push @list, "chrX", "chrY";

    $i = 0;
    
    while ( $i < @list )
    {
        $chr      = $list[ $i ];
        $chr_len  = $karyo_list->{ $chr }->[ -1 ]->[ 2 ];
        $chr_cent = find_cent( $karyo_list->{ $list[ $i ] } );

        $y = HEIGHT / 2 - $chr_len;
        $x = ( WIDTH / ( @list + 2 ) ) * ( $i + 1 );
        
        draw_chr( $layout_obj, $x, $y, $chr_len, $chr_width, $chr_cent, $chr, $karyo_list, $feat_list );

        $i++;
    }
}


sub find_cent
{
    # Martin A. Hansen, December 2003.

    # Finds the centromeric region in the karyo data.

    my ( $list ) = @_;

    my ( $acen, @nums, $cent );

    @{ $acen } = grep { grep { /^DarkGrey$/ } @{ $_ } } @{ $list };

    push @nums, $acen->[ 0 ]->[ 1 ];
    push @nums, $acen->[ 0 ]->[ 2 ];
    push @nums, $acen->[ 1 ]->[ 1 ];
    push @nums, $acen->[ 1 ]->[ 2 ];


    @nums = grep { defined $_ } @nums;   # FIXME
    @nums = sort { $a <=> $b } @nums;

    $cent = ( $nums[ 1 ] + $nums[ 2 ] ) / 2;

    return $cent;
}


sub draw_chr
{
    # Martin A. Hansen, December 2003.

    # draws a whole cromosome with or without centromeric region

    my ( $svg,         # image object
         $x,           # x position
         $y,           # y position
         $chr_len,     # lenght of chromosome
         $chr_width,   # width of chromosome
         $chr_cent,    # position of centromeric region
         $chr,         # chromosome
         $karyo_list,  # hashref with karyo data
         $feat_list,   # hashref with features
       ) = @_;

    # returns image object

    my ( $chr_obj, $clip_obj, $gr_obj );

    $chr_obj = $svg->group(
        id => $chr,
    );
        
    if ( exists $feat_list->{ $chr } ) {
        draw_chr_feat( $chr_obj, $x, $y, $chr_width, $feat_list->{ $chr } );
    }

    $clip_obj = $chr_obj->clipPath(
        id => $chr . "_clipPath",
    );

    $clip_obj->rectangle(
        x      => sprintf( "%.3f", $x ),
        y      => sprintf( "%.3f", $y ),
        width  => sprintf( "%.3f", $chr_width ),
        height => sprintf( "%.3f", $chr_cent ),
        rx     => 10,
        ry     => 10,
    );
    
    $clip_obj->rectangle(
        x      => sprintf( "%.3f", $x ),
        y      => sprintf( "%.3f", $y + $chr_cent ),
        width  => sprintf( "%.3f", $chr_width ),
        height => sprintf( "%.3f", $chr_len - $chr_cent ),
        rx     => 10,
        ry     => 10,
    );

    $gr_obj = $chr_obj->group(
        "clip-path"  => "url(#$chr" . "_clipPath)",
    );
        
    if ( exists $karyo_list->{ $chr } ) {
        draw_karyo_data( $gr_obj, $x, $y, $chr_width, $karyo_list->{ $chr } );
    }

    $gr_obj->rectangle(
        x      => sprintf( "%.3f", $x ),
        y      => sprintf( "%.3f", $y ),
        width  => sprintf( "%.3f", $chr_width ),
        height => sprintf( "%.3f", $chr_cent ),
        fill   => 'none',
        rx     => 10,
        ry     => 10,
    );
    
    $gr_obj->rectangle(
        x      => sprintf( "%.3f", $x ),
        y      => sprintf( "%.3f", $y + $chr_cent ),
        width  => sprintf( "%.3f", $chr_width ),
        height => sprintf( "%.3f", $chr_len - $chr_cent ),
        fill   => 'none',
        rx     => 10,
        ry     => 10,
    );

    draw_chr_num( $chr_obj, $x, $y, $chr_len, $chr_width, $chr );
}


sub draw_chr_num
{
    # Martin A. Hansen, December 2003.

    # draws a cromosome number

    my ( $svg,        # image object
         $x,         # x position
         $y,         # y position
         $chr_len,   # lenght of chromosome
         $chr_width, # width of chromosome
         $chr,       # chromosome number
       ) = @_;

    # returns image object

    my ( $chr_num, $chars, @a, $word_width );

    $chr_num = $chr;
    $chr_num =~ s/chr//;

    $chars = @a = split "", $chr_num;
 
    $word_width = ( $chars * 8 ) / 2;

    $svg->text(
        x  => sprintf("%.3f", $x + ( $chr_width / 2 ) - $word_width ),
        y  => sprintf("%.3f", $y + $chr_len + 15 ),
    )->cdata( $chr_num );
}


sub draw_karyo_data
{
    # Martin A. Hansen, February 2004.

    # Plots chromosome features

    my ( $svg,
         $x,
         $y,
         $chr_width,
         $list,
       ) = @_;

    # returns an image object

    my ( $feat_beg, $feat_end, $feat_height, $i, $color, $label );

    for ( $i = 0; $i < @{ $list }; $i++ )
    {
        ( $label, $feat_beg, $feat_end, $color ) = @{ $list->[ $i ] };

        $feat_height = $feat_end - $feat_beg;

        $svg->rectangle(
            x      => sprintf("%.3f", $x ),
            y      => sprintf("%.3f", $y + $feat_beg ),
            width  => sprintf("%.3f", $chr_width ),
            height => sprintf("%.3f", $feat_height ),
            'stroke-width' => 0,
            fill   => $color,
        );
    }
}


sub draw_chr_feat
{
    # Martin A. Hansen, February 2004.

    # Plots chromosome features

    my ( $svg,
         $x,
         $y,
         $chr_width,
         $list,
       ) = @_;

    # returns an image object

    my ( $feat_beg, $feat_end, $feat_height, $i, $color, $height, $width, $x1, $y1, %lookup );

    for ( $i = 0; $i < @{ $list }; $i++ )
    {
        ( $feat_beg, $feat_end, $color ) = @{ $list->[ $i ] };
    
        $feat_height = $feat_end - $feat_beg;

        $x1     = sprintf("%.0f", $x + ( $chr_width / 2 ) ),
        $y1     = sprintf("%.0f", $y + $feat_beg ),
        $width  = sprintf("%.0f", ( $chr_width / 2 ) + 5 ),
        $height = sprintf("%.0f", $feat_height );

        if ( $height < 1 )
        {
            $height = 1;
        
            if ( exists $lookup{ $x1 . $y1 } ) {
                next;
            } else {
                $lookup{ $x1 . $y1 } = 1;
            }
        }

        $svg->rectangle(
            x      => $x1,
            y      => $y1,
            width  => $width,
            height => $height,
            stroke => $color,
            fill   => $color,
        );
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SEQUENCE LOGO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub seq_logo
{
    # Martin A. Hansen, August 2007.

    # Calculates and renders a sequence logo in SVG format.

    my ( $entries,   # aligned sequence entries - list of tuples
       ) = @_;

    # Returns string.

    my ( $type, $bit_max, $logo_data, $svg );

    $type = Maasha::Seq::seq_guess_type( $entries->[ 0 ]->[ 1 ] );

    if ( $type eq "PROTEIN" ) {
        $bit_max = 4;
    } else {
        $bit_max = 2;
    }

    $logo_data = Maasha::Seq::seqlogo_calc( $bit_max, $entries );

    $svg = Maasha::Plot::svg_init();

    svg_draw_logo( $svg, $logo_data, $bit_max, $type );
    svg_draw_logo_scale( $svg, $bit_max );

    return $svg->xmlify;
}


sub svg_init
{
    # Martin A. Hansen, October 2005.

    # inititalizes SVG object, which is returned.

    my $svg;

    $svg = SVG->new(
        style  => {
            'font-weight'  => 'normal',
            'font-family'  => 'Courier New',
            'font-size'    => 10,
        },
    );

    return $svg;
}


sub svg_draw_logo
{
    # Martin A. Hansen, January 2007.

    # Renders a sequence logo in SVG using a
    # given data structure with logo details.

    my ( $svg,         # SVG object,
         $logo_data,   # data structure
         $bit_max,     # maximum bit height
         $type,        # sequence type
         $nocolor,     # render black and white - OPTIONAL
       ) = @_;

    my ( $pos, $elem, $char, $char_height_bit, $char_height_px, $block, $x, $y, $scale_factor, $color );

    $x = 0;

    foreach $pos ( @{ $logo_data } )
    {
        $y = 30;

        foreach $elem ( @{ $pos } )
        {
            ( $char, $char_height_bit ) = @{ $elem };

            $char_height_px = $char_height_bit * ( 30 / $bit_max );

            $block = $svg->group(
                transform => "translate($x,$y)",
            );

            $scale_factor = $char_height_px / 7;

            if ( $nocolor ) {
                $color = "black";
            } elsif ( $type eq "dna" or $type eq "rna" ) {
                $color = Maasha::Seq::color_nuc( $char );
            } else {
                $color = Maasha::Seq::color_pep( $char );
            }

            $block->text(
                transform => "scale(1,$scale_factor)",
                x  => 0,
                y  => 0,
                style => {
                    'font-weight' => 'bold',
                    fill          => Maasha::Seq::color_palette( $color ),
                }
            )->cdata( $char );

            $y -= $char_height_px;
        }

        $x += 7;
    }
}


sub svg_draw_logo_scale
{
    # Martin A. Hansen, January 2007.

    # draws the bit scale for the sequence logo

    my ( $svg,         # SVG object,
         $bit_max,     # maximum bit height
       ) = @_;

    my ( $scale, $i );

    $scale = $svg->group(
        transform => "translate(-10)",
        style => {
            stroke      => 'black',
            'font-size' => '8px',
        }
    );

    $svg->text(
#        transform => "translate(0,$logo_y)",
        transform => "rotate(-90)",
        x  => -26,
        y  => -30,
        style => {
            stroke => 'none',
        }
    )->cdata( "bits" );

    $scale->line(
        x1 => 0,
        x2 => 0,
        y1 => 0,
        y2 => 30,
    );

    for ( $i = 0; $i <= $bit_max; $i++ )
    {
        $scale->line(
            x1 => -5,
            x2 => 0,
            y1 => ( 30 / $bit_max ) * $i,
            y2 => ( 30 / $bit_max ) * $i,
        );

        $scale->text(
            x  => -13,
            y  => ( 30 / $bit_max ) * $i + 2,
            style => {
                stroke => 'none',
            }
        )->cdata( $bit_max - $i );
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
