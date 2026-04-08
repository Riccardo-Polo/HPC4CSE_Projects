#include <mpi.h> // MPI
#include <stdio.h>

int main(int argc, char *argv[]) {

  // Initialize MPI, get size and rank
  int size, rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  // IMPLEMENT: Ring sum algorithm
  int sum = rank;
  for (int i = 0; i < size - 1; i++) {
    int send_to = (rank + 1) % size;
    int recv_from = (rank - 1 + size) % size;

    int recv_sum;
    MPI_Sendrecv(&sum, 1, MPI_INT, send_to, 0,
                &recv_sum, 1, MPI_INT, recv_from, 0,
                MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    sum += recv_sum;
  }
  printf("Process %i: Sum = %i\n", rank, sum);

  // Finalize MPI
  MPI_Finalize();

  return 0;
}