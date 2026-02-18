BUILD_ONE = build_1
BUILD_TWO = build_2

all: $(BUILD_ONE) $(BUILD_TWO)

$(BUILD_ONE):
	mkdir -p $(BUILD_ONE)

$(BUILD_TWO):
	mkdir -p $(BUILD_TWO)

clean:
	rm -rf $(BUILD_ONE)
	rm -rf $(BUILD_TWO)

.PHONY: all clean