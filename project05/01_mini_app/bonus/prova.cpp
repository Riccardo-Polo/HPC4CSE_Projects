#include <mpi.h>
#include <vector>
#include <iostream>

void do_work(double delay);  // assume this is defined elsewhere

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    const int count = 80000000;
    std::vector<char> buf(count);

    double delay = 0.0;

    while (true) {
        MPI_Barrier(MPI_COMM_WORLD);

        if (rank == 0) {
            double t = MPI_Wtime();

            MPI_Request req;
            MPI_Irecv(buf.data(), count, MPI_BYTE,
                      1, 0, MPI_COMM_WORLD, &req);

            do_work(delay);

            MPI_Wait(&req, MPI_STATUS_IGNORE);

            t = MPI_Wtime() - t;

            std::cout << "Overall: " << t
                      << " Delay: " << delay << std::endl;
        } else {
            MPI_Send(buf.data(), count, MPI_BYTE,
                     0, 0, MPI_COMM_WORLD);
        }

        delay += 1.e-2;

        if (delay >= 2.0) break;
    }

    MPI_Finalize();
    return 0;
}