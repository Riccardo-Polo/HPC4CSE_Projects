from mpi4py import MPI
import numpy as np

# get comm, size, rank & host name
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()
proc = MPI.Get_processor_name()

SUBDOMAIN_SIZE = 6
DOMAIN_SIZE = SUBDOMAIN_SIZE + 2

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

data = np.ndarray((DOMAIN_SIZE, DOMAIN_SIZE), dtype=np.int32)

if (size != 12):
    if rank == 0:
        print("Please run this with exactly 12 processes.")
    exit()

# Initialize the domain
for i in range(1, DOMAIN_SIZE):
    for j in range(1, DOMAIN_SIZE):
        data[i, j] = rank
# set corners to dummy value
data[0,0] = -1
data[0,DOMAIN_SIZE-1] = -1
data[DOMAIN_SIZE-1,0] = -1
data[DOMAIN_SIZE-1,DOMAIN_SIZE-1] = -1

# set the dimensions of the processor grid and periodic boundaries in both dimensions 
dims = np.array((2,1), dtype=np.int32)
dims[0] = 3
dims[1] = 4
periods = np.array((2,1), dtype=np.int32)
periods[0] = 1
periods[1] = 1

#Create a Cartesian communicator (3*4) with periodic boundaries and
#  use it to find your neighboring ranks in all dimensions in a
#  cyclic manner.
cart = comm.Create_cart(dims=dims,periods=periods,reorder=True)
cart_rank = cart.Get_rank()
coords = cart.Get_coords(cart_rank)

# get the neighboring ranks in all dimensions
rank_south , rank_north = cart.Shift(1,-1)
rank_west , rank_east = cart.Shift(0,-1)

# exchange the ghost cells with the neighbors

# send top interior row to nort , receive bottom ghost row from south
comm.Sendrecv(
    np.ascontiguousarray(data[1,:]), dest=rank_north, sendtag=0,
    recvbuf=np.ascontiguousarray(data[DOMAIN_SIZE-1,:]), source=rank_south, recvtag=0
)

#send bottom interior row to south,receive top ghost row from north 
comm.Sendrecv(
    np.ascontiguousarray(data[DOMAIN_SIZE-2,:]), dest=rank_south, sendtag=1,
    recvbuf=np.ascontiguousarray(data[0,:]), source=rank_north, recvtag=1
)

#send right interior column to east, receive left ghost column from west
comm.Sendrecv(
    np.ascontiguousarray(data[:, DOMAIN_SIZE-2]), dest=rank_east, sendtag=2,
    recvbuf=np.ascontiguousarray(data[:, 0]), source=rank_west, recvtag=2
)

# send left interior column to west, receive right ghost column  from east 
comm.Sendrecv(
    np.ascontiguousarray(data[:, 1]), dest=rank_west, sendtag=3,
    recvbuf=np.ascontiguousarray(data[:, DOMAIN_SIZE-1]), source=rank_east, recvtag=3
)

io_rank = 5
if rank == io_rank:
    print(f"North rank {rank_north}, South rank {rank_south}, West rank {rank_west}, East rank {rank_east}")
    print(f"data of rank {io_rank} after communication")
    print("j")
    print("^")
    for j in range(DOMAIN_SIZE-1, -1, -1):
        print("| ", end="")
        for i in range(DOMAIN_SIZE):
            print(f"{data[j,i]:4.1f} ", end="")
        print()
    print("--", end="")
    for i in range(DOMAIN_SIZE):
        print("-----", end="")
    print("> i")

