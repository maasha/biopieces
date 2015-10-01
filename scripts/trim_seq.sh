#!/bin/sh

# Trim sequences in the stream based on quality scores and
# outputs a number of plots.

pid=$$

plot_scores -t post -o 00_trim_seq_scores_pretrim.$pid.ps |
plot_lendist -k SEQ_LEN -t post -o 01_trim_seq_lendist_pretrim.$pid.ps |
trim_seq |
grab -e "SEQ_LEN>=30" |
mean_scores -l |
grab -e "SCORES_LOCAL_MEAN>=15" |
plot_scores -t post -o 02_trim_seq_scores_posttrim.$pid.ps |
plot_lendist -k SEQ_LEN -t post -o 03_trim_seq_lendist_posttrim.$pid.ps 
