#!/bin/sh

# Remove adaptor from sequences and trim according to scores.
# Produces a number of plots during the process.

# Usage: read_fastq -i test.fq | clean_reads.sh | write_fastq -xo clean.fq

adaptor='TCGTATGCCGTCTTCTGCTTG' # 454 adaptor
#adaptor='AGATCGGAAGACACACGTCT'  # Solexa adaptor
pid=$$

progress_meter |
plot_lendist -t post -o 00_remove_adaptor_lendist_seq_before.$pid.ps -k SEQ_LEN |
find_adaptor -a $adaptor -p |
plot_histogram -t post -o 01_remove_adaptor_histogram_adaptor_pos.$pid.ps -k ADAPTOR_POS -s num |
plot_lendist -t post -o 02_remove_adaptor_lendist_adaptor_len.$pid.ps -k ADAPTOR_LEN |
analyze_vals -k ADAPTOR_POS,ADAPTOR_LEN -o 03_remove_adaptor_analyze_vals.$pid.txt |
clip_adaptor |
plot_scores -t post -o 04_trim_seq_scores_pretrim.$pid.ps |
plot_lendist -k SEQ_LEN -t post -o 05_trim_seq_lendist_pretrim.$pid.ps |
trim_seq |
grab -e "SEQ_LEN>=50" |
mean_scores -l |
grab -e "SCORES_LOCAL_MEAN>=15" |
plot_scores -t post -o 06_trim_seq_scores_posttrim.$pid.ps |
plot_lendist -k SEQ_LEN -t post -o 07_trim_seq_lendist_posttrim.$pid.ps
