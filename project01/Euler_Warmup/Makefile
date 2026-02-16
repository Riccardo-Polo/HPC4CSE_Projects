CXX = g++
TARGET = build/hello_world
SRC = helloworld.cpp

all:
	mkdir -p build_job_one
	mkdir -p build_job_two
	$(CXX) $(SRC) -o $(TARGET)

clean:
	rm -rf build_job_one
	rm -rf build_job_two

.PHONY: all clean
