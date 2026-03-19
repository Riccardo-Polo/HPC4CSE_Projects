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

#include <cstdio>
#include <cmath>
#include <cstdlib>
#include <cstring>

#include <omp.h>


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
    double t = atof(argv[3]);
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
    double D = 1.;
    options.alpha = (options.dx * options.dx) / (D * options.dt);

    // set beta, assume diffusion coefficient D=1, reaction coefficient R=500
    double R = 500.;
    options.beta = (R * options.dx * options.dx)/D;
}


void write_output(const Field& y, const std::string& bin_name,
                  const std::string& bov_name, double time)
{
    int nx = options.nx;

    // binary data
    FILE* output = fopen(bin_name.c_str(), "wb");
    fwrite(y.data(), sizeof(double), nx * nx, output);
    fclose(output);

    // bov header
    std::ofstream fid(bov_name);
    fid << "TIME: " << time << std::endl;
    fid << "DATA_FILE: " << bin_name << std::endl;
    fid << "DATA_SIZE: " << options.nx << " " << options.nx << " 1" << std::endl;
    fid << "DATA_FORMAT: DOUBLE" << std::endl;
    fid << "VARIABLE: phi" << std::endl;
    fid << "DATA_ENDIAN: LITTLE" << std::endl;
    fid << "CENTERING: nodal" << std::endl;
    fid << "BRICK_ORIGIN: 0. 0. 0." << std::endl;
    fid << "BRICK_SIZE: " << (options.nx - 1) * options.dx << ' '
                          << (options.nx - 1) * options.dx << ' '
                          << "1.0" << std::endl;
}

// =============================================================================

int main(int argc, char* argv[]) {
    // read command line arguments
    readcmdline(options, argc, argv);
    int nx = options.nx;
    int N  = options.N;
    int nt = options.nt;

    // set iteration parameters
    int max_cg_iters     = 300;
    int max_newton_iters = 50;
    double tolerance     = 1.e-6;

    // get number of threads
    int threads = omp_get_max_threads(); 

    // welcome message
    std::cout << std::string(80, '=') << std::endl;
    std::cout << "                      Welcome to mini-stencil!" << std::endl;
    #ifdef _OPENMP
    std::cout << "version   :: C++ OpenMP" << std::endl;
    #endif
    #ifndef _OPENMP
    std::cout << "version   :: C++ serial" << std::endl;
    #endif
    std::cout << "threads   :: " << threads << std::endl;
    std::cout << "mesh      :: " << options.nx << " * " << options.nx
                                 << " dx = " << options.dx << std::endl;
    std::cout << "time      :: " << nt << " time steps from 0 .. "
                                       << options.nt*options.dt << std::endl;
    std::cout << "iteration :: " << "CG "          << max_cg_iters
                                 << ", Newton "    << max_newton_iters
                                 << ", tolerance " << tolerance << std::endl;
    std::cout << std::string(80, '=') << std::endl;

    // allocate global fields
    y_new.init(nx, nx);
    y_old.init(nx, nx);
    bndN.init(nx, 1);
    bndS.init(nx, 1);
    bndE.init(nx, 1);
    bndW.init(nx, 1);

    Field f(nx, nx);
    Field deltay(nx, nx);

    // set Dirichlet boundary conditions to 0 all around
    double const_bdy = 0.1;
    hpc_fill(bndN, const_bdy);
    hpc_fill(bndS, const_bdy);
    hpc_fill(bndE, const_bdy);
    hpc_fill(bndW, const_bdy);

    // set the initial condition
    // a circle of concentration 0.125 centred at (xdim/4, ydim/4) with radius
    // no larger than 1/8 of both xdim and ydim
    double const_fill = 0.1;
    double inner_circle = 0.2;
    hpc_fill(y_new, const_fill);
    double xc = 1.0 / 4.0;
    double yc = 1.0 / 4.0;
    double radius = std::min(xc, yc) / 2.0;
    for (int j = 0; j < nx; j++) {
        double y = (j - 1) * options.dx;
        for (int i = 0; i < nx; i++) {
            double x = (i - 1) * options.dx;
            if ((x - xc) * (x - xc) + (y - yc) * (y - yc) < radius * radius) {
                y_new(i,j) = inner_circle;
            }
        }
    }

    write_output(y_new, "output_initial.bin", "output_initial.bov", 0.0);

    tot_iters_cg = 0;
    tot_iters_newton = 0;
    unsigned int iters_cg = 0;

    // start timer
    double time_start = walltime();

    // main time loop
    for (int timestep = 1; timestep <= nt; timestep++) {
        // set y_new and y_old to be the solution
        hpc_copy(y_old, y_new);

        double residual;
        bool converged = false;
        int it;
        for (it = 0; it < max_newton_iters; it++) {
            // compute residual
            diffusion(y_old, y_new, f);
            residual = hpc_norm2(f);

            // check for convergence
            if (residual < tolerance) {
                converged = true;
                break;
            }

            // solve linear system to get deltay
            bool cg_converged = false;
            iters_cg = hpc_cg(deltay, y_old, y_new, f, max_cg_iters, tolerance,
                              cg_converged);
            tot_iters_cg += iters_cg;

            // check that the CG solver converged
            if (!cg_converged) break;

            // update solution
            hpc_axpy(y_new, -1.0, deltay);
        }
        tot_iters_newton += it + 1;

        // output some statistics
        if (converged && verbose_output) {
            std::cout << "step " << timestep
                      << " required " << it + 1
                      << " Newton iterations and "
                      << iters_cg << " CG iterations "
                      << "for residual " << residual
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
    double time_end = walltime();

    ////////////////////////////////////////////////////////////////////
    // write final solution to BOV file for visualization
    ////////////////////////////////////////////////////////////////////

    write_output(y_new, "output_final.bin", "output_final.bov", options.nt * options.dt);

    // print table summarizing results
    double timespent = time_end - time_start;
    std::cout << std::string(80, '-') << std::endl;
    std::cout << "simulation took " << timespent << " seconds" << std::endl;
    std::cout << tot_iters_cg
              << " conjugate gradient iterations, at rate of "
              << float(tot_iters_cg)/timespent << " iters/second" << std::endl;
    std::cout << tot_iters_newton << " Newton iterations" << std::endl;
    std::cout << std::string(80, '-') << std::endl;
    std::cout << "### " << threads << ", "
                        << options.nx << ", "
                        << options.nt << ", "
                        << tot_iters_cg   << ", "
                        << tot_iters_newton <<  ", "
                        << timespent
              << " ###" << std::endl;
    std::cout << "Goodbye!" << std::endl;

    return 0;
}
