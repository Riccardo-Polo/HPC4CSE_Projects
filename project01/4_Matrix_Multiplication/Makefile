# Some possible configs ########################################################

# Euler GCC config
# (module load stack gcc openblas)
CC = gcc                         # compiler (& linker)
OPT = -O3 -march=native          # optimization flags (add more here!)
CFLAGS = -Wall -std=gnu99 $(OPT) # standard compiler flags
LDLIBS = -lopenblas              # linker options

# Euler INTEL config
# (module load stack/2024-06 intel-oneapi-compilers intel-oneapi-mkl)
# CC = icx                           # compiler (& linker)
# OPT = -O3 -axCORE-AVX512           # optimization flags (you may add more)
# CFLAGS = -Wall -std=gnu99 $(OPT)   # standard compiler flags
# # See the Intel oneAPI Math Kernel Library Link Line Advisor
# # https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-link-line-advisor.html#gs.5jekhw
# CFLAGS += -I"${MKLROOT}/include"   # more header files
# LDLIBS = -L${MKLROOT}/lib/intel64 \
#          -lmkl_intel_lp64         \
#          -lmkl_sequential         \
#          -lmkl_core               \
#          -lpthread -lm -ldl        # linker options

################################################################################

targets = benchmark-naive benchmark-jki benchmark-blocked benchmark-blas
objects = benchmark.o dgemm-naive.o dgemm-jki.o dgemm-blocked.o dgemm-blas.o
results = timing_naive_dgemm.data   \
          timing_jki_dgemm.data     \
          timing_blas_dgemm.data    \
          timing_blocked_dgemm.data \
          timing.pdf

.PHONY: default
default: all

.PHONY: all
all: $(targets)

benchmark-naive: benchmark.o dgemm-naive.o
	$(CC) -o $@ $^ $(LDLIBS)
benchmark-jki: benchmark.o dgemm-jki.o
	$(CC) -o $@ $^ $(LDLIBS)
benchmark-blocked: benchmark.o dgemm-blocked.o
	$(CC) -o $@ $^ $(LDLIBS)
benchmark-blas: benchmark.o dgemm-blas.o
	$(CC) -o $@ $^ $(LDLIBS)

%.o: %.c
	$(CC) -c $(CFLAGS) $<

.PHONY: clean
clean:
	$(RM) $(targets) $(objects)

.PHONY: cleanall
cleanall: clean
	$(RM) $(results)
