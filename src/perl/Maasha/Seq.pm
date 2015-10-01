package Maasha::Seq;

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


# yak yak yak


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


use warnings;
use strict;
use POSIX qw( islower );
use Maasha::Common;
use Data::Dumper;
use IPC::Open2;
use List::Util qw( shuffle );
use Time::HiRes qw( gettimeofday );

use vars qw ( @ISA @EXPORT );

@ISA = qw( Exporter );


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub seq_guess_type
{
    # Martin A. Hansen, May 2007.

    # Makes a qualified guess on the type of a given squence.

    my ( $seq,   # sequence to check
       ) = @_;

    # returns string.

    my ( $check_seq, $count );

    if ( length $seq > 100 ) {
        $check_seq = substr $seq, 0, 100;
    } else {
        $check_seq = $seq;
    }

    if ( $count = $check_seq =~ tr/FLPQIEflpqie// and $count > 0 ) {
        return "PROTEIN";
    } elsif ( $count = $check_seq =~ tr/Uu// and $count > 0 ) {
        return "RNA";
    } else {
        return "DNA";
    }
}


sub wrap
{
    # Martin A. Hansen, July 2007.

    # Wraps a given string reference accoring to given width.

    my ( $strref,   # ref to sting to wrap
         $wrap,     # wrap width
       ) = @_;

    # Returns nothing.

    ${ $strref } =~ s/(.{$wrap})/$1\n/g;

    chomp ${ $strref };
}

                                    
sub dna_revcomp 
{
    # Niels Larsen
    # modified Martin A. Hansen, March 2005.

    # Returns the reverse complement of a dna sequence with preservation of case
    # according to this mapping, 
    #
    # AGCUTRYWSMKHDVBNagcutrywsmkhdvbn
    # TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn
     
    my ( $seq,   # seq
       ) = @_;   

    # returns string

    $seq = reverse $seq;

    $seq =~ tr/AGCUTRYWSMKHDVBNagcutrywsmkhdvbn/TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn/;

    return $seq;
}


sub rna_revcomp
{
    # Niels Larsen
    # modified Martin A. Hansen, March 2005.

    # Returns the complement of a rna sequence with preservation of case
    # according to this mapping, 
    #
    # AGCUTRYWSMKHDVBNagcutrywsmkhdvbn
    # UCGAAYRWSKMDHBVNucgaayrwskmdhbvn

    my ( $seq,   # seq
       ) = @_;

    $seq = reverse $seq;

    $seq =~ tr/AGCUTRYWSMKHDVBNagcutrywsmkhdvbn/UCGAAYRWSKMDHBVNucgaayrwskmdhbvn/;

    return $seq;
}


sub dna_comp 
{
    # Niels Larsen
    # modified Martin A. Hansen, March 2005.

    # Returns the reverse complement of a dna sequence with preservation of case
    # according to this mapping, 
    #
    # AGCUTRYWSMKHDVBNagcutrywsmkhdvbn
    # TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn
     
    my ( $seqref,   # seqref
       ) = @_;   

    # Returns nothing.

    ${ $seqref } =~ tr/AGCUTRYWSMKHDVBNagcutrywsmkhdvbn/TCGAAYRWSKMDHBVNtcgaayrwskmdhbvn/;
}


sub rna_comp
{
    # Niels Larsen
    # modified Martin A. Hansen, March 2005.

    # Returns the complement of a rna sequence with preservation of case
    # according to this mapping, 
    #
    # AGCUTRYWSMKHDVBNagcutrywsmkhdvbn
    # UCGAAYRWSKMDHBVNucgaayrwskmdhbvn

    my ( $seqref,   # seqref
       ) = @_;

    # Returns nothing.

    ${ $seqref } =~ tr/AGCUTRYWSMKHDVBNagcutrywsmkhdvbn/UCGAAYRWSKMDHBVNucgaayrwskmdhbvn/;
}


sub dna2rna
{
    # Martin A. Hansen, March 2007

    # Converts DNA sequence to RNA

    my ( $seq,   # nucleotide sequence
       ) = @_;

    # returns string

    $seq =~ tr/Tt/Uu/;

    return $seq;
}


sub rna2dna
{
    # Martin A. Hansen, March 2007

    # Converts RNA sequence to DNA

    my ( $seq,   # nucleotide sequence
       ) = @_;

    # returns string

    $seq =~ tr/Uu/Tt/;

    return $seq;
}


sub nuc2ambiguity
{
    # Martin A. Hansen, March 2005.

    # given a string of nucleotides
    # returns the corresponding ambiguity code

    my ( $str,
         $type,    # DNA or RNA - DEFAULT DNA
       ) = @_;

    my ( %hash, @nts, $key, $code, %nt_hash );

    $str = uc $str;

    if ( not $type or $type =~ /dna/i )
    {
        $str =~ s/N/ACGT/g;
        $str =~ s/B/CGT/g;
        $str =~ s/D/AGT/g;
        $str =~ s/H/ACT/g;
        $str =~ s/V/ACG/g;
        $str =~ s/K/GT/g;
        $str =~ s/Y/CT/g;
        $str =~ s/S/CG/g;
        $str =~ s/W/AT/g;
        $str =~ s/R/AG/g;
        $str =~ s/M/AC/g;
    }
    else
    {
        $str =~ s/N/ACGU/g;
        $str =~ s/B/CGU/g;
        $str =~ s/D/AGU/g;
        $str =~ s/H/ACU/g;
        $str =~ s/V/ACG/g;
        $str =~ s/K/GU/g;
        $str =~ s/Y/CU/g;
        $str =~ s/S/CG/g;
        $str =~ s/W/AU/g;
        $str =~ s/R/AG/g;
        $str =~ s/M/AC/g;
    }

    @nts = split //, $str;

    %nt_hash = map { $_ => 1 } @nts;

    @nts = sort keys %nt_hash;

    $key = join "", @nts;

    %hash = (
        'A'    => 'A',
        'C'    => 'C',
        'G'    => 'G',
        'T'    => 'T',
        'U'    => 'U',
        'AC'   => 'M',
        'AG'   => 'R',
        'AT'   => 'W',
        'AU'   => 'W',
        'CG'   => 'S',
        'CT'   => 'Y',
        'CU'   => 'Y',
        'GT'   => 'K',
        'GU'   => 'K',
        'ACG'  => 'V',
        'ACT'  => 'H',
        'ACU'  => 'H',
        'AGT'  => 'D',
        'AGU'  => 'D',
        'CGT'  => 'B',
        'CGU'  => 'B',
        'ACGT' => 'N',
        'ACGU' => 'N',
    );

    $code = $hash{ $key };

    warn qq(WARNING: No ambiguity code for key->$key\n) if not $code;

    return $code;
}


sub aa2codons
{
    # Martin A. Hansen, March 2005.

    # given an amino acid, returns a list of corresponding codons

    my ( $aa,   # amino acid to translate
       ) = @_;

    # returns list

    my ( %hash, $codons );

    $aa = uc $aa;

    %hash = (
        'F' => [ 'TTT', 'TTC' ],                               # Phe
        'L' => [ 'TTA', 'TTG', 'CTT', 'CTC', 'CTA', 'CTG' ],   # Leu
        'S' => [ 'TCT', 'TCC', 'TCA', 'TCG', 'AGT', 'AGC' ],   # Ser
        'Y' => [ 'TAT', 'TAC' ],                               # Tyr
        '*' => [ 'TAA', 'TAG', 'TGA' ],                        # Stop
        'X' => [ 'TAA', 'TAG', 'TGA' ],                        # Stop
        'C' => [ 'TGT', 'TGC' ],                               # Cys
        'W' => [ 'TGG' ],                                      # Trp
        'P' => [ 'CCT', 'CCC', 'CCA', 'CCG' ],                 # Pro
        'H' => [ 'CAT', 'CAC' ],                               # His
        'Q' => [ 'CAA', 'CAG' ],                               # Gln
        'R' => [ 'CGT', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG' ],   # Arg
        'I' => [ 'ATT', 'ATC', 'ATA' ],                        # Ile
        'M' => [ 'ATG' ],                                      # Met
        'T' => [ 'ACT', 'ACC', 'ACA', 'ACG' ],                 # Thr
        'N' => [ 'AAT', 'AAC' ],                               # Asn
        'K' => [ 'AAA', 'AAG' ],                               # Lys
        'V' => [ 'GTT', 'GTC', 'GTA', 'GTG' ],                 # Val
        'A' => [ 'GCT', 'GCC', 'GCA', 'GCG' ],                 # Ala
        'D' => [ 'GAT', 'GAC' ],                               # Asp
        'E' => [ 'GAA', 'GAG' ],                               # Glu
        'G' => [ 'GGT', 'GGC', 'GGA', 'GGG' ],                 # Gly
    );

    $codons = $hash{ $aa };

    return wantarray ? @{ $codons } : $codons;
}


sub codon2aa
{
    # Martin A. Hansen, March 2005.

    # given a codon, returns the correponding
    # vertebrate amino acid.

    my ( $codon,   # codon to translate
       ) = @_;

    # returns string

    my ( %hash, $aa );

    die qq(ERROR: Bad codon: "$codon"\n) if not $codon =~ /[ATCGatcg]{3}/;

    %hash = (
        'TTT' => 'F',   # Phe
        'TTC' => 'F',   # Phe
        'TTA' => 'L',   # Leu
        'TTG' => 'L',   # Leu
        'TCT' => 'S',   # Ser
        'TCC' => 'S',   # Ser
        'TCA' => 'S',   # Ser
        'TCG' => 'S',   # Ser
        'TAT' => 'Y',   # Tyr
        'TAC' => 'Y',   # Tyr
        'TAA' => '*',   # Stop
        'TAG' => '*',   # Stop
        'TGT' => 'C',   # Cys
        'TGC' => 'C',   # Cys
        'TGA' => '*',   # Stop
        'TGG' => 'W',   # Trp
        'CTT' => 'L',   # Leu
        'CTC' => 'L',   # Leu
        'CTA' => 'L',   # Leu
        'CTG' => 'L',   # Leu
        'CCT' => 'P',   # Pro
        'CCC' => 'P',   # Pro
        'CCA' => 'P',   # Pro
        'CCG' => 'P',   # Pro
        'CAT' => 'H',   # His
        'CAC' => 'H',   # His
        'CAA' => 'Q',   # Gln
        'CAG' => 'Q',   # Gln
        'CGT' => 'R',   # Arg
        'CGC' => 'R',   # Arg
        'CGA' => 'R',   # Arg
        'CGG' => 'R',   # Arg
        'ATT' => 'I',   # Ile
        'ATC' => 'I',   # Ile
        'ATA' => 'I',   # Ile
        'ATG' => 'M',   # Met
        'ACT' => 'T',   # Thr
        'ACC' => 'T',   # Thr
        'ACA' => 'T',   # Thr
        'ACG' => 'T',   # Thr
        'AAT' => 'N',   # Asn
        'AAC' => 'N',   # Asn
        'AAA' => 'K',   # Lys
        'AAG' => 'K',   # Lys
        'AGT' => 'S',   # Ser
        'AGC' => 'S',   # Ser
        'AGA' => 'R',   # Arg
        'AGG' => 'R',   # Arg
        'GTT' => 'V',   # Val
        'GTC' => 'V',   # Val
        'GTA' => 'V',   # Val
        'GTG' => 'V',   # Val
        'GCT' => 'A',   # Ala
        'GCC' => 'A',   # Ala
        'GCA' => 'A',   # Ala
        'GCG' => 'A',   # Ala
        'GAT' => 'D',   # Asp
        'GAC' => 'D',   # Asp
        'GAA' => 'E',   # Glu
        'GAG' => 'E',   # Glu
        'GGT' => 'G',   # Gly
        'GGC' => 'G',   # Gly
        'GGA' => 'G',   # Gly
        'GGG' => 'G',   # Gly
    );

    $aa = $hash{ uc $codon };

    return $aa;
}


sub translate
{
    # Martin A. Hansen, June 2005.

    # translates a dna sequence to protein according to a optional given
    # frame.

    my ( $dna,     # dna sequence
         $frame,   # frame of translation - OPTIONAL
       ) = @_;

    # returns string

    my ( $codon, $pos, $pep );

    $frame ||= 1;

    if ( $frame =~ /-?[1-3]/ )
    {
        if ( $frame < 0 ) {
            $dna = Maasha::Seq::dna_revcomp( $dna );
        }

        $frame = abs( $frame ) - 1;

        $dna =~ s/^.{${frame}}//;
    }
    else
    {
        Maasha::Common::error( qq(Badly formated frame "$frame") );
    }

    $pos = 0;

    while ( $codon = substr $dna, $pos, 3 )
    {
        last if not length $codon == 3;

        $pep .= codon2aa( $codon );
    
        $pos += 3;
    }

    return $pep;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RNA FOLDING <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub fold_struct_rnafold
{
    # Martin A. Hansen, February 2008.

    # Given a squence fold this using RNAfold.

    my ( $seq,   # sequence to fold
       ) = @_;

    # Returns a tuple of fold string and free energy.

    my ( $pid, $fh_out, $fh_in, @lines, $struct, $energy );

    $pid = open2( $fh_out, $fh_in, "RNAfold -noPS" );

    Maasha::Fasta::put_entry( [ "RNAfold", $seq ], $fh_in );

    close $fh_in;

    @lines = <$fh_out>;

    close $fh_out;

    waitpid $pid, 0;

    chomp @lines;

    if ( $lines[ - 1 ] =~ /^([^ ]+) \((.+)\)$/ )
    {
        $struct = $1;
        $energy = $2;
    }

    return wantarray ? ( $struct, $energy ) : [ $struct, $energy ];
}


sub fold_struct_contrastruct
{
    # Martin A. Hansen, February 2008.

    # Given a sequence fold this using Contrafold.

    my ( $seq,       # sequence to fold
         $tmp_dir,   # temporary directory - OPTIONAL
       ) = @_;

    # Returns a tuple of fold string and temp index.

    my ( $tmp_file, $out_file1, $out_file2, $fh, $line, $struct, @AoA, $i, $temp, $index );

    $tmp_dir ||= $ENV{ 'BP_TMP' };

    $tmp_file  = "$tmp_dir/fold.fna";
    $out_file1 = "$tmp_dir/fold.out1";
    $out_file2 = "$tmp_dir/fold.out2";

    Maasha::Fasta::put_entries( [ [ "fold", $seq ] ], $tmp_file );

    Maasha::Common::run( "contrafold", "predict --parens $out_file1 --bpseq $out_file2 $tmp_file" );

    unlink $tmp_file;

    $fh = Maasha::Common::read_open( $out_file1 );

    while ( $line = <$fh> )
    {
        chomp $line;
    
        $struct = $line;
    }

    close $fh;

    unlink $out_file1;

    $fh = Maasha::Common::read_open( $out_file2 );

    while ( $line = <$fh> )
    {
        chomp $line;
    
        push @AoA, [ split " ", $line ];
    }

    close $fh;

    unlink $out_file2;

    for ( $i = 0; $i < @AoA; $i++ )
    {
        if ( $AoA[ $i ]->[ 2 ] != 0 )
        {
            last if $AoA[ $i ]->[ 0 ] > $AoA[ $i ]->[ 2 ];

            $temp += base_pair_melting_temp( $AoA[ $i ]->[ 1 ] . $AoA[ $AoA[ $i ]->[ 2 ] - 1 ]->[ 1 ] );
        }
    }

    $index = sprintf( "%.2f", $temp / length $seq );

    return wantarray ? ( $struct, $index ) : [ $struct, $index ];
}


sub base_pair_melting_temp
{
    # Martin A. Hansen, February 2008.

    # Given a basepair, returns the melting temperature.

    my ( $bp,   # basepair string
       ) = @_;
    
    # Returns integer

    my ( %melt_hash );

    %melt_hash = (
        AA => 0,
        AT => 2,
        AC => 0,
        AG => 0,
        AU => 2,
        TA => 2,
        TT => 0,
        TC => 0,
        TG => 1, #
        TU => 0,
        CA => 0,
        CT => 0,
        CC => 0,
        CG => 4,
        CU => 0,
        GA => 0,
        GT => 1, #
        GC => 4,
        GG => 0,
        GU => 1, #
        UA => 2,
        UT => 0,
        UC => 0,
        UG => 1, #
        UU => 0,
    );

    return $melt_hash{ uc $bp };
}


sub generate_dna_oligos
{
    # Martin A. Hansen, April 2007.

    # Generates all possible DNA oligos of a given wordsize.

    # alternative way: perl -MData::Dumper -e '@CONV = glob( "{A,T,C,G}" x 4 ); print Dumper( \@CONV )'


    my ( $wordsize,   # size of DNA oligos
       ) = @_;

    # Returns list

    my ( @alph, @oligos, $oligo, $char, @list );

    @alph   = ( qw( A T C G N ) );
    @oligos = ( '' );

    for ( 1 .. $wordsize )
    {
        foreach $oligo ( @oligos )
        {
            foreach $char ( @alph ) {
                push @list, $oligo . $char;
            }
        }

        @oligos = @list;

        undef @list;
    }

    return wantarray ? @oligos : \@oligos;
}


sub seq2oligos
{
    # Martin A. Hansen, April 2007

    # Given a sequence and a wordsize,
    # breaks the sequence into overlapping
    # oligos of that wordsize.

    my ( $seq,       # sequence reference
         $wordsize,  # wordsize
       ) = @_;

    # returns list

    my ( $i, $oligo, @oligos );

    for ( $i = 0; $i < length( ${ $seq } ) - $wordsize + 1; $i++ )
    {
        $oligo = substr ${ $seq }, $i, $wordsize;

        push @oligos, $oligo;
    }

    return wantarray ? @oligos : \@oligos;
}


sub seq2oligos_uniq
{
    # Martin A. Hansen, April 2007

    # Given a sequence and a wordsize,
    # breaks the sequence into overlapping
    # oligos of that wordsize and return 
    # only unique words.

    my ( $seq,       # sequence reference
         $wordsize,  # wordsize
       ) = @_;

    # returns list

    my ( $i, $oligo, %lookup, @oligos );

    for ( $i = 0; $i < length( ${ $seq } ) - $wordsize + 1; $i++ )
    {
        $oligo = substr ${ $seq }, $i, $wordsize;

        if ( not exists $lookup{ $oligo } )
        {
            push @oligos, $oligo;
            $lookup{ $oligo } = 1;
        }
    }

    return wantarray ? @oligos : \@oligos;
}


sub oligo_freq
{
    # Martin A. Hansen, August 2007.

    # Given a hashref with oligo=>count, calculates
    # a frequency table. Returns a list of hashes

    my ( $oligo_freq,   # hashref
       ) = @_;

    # Returns data structure

    my ( @freq_table, $total );

    $total = 0;

    map { push @freq_table, { OLIGO => $_, COUNT => $oligo_freq->{ $_ } }; $total += $oligo_freq->{ $_ } } keys %{ $oligo_freq };

    @freq_table = sort { $b->{ "COUNT" } <=> $a->{ "COUNT" } or $a->{ "OLIGO" } cmp $b->{ "OLIGO" } } @freq_table;

    map { $_->{ "FREQ" } = sprintf( "%.4f", $_->{ "COUNT" } / $total ) } @freq_table;

    return wantarray ? return @freq_table : \@freq_table;
}


sub seq_generate
{
    # Martin A. Hansen, May 2007

    # Generates a random sequence given a sequence length
    # and a alphabet.

    my ( $len,    # sequence length
         $alph,   # sequence alphabet
       ) = @_;

    # Returns a string

    my ( $alph_len, $i, $seq );
    
    $alph_len = scalar @{ $alph };

    for ( $i = 0; $i < $len; $i++ ) {
        $seq .= $alph->[ int( rand( $alph_len ) ) ];
    }

    return $seq;
}


sub seq_insert
{
    # Martin A. Hansen, June 2009.

    # Randomly duplicates a given number of residues in a given sequence.

    my ( $seq,          # sequence to mutate
         $insertions,   # number of residues to insert
       ) = @_;

    # Returns a string.

    my ( $i, $pos );

    for ( $i = 0; $i < $insertions; $i++ )
    {
        $pos = int( rand( length $seq ) );

        substr $seq, $pos, 0, substr $seq , $pos, 1;
    }

    return $seq;
}


sub seq_delete
{
    # Martin A. Hansen, June 2009.

    # Randomly deletes a given number of residues from a given sequence.

    my ( $seq,         # sequence to mutate
         $deletions,   # number of residues to delete
       ) = @_;

    # Returns a string.

    my ( $i, $pos );

    for ( $i = 0; $i < $deletions; $i++ )
    {
        $pos = int( rand( length $seq ) );

        substr $seq, $pos, 1, '';
    }

    return $seq;
}


sub seq_mutate
{
    # Martin A. Hansen, June 2009.

    # Introduces a given number of random mutations in a 
    # given sequence of a specified alphabet.

    my ( $seq,         # sequence to mutate
         $mutations,   # number of mutations
         $alph,        # alphabet of sequence
       ) = @_;

    # Returns a string.

    my ( $i, $pos, %lookup_hash );

    $i = 0;

    while ( $i < $mutations )
    {
        $pos = int( rand( length $seq ) );

        if ( not exists $lookup_hash{ $pos } )
        {
            substr $seq, $pos, 1, res_mutate( substr( $seq , $pos, 1 ), $alph );

            $lookup_hash{ $pos } = 1;
        
            $i++;
        }
    }

    return $seq;
}


sub res_mutate
{
    # Martin A. Hansen, June 2009.

    # Mutates a given residue to another from a given alphabet.

    my ( $res,    # residue to mutate
         $alph,   # alphabet
       ) = @_;

    # Returns a char.

    my ( $alph_len, $new );

    $alph_len = scalar @{ $alph };
    $new      = $res;

    while ( uc $new eq uc $res ) {
        $new = $alph->[ int( rand( $alph_len ) ) ];
    }

    return POSIX::islower( $res ) ? lc $new : uc $new;
}


sub seq_shuffle
{
    # Martin A. Hansen, December 2007.

    # Shuffles sequence of a given string.

    my ( $seq,   # sequence string
       ) = @_;

    # Returns a string.

    my ( @list );

    @list = split "", $seq;

    return join "", shuffle( @list );
}


sub seq_alph
{
    # Martin A. Hansen, May 2007.

    # Returns a requested sequence alphabet.

    my ( $type,   # alphabet type
       ) = @_;

    # returns list

    my ( %alph_hash, $alph );

    %alph_hash = (
        DNA      => [ qw(A T C G) ],
        DNA_AMBI => [ qw(A G C U T R Y W S M K H D V B N) ],
        RNA      => [ qw(A U C G) ],
        RNA_AMBI => [ qw(A G C U T R Y W S M K H D V B N) ],
        PROTEIN  => [ qw(F L S Y C W P H Q R I M T N K V A D E G) ],
    );

    if ( exists $alph_hash{ uc $type } ) {
        $alph = $alph_hash{ uc $type };
    } else {
        die qq(ERROR: Unknown alphabet type: "$type"\n);
    }

    return wantarray ? @{ $alph } : $alph;
}


sub seq_analyze
{
    # Martin A. Hansen, August 2007.

    # Analyses the sequence composition of a given sequence.

    my ( $seq,   # sequence to analyze
       ) = @_;

    # Returns hash

    my ( %analysis, @chars, @chars_lc, $char, %char_hash, $gc, $at, $lc, $max, $res_sum, @indels, %indel_hash );

    $analysis{ "SEQ_TYPE" } = Maasha::Seq::seq_guess_type( $seq );
    $analysis{ "SEQ_LEN" }  = length $seq;

    @indels = qw( - ~ . _ );

    if ( $analysis{ "SEQ_TYPE" } eq "DNA" )
    {
        @chars    = split //, "AGCUTRYWSMKHDVBNagcutrywsmkhdvbn";
        @chars_lc = split //, "agcutrywsmkhdvbn";
    }
    elsif ( $analysis{ "SEQ_TYPE" } eq "RNA" )
    {
        @chars    = split //, "AGCUTRYWSMKHDVBNagcutrywsmkhdvbn";
        @chars_lc = split //, "agcutrywsmkhdvbn";
    }
    else
    {
        @chars    = split //, "FLSYCWPHQRIMTNKVADEGflsycwphqrimtnkvadeg";
        @chars_lc = split //, "flsycwphqrimtnkvadeg";
    }

    @char_hash{ @chars }   = map { eval "scalar \$seq =~ tr/$_//" } @chars;
    @indel_hash{ @indels } = map { eval "scalar \$seq =~ tr/$_//" } @indels;

    if ( $analysis{ "SEQ_TYPE" } =~ /DNA|RNA/ )
    {
        $gc = $char_hash{ "g" } + $char_hash{ "G" } + $char_hash{ "c" } + $char_hash{ "C" };
        $at = $char_hash{ "a" } + $char_hash{ "A" } + $char_hash{ "t" } + $char_hash{ "T" } + $char_hash{ "u" } + $char_hash{ "U" };

        $analysis{ "GC%" } = sprintf( "%.2f", 100 * $gc / $analysis{ "SEQ_LEN" } );

        map { $lc += $char_hash{ lc $_ } } @chars_lc;

        $analysis{ "SOFT_MASK%" } = sprintf( "%.2f", 100 * $lc / $analysis{ "SEQ_LEN" } );
        $analysis{ "HARD_MASK%" } = sprintf( "%.2f", 100 * ( $char_hash{ "n" } + $char_hash{ "N" } ) / $analysis{ "SEQ_LEN" } );
    }

    $max = 0;

    foreach $char ( @chars_lc )
    {
        $char = uc $char;

        $char_hash{ $char } += $char_hash{ lc $char };

        $analysis{ "RES[$char]" } = $char_hash{ $char };

        $max = $char_hash{ $char } if $char_hash{ $char } > $max;

        $analysis{ "RES_SUM" } += $char_hash{ $char };
    }

    map { $analysis{ "RES[$_]" } = $indel_hash{ $_ } } @indels;

    $analysis{ "MIX_INDEX" } = sprintf( "%.2f", $max / $analysis{ "SEQ_LEN" } );
    #$analysis{ "MELT_TEMP" } = sprintf( "%.2f", 4 * $gc + 2 * $at );

    return wantarray ? %analysis : \%analysis;
}


sub seq_complexity
{
    # Martin A. Hansen, May 2008.

    # Given a sequence computes a complexity index
    # as the most common di-residue over
    # the sequence length. Return ~1 if the entire
    # sequence is homopolymeric. Above 0.4 indicates
    # low complexity sequence.

    my ( $seq,   # sequence
       ) = @_;

    # Returns float.

    my ( $len, $i, $max, $di, %hash );

    $seq = uc $seq;
    $len = length $seq;
    $max = 0;

    for ( $i = 0; $i < $len - 1; $i++ ) {
        $hash{ substr $seq, $i, 2  }++;
    }

    foreach $di ( keys %hash ) {
        $max = $hash{ $di } if $hash{ $di } > $max;
    }

    return $max / $len;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SEQLOGO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub seqlogo_calc
{
    # Martin A. Hansen, January 2007.

    # given max bit size and a list of aligned entries
    # in FASTA format, calculates for each sequence position
    # the height of the letters in bits.
    # returns a data structure with [ letter, height ] tuples
    # for all letters at each position.

    my ( $bit_max,   # maximum bit height
         $entries,   # FASTA entries
       ) = @_;

    # returns data structure

    my ( $logo_len, $char_tot, $i, %char_hash, $bit_height, $bit_diff, $char_heights, @logo );

    $logo_len = length $entries->[ 0 ]->[ 1 ];
    $char_tot = scalar @{ $entries };

    for ( $i = 0; $i < $logo_len; $i++ )
    {
        undef %char_hash;
        
        map { $char_hash{ uc substr( $_->[ 1 ], $i, 1 ) }++ } @{ $entries };

        delete $char_hash{ "-" };
        delete $char_hash{ "_" };
        delete $char_hash{ "~" };
        delete $char_hash{ "." };

        $bit_height = seqlogo_calc_bit_height( \%char_hash, $char_tot );

        $bit_diff = $bit_max - $bit_height;

        $char_heights = seqlogo_calc_char_heights( \%char_hash, $char_tot, $bit_diff );

        push @logo, $char_heights;
    }

    return wantarray ? @logo : \@logo;
}


sub seqlogo_calc_bit_height
{
    # Martin A. Hansen, January 2007.
    
    # calculates the bit height using Shannon's famous
    # general formula for uncertainty as documentet:
    # http://www.ccrnp.ncifcrf.gov/~toms/paper/hawaii/latex/node5.html
    
    my ( $char_hash,   # hashref with chars and frequencies
         $tot,         # total number of chars
       ) = @_;

    # returns float

    my ( $char, $freq, $bit_height );

    foreach $char ( keys %{ $char_hash } )
    {
        $freq = $char_hash->{ $char } / $tot;

        $bit_height += $freq * ( log( $freq ) / log( 2 ) );
    }

    $bit_height *= -1;

    return $bit_height;
}


sub seqlogo_calc_char_heights
{
    # Martin A. Hansen, January 2007.

    # calculates the hight of each char in bits, and sorts
    # according to height.

    my ( $char_hash,   # hashref with chars and frequencies
         $tot,         # tot number of chars
         $bit_diff,    # information gained from uncertainties
       ) = @_;

    # returns list of tuples

    my ( $char, $freq, $char_height, @char_heights );

    foreach $char ( keys %{ $char_hash } )
    {
        $freq = $char_hash->{ $char } / $tot;

        $char_height = $freq * $bit_diff;   # char height in bits

        push @char_heights, [ $char, $char_height ];
    }

    @char_heights = sort { $a->[ 1 ] <=> $b->[ 1 ] } @char_heights;

    return wantarray ? @char_heights : \@char_heights;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RESIDUE COLORS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub color_pep
{
    # Martin A. Hansen, October 2005.

    # color scheme for proteins as defined in Mview.
    # given a char returns the appropriate color.
    # The amino acids are colored according to physicochemical properties:
    # bright green = hydrophobic; dark green = large hydrophobic;
    # bright blue = negative charge; red = positive charge;
    # dull blue = small alcohol; purple = polar; yellow = cysteine.

    my ( $char,   # char to decorate
       ) = @_;

    # returns string

    my ( %hash, $color_set );

    %hash = (
        K   => "bright-red",
        R   => "bright-red",
        H   => "dark-green",
        D   => "bright-blue",
        E   => "bright-blue",
        S   => "dull-blue",
        T   => "dull-blue",
        N   => "purple",
        Q   => "purple",
        A   => "bright-green",
        V   => "bright-green",
        I   => "bright-green",
        L   => "bright-green",
        M   => "bright-green",
        F   => "dark-green",
        Y   => "dark-green",
        W   => "dark-green",
        C   => "yellow",
        G   => "bright-green",
        P   => "bright-green",
        Z   => "dark-gray",
        B   => "dark-gray",
        "?" => "light-gray",
        "~" => "light-gray",
        "*" => "dark-gray",
    );

    if ( exists $hash{ uc $char } ) {
        $color_set = $hash{ uc $char };
    } else {
        $color_set = "black";
    }

    return $color_set;
}


sub color_nuc
{
    # Martin A. Hansen, October 2005.
    
    # color scheme for nucleotides as defined in Mview.
    # given a char returns the appropriate color
    # according to physical/chemical proterties.

    my ( $char,   # char to decorate
       ) = @_;

    # returns string

    my ( %hash, $color_set );

    %hash = (
        A => "bright-red",
        G => "yellow",
        C => "blue",
        T => "green",
        U => "green",
    );

    if ( exists $hash{ uc $char } ) {
        $color_set = $hash{ uc $char };
    } else {
        $color_set = "black";
    }

    return $color_set;
}


sub color_palette
{
    # Martin A. Hansen, October 2005.

    # hash table with color-names and color-hex.

    my ( $color,   # common color name
       ) = @_;

    # returns string

    my ( %hash );

    %hash = (
        "black"                => "#000000",
        "white"                => "#ffffff",
        "red"                  => "#ff0000",
        "green"                => "#00ff00",
        "blue"                 => "#0000ff",
        "cyan"                 => "#00ffff",
        "magenta"              => "#ff00ff",
#        "yellow"               => "#ffff00",
        "yellow"               => "#ffc800",
        "purple"               => "#6600cc",
        "dull-blue"            => "#0099ff",
        "dark-green-blue"      => "#33cccc",
        "medium-green-blue"    => "#00ffcc",
        "bright-blue"          => "#0033ff",
        "dark-green"           => "#009900",
        "bright-green"         => "#33cc00",
        "orange"               => "#ff3333",
        "orange-brown"         => "#cc6600",
        "bright-red"           => "#cc0000",
        "light-gray"           => "#999999",
        "dark-gray"            => "#666666",
        "gray0"                => "#ffffff",
        "gray1"                => "#eeeeee",
        "gray2"                => "#dddddd",
        "gray3"                => "#cccccc",
        "gray4"                => "#bbbbbb",
        "gray5"                => "#aaaaaa",
        "gray6"                => "#999999",
        "gray7"                => "#888888",
        "gray8"                => "#777777",
        "gray9"                => "#666666",
        "gray10"               => "#555555",
        "gray11"               => "#444444",
        "gray12"               => "#333333",
        "gray13"               => "#222222",
        "gray14"               => "#111111",
        "gray15"               => "#000000",
        "clustal-red"          => "#ff1111",
        "clustal-blue"         => "#1155ff",
        "clustal-green"        => "#11dd11",
        "clustal-cyan"         => "#11ffff",
        "clustal-yellow"       => "#ffff11",
        "clustal-orange"       => "#ff7f11",
        "clustal-pink"         => "#ff11ff",
        "clustal-purple"       => "#6611cc",
        "clustal-dull-blue"    => "#197fe5",
        "clustal-dark-gray"    => "#666666",
        "clustal-light-gray"   => "#999999",
        "lin-A"                => "#90fe23",
        "lin-R"                => "#fe5e2d",
        "lin-N"                => "#2e3d2d",
        "lin-D"                => "#00903b",
        "lin-C"                => "#004baa",
        "lin-Q"                => "#864b00",
        "lin-E"                => "#3fa201",
        "lin-G"                => "#10fe68",
        "lin-H"                => "#b2063b",
        "lin-I"                => "#04ced9",
        "lin-L"                => "#4972fe",
        "lin-K"                => "#c4a100",
        "lin-M"                => "#2a84dd",
        "lin-F"                => "#a60ade",
        "lin-P"                => "#fe61fe",
        "lin-S"                => "#f7e847",
        "lin-T"                => "#fefeb3",
        "lin-W"                => "#4a007f",
        "lin-Y"                => "#e903a8",
        "lin-V"                => "#5bfdfd",
    );

    if ( exists $hash{ $color } ) {
        return $hash{ $color };
    } else {
        print STDERR qq(WARNING: color "$color" not found in palette!\n);
    }
}       


sub color_contrast
{
    # Martin A. Hansen, October 2005.

    # Hash table with contrast colors to be used for frontground
    # text on a given background color. 

    my ( $color,    # background color
       ) = @_;

    # returns string

    my ( %hash );

    %hash = (
        "black"                => "white",
        "white"                => "black",
        "red"                  => "white",
        "green"                => "white",
        "blue"                 => "white",
        "cyan"                 => "white",
        "magenta"              => "white",
        "yellow"               => "black",
        "purple"               => "white",
        "dull-blue"            => "white",
        "dark-green-blue"      => "white",
        "medium-green-blue"    => "white",
        "bright-blue"          => "white",
        "dark-green"           => "white",
        "bright-green"         => "black",
        "orange"               => "",
        "orange-brown"         => "",
        "bright-red"           => "white",
        "light-gray"           => "black",
        "dark-gray"            => "white",
        "gray0"                => "",
        "gray1"                => "",
        "gray2"                => "",
        "gray3"                => "",
        "gray4"                => "",
        "gray5"                => "",
        "gray6"                => "",
        "gray7"                => "",
        "gray8"                => "",
        "gray9"                => "",
        "gray10"               => "",
        "gray11"               => "",
        "gray12"               => "",
        "gray13"               => "",
        "gray14"               => "",
        "gray15"               => "",
        "clustal-red"          => "black",
        "clustal-blue"         => "black",
        "clustal-green"        => "black",
        "clustal-cyan"         => "black",
        "clustal-yellow"       => "black",
        "clustal-orange"       => "black",
        "clustal-pink"         => "black",
        "clustal-purple"       => "black",
        "clustal-dull-blue"    => "black",
        "clustal-dark-gray"    => "black",
        "clustal-light-gray"   => "black",
        "lin-A"                => "",
        "lin-R"                => "",
        "lin-N"                => "",
        "lin-D"                => "",
        "lin-C"                => "",
        "lin-Q"                => "",
        "lin-E"                => "",
        "lin-G"                => "",
        "lin-H"                => "",
        "lin-I"                => "",
        "lin-L"                => "",
        "lin-K"                => "",
        "lin-M"                => "",
        "lin-F"                => "",
        "lin-P"                => "",
        "lin-S"                => "",
        "lin-T"                => "",
        "lin-W"                => "",
        "lin-Y"                => "",
        "lin-V"                => "",
    );

    if ( exists $hash{ $color } ) {
        return $hash{ $color };
    } else {
        print STDERR qq(WARNING: color "$color" not found in palette!\n);
    }
}       


sub seq_word_pack
{
    # Martin A. Hansen, April 2008.

    # Packs a sequence word into a binary number.

    my ( $word,        # Word to be packed
       ) = @_;

    # Returns integer.

    my ( %hash, $bin, $word_size, $pad );
    
    %hash = (
        'A' => '000',
        'T' => '001',
        'C' => '010',
        'G' => '100',
        'N' => '011',
        '-' => '101',
        '.' => '110',
        '~' => '111',
    );

    map { $bin .= pack "B3", $hash{ $_ } } split //, $word;

    $word_size = length $word;

    $pad = ( 3 * $word_size ) / 8;

    if ( $pad =~ /\./ )
    {
        $pad = ( ( int $pad + 1 ) * 8 ) - 3 * $word_size;

        $bin .= pack "B$pad", 0 x $pad;
    }   

    return $bin;
}


sub seq_word_unpack
{
    # Martin A. Hansen, April 2008.

    # Unpacks a binary sequence word to ASCII.

    my ( $bin,         # Binary sequence word
         $word_size,   # Size of word
       ) = @_;

    # Returns string.

    my ( %hash, $word );

    %hash = (
        '000' => 'A',
        '001' => 'T',
        '010' => 'C',
        '100' => 'G',
        '011' => 'N',
        '101' => '-',
        '110' => '.',
        '111' => '~',
    );

    map { $word .= $hash{ $_ } } unpack "(B3)$word_size", $bin;

    return $word;
}


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ADAPTOR LOCATING <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


###############################    REDUNDANT   ##############################

# these functions have been replaced by index_m and match_m in Common.pm

sub find_adaptor
{
    # Martin A. Hansen & Selene Fernandez, August 2008

    # Locates an adaptor sequence in a given sequence
    # starting from a given offset position allowing a given
    # number of mismatches (no indels).

    my ( $adaptor,       # list of chars
         $tag,           # list of chars
         $adaptor_len,   # length of adaptor sequence
         $tag_len,       # length of tag sequence
         $tag_offset,    # offset position
         $max_match,     # number of matches indicating success
         $max_mismatch,  # number of mismatches
       ) = @_;

    # Returns an integer.

    my ( $i, $j, $match, $mismatch );

    $i = $tag_offset;

    while ( $i < $tag_len - ( $max_match + $max_mismatch ) + 1 )
    {
        $j = 0;
        
        while ( $j < $adaptor_len - ( $max_match + $max_mismatch ) + 1 )
        {
            return $i if check_diag( $adaptor, $tag, $adaptor_len, $tag_len, $j, $i, $max_match, $max_mismatch );

            $j++
        }
    
        $i++;
    }

    return -1;
}


sub check_diag
{
    # Martin A. Hansen & Selene Fernandez, August 2008

    # Checks the diagonal starting at a given coordinate 
    # of a search space constituted by an adaptor and a tag sequence.
    # Residues in the diagonal are compared between the sequences allowing
    # for a given number of mismatches. We terminate when search space is
    # exhausted or if max matches or mismatches is reached.

    my ( $adaptor,       # list of chars
         $tag,           # list of chars
         $adaptor_len,   # length of adaptor sequence
         $tag_len,       # length of tag sequence
         $adaptor_beg,   # adaptor begin coordinate
         $tag_beg,       # tag begin coordinate
         $max_match,     # number of matches indicating success
         $max_mismatch,  # number of mismatches
       ) = @_;

    # Returns boolean.

    my ( $match, $mismatch );

    $match    = 0;
    $mismatch = 0;

    while ( $adaptor_beg <= $adaptor_len and $tag_beg <= $tag_len )
    {
        if ( $adaptor->[ $adaptor_beg ] eq $tag->[ $tag_beg ] )
        {
            $match++;

            return 1 if $match >= $max_match;
        }
        else
        {
            $mismatch++;

            return 0 if $mismatch > $max_mismatch;
        }
    
        $adaptor_beg++;
        $tag_beg++;
    }

    return 0;
}
        

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
