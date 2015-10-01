#!/bin/sh

# Remove adaptor from sequences and produce a number of plots.

# Usage: read_fastq -i test.fq | remove_adaptor_454.sh | write_fastq -xo test_no_adaptor.fq

adaptor='TCGTATGCCGTCTTCTGCTTG' # 454 adaptor
pid=$$

plot_lendist -t post -o 00_remove_adaptor_lendist_seq_before.$pid.ps -k SEQ_LEN |
find_adaptor -a $adaptor -p |
plot_histogram -t post -o 01_remove_adaptor_histogram_adaptor_pos.$pid.ps -k ADAPTOR_POS -s num |
plot_lendist -t post -o 02_remove_adaptor_lendist_adaptor_len.$pid.ps -k ADAPTOR_LEN |
plot_lendist -t post -o 03_remove_adaptor_lendist_seq_after.$pid.ps -k SEQ_LEN |
analyze_vals -k ADAPTOR_POS,ADAPTOR_LEN -o 04_remove_adaptor_analyze_vals.$pid.txt |
clip_adaptor
