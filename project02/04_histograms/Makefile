CXX    ?= g++
CFLAGS  = -O3 -fopenmp

all: hist_seq hist_omp hist_omp_strong

hist_seq: hist_seq.o walltime.o
	$(CXX) $(CFLAGS) $^ -o $@

hist_seq.o: hist_seq.cpp walltime.h
	$(CXX) -c $(CFLAGS) $<

hist_omp: hist_omp.o walltime.o
	$(CXX) $(CFLAGS) $^ -o $@

hist_omp.o: hist_omp.cpp walltime.h
	$(CXX) -c $(CFLAGS) $<

hist_omp_strong: hist_omp_strong.o walltime.o
	$(CXX) $(CFLAGS) $^ -o $@

hist_omp_strong.o: hist_omp_strong.cpp walltime.h
	$(CXX) -c $(CFLAGS) $<

walltime.o: walltime.c walltime.h
	$(CXX) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) *.o hist_seq hist_omp hist_omp_strong *.data
