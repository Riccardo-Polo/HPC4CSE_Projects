CXX     ?= g++
NVCC    ?= nvcc

CXXFLAGS = -O3
NVCCFLAGS = -O3 -arch=sm_75

SOURCES = walltime.cpp stats.cpp data.cpp operators.cu  linalg.cu main.cu
HEADERS = walltime.h   stats.h   data.h   operators.h   linalg.h
OBJ     = walltime.o   stats.o   data.o   operators.o   linalg.o  main.o

all: main

walltime.o: walltime.cpp walltime.h
	$(CXX) $(CXXFLAGS) -c $<

stats.o: stats.cpp stats.h
	$(CXX) $(CXXFLAGS) -c $<

data.o: data.cpp data.h
	$(CXX) $(CXXFLAGS) -c $<

operators.o: operators.cu operators.h data.h
	$(NVCC) $(NVCCFLAGS) -c $<

linalg.o: linalg.cu linalg.h data.h
	$(NVCC) $(NVCCFLAGS) -c $<

main.o: main.cu $(HEADERS)
	$(NVCC) $(NVCCFLAGS) -c $<

main: $(OBJ)
	$(NVCC) $(NVCCFLAGS) $(OBJ) -o $@

.PHONY: clean
clean:
	$(RM) main $(OBJ)
