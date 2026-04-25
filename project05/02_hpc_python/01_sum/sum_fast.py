from mpi4py import MPI
import numpy as np

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()


total = np.array(rank, dtype=np.int)
current_value = np.array(rank, dtype=np.int)

for _ in range(size - 1):
    received_value = comm.Sendrecv(
        current_value,
        dest=(rank + 1) % size,
        sendtag=0,
        source=(rank - 1 + size) % size,
        recvtag=0,
    )
    total += received_value
    current_value = received_value

print(f"Sum is {total} on processor {proc}, rank {rank} out of {size} "
      f"processes")