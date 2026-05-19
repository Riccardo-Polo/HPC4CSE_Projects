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
}

}

} // namespace operators
