CXX     ?= g++
NVCC    ?= nvcc

CXXFLAGS = -O3
NVCCFLAGS = -O3 -arch=sm_75

SOURCES = linalg.cu benchmark.cu
HEADERS = linalg.h
OBJ     = linalg.o  benchmark.o

all: benchmark

linalg.o: linalg.cu $(HEADERS)
	$(NVCC) $(NVCCFLAGS) -c $<

benchmark.o: benchmark.cu $(HEADERS)
	$(NVCC) $(NVCCFLAGS) -c $<

benchmark: benchmark.o linalg.o
	$(NVCC) $(NVCCFLAGS) $(OBJ) -o $@

.PHONY: clean
clean:
	$(RM) $(OBJ) benchmark
