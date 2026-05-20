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
__global__ void diffusion(real_t* const s_old,
               real_t* const s_new,
               real_t* f,
               real_t alpha,
               real_t beta,
               real_t* const bndE,
               real_t* const bndW,
               real_t* const bndN,
               real_t* const bndS,
               int nx) {
    // TODO: study matrix add example in mat_add/mat_add.cu
    using data::options;

    using data::bndE;
    using data::bndW;
    using data::bndN;
    using data::bndS;

    int iend = nx-1;
    int jend = nx-1;

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    if (i > 0 && i < iend && j > 0 && j < jend) {
        // interior points
        f(i,j) = -(4+alpha)*s_new(i,j)
                        + s_new(i-1,j) + s_new(i+1,j)
                        + s_new(i,j-1) + s_new(i,j+1)
                        + beta*s_new(i,j)*(1-s_new(i,j))
                        + alpha*s_old(i,j);
    }

    else if (i==iend && j > 0 && j < jend) {
        // east interior boundary
        f(i,j) = -(4+alpha)*s_new(i,j)
                        + s_new(i-1,j) + bndE[j]
                        + s_new(i,j-1) + s_new(i,j+1)
                        + beta*s_new(i,j)*(1-s_new(i,j))
                        + alpha*s_old(i,j);
    }
    
    else if (i==1 && j > 0 && j < jend) {
        // west interior boundary
        f(i,j) = -(4+alpha)*s_new(i,j)
                    + bndW[j] + s_new(i+1,j)
                    + s_new(i,j-1) + s_new(i,j+1)
                    + beta*s_new(i,j)*(1-s_new(i,j))
                    + alpha*s_old(i,j);
    }

    else if(j==jend && i > 0 && i < iend) {
        // north interior boundary
        f(i,j) = -(4+alpha)*s_new(i,j)
                        + s_new(i-1,j) + s_new(i+1,j)
                        + s_new(i,j-1) + bndN[i]
                        + beta*s_new(i,j)*(1-s_new(i,j))
                        + alpha*s_old(i,j);
    }

    else if(j==1 && i > 0 && i < iend) {
        // south interior boundary
        f(i,j) = -(4+alpha)*s_new(i,j)
                    + s_new(i-1,j) + s_new(i+1,j)
                    + bndS[i] + s_new(i,j+1)
                    + beta*s_new(i,j)*(1-s_new(i,j))
                    + alpha*s_old(i,j);
    }

    else if (i==iend && j==jend) {
        // NE corner
        f(i,j) = -(4+alpha)*s_new(i,j)
                    + s_new(i-1,j) + bndE[j]
                    + s_new(i,j-1) + bndN[i]
                    + beta*s_new(i,j)*(1-s_new(i,j))
                    + alpha*s_old(i,j);
    }
    
    else if (i==1 && j==jend) {
        // NW corner
        f(i,j) = -(4+alpha)*s_new(i,j)
                + 0.1 + s_new(i+1,j)
                + s_new(i,j-1) + bndN[i]
                + beta*s_new(i,j)*(1-s_new(i,j))
                + alpha*s_old(i,j);
    }

    else if(i == iend && j == 1) {
        // SE corner
        f(i,j) = -(4+alpha)*s_new(i,j)
                + s_new(i-1,j) + bndE[j]
                + 0.1 + s_new(i,j+1)
                + beta*s_new(i,j)*(1-s_new(i,j))
                + alpha*s_old(i,j);
    }

    else if(i == 1 && j == 1) {
    // SW corner
    f(i,j) = -(4+alpha)*s_new(i,j)
        + bndW[j] + s_new(i+1,j)
        + bndS[i] + s_new(i,j+1)
        + beta*s_new(i,j)*(1-s_new(i,j))
        + alpha*s_old(i,j);
    }
}

} // namespace operators
