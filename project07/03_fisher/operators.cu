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
    
    int iend = nx - 1;
    int jend = nx - 1;

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    if (i < 1 || i > iend || j < 1 || j > jend) {
        return;
    }

    int idx = i + j * nx;

    real_t center = s_new[idx];

    real_t west  = (i == 1)    ? bndW[j] : s_new[idx - 1];
    real_t east  = (i == iend) ? bndE[j] : s_new[idx + 1];
    real_t south = (j == 1)    ? bndS[i] : s_new[idx - nx];
    real_t north = (j == jend) ? bndN[i] : s_new[idx + nx];

    f[idx] = -(4.0 + alpha) * center
           + west + east + south + north
           + beta * center * (1.0 - center)
           + alpha * s_old[idx];
}

} // namespace operators
