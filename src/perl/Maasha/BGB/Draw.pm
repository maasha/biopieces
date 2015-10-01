package Maasha::BGB::Draw;

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


# Routines for creating Biopieces Browser graphics using Cairo and Pango.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Data::Dumper;
use Cairo;
use Pango;
use MIME::Base64;
use POSIX;

use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub draw_feature
{
    # Martin A. Hansen, November 2009

    # Given a list of features add these to
    # a Cairo::Context object.

    my ( $cr,         # Cairo::Context object
         $features,   # List of features
       ) = @_;

    # Returns nothing.

    my ( $feature, $first );

    $first = 1;

    foreach $feature ( @{ $features } )
    {
        $cr->set_source_rgb( @{ $feature->{ 'color' } } );

        if ( $feature->{ 'type' } eq 'line' )
        {
            $cr->set_line_width( $feature->{ 'line_width' } );
            $cr->move_to( $feature->{ 'x1' }, $feature->{ 'y1' } );
            $cr->line_to( $feature->{ 'x2' }, $feature->{ 'y2' } );
        }
        elsif ( $feature->{ 'type' } eq 'grid' )
        {
            $cr->set_line_width( $feature->{ 'line_width' } );
            $cr->move_to( $feature->{ 'x1' }, $feature->{ 'y1' } );
            $cr->line_to( $feature->{ 'x2' }, $feature->{ 'y2' } );
        }
        elsif ( $feature->{ 'type' } eq 'wiggle' )
        {
            $cr->set_line_width( $feature->{ 'line_width' } );

            if ( $first )
            {
                $cr->move_to( $feature->{ 'x1' }, $feature->{ 'y1' } );

                undef $first;
            }

            $cr->line_to( $feature->{ 'x1' }, $feature->{ 'y2' } );
            $cr->line_to( $feature->{ 'x2' }, $feature->{ 'y2' } );
        }
        elsif ( $feature->{ 'type' } eq 'arrow' )
        {
            draw_arrow_horizontal(
                $cr,
                $feature->{ 'x1' },
                $feature->{ 'y1' },
                $feature->{ 'x2' },
                $feature->{ 'y2' },
                $feature->{ 'strand' },
            );

        }
        elsif ( $feature->{ 'type' } eq 'rect' )
        {
            $cr->rectangle(
                $feature->{ 'x1' },
                $feature->{ 'y1' },
                $feature->{ 'x2' } - $feature->{ 'x1' } + 1,
                $feature->{ 'y2' } - $feature->{ 'y1' } + 1,
            );

            $cr->fill;
        }
        elsif ( $feature->{ 'type' } eq 'text' )
        {
            $cr->move_to( $feature->{ 'x1' }, $feature->{ 'y1' } );
            $cr->set_font_size( $feature->{ 'font_size' } );
            $cr->show_text( $feature->{ 'txt' } );
        }
        elsif ( $feature->{ 'type' } eq 'track_name' )
        {
            $cr->move_to( $feature->{ 'x1' }, $feature->{ 'y1' } );
            $cr->set_font_size( $feature->{ 'font_size' } );
            $cr->show_text( $feature->{ 'txt' } );
        }

        #$cr->stroke;
    }

    $cr->fill_preserve;
    $cr->stroke;
}


sub draw_arrow_horizontal
{
    # Draws a horizontal arraw that
    # consists of a shaft and arrow head.

    my ( $cr,   # Cairo::Context object
         $x1,
         $y1,
         $x2,
         $y2,
         $strand,
       ) = @_;

    # Returns nothing.

    my ( $x_diff, $y_diff, $mid, $width, $s_width );

    $x_diff = abs( $x2 - $x1 );
    $y_diff = abs( $y2 - $y1 );

    $mid = $y_diff / 2;

    if ( $x_diff < $mid ) {
        $width = $x_diff;
    } else {
        $width = $mid;
    }

    # Draw arrow head

    $cr->set_line_width( 1 );

    if ( $strand eq '+' )
    {
        $cr->move_to( $x2 - $width, $y1 );
        $cr->line_to( $x2, $y1 + $mid );
        $cr->line_to( $x2 - $width, $y2 );
    }
    else
    {
        $cr->move_to( $x1 + $width, $y1 );
        $cr->line_to( $x1, $y1 + $mid );
        $cr->line_to( $x1 + $width, $y2 );
    }
    
    $cr->close_path;
    $cr->fill_preserve;
    $cr->stroke;

    # Draw arrow shaft

    if ( $x_diff > $mid )
    {
        if ( $strand eq '+' ) {
            $cr->rectangle( $x1, $y1, ( $x2 - $width ) - $x1, $y2 - $y1 );    
        } else {
            $cr->rectangle( $x1 + $width, $y1, $x2 - ( $x1 + $width ), $y2 - $y1 );    
        }

        $cr->fill_preserve;
        $cr->stroke;
    }
}


sub palette
{
    # Martin A. Hansen, November 2009.
    
    # Given a color number, pick that color from 
    # the color palette and return.
    
    my ( $i,   # color number
       ) = @_; 
       
    # Returns a arrayref
    
    my ( $palette, $color );
    
    $palette = [
        [  30, 130, 130 ],
        [  30,  50, 150 ],
        [ 130, 130,  50 ],
        [ 130,  90, 130 ],
        [ 130,  70,  70 ],
        [  70, 170, 130 ],
        [ 130, 170,  50 ],
        [  30, 130, 130 ],
        [  30,  50, 150 ],
        [ 130, 130,  50 ],
        [ 130,  90, 130 ],
        [ 130,  70,  70 ],
        [  70, 170, 130 ],
        [ 130, 170,  50 ],
        [  30, 130, 130 ],
        [  30,  50, 150 ],
        [ 130, 130,  50 ],
        [ 130,  90, 130 ],
        [ 130,  70,  70 ],
        [  70, 170, 130 ],
        [ 130, 170,  50 ],
        [  30, 130, 130 ],
        [  30,  50, 150 ],
        [ 130, 130,  50 ],
        [ 130,  90, 130 ],
        [ 130,  70,  70 ],
        [  70, 170, 130 ],
        [ 130, 170,  50 ],
    ];  

    $color = $palette->[ $i ];

    map { $_ /= 255 } @{ $color };
    
    return $color;
}   


sub render_png
{
    # Martin A. Hansen, March 2010.

    # Given a list of BGB tracks, render the
    # PNG surface stream and return the base64
    # encoded PNG data.

    my ( $width,    # image width
         $height,   # image height
         $tracks,   # list of BGB tracks to render
       ) = @_;

    # Returns a string.

    my ( $surface, $cr, $track, $png_data );

    $surface = Cairo::ImageSurface->create( 'argb32', $width, $height );
    $cr      = Cairo::Context->create( $surface );

    $cr->rectangle( 0, 0, $width, $height );
    $cr->set_source_rgb( 1, 1, 1 );
    $cr->fill;

    foreach $track ( @{ $tracks } ) {
        draw_feature( $cr, $track ) if $track;
    }

    $png_data = base64_png( $surface );

    return $png_data;
}


sub render_pdf_file
{
    # Martin A. Hansen, March 2010.

    # Given a list of BGB tracks, render these and save
    # to a PDF file.

    my ( $file,     # path to PDF file
         $width,    # image width
         $height,   # image height
         $tracks,   # list of BGB tracks to render
       ) = @_;

    # Returns nothing.

    my ( $surface, $cr, $track );

    $surface = Cairo::PdfSurface->create ( $file, $width, $height );
    $cr      = Cairo::Context->create( $surface );

    $cr->rectangle( 0, 0, $width, $height );
    $cr->set_source_rgb( 1, 1, 1 );
    $cr->fill;

    foreach $track ( @{ $tracks } ) {
        draw_feature( $cr, $track ) if $track;
    }
}


sub render_svg_file
{
    # Martin A. Hansen, March 2010.

    # Given a list of BGB tracks, render these and save
    # to a SVG file.

    my ( $file,     # path to PDF file
         $width,    # image width
         $height,   # image height
         $tracks,   # list of BGB tracks to render
       ) = @_;

    # Returns nothing.

    my ( $surface, $cr, $track );

    $surface = Cairo::SvgSurface->create ( $file, $width, $height );
    $cr      = Cairo::Context->create( $surface );

    $cr->rectangle( 0, 0, $width, $height );
    $cr->set_source_rgb( 1, 1, 1 );
    $cr->fill;

    foreach $track ( @{ $tracks } ) {
        draw_feature( $cr, $track ) if $track;
    }
}


sub file_png
{
    # Martin A. Hansen, October 2009.

    # Prints a Cairo::Surface object to a PNG file.

    my ( $surface,   # Cairo::Surface object
         $file,      # path to PNG file
       ) = @_;

    # Returns nothing

    $surface->write_to_png( $file );
}


sub base64_png
{
    # Martin A. Hansen, December 2009.

    # Extract a PNG stream from a Cairo::Surface object
    # and convert it to base64 before returning it.

    my ( $surface,   # Cairo::Surface object
       ) = @_;

    # Returns a string.

    my ( $png_data, $callback, $base64 );

    $png_data = "";

    $callback = sub { $png_data .= $_[ 1 ] };
    
    $surface->write_to_png_stream( $callback );

    $base64 = MIME::Base64::encode_base64( $png_data );

    return $base64;
}


sub get_distinct_colors
{
    # Martin A. Hansen, November 2003.

    # returns a number of distinct colors

    my ( $num_colors
       ) = @_;

    # returns triplet of colors [ 0, 255, 127 ]

    my ( $num_discrete, @color_vals, $c, @colors, $r_idx, $g_idx, $b_idx, $i );

    $num_discrete = POSIX::ceil( $num_colors ** ( 1 / 3 ) );

    @color_vals = map {
        $c = 1 - ($_ / ($num_discrete - 1) );
        $c < 0 ? 0 : ($c > 1 ? 1 : $c);
    } 0 .. $num_discrete;

    ( $r_idx, $g_idx, $b_idx ) = ( 0, 0, 0 );

    foreach $i ( 1 .. $num_colors )
    {
        push @colors, [ @color_vals [ $r_idx, $g_idx, $b_idx ] ];
        
        if ( ++$b_idx >= $num_discrete )
        {
            if ( ++$g_idx >= $num_discrete ) {
                $r_idx = ( $r_idx + 1 ) % $num_discrete;
            }
            
            $g_idx %= $num_discrete;
        }

        $b_idx %= $num_discrete;
    }

    @colors = map { [ int( $_->[ 0 ] * 255), int( $_->[ 1 ] * 255), int( $_->[ 2 ] * 255 ) ] } @colors;
 
    return wantarray ? @colors : \@colors;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;


