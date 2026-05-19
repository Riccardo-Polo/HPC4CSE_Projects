// linear algebra subroutines
// Timo Schwab @ ETH Zurich

#include "linalg.h"

// sets entries in a vector to value
// x is a vector of length N
// value is a scalar
__global__ void hpc_fill(real_t* x, const real_t value, const size_t N) {
    // TODO
}

////////////////////////////////////////////////////////////////////////////////
//  blas level 1 vector-vector operations
////////////////////////////////////////////////////////////////////////////////

// computes y := alpha*x + y
// x and y are vectors of length N
// alpha is a scalar
__global__ void hpc_axpy(real_t* y, const real_t alpha, real_t* const x,
                         const size_t N) {
    // TODO
}

// computes y = x + alpha*(l-r)
// y, x, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_add_scaled_diff(real_t* y, real_t* const x,
                                    const real_t alpha,
                                    real_t* const l, real_t* const r,
                                    size_t const N) {
    // TODO
}

// computes y = alpha*(l-r)
// y, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_scaled_diff(real_t* y, const real_t alpha,
                                real_t* const l, real_t* const r,
                                size_t const N) {
    // TODO
}

// computes y := alpha*x
// alpha is scalar
// y and x are vectors of length N
__global__ void hpc_scale(real_t* y, const real_t alpha, real_t* const x,
                          size_t const N) {
    // TODO
}

// computes linear combination of two vectors y := alpha*x + beta*z
// alpha and beta are scalar
// y, x and z are vectors of length N
__global__ void hpc_lcomb(real_t* y, const real_t alpha, real_t* const x,
                          const real_t beta, real_t* const z,
                          size_t const N) {
    // TODO
}

// copy one vector into another y := x
// x and y are vectors of length N
__global__ void hpc_copy(real_t* y, real_t* const x, size_t const N) {
    // TODO
}
