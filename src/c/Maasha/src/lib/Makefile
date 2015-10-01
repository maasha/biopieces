# Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved 

CC      = gcc
# Cflags  = -Wall -Werror
Cflags = -Wall -Werror -g -pg  # gprof
INC_DIR = -I ../inc/

all: barray.o bits.o common.o mem.o strings.o seq.o filesys.o fasta.o list.o hash.o ucsc.o

barray.o: barray.c
	$(CC) $(Cflags) $(INC_DIR) -c barray.c

bits.o: bits.c
	$(CC) $(Cflags) $(INC_DIR) -c bits.c

common.o: common.c
	$(CC) $(Cflags) $(INC_DIR) -c common.c

mem.o: mem.c
	$(CC) $(Cflags) $(INC_DIR) -c mem.c

strings.o: strings.c
	$(CC) $(Cflags) $(INC_DIR) -c strings.c

seq.o: seq.c
	$(CC) $(Cflags) $(INC_DIR) -c seq.c

filesys.o: filesys.c
	$(CC) $(Cflags) $(INC_DIR) -c filesys.c

fasta.o: fasta.c
	$(CC) $(Cflags) $(INC_DIR) -c fasta.c

list.o: list.c
	$(CC) $(Cflags) $(INC_DIR) -c list.c

hash.o: hash.c
	$(CC) $(Cflags) $(INC_DIR) -c hash.c

ucsc.o: ucsc.c
	$(CC) $(Cflags) $(INC_DIR) -c ucsc.c

clean:
	rm barray.o
	rm bits.o
	rm common.o
	rm mem.o
	rm strings.o
	rm seq.o
	rm filesys.o
	rm fasta.o
	rm list.o
	rm hash.o
	rm ucsc.o

