CC      ?= gcc
CFLAGS  := -O3 -fopenmp -march=native -std=c11 -Wall -Wextra
OUTPUT_DIR := outputs

all: naive_strong naive_weak optimized_strong optimized_weak reduction_strong reduction_weak

%: %.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

walltime.o: walltime.c walltime.h
	$(CC) $(CFLAGS) -c $< -o $@

naive_strong.o: naive_strong.c walltime.h
naive_weak.o: naive_weak.c walltime.h
optimized_strong.o: optimized_strong.c walltime.h
optimized_weak.o: optimized_weak.c walltime.h
reduction_strong.o: reduction_strong.c walltime.h
reduction_weak.o: reduction_weak.c walltime.h

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o naive_strong naive_weak optimized_strong optimized_weak reduction_strong reduction_weak

cleanall: clean
	rm -f *.data *.pdf *.out *.err
	rm -f $(OUTPUT_DIR)/*.data $(OUTPUT_DIR)/*.pdf $(OUTPUT_DIR)/*.out $(OUTPUT_DIR)/*.err
