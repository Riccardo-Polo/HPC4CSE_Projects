CC = gcc
CFLAGS = -O3 -fopenmp -march=native
LDFLAGS = -fopenmp

TARGET = mandelbrot
SRC = mandel_omp_scaling.c ppmwriter.c walltime.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET) *.o outputs/strong_scaling.pdf outputs/strong_speedup.pdf outputs/timing_strong_raw.data outputs/timing_strong_avg.data outputs/*.out outputs/*.err
