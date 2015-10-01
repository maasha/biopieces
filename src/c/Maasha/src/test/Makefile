# Martin Asser Hansen (mail@maasha.dk) Copyright (C) 2008 - All right reserved

CC      = gcc
CFLAGS  = -Wall -Werror

INC = -I ../inc/ -I $(HOME)/maasha_install/include/
LIB = -lm ../lib/*.o

all: test

test: test_common

test_common: test_common.c
	$(CC) $(CFLAGS) $(INC) $(LIB) test_common.c -o test_common

clean:
	rm test_common
