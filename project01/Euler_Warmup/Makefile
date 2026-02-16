CXX = g++
TARGET = build/hello_world
SRC = helloworld.cpp

all:
	$(CXX) $(SRC) -o build_job_one/hello_world
	$(CXX) $(SRC) -o build_job_two/hello_world

clean:
	rm -rf build_job_one
	rm -rf build_job_two

.PHONY: all clean
