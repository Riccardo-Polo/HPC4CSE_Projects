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

# Initialization
data = np.full((DOMAIN_SIZE, DOMAIN_SIZE), -1, dtype=np.int32)
data[1:-1, 1:-1] = rank

dims = [3, 4]
periods = [True, True]

cart = comm.Create_cart(dims=dims, periods=periods, reorder=False)

rank_south, rank_north = cart.Shift(1, 1)
rank_west, rank_east   = cart.Shift(0, 1)

# North/South exchange
cart.Sendrecv(
    sendbuf=data[DOMAIN_SIZE-2, 1:-1],
    dest=rank_north,
    sendtag=0,
    recvbuf=data[0, 1:-1],
    source=rank_south,
    recvtag=0
)

cart.Sendrecv(
    sendbuf=data[1, 1:-1],
    dest=rank_south,
    sendtag=1,
    recvbuf=data[DOMAIN_SIZE-1, 1:-1],
    source=rank_north,
    recvtag=1
)

# West/East exchange: columns are not contiguous, so use temporary arrays
recv_west = np.empty(SUBDOMAIN_SIZE, dtype=np.int32)
recv_east = np.empty(SUBDOMAIN_SIZE, dtype=np.int32)

send_east = np.ascontiguousarray(data[1:-1, DOMAIN_SIZE-2])
send_west = np.ascontiguousarray(data[1:-1, 1])

cart.Sendrecv(
    sendbuf=send_east,
    dest=rank_east,
    sendtag=2,
    recvbuf=recv_west,
    source=rank_west,
    recvtag=2
)
data[1:-1, 0] = recv_west

cart.Sendrecv(
    sendbuf=send_west,
    dest=rank_west,
    sendtag=3,
    recvbuf=recv_east,
    source=rank_east,
    recvtag=3
)
data[1:-1, DOMAIN_SIZE-1] = recv_east

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

