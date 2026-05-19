// linear algebra subroutines
// Ben Cumming @ CSCS

#ifndef LINALG_H
#define LINALG_H

#include "data.h"

namespace linalg {

using data::Field;

extern bool cg_initialized;
extern real_t *r, *Ap, *p, *v, *fv;

// initialize temporary storage fields used by the cg solver
// I do this here so that the fields are persistent between calls
// to the CG solver. This is useful if we want to avoid malloc/free calls
// on the device for the OpenACC implementation (feel free to suggest a
// better method for doing this)
void cg_init(const int N);

////////////////////////////////////////////////////////////////////////////////
//  blas level 1 reductions
////////////////////////////////////////////////////////////////////////////////

// computes the inner product of x and y
// x and y are vectors of length N
__global__ void hpc_dot(real_t* const x, real_t* const y, real_t* result,
                        size_t const N);

// computes the 2-norm of x
// x is a vector of length N
void hpc_norm2(real_t* const x, real_t* result, size_t const N);

// sets entries in a vector to value
// x is a vector on length N
// value is th
__global__ void hpc_fill(real_t* x, const real_t value, const size_t N);

////////////////////////////////////////////////////////////////////////////////
//  blas level 1 vector-vector operations
////////////////////////////////////////////////////////////////////////////////

// computes y := alpha*x + y
// x and y are vectors on length N
// alpha is a scalar
__global__ void hpc_axpy(real_t* y, const real_t alpha, real_t* const x,
                         size_t const N);

// computes y = x + alpha*(l-r)
// y, x, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_add_scaled_diff(real_t* y, real_t* const x,
                                    const real_t alpha,
                                    real_t* const l, real_t* const r,
                                    size_t const N);

// computes y = alpha*(l-r)
// y, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_scaled_diff(real_t* y, const real_t alpha,
                                real_t* const l, real_t* const r,
                                size_t const N);

// computes y := alpha*x
// alpha is scalar
// y and x are vectors on length N
__global__ void hpc_scale(real_t* y, const real_t alpha, real_t* const x,
                          size_t const N);

// computes linear combination of two vectors y := alpha*x + beta*z
// alpha and beta are scalar
// y, x and z are vectors on length N
__global__ void hpc_lcomb(real_t* y, const real_t alpha, real_t* const x,
                          const real_t beta, real_t* const z,
                          size_t const N);

// copy one vector into another y := x
// x and y are vectors of length N
__global__ void hpc_copy(real_t* y, real_t* const x, size_t const N);

// conjugate gradient solver
// solve the linear system J_{f}(y_old, y_new) \delta y = f(y_old, y_new)
// the Jacobian matrix J_{f} is implicit in the objective function for the
// diffusion equation (a simple finite difference approximation is used)
// ON ENTRY deltay contains the initial guess for the solution
// ON EXIT  deltay contains the solution
unsigned int hpc_cg(real_t* deltay, real_t* const y_old, real_t* const y_new,
                    real_t* const f, real_t* bndE, real_t* bndW, real_t* bndN,
                    real_t* bndS, const int maxiters, const real_t tol,
                    bool& success);

}

#endif /* LINALG_H */
