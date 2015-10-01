#!/bin/sh

# Count how many times each Biopieces has been used and output as a table.

read_tab -d '\t' -i $BP_LOG/biopieces.log -k TIME_BEG,TIME_END,TIME_ELAP,USER,STATUS,COMMAND |
split_vals -d ' ' -k COMMAND |
count_vals -k COMMAND_0 |
uniq_vals -k COMMAND_0 |
sort_records -k COMMAND_0_COUNTn -r |
write_tab -k COMMAND_0_COUNT,COMMAND_0 -x
