CC       = gcc
MPICC    = mpicc
CFLAGS   = -O3 -march=native

all: pi_serial pi_mpi

pi_serial: pi_serial.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

pi_serial.o: pi_serial.c walltime.h
	$(CC) $(CFLAGS) -c $< -o $@

pi_mpi: pi_mpi_fixed.o walltime.o
	$(MPICC) $(CFLAGS) $^ -o $@ 

pi_mpi_fixed.o: pi_mpi_fixed.c walltime.h
	$(MPICC) $(CFLAGS) -c $< -o $@

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o pi_serial pi_mpi *.data *.pdf

.PHONY: all clean
