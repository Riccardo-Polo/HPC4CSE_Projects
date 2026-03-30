CC      = gcc
CFLAGS  = -O2

all: pi_serial pi_mpi

pi_serial: pi_serial.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

pi_serial.o: pi_serial.c walltime.h
	$(CC) -c $(CFLAGS) $<

pi_mpi: pi_mpi.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

pi_mpi.o: pi_mpi.c walltime.h
	$(CC) -c $(CFLAGS) $<

walltime.o: walltime.c walltime.h
	$(CC) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) *.o pi_serial pi_mpi

.PHONY: cleanall
cleanall: clean
	$(RM) *.data
