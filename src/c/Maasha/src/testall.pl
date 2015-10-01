#!/usr/bin/env perl

use warnings;
use strict;

my ( $test_dir, @tests, $test );

$test_dir = "test";

@tests = qw(
    test_barray
    test_common
    test_fasta
    test_filesys
    test_list
    test_mem
    test_seq
    test_strings
    test_ucsc
);

print STDERR "\nRunning all unit tests:\n\n";

foreach $test ( @tests )
{
    system( "$test_dir/$test" ) == 0 or print STDERR "FAILED\n\n" and exit;
}

print STDERR "All unit tests OK.\n\n"
