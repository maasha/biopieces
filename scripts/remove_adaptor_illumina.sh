#!/bin/sh

# Remove adaptor from sequences and produce a number of plots.

# Usage: read_fastq -i test.fq | remove_adaptor.sh | write_fastq -xo test_no_adaptor.fq

#adaptor='AGATCGGAAGACACACGTCT'  # Solexa adaptor
adaptor='TCGTATGCCGTCTTCTGCTTG' # 454 adaptor
pid=$$

#find_adaptor -a $adaptor |
parallel -k --blocksize 50M --pipe --recend "\n---\n" "nice -n 19 find_adaptor -a $adaptor" |
plot_histogram -t post -o remove_adaptor_histogram.$pid.ps -k ADAPTOR_POS -s num |
plot_lendist -t post -o remove_adaptor_lendist.$pid.ps -k ADAPTOR_LEN |
analyze_vals -k ADAPTOR_POS,ADAPTOR_LEN -o remove_adaptor_analyze_vals.$pid.txt |
clip_adaptor
