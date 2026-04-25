from mpi4py import MPI
import numpy as np

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()


total = np.array(rank,dtype=np.int32)
current_value = np.array(rank,dtype=np.int32)
received_value = np.array(0,dtype=np.int32)
for _ in range(size - 1):
    comm.Sendrecv(
        current_value,
        dest=(rank + 1) % size,
        sendtag=0,
        recvbuf=received_value,
        source=(rank - 1 + size) % size,
        recvtag=0,
    )

    total += received_value
    current_value[...] = received_value

print(f"Sum is {total} on processor {proc}, rank {rank} out of {size} "
      f"processes")
