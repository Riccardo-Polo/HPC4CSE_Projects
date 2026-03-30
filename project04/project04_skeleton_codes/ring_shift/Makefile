CC     = mpicc
CFLAGS =

all: ring_shift collective

ring_shift: ring_shift.c
	$(CC) $(CFLAGS) $^ -o $@

collective: collective.c
	$(CC) $(CFLAGS) $^ -o $@

.PHONY: clean
clean:
	$(RM) ring_shift collective
