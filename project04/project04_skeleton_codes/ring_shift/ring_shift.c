#include <mpi.h> // MPI
#include <stdio.h>

int main(int argc, char *argv[]) {

  // Initialize MPI, get size and rank
  int size, rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  // Set left and right neighbors in ring
  int left  = rank - 1;
  int right = rank + 1;
  // Close the ring
  if (left  <  0   ) left  = size - 1;
  if (right >= size) right = 0;

  // Send to left and receive from right neighbor in ring
  int send, recv;
  MPI_Status  status;
  send = rank; // sending my rank

  /*
  // Naive usage of MPI_Send (standard-mode blocking send): May deadlock
  MPI_Send(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
  MPI_Recv(&recv, 1, MPI_INT, left , 0, MPI_COMM_WORLD, &status);
  // Standard synchronous, blocking send: Will deadlock
  MPI_Ssend(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
  MPI_Recv (&recv, 1, MPI_INT, left , 0, MPI_COMM_WORLD, &status);
  // Interleave send/recv: first even ranks send and odd ranks receive;
  // send odd ranks send and even ranks receive
  if (size > 1) {
    if (rank % 2) {
      // MPI_Ssend(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
      MPI_Send(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
      MPI_Recv (&recv, 1, MPI_INT, left , 0, MPI_COMM_WORLD, &status);
    } else {
      MPI_Recv (&recv, 1, MPI_INT, left , 0, MPI_COMM_WORLD, &status);
      // MPI_Ssend(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
      MPI_Send(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
    }
  } else {
    MPI_Request req;
    MPI_Irecv (&recv, 1, MPI_INT, left , 0, MPI_COMM_WORLD, &req);
    MPI_Ssend(&send, 1, MPI_INT, right, 0, MPI_COMM_WORLD);
    MPI_Wait(&req, &status);
  }
  */
  // Combined send-receive operations
  MPI_Sendrecv(&send, 1, MPI_INT, right, 0,
               &recv, 1, MPI_INT, left , 0,
               MPI_COMM_WORLD, &status);

  // Report what was sent/received
  printf("Process %2i: send = %2i / recv = %2i\n", rank, send, recv);

  // Finalize MPI
  MPI_Finalize();

  return 0;
}
