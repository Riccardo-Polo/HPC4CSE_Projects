#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include "walltime.h"

int main(int argc, char *argv[]) {
    uint64_t N = 1000000000;
    double time_start, h, local_sum = 0.0, sum = 0.0, pi;
    int rank, size;

    if (argc > 1) N = strtoull(argv[1], NULL, 10);

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    h = 1.0 / (double)N;

    MPI_Barrier(MPI_COMM_WORLD);
    time_start = walltime();

    for (uint64_t i = (uint64_t)rank; i < N; i += (uint64_t)size) {
        double x = (i + 0.5) * h;
        local_sum += 4.0 / (1.0 + x * x);
    }

    MPI_Reduce(&local_sum, &sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    double time = walltime() - time_start;

    if (rank == 0) {
        pi = sum * h;
        printf("# pi N procs time [secs]\n");
        printf("%.15f %20" PRIu64 " %3d %.8f\n", pi, N, size, time);
    }

    MPI_Finalize();
    return 0;
}
