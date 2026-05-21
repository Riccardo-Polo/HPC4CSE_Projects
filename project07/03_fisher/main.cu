// ******************************************
// implicit time stepping implementation of 2D diffusion problem
// Ben Cumming, CSCS
// *****************************************

// A small benchmark app that solves the 2D fisher equation using second-order
// finite differences.

// Syntax: ./main nx nt t [verbose]

#include <algorithm>
#include <fstream>
#include <iostream>
#include <string>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>


#include "data.h"
#include "linalg.h"
#include "operators.h"
#include "walltime.h"
#include "stats.h"

using namespace data;
using namespace linalg;
using namespace operators;
using namespace stats;

// =============================================================================

// read command line arguments
void readcmdline(Discretization& options, int argc, char* argv[]) {
    if (argc<4 || argc>5) {
        std::cerr << "Usage: main nx nt t verbose\n";
        std::cerr << "  nx      number of grid points in x-direction and "
                               "y-direction, respectively\n";
        std::cerr << "  nt      number of time steps\n";
        std::cerr << "  t       total time\n";
        std::cerr << "  verbose (optional) verbose output\n";
        exit(1);
    }

    // read nx
    options.nx = atoi(argv[1]);
    if (options.nx < 1) {
        std::cerr << "nx must be positive integer\n";
        exit(-1);
    }

    // read nt
    options.nt = atoi(argv[2]);
    if (options.nt < 1) {
        std::cerr << "nt must be positive integer\n";
        exit(-1);
    }

    // read total time
    real_t t = atof(argv[3]);
    if (t < 0) {
        std::cerr << "t must be positive real value\n";
        exit(-1);
    }

    // set verbosity if requested
    verbose_output = false;
    if (argc==5) {
        verbose_output = true;
    }

    // set total number of grid points
    options.N = options.nx * options.nx;

    // set time step size
    options.dt = t / options.nt;

    // set distance between grid points
    // assume that x dimension has length 1.0
    options.dx = 1. / (options.nx - 1);

    // set alpha, assume diffusion coefficient D is 1
    real_t D = 1.;
    options.alpha = (options.dx * options.dx) / (D * options.dt);

    // set beta, assume diffusion coefficient D=1, reaction coefficient R=500
    real_t R = 500.;
    options.beta = (R * options.dx * options.dx)/D;
}

// =============================================================================

int main(int argc, char* argv[]) {
    // read command line arguments
    readcmdline(options, argc, argv);
    int nx = options.nx;
    int N  = options.N;
    int nt = options.nt;

    real_t alpha = options.alpha;
    real_t beta = options.beta;

    // set iteration parameters
    int max_cg_iters     = 300;
    int max_newton_iters = 50;
    real_t tolerance = 0.;
    if (sizeof(real_t) == sizeof(float)) {
        tolerance     = 1.e-3;
    } else if (sizeof(real_t) == sizeof(double)) {
        tolerance     = 1.e-6;
    }


    // welcome message
    std::cout << std::string(80, '=') << std::endl;
    std::cout << "                      Welcome to mini-stencil!" << std::endl;
    std::cout << "version   :: CUDA" << std::endl;
    std::cout << "mesh      :: " << options.nx << " * " << options.nx
                                 << " dx = " << options.dx << std::endl;
    std::cout << "time      :: " << nt << " time steps from 0 .. "
                                       << options.nt*options.dt << std::endl;
    std::cout << "iteration :: " << "CG "          << max_cg_iters
                                 << ", Newton "    << max_newton_iters
                                 << ", tolerance " << tolerance << std::endl;
    std::cout << std::string(80, '=') << std::endl;

    // allocate fields on gpu
    real_t *d_y_new, *d_y_old;
    real_t *d_bndN, *d_bndS, *d_bndE, *d_bndW;
    cudaMalloc(&d_y_new, nx*nx*sizeof(real_t));
    cudaMalloc(&d_y_old, nx*nx*sizeof(real_t));
    cudaMalloc(&d_bndN, nx*sizeof(real_t));
    cudaMalloc(&d_bndS, nx*sizeof(real_t));
    cudaMalloc(&d_bndE, nx*sizeof(real_t));
    cudaMalloc(&d_bndW, nx*sizeof(real_t));

    real_t *d_f, *d_deltay;
    cudaMalloc(&d_f, nx*nx*sizeof(real_t));
    cudaMalloc(&d_deltay, nx*nx*sizeof(real_t));
    cudaMemset(d_deltay, 0, nx*nx*sizeof(real_t));
    cudaMemset(d_f, 0, nx*nx*sizeof(real_t));

    // set launch parameters for hpc kernels
    int threads = 256;
    int blocks = (nx + threads - 1) / threads;
    int blocks_2d = (nx * nx + threads - 1) / threads;

    // TODO: determine grid size
    /* dim3 diffusion_block */
    dim3 diffusion_block(16,16);
    dim3 diffusion_grid( (nx + diffusion_block.x - 1) / diffusion_block.x,
               (nx + diffusion_block.y - 1) / diffusion_block.y );

    real_t const_bdy = 0.1;
    hpc_fill<<<blocks, threads>>>(d_bndN, const_bdy, nx);
    hpc_fill<<<blocks, threads>>>(d_bndS, const_bdy, nx);
    hpc_fill<<<blocks, threads>>>(d_bndE, const_bdy, nx);
    hpc_fill<<<blocks, threads>>>(d_bndW, const_bdy, nx);

    // set the initial condition on CPU, then copy over to GPU
    // a circle of concentration 0.1 centred at (xdim/4, ydim/4) with radius
    // no larger than 1/8 of both xdim and ydim
    y_new.init(nx, nx);

    real_t const_fill = 0.1;
    real_t inner_circle = 0.2;

    for (int i = 0; i < nx; i++){
        for (int j = 0; j < nx; j++){
            y_new(i,j) = const_fill;
        }
    }

    real_t xc = 1.0 / 4.0;
    real_t yc = 1.0 / 4.0;
    real_t radius = std::min(xc, yc) / 2.0;
    for (int j = 0; j < nx; j++) {
        real_t y = (j - 1) * options.dx;
        for (int i = 0; i < nx; i++) {
            real_t x = (i - 1) * options.dx;
            if ((x - xc) * (x - xc) + (y - yc) * (y - yc) < radius * radius) {
                y_new(i,j) = inner_circle;
            }
        }
    }

    cudaMemcpy(d_y_new, y_new.data(), nx*nx*sizeof(real_t), cudaMemcpyHostToDevice);

    // write the initial condition to disk for visualization
    {
        FILE* output = fopen("output_initial.bin", "wb");
        cudaMemcpy(y_new.data(), d_y_new, nx*nx*sizeof(real_t), cudaMemcpyDeviceToHost);
        fwrite(y_new.data(), sizeof(real_t), nx * nx, output);
        fclose(output);
    }

    tot_iters_cg = 0;
    tot_iters_newton = 0;
    unsigned int iters_cg = 0;

    std::ofstream fid_initial("output_initial.bov");
    fid_initial << "TIME: " << options.nt*options.dt << std::endl;
    fid_initial << "DATA_FILE: output_initial.bin" << std::endl;
    fid_initial << "DATA_SIZE: " << options.nx << " " << options.nx << " 1"
        << std::endl;
    if (sizeof(real_t) == sizeof(float)) {
        fid_initial << "DATA_FORMAT: FLOAT" << std::endl;
    } else if (sizeof(real_t) == sizeof(double)) {
        fid_initial << "DATA_FORMAT: DOUBLE" << std::endl;
    }
    fid_initial << "VARIABLE: phi" << std::endl;
    fid_initial << "DATA_ENDIAN: LITTLE" << std::endl;
    fid_initial << "CENTERING: nodal" << std::endl;
    fid_initial << "BRICK_ORIGIN: " << "0. 0. 0." << std::endl;
    fid_initial << "BRICK_SIZE: " << (options.nx-1)*options.dx << ' '
                          << (options.nx-1)*options.dx << ' '
                          << " 1.0"
        << std::endl;

    // start timer
    real_t time_start = walltime();


    // main time loop
    for (int timestep = 1; timestep <= nt; timestep++) {
        // set y_new and y_old to be the solution
        hpc_copy<<<blocks_2d, threads>>>(d_y_old, d_y_new, nx*nx);

        real_t *d_residual, h_residual;
        cudaMalloc(&d_residual, sizeof(real_t));
        cudaMemset(d_residual, 0, sizeof(real_t));

        bool converged = false;
        int it;
        for (it = 0; it < max_newton_iters; it++) {
            // compute residual
            diffusion<<<diffusion_grid, diffusion_block>>>
                (d_y_old, d_y_new, d_f, alpha, beta, d_bndE, d_bndW, d_bndN, d_bndS, nx);

            hpc_norm2(d_f, d_residual, nx*nx);
            cudaMemcpy(&h_residual, d_residual, sizeof(real_t), cudaMemcpyDeviceToHost);
            cudaMemset(d_residual, 0, sizeof(real_t));

            // check for convergence
            if (h_residual < tolerance) {
                converged = true;
                break;
            }

            // solve linear system to get deltay
            bool cg_converged = false;
            iters_cg = hpc_cg(d_deltay, d_y_old, d_y_new, d_f,
                              d_bndE, d_bndW, d_bndN, d_bndS,
                              max_cg_iters, tolerance, cg_converged);
            tot_iters_cg += iters_cg;

            // check that the CG solver converged
            if (!cg_converged) break;

            // update solution
            hpc_axpy<<<blocks_2d, threads>>>(d_y_new, -1.0, d_deltay, nx*nx);
        }
        tot_iters_newton += it + 1;

        // output some statistics
        if (converged && verbose_output) {
            std::cout << "step " << timestep
                      << " required " << it + 1
                      << " Newton iterations and "
                      << iters_cg << " CG iterations "
                      << "for residual " << h_residual
                      << std::endl;
        }
        if (!converged) {
            std::cerr << "step " << timestep
                      << " ERROR : nonlinear iterations failed to converge"
                      << std::endl;
            break;
        }
    }

    // get times
    real_t time_end = walltime();

    ////////////////////////////////////////////////////////////////////
    // write final solution to BOV file for visualization
    ////////////////////////////////////////////////////////////////////

    // binary data
    {
        FILE* output = fopen("output_final.bin", "wb");
        cudaMemcpy(y_new.data(), d_y_new, nx*nx*sizeof(real_t), cudaMemcpyDeviceToHost);
        fwrite(y_new.data(), sizeof(real_t), nx * nx, output);
        fclose(output);
    }


    std::ofstream fid_final("output_final.bov");
    fid_final << "TIME: " << options.nt*options.dt << std::endl;
    fid_final << "DATA_FILE: output_final.bin" << std::endl;
    fid_final << "DATA_SIZE: " << options.nx << " " << options.nx << " 1"
        << std::endl;
    if (sizeof(real_t) == sizeof(float)) {
        fid_final << "DATA_FORMAT: FLOAT" << std::endl;
    } else if (sizeof(real_t) == sizeof(double)) {
        fid_final << "DATA_FORMAT: DOUBLE" << std::endl;
    }
    fid_final << "VARIABLE: phi" << std::endl;
    fid_final << "DATA_ENDIAN: LITTLE" << std::endl;
    fid_final << "CENTERING: nodal" << std::endl;
    fid_final << "BRICK_ORIGIN: " << "0. 0. 0." << std::endl;
    fid_final << "BRICK_SIZE: " << (options.nx-1)*options.dx << ' '
                          << (options.nx-1)*options.dx << ' '
                          << " 1.0"
        << std::endl;

    // print table summarizing results
    real_t timespent = time_end - time_start;
    std::cout << std::string(80, '-') << std::endl;
    std::cout << "simulation took " << timespent << " seconds" << std::endl;
    std::cout << tot_iters_cg
              << " conjugate gradient iterations, at rate of "
              << float(tot_iters_cg)/timespent << " iters/second" << std::endl;
    std::cout << tot_iters_newton << " Newton iterations" << std::endl;
    std::cout << std::string(80, '-') << std::endl;
    std::cout << "### " << options.nx << ", "
                        << options.nt << ", "
                        << tot_iters_cg   << ", "
                        << tot_iters_newton <<  ", "
                        << timespent
              << " ###" << std::endl;
    std::cout << "Goodbye!" << std::endl;

    return 0;
}
