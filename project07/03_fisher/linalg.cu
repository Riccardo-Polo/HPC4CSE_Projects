// linear algebra subroutines
// Ben Cumming @ CSCS

#include <iostream>

#include <cmath>
#include <cstdio>
#include <cuda_runtime.h>

#include "linalg.h"
#include "operators.h"
#include "stats.h"
#include "data.h"


namespace linalg {

bool cg_initialized = false;
real_t* r;
real_t* Ap;
real_t* p;
real_t* v;
real_t* fv;

using namespace data;
using namespace operators;
using namespace stats;

// initialize temporary storage fields used by the cg solver
// I do this here so that the fields are persistent between calls
// to the CG solver. This is useful if we want to avoid malloc/free calls
// on the device for the OpenACC implementation (feel free to suggest a better
// method for doing this)
void cg_init(int nx, int ny) {
    cudaMalloc(&Ap, nx*ny*sizeof(real_t));
    cudaMalloc(&r, nx*ny*sizeof(real_t));
    cudaMalloc(&p, nx*ny*sizeof(real_t));
    cudaMalloc(&v, nx*ny*sizeof(real_t));
    cudaMalloc(&fv, nx*ny*sizeof(real_t));

    cg_initialized = true;
}

__global__ void sqrt_kernel(real_t* d) {
    // only one thread executes:
    if (threadIdx.x == 0 && blockIdx.x == 0)
        d[0] = sqrt(d[0]);
}

////////////////////////////////////////////////////////////////////////////////
//  blas level 1 reductions
////////////////////////////////////////////////////////////////////////////////

// computes the inner product of x and y
// x and y are vectors of length N
__global__ void hpc_dot(real_t* const x, real_t* const y, real_t* result,
                        size_t const N) {
    // TODO: put your hpc_dot from dot_product/dot_prod.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        atomicAdd(result, x[i] * y[i]);
    }
}

// computes the 2-norm of x
// x is a vector of length N
void hpc_norm2(real_t* const x, real_t* result, size_t const N) {
    hpc_dot<<<7*68, 256>>>(x, x, result, N);
    sqrt_kernel<<<1,1>>>(result);
}

// sets entries in a vector to value
// x is a vector of length N
// value is a scalar
__global__ void hpc_fill(real_t* x, const real_t value, const size_t N) {
    // TODO: put your hpc_fill from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        x[i] = value;
    }
}

////////////////////////////////////////////////////////////////////////////////
//  blas level 1 vector-vector operations
////////////////////////////////////////////////////////////////////////////////

// computes y := alpha*x + y
// x and y are vectors of length N
// alpha is a scalar
__global__ void hpc_axpy(real_t* y, const real_t alpha, real_t* const x,
                         const size_t N) {
    // TODO: put your hpc_axpy from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = alpha*x[i] + y[i];
    }
}

// computes y = x + alpha*(l-r)
// y, x, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_add_scaled_diff(real_t* y, real_t* const x,
                                    const real_t alpha,
                                    real_t* const l, real_t* const r,
                                    size_t const N) {
    // TODO: put your hpc_add_scaled_diff from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = x[i] + alpha*(l[i]-r[i]);
    }
}

// computes y = alpha*(l-r)
// y, l and r are vectors of length N
// alpha is a scalar
__global__ void hpc_scaled_diff(real_t* y, const real_t alpha,
                                real_t* const l, real_t* const r,
                                size_t const N) {
    // TODO: put your hpc_scaled_diff from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = alpha*(l[i]-r[i]);
    }
}

// computes y := alpha*x
// alpha is scalar
// y and x are vectors of length N
__global__ void hpc_scale(real_t* y, const real_t alpha, real_t* const x,
                          size_t const N) {
    // TODO: put your hpc_scale from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = alpha*x[i];
    }
}

// computes linear combination of two vectors y := alpha*x + beta*z
// alpha and beta are scalar
// y, x and z are vectors of length N
__global__ void hpc_lcomb(real_t* y, const real_t alpha, real_t* const x,
                          const real_t beta, real_t* const z,
                          size_t const N) {
    // TODO: put your hpc_lcomb from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = alpha*x[i] + beta*z[i];
    }
}

// copy one vector into another y := x
// x and y are vectors of length N
__global__ void hpc_copy(real_t* y, real_t* const x, size_t const N) {
    // TODO: put your hpc_copy from simple_kernels/linalg.cu
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        y[i] = x[i];
    }
}

// conjugate gradient solver
// solve the linear system J_{f}(y_old, y_new) \delta y = f(y_old, y_new)
// the Jacobian matrix J_{f} is implicit in the objective function for the
// diffusion equation (a simple finite difference approximation is used)
// ON ENTRY deltay contains the initial guess for the solution
// ON EXIT  deltay contains the solution

unsigned int hpc_cg(real_t* deltay, real_t* const y_old, real_t* const y_new,
                    real_t* const f, real_t* bndE, real_t* bndW, real_t* bndN,
                    real_t* bndS, const int maxiters, const real_t tol,
                    bool& success) {
    // this is the dimension of the linear system that we are to solve
    int nx = data::options.nx;

    // set launch parameters for hpc kernels
    int threads = 256;
    int blocks_2d = (nx * nx + threads - 1) / threads;

    // set launch parameters for diffusion operator
    dim3 diffusion_block(16,16);
    dim3 diffusion_grid( (nx + diffusion_block.x - 1) / diffusion_block.x,
               (nx + diffusion_block.y - 1) / diffusion_block.y );

    if (!cg_initialized) cg_init(nx, nx);

    // epslion value use for matrix-vector approximation
    real_t eps     = 1.e-4;
    real_t eps_inv = 1. / eps;

    // initialize to zero
    hpc_fill<<<blocks_2d, threads>>>(fv, 0.0, nx*nx);

    // the Jacobian times deltay matrix vector multiplication is approximated
    // with J*deltay = 1/epsilon * ( f(y_new+epsilon*deltay) - f(y_new) )

    // v = y_new + epsilon*deltay
    hpc_lcomb<<<blocks_2d, threads>>>(v, 1.0, y_new, eps, deltay, nx*nx);

    // fv = f(v)
    diffusion<<<diffusion_grid, diffusion_block>>>
                (y_old, v, fv, data::options.alpha, data::options.beta, bndE, bndW, bndN, bndS, nx);

    // r = b - A*x = f(y_new) - J*deltay
    // where A*x = (f(v) - f)/eps
    hpc_add_scaled_diff<<<blocks_2d, threads>>>(r, f, -eps_inv, fv, f, nx*nx);

    // p = r
    hpc_copy<<<blocks_2d, threads>>>(p, r, nx*nx);

    // r_old_inner = <r,r>
    real_t *d_r_old_inner, r_old_inner;
    cudaMalloc(&d_r_old_inner, sizeof(real_t));
    hpc_dot<<<68*4, threads>>>(r, r, d_r_old_inner, nx*nx);

    cudaMemcpy(&r_old_inner, d_r_old_inner, sizeof(real_t), cudaMemcpyDeviceToHost);
    cudaMemset(d_r_old_inner, 0, sizeof(real_t));

    real_t r_new_inner = r_old_inner;

    // check for convergence
    success = false;
    if (sqrt(r_old_inner) < tol) {
        success = true;
        return 0;
    }

    int iter;
    for (iter=0; iter<maxiters; iter++) {
        // Ap = A*p
        hpc_lcomb<<<blocks_2d, threads>>>(v, 1.0, y_new, eps, p, nx*nx);
        diffusion<<<diffusion_grid, diffusion_block>>>
                (y_old, v, fv, data::options.alpha, data::options.beta, bndE, bndW, bndN, bndS, nx);
        hpc_scaled_diff<<<blocks_2d, threads>>>(Ap, eps_inv, fv, f, nx*nx);

        // alpha = r_old_inner / p'*Ap
        real_t *d_alpha, h_alpha;
        cudaMalloc(&d_alpha, sizeof(real_t));
        cudaMemset(d_alpha, 0, sizeof(real_t));
        hpc_dot<<<68*7, threads>>>(p, Ap, d_alpha, nx*nx);

        cudaMemcpy(&h_alpha, d_alpha, sizeof(real_t), cudaMemcpyDeviceToHost);
        cudaMemset(d_alpha, 0, sizeof(real_t));
        h_alpha = r_old_inner / h_alpha;

        // deltay += alpha*p
        hpc_axpy<<<blocks_2d, threads>>>(deltay, h_alpha, p, nx*nx);

        // r -= alpha*Ap
        hpc_axpy<<<blocks_2d, threads>>>(r, -h_alpha, Ap, nx*nx);

        // find new norm
        real_t *d_r_new_inner;
        cudaMalloc(&d_r_new_inner, sizeof(real_t));
        cudaMemset(d_r_new_inner, 0, sizeof(real_t));
        hpc_dot<<<blocks_2d, threads>>>(r, r, d_r_new_inner, nx*nx);

        cudaMemcpy(&r_new_inner, d_r_new_inner, sizeof(real_t), cudaMemcpyDeviceToHost);

        // test for convergence
        if (sqrt(r_new_inner) < tol) {
            success = true;
            break;
        }

        // p = r + r_new_inner.r_old_inner * p
        hpc_lcomb<<<blocks_2d, threads>>>(p, 1.0, r, r_new_inner / r_old_inner, p, nx*nx);

        r_old_inner = r_new_inner;
    }

    if (!success) std::cerr << "ERROR: CG failed to converge" << std::endl;

    return iter + 1;
}

} // namespace linalg
