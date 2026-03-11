CC = gcc
CFLAGS = -O3 -fopenmp

TARGET = quicksort_omp

all: $(TARGET)

$(TARGET): quicksort_omp.o walltime.o
	$(CC) $(CFLAGS) $^ -o $(TARGET)

quicksort_omp.o: quicksort_omp.c walltime.h
	$(CC) $(CFLAGS) -c quicksort_omp.c

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c walltime.c

clean:
	rm -f *.o $(TARGET) 
