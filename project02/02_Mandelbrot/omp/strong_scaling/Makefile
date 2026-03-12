CC = gcc
CFLAGS = -O3 -fopenmp -march=native
LDFLAGS = -fopenmp

TARGET = mandelbrot
SRC = mandel_omp_scaling.c ppmwriter.c walltime.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET) *.o timing_strong.data timing_strong_raw.data timing_strong_avg.data strong_scaling.pdf strong_speedup.pdf
