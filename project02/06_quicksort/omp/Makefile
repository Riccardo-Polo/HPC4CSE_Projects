CC      = gcc
CFLAGS  = -O3 -fopenmp -march=native -Wall -Wextra -std=c11
LDFLAGS = -fopenmp
TARGET  = quicksort_omp

OBJS = quicksort_omp.o walltime.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

quicksort_omp.o: quicksort_omp.c walltime.h
	$(CC) $(CFLAGS) -c quicksort_omp.c

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c walltime.c

clean:
	rm -f $(TARGET) *.o *.data *.csv *.gp *.pdf *.png

.PHONY: all clean
