//******************************************
// operators.h
// based on min-app code written by Oliver Fuhrer, MeteoSwiss
// modified by Ben Cumming, CSCS
// *****************************************

// Description: Contains simple operators which can be used on 2d-meshes

#ifndef OPERATORS_H
#define OPERATORS_H

#include "data.h"

namespace operators {

__global__ void diffusion(real_t* const s_old,
               real_t* const s_new,
               real_t* f,
               real_t alpha,
               real_t beta,
               real_t* const bndE,
               real_t* const bndW,
               real_t* const bndN,
               real_t* const bndS,
               int nx);

}

#endif /* OPERATORS_H */
