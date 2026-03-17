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

    // the interior grid points
    for (int j=1; j < jend; j++) {
        for (int i=1; i < iend; i++) {
            // TODO
            f(i,j) = -(4+alpha)*s_new(i,j) + s_new(i-1,j) + s_new(i+1,j) + s_new(i,j-1) + s_new(i,j+1) +beta*s_new(i,j)*(1-s_new(i,j)) +alpha*s_old(i,j);
        }
    }

    // east boundary
    // TODO
    for(int j = 1 ; j < jend ; j++)
    {
        f(iend,j) = -(4+alpha)*0.1 + s_new(iend-1,j) + s_new(iend,j-1) + s_new(iend,j+1) + beta*0.1*(1-0.1) + alpha*0.1;  
    }
    // west boundary
    // TODO
    for(int j = 1 ; j < jend ; j++)
    {
        f(0,j) = -(4+alpha)*0.1 + s_new(1,j) + s_new(0,j-1) + s_new(0,j+1) + beta*0.1*(1-0.1) + alpha*0.1;
    }

    // north boundary (plus NE and NW corners)
    // TODO
    for(int i = 0 ; i <= iend ; i++)
    {
        f(i,jend) = -(4+alpha)*0.1 + s_new(i-1,jend) + s_new(i+1,jend) + s_new(i,jend-1) + beta*0.1*(1-0.1) + alpha*0.1;
        
        // NE corner
        f(iend,jend) = -(4+alpha)*0.1 + s_new(iend-1,jend) + s_new(iend,jend-1) + beta*0.1*(1-0.1) + alpha*0.1;

        // NW corner
        f(0,jend) = -(4+alpha)*0.1 + s_new(1,jend) + s_new(0,jend-1) + beta*0.1*(1-0.1) + alpha*0.1;
    }

    // south boundary (plus SW and SE corners)
    // TODO
    for(int i = 0 ; i <= iend ; i++)
    {
        f(i,0) = -(4+alpha)*0.1 + s_new(i-1,0) + s_new(i+1,0) + s_new(i,1) + beta*0.1*(1-0.1) + alpha*0.1;

        // SE corner
        f(iend,0) = -(4+alpha)*0.1 + s_new(iend-1,0) + s_new(iend,1) + beta*0.1*(1-0.1) + alpha*0.1;

        // SW corner
        f(0,0) = -(4+alpha)*0.1 + s_new(1,0) + s_new(0,1) + beta*0.1*(1-0.1) + alpha*0.1;
    }

    // Accumulate the flop counts
    // 8 ops total per point
    stats::flops_diff += 12 * (nx - 2) * (nx - 2) // interior points
                      +  11 * (nx - 2  +  nx - 2) // NESW boundary points
                      +  11 * 4;                  // corner points
}

} // namespace operators
