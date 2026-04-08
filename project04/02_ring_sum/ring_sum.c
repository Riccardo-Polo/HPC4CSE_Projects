#include <mpi.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
  int size, rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  int send_to   = (rank + 1) % size;
  int recv_from = (rank - 1 + size) % size;

  int sum = rank;       // accumulatore finale
  int value = rank;     // valore che circola nel ring
  int recv_value;

  for (int i = 0; i < size - 1; i++) {
    MPI_Sendrecv(&value, 1, MPI_INT, send_to, 0,
                 &recv_value, 1, MPI_INT, recv_from, 0,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    sum += recv_value;   // accumula il rank ricevuto
    value = recv_value;  // inoltra al passo successivo
  }

  printf("Process %d: Sum = %d\n", rank, sum);

  MPI_Finalize();
  return 0;
}