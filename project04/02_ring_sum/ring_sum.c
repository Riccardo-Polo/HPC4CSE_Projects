#include <mpi.h> // MPI
#include <stdio.h>

int main(int argc, char *argv[]) {

  // Initialize MPI, get size and rank
  int size, rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  // IMPLEMENT: Ring sum algorithm
  int sum = 0; // initialize sum
  for (int i = 0; i < size; i++) {
    sum += rank; // add own rank to sum

    // Send sum to next process and receive from previous process
    int send_to = (rank + 1) % size; // next process
    int recv_from = (rank - 1 + size) % size; // previous process

    int recv_sum;
    MPI_Send(&sum, 1, MPI_INT, send_to, 0, MPI_COMM_WORLD); // send sum
    MPI_Recv(&recv_sum, 1, MPI_INT, recv_from, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE); // receive sum

    sum = recv_sum; // update sum with received value
  }
  printf("Process %i: Sum = %i\n", rank, sum);

  // Finalize MPI
  MPI_Finalize();

  return 0;
}
