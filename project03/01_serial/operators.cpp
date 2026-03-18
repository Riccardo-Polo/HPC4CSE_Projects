//******************************************
// operators.cpp
// based on min-app code written by Oliver Fuhrer, MeteoSwiss
// modified by Ben Cumming, CSCS
// *****************************************

// Description: Contains simple operators which can be used on 2d-meshes

#include "data.h"
#include "operators.h"
#include "stats.h"

namespace operators {

// compute the diffusion-reaction stencils
// s_old is the population concentration at time step k-1, s_new at k,
// and f is the residual (see Eq. (7) in Project 3).
void diffusion(data::Field const& s_old, data::Field const& s_new,
               data::Field& f) {
    using data::options;

    using data::bndE;
    using data::bndW;
    using data::bndN;
    using data::bndS;

    double alpha = options.alpha;
    double beta = options.beta;

    int nx = options.nx;
    int iend  = nx - 1;
    int jend  = nx - 1;

    // interior points excluding last interior row/column
    for (int j = 1; j < jend; j++) {
        for (int i = 1; i < iend; i++) {
            f(i,j) = -(4+alpha)*s_new(i,j)
                + s_new(i-1,j) + s_new(i+1,j)
                + s_new(i,j-1) + s_new(i,j+1)
                + beta*s_new(i,j)*(1-s_new(i,j))
                + alpha*s_old(i,j);
        }
    }

    // east interior boundary
    for (int j = 1; j < jend; j++) {
        f(iend,j) = -(4+alpha)*s_new(iend,j)
                + s_new(iend-1,j) + 0.1
                + s_new(iend,j-1) + s_new(iend,j+1)
                + beta*s_new(iend,j)*(1-s_new(iend,j))
                + alpha*s_old(iend,j);
    }

    // west interior boundary
    for (int j = 1; j < jend; j++) {
        f(1,j) = -(4+alpha)*s_new(1,j)
            + 0.1 + s_new(2,j)
            + s_new(1,j-1) + s_new(1,j+1)
            + beta*s_new(1,j)*(1-s_new(1,j))
            + alpha*s_old(1,j);
    }

    // north interior boundary
    for (int i = 2; i < iend; i++) {
        f(i,jend) = -(4+alpha)*s_new(i,jend)
                + s_new(i-1,jend) + s_new(i+1,jend)
                + s_new(i,jend-1) + 0.1
                + beta*s_new(i,jend)*(1-s_new(i,jend))
                + alpha*s_old(i,jend);
    }

    // south interior boundary:
    for (int i = 2; i < iend; i++) {
        f(i,1) = -(4+alpha)*s_new(i,1)
            + s_new(i-1,1) + s_new(i+1,1)
            + 0.1 + s_new(i,2)
            + beta*s_new(i,1)*(1-s_new(i,1))
            + alpha*s_old(i,1);
    }

    // NE corner
    f(iend,jend) = -(4+alpha)*s_new(iend,jend)
                + s_new(iend-1,jend) + 0.1
                + s_new(iend,jend-1) + 0.1
                + beta*s_new(iend,jend)*(1-s_new(iend,jend))
                + alpha*s_old(iend,jend);

    // NW corner
    f(1,jend) = -(4+alpha)*s_new(1,jend)
            + 0.1 + s_new(2,jend)
            + s_new(1,jend-1) + 0.1
            + beta*s_new(1,jend)*(1-s_new(1,jend))
            + alpha*s_old(1,jend);

    // SE corner
    f(iend,1) = -(4+alpha)*s_new(iend,1)
            + s_new(iend-1,1) + 0.1
            + 0.1 + s_new(iend,2)
            + beta*s_new(iend,1)*(1-s_new(iend,1))
            + alpha*s_old(iend,1);

    // SW corner
    f(1,1) = -(4+alpha)*s_new(1,1)
        + 0.1 + s_new(2,1)
        + 0.1 + s_new(1,2)
        + beta*s_new(1,1)*(1-s_new(1,1))
        + alpha*s_old(1,1);

        // Accumulate the flop counts
        // 8 ops total per point
        stats::flops_diff += 12 * (nx - 2) * (nx - 2) // interior points
                        +  11 * (nx - 2  +  nx - 2) // NESW boundary points
                        +  11 * 4;                  // corner points
    }

} // namespace operators
