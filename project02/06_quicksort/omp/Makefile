CC      = gcc
CFLAGS  = -O3 -fopenmp -march=native -Wall -Wextra -std=c11
LDFLAGS = -fopenmp
TARGET  = quicksort_omp

OBJS = quicksort.o walltime.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

quicksort.o: quicksort.c walltime.h
	$(CC) $(CFLAGS) -c quicksort.c

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c walltime.c

clean:
	rm -f $(TARGET) *.o *.data *.csv *.gp *.pdf *.png

.PHONY: all clean
