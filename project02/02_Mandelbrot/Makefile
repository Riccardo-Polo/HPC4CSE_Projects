CC     ?= gcc
CFLAGS  = -O2

all: mandel_seq #mandel_omp

mandel_seq: mandel_seq.o ppmwriter.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

mandel_seq.o: mandel_seq.c consts.h ppmwriter.h walltime.h
	$(CC) -c $(CFLAGS) $<

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
	$(RM) *.o mandel_seq mandel_omp

.PHONY: cleanall
cleanall: clean
	$(RM) mandel.ppm
