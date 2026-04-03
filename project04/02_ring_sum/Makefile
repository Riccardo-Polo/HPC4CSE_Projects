CC     = mpicc
CFLAGS = -O2

ring_sum: ring_sum.c
	$(CC) $(CFLAGS) $^ -o $@

.PHONY: clean
clean:
	$(RM) ring_sum
