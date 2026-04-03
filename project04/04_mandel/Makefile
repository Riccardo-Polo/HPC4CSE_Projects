CC     = mpicc
CFLAGS = -O3

all: mandel_mpi

mandel_mpi: mandel_mpi.o ppmwriter.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

mandel_mpi.o: mandel_mpi.c consts.h ppmwriter.h walltime.h
	$(CC) -c $(CFLAGS) $<

ppmwriter.o: ppmwriter.c ppmwriter.h
	$(CC) -c $(CFLAGS) $<

walltime.o: walltime.c walltime.h
	$(CC) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) *.o mandel_mpi

.PHONY: cleanall
cleanall: clean
	$(RM) mandel.ppm
