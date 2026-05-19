CXX     ?= g++
NVCC    ?= nvcc

CXXFLAGS = -O3
NVCCFLAGS = -O3 -arch=sm_75

all: vec_max

vec_max: vec_max.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

.PHONY: clean
clean:
	$(RM) vec_max
