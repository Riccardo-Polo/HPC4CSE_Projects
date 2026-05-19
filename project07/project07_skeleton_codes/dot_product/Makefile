CXX     ?= g++
NVCC    ?= nvcc

CXXFLAGS = -O3
NVCCFLAGS = -O3 -arch=sm_75

all: dot_prod

dot_prod: dot_prod.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

.PHONY: clean
clean:
	$(RM) dot_prod
