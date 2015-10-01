#!/bin/sh

# Output a histogram of how many times each user have executed Biopieces.

read_tab -d '\t' -i $BP_LOG/biopieces.log -k TIME_BEG,TIME_END,TIME_ELAP,USER,STATUS,COMMAND |
plot_histogram -T 'User distribution' -k USER -x
