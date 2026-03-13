CC     ?= gcc
CFLAGS  = -O2 -fopenmp

all: mandel_omp

mandel_omp: mandel_omp.o ppmwriter.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

mandel_omp.o: mandel_omp.c consts.h ppmwriter.h walltime.h
	$(CC) -c $(CFLAGS) $<

ppmwriter.o: ppmwriter.c ppmwriter.h
	$(CC) -c $(CFLAGS) $<

walltime.o: walltime.c walltime.h
	$(CC) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) *.o mandel_omp

.PHONY: cleanall
cleanall: clean
	$(RM) mandel.ppm