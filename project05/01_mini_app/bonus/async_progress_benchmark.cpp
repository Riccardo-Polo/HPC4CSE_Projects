#include <mpi.h>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <vector>

static volatile double sink = 0.0;

// Register-heavy artificial work. Avoids large memory traffic so that we measure
// MPI progress, not memory-bandwidth contention.
void do_work(double seconds) {
    const double t0 = MPI_Wtime();
    double x0 = 1.0000001, x1 = 1.0000002, x2 = 1.0000003, x3 = 1.0000004;
    while (MPI_Wtime() - t0 < seconds) {
        for (int k = 0; k < 2000; ++k) {
            x0 = x0 * 1.0000000001 + x1;
            x1 = x1 * 0.9999999999 + x2;
            x2 = x2 * 1.0000000002 + x3;
            x3 = x3 * 0.9999999998 + x0;
        }
    }
    sink += x0 + x1 + x2 + x3;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size != 2) {
        if (rank == 0) std::cerr << "Run with exactly 2 MPI processes.\n";
        MPI_Finalize();
        return 1;
    }

    std::size_t count = 80'000'000; // bytes, as in the book example
    if (argc > 1) count = static_cast<std::size_t>(std::atoll(argv[1]));

    std::vector<unsigned char> buf(count, static_cast<unsigned char>(rank));

    if (rank == 0) {
        std::cout << "# count_bytes " << count << "\n";
        std::cout << "# delay_s overall_s\n";
    }

    for (double delay = 0.0; delay < 2.0001; delay += 0.01) {
        MPI_Barrier(MPI_COMM_WORLD);

        if (rank == 0) {
            MPI_Request req;
            const double t0 = MPI_Wtime();
            MPI_Irecv(buf.data(), static_cast<int>(count), MPI_BYTE, 1, 0,
                      MPI_COMM_WORLD, &req);
            do_work(delay);
            MPI_Wait(&req, MPI_STATUS_IGNORE);
            const double t = MPI_Wtime() - t0;
            std::cout << delay << " " << t << "\n";
        } else {
            MPI_Send(buf.data(), static_cast<int>(count), MPI_BYTE, 0, 0,
                     MPI_COMM_WORLD);
        }
    }

    MPI_Finalize();
    return 0;
}
