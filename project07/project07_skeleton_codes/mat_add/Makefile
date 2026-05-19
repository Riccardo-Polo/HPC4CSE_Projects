mat_add: mat_add.cu
	nvcc -arch=sm_75 $< -o $@

.PHONY: clean
clean:
	${RM} mat_add mat_add-*.out mat_add-*.err
