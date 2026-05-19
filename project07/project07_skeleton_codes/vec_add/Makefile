vec_add: vec_add.cu
	nvcc -arch=sm_75 $< -o $@

.PHONY: clean
clean:
	${RM} vec_add vec_add-*.out vec_add-*.err
