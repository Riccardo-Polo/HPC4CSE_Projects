from mpi4py import MPI

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()

# pickle-based 
total = comm.allreduce(rank, op=MPI.SUM)

print(
    f"Sum is {total} on processor {proc}, "
    f"rank {rank} out of {size} processes"
)