#include <mpi.h>
#include <stdio.h>   // For printf
#include <stdlib.h>  // For rand, srand, and atoi (random number generation)

int main(int argc, char* argv[]) {

  // Initialize MPI, get size and rank
  int size, rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  // Master generates a random number
  int random_number;
  if (rank == 0) {
    srand(42);
    random_number = 1 + rand() % 6;
    printf("Process 0 generated number: %d\n", random_number);
  }

  // Broadcast the random number to all processes
  MPI_Bcast(&random_number, 1, MPI_INT, 0, MPI_COMM_WORLD);
  printf("Process %d received number: %d\n", rank, random_number);

  // Product reduction
  int input_value = rank + random_number;
  int product_result;
  MPI_Reduce(&input_value, &product_result, 1, MPI_INT, MPI_PROD, 0,
             MPI_COMM_WORLD);

  // Report result
    if (rank == 0) {
        printf("Product of all random_number + ranks: %d\n", product_result);
    }

  // Finalize MPI
    MPI_Finalize();

    return 0;
}
