CC      = mpicc
CFLAGS  = -O3 -Wall
LDFLAGS = -lm

all: powermethod_rows

powermethod_rows: powermethod_rows.o walltime.o
	$(CC) powermethod_rows.o walltime.o $(LDFLAGS) -o $@

powermethod_rows.o: powermethod_rows.c walltime.h
	$(CC) $(CFLAGS) -c $< -o $@

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o powermethod_rows

.PHONY: all clean