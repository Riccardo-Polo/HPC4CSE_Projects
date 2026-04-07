CC     = mpicc
CFLAGS = -O2

ghost: ghost.c
	$(CC) $(CFLAGS) $^ -o $@

.PHONY: clean
clean:
	$(RM) ghost
