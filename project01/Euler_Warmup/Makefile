CXX = g++
SRC = helloworld.cpp

BUILD_ONE = build_job_one
BUILD_TWO = build_job_two

TARGET_ONE = $(BUILD_ONE)/hello_world
TARGET_TWO = $(BUILD_TWO)/hello_world

all: $(TARGET_ONE) $(TARGET_TWO)

$(BUILD_ONE):
	mkdir -p $(BUILD_ONE)

$(BUILD_TWO):
	mkdir -p $(BUILD_TWO)

$(TARGET_ONE): $(SRC) | $(BUILD_ONE)
	$(CXX) $(SRC) -o $(TARGET_ONE)

$(TARGET_TWO): $(SRC) | $(BUILD_TWO)
	$(CXX) $(SRC) -o $(TARGET_TWO)

clean:
	rm -rf $(BUILD_ONE)
	rm -rf $(BUILD_TWO)

.PHONY: all clean

