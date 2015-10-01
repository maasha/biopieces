# Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved

CC      = gcc
# CFLAGS = -Wall -Werror
CFLAGS = -Wall -Werror -g -pg # for gprof

INC_DIR  = inc/
LIB_DIR  = lib/
TEST_DIR = test/

INC = -I $(INC_DIR)
LIB = -lm $(LIB_DIR)*.o

# all: libs utest bed2fixedstep bed2tag_contigs bed_sort bipartite_scan bipartite_decode fasta_count repeat-O-matic
all: libs align_two_seq bed2fixedstep bed2tag_contigs bed_sort bipartite_scan bipartite_decode fasta_count repeat-O-matic

libs:
	cd $(LIB_DIR) && ${MAKE} all

utest:
	cd $(TEST_DIR) && ${MAKE} all

align_two_seq: align_two_seq.c
	$(CC) $(CFLAGS) $(INC) $(LIB) align_two_seq.c -o align_two_seq

bed2fixedstep: bed2fixedstep.c
	$(CC) $(CFLAGS) $(INC) $(LIB) bed2fixedstep.c -o bed2fixedstep

bed2tag_contigs: bed2tag_contigs.c
	$(CC) $(CFLAGS) $(INC) $(LIB) bed2tag_contigs.c -o bed2tag_contigs

bed_sort: bed_sort.c
	$(CC) $(CFLAGS) $(INC) $(LIB) bed_sort.c -o bed_sort

bipartite_scan: bipartite_scan.c
	$(CC) $(CFLAGS) $(INC) $(LIB) bipartite_scan.c -o bipartite_scan

bipartite_decode: bipartite_decode.c
	$(CC) $(CFLAGS) $(INC) $(LIB) bipartite_decode.c -o bipartite_decode

fasta_count: fasta_count.c
	$(CC) $(CFLAGS) $(INC) $(LIB) fasta_count.c -o fasta_count

repeat-O-matic: repeat-O-matic.c
	$(CC) $(CFLAGS) $(INC) $(LIB) repeat-O-matic.c -o repeat-O-matic

clean:
	cd $(LIB_DIR) && ${MAKE} clean
	cd $(TEST_DIR) && ${MAKE} clean
	rm bed2fixedstep
	rm bed2tag_contigs
	rm bed_sort
	rm bipartite_scan
	rm bipartite_decode
	rm fasta_count
	rm repeat-O-matic
