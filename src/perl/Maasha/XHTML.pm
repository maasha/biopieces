package Maasha::XHTML;

# Copyright (C) 2005-2010 Martin A. Hansen.

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


# Version 1.1

# Martin A. Hansen, July 2005.
# mail@maasha.dk

# Routines for generating XHTML code with CSS support.
# Intentionally as much layout control as possible is done with CSS.
# locate the 'xthml_examples' script for examples of usage.

# Caveat: these routines return one or more lines of HTML code, and generally
# does not know about the layout of a HTML document. HTML elements, such as
# a, input, select, textarea etc. that must be embedded in other elements such as,
# h1 .. h6, p, ol, ul, etc. will have to be considered carefully to get the embedding
# correct. Do have a look at the 'xthml_examples' script for examples of usage.

# NB! do use w3's excellent HTML Validator while designing HTML layout (http://validator.w3.org/)

# NB! alternatively use Dave Raggett's TIDY (http://tidy.sourceforge.net/)

# Example:   $name = &XHTML::text( name => "NAME", value => $name_def || "", size => 25, maxlength => 20 );

# Suggested reading: XHTML standard -> http://www.w3.org/TR/xhtml1/
#                      CSS standard -> http://www.w3schools.com/css/css_reference.asp
#                                      http://htmldog.com/guides/htmlbeginner/
#                                      http://htmldog.com/guides/htmlintermediate/
#                                      http://htmldog.com/guides/htmladvanced/


# WISHLIST:

# intelligent insertion of \n in the HTML blocks so that
# 1) p( ln(), ln(), ln() ) behaves similar to
# 2) p( join( "\n", ln(), ln(), ln() ) or
# 3) p( join( "", ln(), ln(), ln() )
# all producing nicely layouted HTML code:
# <p><a href="#"></a><a href="#"></a><a href="#"></a></p>

# 1) is probably not wise to undertake..
# 2) + 3) should be doable but may also be unwise:
# this would imply that the tag_pair routine should parse the
# incomming txt string for HTML tags and make sure newlines are
# inserted in a logical way. this requires a recursive HTML parse
# routine. but then one might as well postprocess the entire list
# of HTML lines using TIDY.

# buttons with action:
#
# <input type='button' value='Print this page' name='print_page' onClick='window.print()'>
# <input TYPE='button' VALUE='Close this window' NAME='bouton_close'  onClick="window.close('this')"> 

use strict;
use warnings;
use Data::Dumper;

use vars qw( @ISA @EXPORT );

require Exporter;

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SIGNAL HANDLERS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

use sigtrap qw( die normal-signals stack-trace any error-signals );

my $WARNINGS = 0;

$SIG{ '__DIE__' }  = \&sig_die;
$SIG{ '__WARN__' } = \&sig_warn;


sub sig_die
{
    my ( $sig,   # signal from the %SIG
       ) = @_;

    my ( @html );

    push @html, &cgi_header;
    push @html, p( txt => "ERROR: $sig" );

    $WARNINGS++;

    print "$_" for @html;
}


sub sig_warn
{
    my ( $sig,   # signal from the %SIG
       ) = @_;

    my ( @html );

    push @html, &cgi_header if $WARNINGS == 0;
    push @html, p( txt => "WARNING: $sig" );

    $WARNINGS++;

    print "$_" for @html;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HEADERS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub html_header 
{
    # Martin A. Hansen, July 2005.

    # Creates HTML header

    my ( %args,   # arguments
       ) = @_;

    # Returns string

    my ( @html );

    push @html, &cgi_header                            if $args{ "cgi_header" } and $WARNINGS == 0;
    push @html, &doc_type;
    push @html, &head_beg;
    push @html, &title( $args{ "title" } )             if $args{ "title" };
    push @html, &css( $args{ "css_file" } )            if $args{ "css_file" };
    push @html, &author( $args{ "author" } )           if $args{ "author" };
    push @html, &description( $args{ "description" } ) if $args{ "description" };
    push @html, &keywords( $args{ "keywords" } )       if $args{ "keywords" };   
    push @html, &no_cache( $args{ "no_cache" } )       if $args{ "no_cache" };
    push @html, &head_end;
    push @html, &body_beg;

    return join "\n", @html;
}


sub cgi_header
{
    # Martin A. Hansen, July 2005.

    # Header for CGI scripts.

    return "Content-Type: text/html; charset=ISO-8859-1\n\n";
}


sub doc_type
{
    # Martin A. Hansen, July 2005.

    # Header for XHTML 1.0 Strict

    return qq(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">);
}


sub head_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <head> element

    return "<head>";
}


sub title
{
    # Martin A. Hansen, July 2005.

    # HTML <title> element.

    my ( $title,   # docuement title
       ) = @_;

    warn qq(WARNING: no title given\n) if not $title;

    return &tag_pair( "title", { txt => $title } );
}


sub css
{
    # Martin A. Hansen, July 2005.

    # Links external CSS file.

    my ( $css_file,   # path to external CSS file
       ) = @_;

    warn qq(WARNING: could not locate CSS file "$css_file"\n) if not -f $css_file;

    return &tag_single( "link", { rel => "stylesheet", type => "text/css", href => $css_file } );
}


sub icon
{
    # Martin A. Hansen, July 2005.

    # Links flavicon.

    my ( $icon_file,   # path to flavicon file
       ) = @_;

    warn qq(WARNING: could not locate icon file "$icon_file"\n) if not -f $icon_file;

    return &tag_single( "link", { rel => "shortcut icon", href => $icon_file } );
}


sub author
{
    # Martin A. Hansen, July 2005.

    # HTML meta tag containing author information.

    my ( $author,   # name of webpage author
       ) = @_;

    warn qq(WARNING: no author given\n) if not $author;

    return &tag_single( "meta", { name => "author", content => $author } );
}


sub description
{
    # Martin A. Hansen, July 2005.

    # HTML meta tag containing webpage description.

    my ( $description,    # webpage description
       ) = @_;
       
    warn qq(WARNING: no description given\n) if not $description;

    return &tag_single( "meta", { name => "description", content => $description } );
}


sub keywords
{
    # Martin A. Hansen, July 2005.

    # HTML meta tag contining webpage keywords for webcrawlers.

    my ( $keywords,   # list of keywords
       ) = @_;

    my ( $keyword );

    warn qq(WARNING: no keywords given\n) if not $keywords;

    $keyword = join ", ", @{ $keywords };
    
    return &tag_single( "meta", { name => "keywords", content => $keyword } );
}


sub no_cache
{
    # Martin A. Hansen, July 2005.
    
    # HTML meta tags disabling browser caching.
    # (uncomfirmed behaviour - works sometimes - sometimes not)

    my @html;

    push @html, &tag_single( "meta", { "http-equiv" => "pragma", content => "no-cache" } );
    push @html, &tag_single( "meta", { "http-equiv" => "cache-control", content => "no-store" } );

    return join "\n", @html;
}


sub head_end
{
    # Martin A. Hansen, July 2005.

    # HTML </head> element

    return "</head>";
}


sub body_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <body> element

    return "<body>";
}


sub javascript
{
    # Martin A. Hansen, July 2005.

    # Links external java script file

    # Must be located in the HTML body section
    # (after <body> and before </body>)

    my ( $js_file,   # path to javascript file
       ) = @_;

    warn qq(WARNING: could not locate javascript file "$js_file"\n) if not -f $js_file;

    return qq(<script src="$js_file" type="text/javascript"></script>);
}


sub body_end
{
    # Martin A. Hansen, July 2005.

    # HTML </body> element

    return "</body>";
}


sub html_end
{
    # Martin A. Hansen, July 2005.

    # HTML </html> element

    return "</html>";
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HEADINGS & PARAGRAPH <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub h1
{
    # Martin A. Hansen, July 2005.

    # HTML <h1> element

    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h1", \%args );
}


sub h2
{
    # Martin A. Hansen, July 2005.

    # HTML <h2> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h2", \%args );
}


sub h3
{
    # Martin A. Hansen, July 2005.

    # HTML <h3> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h3", \%args );
}


sub h4
{
    # Martin A. Hansen, July 2005.

    # HTML <h4> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h4", \%args );
}


sub h5
{
    # Martin A. Hansen, July 2005.

    # HTML <h5> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h5", \%args );
}


sub h6
{
    # Martin A. Hansen, July 2005.

    # HTML <h6> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "h6", \%args );
}


sub p
{
    # Martin A. Hansen, July 2005.

    # HTML <p> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_pair( "p", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LISTS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# Lists comes in two flavors - simple and advanced.
# simple lists work on a simple list of items, while
# advamced lists work on a list where each item is specified.


sub ul_simple
{
    # Martin A. Hansen, July 2005.

    # HTML <ul> element

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARINING: no ul_simple items given\n) if not $args{ "li" };

    return &list_simple( "ul", \%args );
}


sub ol_simple
{
    # Martin A. Hansen, July 2005.

    # HTML <ul> element

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARINING: no ol_simple items given\n) if not $args{ "li" };

    return &list_simple( "ol", \%args );
}


sub ul_advanced
{
    # Martin A. Hansen, July 2005.

    # HTML <ul> element

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARINING: no ul_advanced items given\n) if not $args{ "li" };

    return &list_advanced( "ul", \%args );
}


sub ol_advanced
{
    # Martin A. Hansen, July 2005.

    # HTML <ol> element

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARINING: no ol_advanced items given\n) if not $args{ "li" };

    return &list_advanced( "ol", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LABEL <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub label
{
    # Martin A. Hansen, July 2005.

    # HTML <label> element

    my ( %args,
       ) = @_;

    # Returns string
    
    warn qq(WARNING: no "for" given in label\n) if not $args{ "for" };

    return &tag_pair( "label", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LINE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub hr
{
    # Martin A. Hansen, July 2005.

    # HTML <hr> element

    # NB - rather use proper CSS than <hr>!

    my ( %args,
       ) = @_;

    # Returns string

    return &tag_single( "hr", \%args );
}


sub br
{
    # Martin A. Hansen, July 2005.

    # HTML <br> element

    # NB - rather use proper CSS than <br>!

    my ( %args,
       ) = @_;

    # Returns string

    return &tag_single( "br", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LINK <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub ln
{
    # Martin A. Hansen, July 2005.

    # HTML <ln> element
    
    my ( %args,
       ) = @_;

    # Returns string

    my ( @html );

    warn qq(WARNING: no link href given\n) if not $args{ "href" };
    
    $args{ "href" } =~ s/&/&amp;/g;
    
    if ( $args{ "txt" } ) {
        return &tag_pair( "a", \%args );
    } else {
        return &tag_single( "a", \%args );
    }
}


sub anchor
{
    # Martin A. Hansen, July 2005.

    # HTML anchor

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no anchor txt given\n) if not $args{ "txt" };
    warn qq(WARNING: no anchor name given\n) if not $args{ "name" };

    return &tag_pair( "a", \%args );
}


sub mailto
{
    # Martin A. Hansen, July 2005.

    # HTML mailto
    
    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no mailto txt given\n)    if not $args{ "txt" };
    warn qq(WARNING: no mailto address given\n) if not $args{ "email" };

    $args{ "href" } = "mailto:" . $args{ "email" };

    delete $args{ "email" };

    return &tag_pair( "a", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IMG & OBJECT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub img
{
    # Martin A. Hansen, July 2005.

    # HTML <img> element
    
    my ( %args,
       ) = @_;

    # Returns string

    return &tag_single( "img", \%args );
}


sub object
{
    # Martin A. Hansen, October 2009.

    # HTML <object> element

    my ( %args,
       ) = @_;

    # Returns string

    return &tag_single( "object", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DIV & SPAN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub div
{
    # Martin A. Hansen, July 2005.

    # HTML <div> element

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $lines );

    $lines  = $args{ "txt" };

    if ( $lines )
    {
        $args{ "txt" } = $lines;

        return &tag_pair( "div", \%args );
    }
    else
    {
        return &tag_single( "div", \%args );
    }
}


sub span
{
    # Martin A. Hansen, July 2005.

    # HTML <span> element

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no span given\n) if not $args{ "txt" };

    return &tag_pair( "span", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAP <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub map_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <map> element
    
    my ( %args,
       ) = @_;

    warn qq(WARNING: no map name given\n) if not $args{ "name" };
    warn qq(WARNING: no map id given \n)  if not $args{ "id" };

    my $arg = &format_args( \%args );

    return qq(<map $arg>);
}


sub map_end
{
    # Martin A. Hansen, July 2005.

    # HTML </map> element

    return qq(</map>);
}


sub area
{
    # Martin A. Hansen, October 2009.

    # HTML <area> element

    my ( %args,
       ) = @_;

    warn qq(WARNING: no area href given\n)    if not $args{ "href" };
    warn qq(WARNING: no area shape given \n)  if not $args{ "shape" };
    warn qq(WARNING: no area coords given \n) if not $args{ "coords" };

    return tag_single( "area", \%args )
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PRE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub pre
{
    # Martin A. Hansen, July 2005.

    # HTML <pre> element
    
    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no pre lines given\n) if not $args{ "txt" };

    $args{ "txt" } =~ s/&/&amp;/g;
    $args{ "txt" } =~ s/>/&gt;/g;
    $args{ "txt" } =~ s/</&lt;/g;

    return &tag_pair( "pre", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FORMS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub form_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <form> element

    my ( %args,
       ) = @_;

    my ( $arg );

    $arg = &format_args( \%args );

    warn qq(WARNING: no form method given\n) if not $args{ "method" };
    warn qq(WARNING: "method" must be eihter "post" or "get" - not ") . $args{ "method" } . qq("\n) if not $args{ "method" } =~ /get|post/;

    return qq(<form $arg>);
}


sub form_end
{
    # Martin A. Hansen, July 2005.

    # HTML </form> element

    return qq(</form>);
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BUTTONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub submit
{
    # Martin A. Hansen, July 2005.

    # HTML submit button

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "submit", \%args );
}


sub reset
{
    # Martin A. Hansen, July 2005.

    # HTML reset button

    return &input_field( "reset" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIELDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub text
{
    # Martin A. Hansen, July 2005.

    # HTML text field

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "text", \%args );
}


sub password
{
    # Martin A. Hansen, July 2005.

    # HTML password field

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "password", \%args );
}


sub file
{
    # Martin A. Hansen, July 2005.

    # HTML file field

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "file", \%args );
}


sub checkbox
{
    # Martin A. Hansen, July 2005.

    # HTML checkbox field

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "checkbox", \%args );
}


sub radio
{
    # Martin A. Hansen, July 2005.

    # HTML radio button field

    my ( %args,
       ) = @_;

    # Returns string

    return &input_field( "radio", \%args );
}


sub hidden
{
    # Martin A. Hansen, July 2005.

    # HTML hidden field

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no hidden value given\n) if not $args{ "value" };

    return &input_field( "hidden", \%args );
}


sub menu
{
    # Martin A. Hansen, July 2005.

    # HTML popup/drowdown menu
    
    my ( %args,    # name of variable
       ) = @_;

    # Returns string

    my ( @html, $name, $selected, $options, $option, $value );
 
    warn qq(WARNING: no menu name given\n)    if not $args{ "name" };
    warn qq(WARNING: no menu options given\n) if not $args{ "options" };
 
    $name     = $args{ "name" };
    $selected = $args{ "selected" };
    $options  = $args{ "options" };
 
    push @html, qq(<select name="$name">);

    push @html, &tag_pair( "option", { selected => "selected", value => $selected, txt => $selected } ) if exists $args{ "selected" };

    foreach $option ( @{ $options } ) {
        push @html, &tag_pair( "option", { value => "$option", txt => $option } );
    }

    push @html, qq(</select>);

    return join "\n", @html;
}


sub textarea
{
    # Martin A. Hansen, July 2005.

    # HTML textarea field

    my ( %args,
       ) = @_;

    # Returns string

    warn qq(WARNING: no textarea name given\n)  if not $args{ "name" };
    warn qq(WARNING: no textarea rows given\n)  if not $args{ "rows" };
    warn qq(WARNING: no textarea cols given\n)  if not $args{ "cols" };

    return &tag_pair( "textarea", \%args );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TABLE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# XHTML allows several forms of tables: table, thead, tbody, and tfoot.
# All are supported in the below routines, considering that each of these
# table types are generically handled in two flavors - simple and advanced.
# simple tables takes a list of rows as arguments, while advamced tables 
# takes a list of rows each cell is specified.
# NB! the order of tables is important thead->tfoot->tbody (if used)


sub table_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <table> element

    my ( %args,
       ) = @_;

    my $arg = &format_args( \%args );

    if ( $arg ) {
        return "<table $arg>";
    } else {
        return "<table>";
    }
}


sub table_end
{
    # Martin A. Hansen, July 2005.

    # HTML </table> element

    return "</table>";
}


sub table_head_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <thead> element

    my ( %args,
       ) = @_;

    my $arg = &format_args( \%args );

    if ( $arg ) {
        return "<thead $arg>";
    } else {
        return "<thead>";
    }
}


sub table_head_end
{
    # Martin A. Hansen, July 2005.

    # HTML </thead> element

    return "</thead>";
}


sub table_foot_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <tfoot> element

    my ( %args,
       ) = @_;

    my $arg = &format_args( \%args );

    if ( $arg ) {
        return "<tfoot $arg>";
    } else {
        return "<tfoot>";
    }
}


sub table_foot_end
{
    # Martin A. Hansen, July 2005.

    # HTML </tfoot> element

    return "</tfoot>";
}


sub table_body_beg
{
    # Martin A. Hansen, July 2005.

    # HTML <tbody> element

    my ( %args,
       ) = @_;

    my $arg = &format_args( \%args );

    if ( $arg ) {
        return "<tbody $arg>";
    } else {
        return "<tbody>";
    }
}


sub table_body_end
{
    # Martin A. Hansen, July 2005.

    # HTML </tbody> element

    return "</tbody>";
}


sub table_caption
{
    # Martin A. Hansen, July 2005.

    # HTML <caption> element

    my ( %args,
       ) = @_;

    # Returns string

    my @html = &tag_pair( "caption", \%args );
    
    return wantarray ? @html : \@html;
}


sub table_row_simple
{
    # Martin A. Hansen, July 2005.

    # HTML simple row

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $cells, $cell );

    warn qq(WARNING: no simple row given\n) if not $args{ "tr" };

    $cells = $args{ "tr" };
    
    delete $args{ "tr" };

    $arg = &format_args( \%args );

    if ( $arg ) {
        push @html, "<tr $arg>";
    } else {
        push @html, "<tr>";
    }

    foreach $cell ( @{ $cells } ) {
        push @html, &tag_pair( "td", { txt => $cell } );
    }

    push @html, "</tr>";
        
    return join "\n", @html;
}


sub table_row_advanced
{
    # Martin A. Hansen, July 2005.

    # HTML advanced row

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $cells, $cell );

    warn qq(WARNING: no advanced row given\n) if not $args{ "tr" };

    $cells = $args{ "tr" };
    
    delete $args{ "tr" };

    $arg = &format_args( \%args );

    if ( $arg ) {
        push @html, "<tr $arg>";
    } else {
        push @html, "<tr>";
    }

    foreach $cell ( @{ $cells } )
    {
        $cell->{ "txt" } = $cell->{ "td" };

        delete $cell->{ "td" };
    
        push @html, &tag_pair( "td", $cell );
    }

    push @html, "</tr>";
        
    return join "\n", @html;
}


sub table_header_simple
{
    # Martin A. Hansen, July 2005.

    # HTML simple header rww

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $cells, $cell );

    warn qq(WARNING: no simple header given\n) if not $args{ "tr" };

    $cells = $args{ "tr" };
    
    delete $args{ "tr" };

    $arg = &format_args( \%args );

    if ( $arg ) {
        push @html, "<tr $arg>";
    } else {
        push @html, "<tr>";
    }

    foreach $cell ( @{ $cells } ) {
        push @html, &tag_pair( "th", { txt => $cell } );
    }

    push @html, "</tr>";
        
    return join "\n", @html;
}


sub table_header_advanced
{
    # Martin A. Hansen, July 2005.

    # HTML advanced header row

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $cells, $cell );

    warn qq(WARNING: no advanced header given\n) if not $args{ "tr" };

    $cells = $args{ "tr" };
    
    delete $args{ "tr" };

    $arg = &format_args( \%args );

    if ( $arg ) {
        push @html, "<tr $arg>";
    } else {
        push @html, "<tr>";
    }

    foreach $cell ( @{ $cells } )
    {
        $cell->{ "txt" } = $cell->{ "th" };

        delete $cell->{ "th" };
    
        push @html, &tag_pair( "th", $cell );
    }

    push @html, "</tr>";
        
    return join "\n", @html;
}


sub table_colgroup
{
    # Martin A. Hansen, July 2005.

    # HTML colgroup row

    my ( %args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $cells, $cell );

    warn qq(WARNING: no colgroup given\n) if not $args{ "colgroup" };

    $cells = $args{ "colgroup" };
    
    delete $args{ "colgroup" };

    $arg = &format_args( \%args );

    if ( $arg ) {
        push @html, "<colgroup $arg>";
    } else {
        push @html, "<colgroup>";
    }

    foreach $cell ( @{ $cells } ) {
        push @html, &tag_single( "col", $cell );
    }

    push @html, "</colgroup>";
        
    return join "\n", @html;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HTML COMMENT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub comment
{
    # Martin A. Hansen, July 2005.

    # HTML comment

    my ( %args,
       ) = @_;

    my $comment = $args{ "txt" };

    warn qq(WARNING: no comment given\n) if not $comment;

    return "\n<!-- $comment -->\n";
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> VALIDATOR BUTTONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub validate_xhtml
{
    # Martin A. Hansen, July 2005.

    # returns an image link to w3.orgs validator page

    return &ln( txt    => &img( src => "http://www.w3.org/Icons/valid-xhtml10", alt => "Valid XHTML 1.0!" ),
                href   => "http://validator.w3.org/check?uri=referer", id => "validate_xhtml" );
}


sub validate_css
{
    # Martin A. Hansen, July 2005.

    # returns an image link to w3.orgs css validator page

    my ( $url,   # url or uri to the CSS file
       ) = @_;

    warn qq(WARNING: no url given for validate css\n) if not $url;

    return &ln( txt    => &img( src => "http://jigsaw.w3.org/css-validator/images/vcss", alt => "Valid CSS!" ),
                href   => "http://jigsaw.w3.org/css-validator/validator?uri=$url", id => "validate_css" );
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HELPERS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub format_args
{
    # Martin A. Hansen, July 2005.

    # given a hash with arguments reformat ( foo => "bar", foo2 => "bar2" ... )
    # these to HTML type argument str      ( foo = "bar" foo2 = "bar2" ... )

    my ( $args,   # hashref
       ) = @_;

    # Returns string

    my ( $str, $arg, @list );

    foreach $arg ( sort keys %{ $args } ) {
        push @list, qq($arg=") . $args->{ $arg } . qq(");
    }

    $str = join " ", @list;

    return $str;
}


sub tag_pair
{
    # Martin A. Hansen, July 2005.

    # handles HTML tags with a begin tab and a end tag such as <h1>string</h2>,
    # where the first tag hold optional arguments and the txt string is mandatory.

    my ( $tag,   # HTML element type
         $args,  # hashref
       ) = @_;

    # Returns string

    my ( @html, $txt, $arg, $embed );

    $txt = $args->{ "txt" };

    delete $args->{ "txt" };

    warn qq(WARNING: no $tag given\n) if not $tag;

    $arg = &format_args( $args );

    if ( $txt =~ /(<[^>]+>)/ )
    {
        if ( $1 =~ /^<(input|textarea|a |img)/ ) {
            $embed = "true";
        }
    }
    else
    {
        $embed = "true";
    }

    if ( $embed )
    {
        if ( $arg ) {
            push @html, "<$tag $arg>$txt</$tag>";
        } else {
            push @html, "<$tag>$txt</$tag>";
        }
    }
    else
    {
        if ( $arg )
        {
            push @html, "<$tag $arg>";
            push @html, $txt;
            push @html, "</$tag>";
        }
        else
        {
            push @html, "<$tag>";
            push @html, $txt;
            push @html, "</$tag>";
        }
    }

    return join "\n", @html;
}


sub tag_single
{
    # Martin A. Hansen, July 2005.

    # handles HTML single element such as <meta>
    # where the tag hold optional arguments.

    my ( $tag,   # HTML tag type
         $args,  # args
       ) = @_;

    # Returns string

    my ( $arg );

    $arg = &format_args( $args );

    if ( $arg ) {
        return "<$tag $arg />";
    } else {
        return "<$tag />";
    }
}


sub list_simple
{
    # Martin A. Hansen, July 2005.

    # formats simple ordered and unordered lists.
    # attributes can only be assigned to the list
    # type element.

    my ( $tag,
         $args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $items, $item );

    $items = $args->{ "li" };

    delete $args->{ "li" };

    $arg = &format_args( $args );
    
    if ( $arg ) {
        push @html, "<$tag $arg>";
    } else {
        push @html, "<$tag>";
    }

    foreach $item ( @{ $items } )
    {
        push @html, &tag_pair( "li", { txt => $item } );
    }

    push @html, "</$tag>";

    return join "\n", @html;
}


sub list_advanced
{
    # Martin A. Hansen, July 2005.

    # formats advanced ordered and unordered lists.
    # attributes can be assigned to both the list
    # type element and the list elements.
    
    my ( $tag,
         $args,
       ) = @_;

    # Returns string

    my ( @html, $arg, $items, $item, $li );

    $items = $args->{ "li" };

    delete $args->{ "li" };

    $arg = &format_args( $args );
    
    if ( $arg ) {
        push @html, "<$tag $arg>";
    } else {
        push @html, "<$tag>";
    }

    foreach $item ( @{ $items } )
    {
        warn qq(WARNING: no list item found in list_advanced\n) if not $item->{ "li" };

        $li = $item->{ "li" };

        delete $item->{ "li" };

        $item->{ "txt" } = $li;

        push @html, &tag_pair( "li", $item );
    }

    push @html, "</$tag>";

    return join "\n", @html;
}


sub input_field
{
    # Martin A. Hansen, July 2005.

    # generic routine to handle the different
    # flavors of input types.

    my ( $type,
         $args,
       ) = @_;

    # Returns string

    my ( $arg, $txt );

    warn qq(WARNING no input name given\n) if $type ne "reset" and not $args->{ "name" };

    $arg = &format_args( $args );

    if ( $arg ) {
        return qq(<input type="$type" $arg />);
    } else {
        return qq(<input type="$type" />);
    }
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DEBUG <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub hdump
{
    # Martin A. Hansen, November 2009.
    #
    # Primitive debug routine that returns given data
    # in <pre> tags as HTML lines.

    my ( $data,   # data to dump
       ) = @_;

    # Returns a list

    my ( @html );

    @html = "Content-Type: text/html; charset=ISO-8859-1\n\n";

    push @html, "<pre>\n";
    push @html, Dumper( $data );
    push @html, "</pre>\n";

    return wantarray ? @html : \@html;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

1;

