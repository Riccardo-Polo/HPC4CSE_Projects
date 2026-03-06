CC     ?= gcc
CFLAGS  = -O2 -fopenmp

#all: naive_strong naive_weak optimized_strong optimized_weak reduction_strong reduction_weak
all: naive_weak optimized_strong optimized_weak reduction_strong reduction_weak

naive_strong: naive_strong.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

optimized_strong: optimized_strong.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

naive_weak: naive_weak.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

optimized_weak: optimized_weak.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

reduction_strong: reduction_strong.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

reduction_weak: reduction_weak.o walltime.o
	$(CC) $(CFLAGS) $^ -o $@

walltime.o: walltime.c walltime.h
	$(CC) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) *.o pi_ naive_strong optimized_strong naive_weak optimized_weak reduction_strong reduction_weak

.PHONY: cleanall
cleanall: clean
	$(RM) *.data *.pdf
