//******************************************
// operators.cpp
// Diffusion operator with communication/computation overlap.
// Replace your current operators.cpp with this file (or copy this file to operators.cpp).
// *****************************************

#include "data.h"
#include "operators.h"
#include "stats.h"
#include <mpi.h>
#include <vector>

namespace operators {

void diffusion(data::Field const& s_old, data::Field const& s_new,
               data::Field& f) {
    using data::options;
    using data::domain;

    using data::bndE;
    using data::bndW;
    using data::bndN;
    using data::bndS;

    const double alpha = options.alpha;
    const double beta  = options.beta;

    const int nx = domain.nx;
    const int ny = domain.ny;
    const int iend = nx - 1;
    const int jend = ny - 1;

    const int countx = nx; // north/south rows are contiguous: s_new(0,j), ..., s_new(nx-1,j)
    const int county = ny; // west/east columns are not contiguous, hence packed below

    // Pack non-contiguous west/east columns before starting the non-blocking sends.
    // These buffers must stay alive until MPI_Waitall has completed.
    std::vector<double> sendW(county), sendE(county);
    for (int j = 0; j < county; ++j) {
        sendW[j] = s_new(0,    j);
        sendE[j] = s_new(nx-1, j);
    }

    MPI_Request reqs[8];
    int reqcnt = 0;

    // 1) Post all receives first.
    if (domain.neighbour_north != MPI_PROC_NULL) {
        MPI_Irecv(bndN.data(), countx, MPI_DOUBLE, domain.neighbour_north, 0,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_south != MPI_PROC_NULL) {
        MPI_Irecv(bndS.data(), countx, MPI_DOUBLE, domain.neighbour_south, 0,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_west != MPI_PROC_NULL) {
        MPI_Irecv(bndW.data(), county, MPI_DOUBLE, domain.neighbour_west, 1,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_east != MPI_PROC_NULL) {
        MPI_Irecv(bndE.data(), county, MPI_DOUBLE, domain.neighbour_east, 1,
                  domain.comm_cart, &reqs[reqcnt++]);
    }

    // 2) Post all sends. North/south rows are contiguous in the Field layout.
    if (domain.neighbour_north != MPI_PROC_NULL) {
        MPI_Isend(&s_new(0, ny-1), countx, MPI_DOUBLE, domain.neighbour_north, 0,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_south != MPI_PROC_NULL) {
        MPI_Isend(&s_new(0, 0), countx, MPI_DOUBLE, domain.neighbour_south, 0,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_west != MPI_PROC_NULL) {
        MPI_Isend(sendW.data(), county, MPI_DOUBLE, domain.neighbour_west, 1,
                  domain.comm_cart, &reqs[reqcnt++]);
    }
    if (domain.neighbour_east != MPI_PROC_NULL) {
        MPI_Isend(sendE.data(), county, MPI_DOUBLE, domain.neighbour_east, 1,
                  domain.comm_cart, &reqs[reqcnt++]);
    }

    // 3) While the halo messages are outstanding, compute only points that do not
    //    need any received halo values. This is the actual overlap region.
    for (int j = 1; j < jend; ++j) {
        for (int i = 1; i < iend; ++i) {
            f(i,j) = -(4. + alpha) * s_new(i,j)
                   + s_new(i-1,j) + s_new(i+1,j)
                   + s_new(i,j-1) + s_new(i,j+1)
                   + alpha * s_old(i,j)
                   + beta * s_new(i,j) * (1.0 - s_new(i,j));
        }
    }

    // 4) Now the boundary computation really needs halo values. Wait only here.
    if (reqcnt > 0) {
        MPI_Waitall(reqcnt, reqs, MPI_STATUSES_IGNORE);
    }

    // East boundary, excluding corners.
    {
        const int i = nx - 1;
        for (int j = 1; j < jend; ++j) {
            f(i,j) = -(4. + alpha) * s_new(i,j)
                   + s_new(i-1,j) + bndE[j]
                   + s_new(i,j-1) + s_new(i,j+1)
                   + alpha * s_old(i,j)
                   + beta * s_new(i,j) * (1.0 - s_new(i,j));
        }
    }

    // West boundary, excluding corners.
    {
        const int i = 0;
        for (int j = 1; j < jend; ++j) {
            f(i,j) = -(4. + alpha) * s_new(i,j)
                   + bndW[j] + s_new(i+1,j)
                   + s_new(i,j-1) + s_new(i,j+1)
                   + alpha * s_old(i,j)
                   + beta * s_new(i,j) * (1.0 - s_new(i,j));
        }
    }

    // North boundary, including corners.
    {
        const int j = ny - 1;
        int i = 0;
        f(i,j) = -(4. + alpha) * s_new(i,j)
               + bndW[j] + s_new(i+1,j)
               + s_new(i,j-1) + bndN[i]
               + alpha * s_old(i,j)
               + beta * s_new(i,j) * (1.0 - s_new(i,j));

        for (i = 1; i < iend; ++i) {
            f(i,j) = -(4. + alpha) * s_new(i,j)
                   + s_new(i-1,j) + s_new(i+1,j)
                   + s_new(i,j-1) + bndN[i]
                   + alpha * s_old(i,j)
                   + beta * s_new(i,j) * (1.0 - s_new(i,j));
        }

        i = nx - 1;
        f(i,j) = -(4. + alpha) * s_new(i,j)
               + s_new(i-1,j) + bndE[j]
               + s_new(i,j-1) + bndN[i]
               + alpha * s_old(i,j)
               + beta * s_new(i,j) * (1.0 - s_new(i,j));
    }

    // South boundary, including corners.
    {
        const int j = 0;
        int i = 0;
        f(i,j) = -(4. + alpha) * s_new(i,j)
               + bndW[j] + s_new(i+1,j)
               + bndS[i] + s_new(i,j+1)
               + alpha * s_old(i,j)
               + beta * s_new(i,j) * (1.0 - s_new(i,j));

        for (i = 1; i < iend; ++i) {
            f(i,j) = -(4. + alpha) * s_new(i,j)
                   + s_new(i-1,j) + s_new(i+1,j)
                   + bndS[i] + s_new(i,j+1)
                   + alpha * s_old(i,j)
                   + beta * s_new(i,j) * (1.0 - s_new(i,j));
        }

        i = nx - 1;
        f(i,j) = -(4. + alpha) * s_new(i,j)
               + s_new(i-1,j) + bndE[j]
               + bndS[i] + s_new(i,j+1)
               + alpha * s_old(i,j)
               + beta * s_new(i,j) * (1.0 - s_new(i,j));
    }

    stats::flops_diff += 12 * (nx - 2) * (ny - 2)
                      + 11 * (nx - 2 + ny - 2)
                      + 11 * 4;
}

} // namespace operators
