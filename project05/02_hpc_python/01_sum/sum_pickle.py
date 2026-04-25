from mpi4py import MPI

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()


sum = rank
current_value = rank
recvalue = 0

for i in range(size-1):
    comm.Sendrecv(sum , (rank+1)%size, 0, recvalue, (rank-1+size)%size , 0)
    sum += recvalue
    current_value = recvalue

print(f"Sum is {sum} on processor {proc}, rank {rank} out of {size} "
      f"processes")