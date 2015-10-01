package Maasha::Backtrack;

# Copyright (C) 2006-2011 Martin A. Hansen.

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


# Routines for locating patterns in sequences.


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use Exporter;
use Data::Dumper;
use Maasha::Common;
use Maasha::Seq;
use Maasha::Fasta;
use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );

use constant {
    SEQ_NAME => 0,
    SEQ  => 1,
};


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use Inline (C => <<'END_C');
#define MATCH(A,B) ((bitmap[(unsigned short) A] & bitmap[(unsigned short) B]) != 0)

// IUPAC ambiguity codes
unsigned short bitmap[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1,14, 4,11, 0, 0, 8, 7, 0, 0,10, 0, 5,15, 0,
    0, 0, 9,12, 2, 2,13, 3, 0, 6, 0, 0, 0, 0, 0, 0,
    0, 1,14, 4,11, 0, 0, 8, 7, 0, 0,10, 0, 5,15, 0,
    0, 0, 9,12, 2, 2,13, 3, 0, 6, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

// ss is the start of the string, used only for reporting the match endpoints.
unsigned int backtrack(char* ss, char* s, char* p, int mm, int ins, int del)
{
    unsigned int r = 0;

    while (*s && MATCH(*s, *p)) ++s, ++p;    // OK to always match longest segment

    if (!*p)
        return (unsigned int) (s - ss) - 1;
    else
    {
        if (mm && *s && *p && (r = backtrack(ss, s + 1, p + 1, mm - 1, ins, del))) return r;
        if (ins && *s &&      (r = backtrack(ss, s + 1, p, mm, ins - 1, del)))     return r;
        if (del && *p &&      (r = backtrack(ss, s, p + 1, mm, ins, del - 1)))     return r;
    }

    return 0;
}

// Find match of p in s, with at most mm mismatches, ins insertions and del deletions.
void patscan(char* s, char* p, int pos, int mm, int ins, int del)
{
    char*        ss = s;
    unsigned int e;

    while (*s && pos) ++s, --pos;   // Fast forward until pos

    while (*s)
    {
        e = backtrack(ss, s, p, mm, ins, del);
        
        if (e)
        {
            // printf("beg: %d   end: %d\n", (int) (s - ss), e);
            Inline_Stack_Vars;
            Inline_Stack_Reset;
            Inline_Stack_Push( sv_2mortal( newSViv(s - ss)));
            Inline_Stack_Push( sv_2mortal( newSViv(e)));
            Inline_Stack_Done;
        }

        s++;
    }
}

END_C


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
