from mpi4py import MPI
import numpy as np

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()

# direct-buffer collective communication
sendbuf = np.array(rank, dtype=np.int32)
recvbuf = np.array(0, dtype=np.int32)

comm.Allreduce(sendbuf, recvbuf, op=MPI.SUM)

print(
    f"Sum is {recvbuf.item()} on processor {proc}, "
    f"rank {rank} out of {size} processes"
)
