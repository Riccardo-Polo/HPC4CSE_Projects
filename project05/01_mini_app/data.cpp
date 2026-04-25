#include "data.h"

#include <iostream>
#include <cmath>
#include <mpi.h>
#include <algorithm>



namespace data {

// fields that hold the solution
Field y_new;
Field y_old;

// fields that hold the boundary points
Field bndN;
Field bndE;
Field bndS;
Field bndW;

// buffers used during boundary halo communication
Field buffN;
Field buffE;
Field buffS;
Field buffW;

// global domain and local sub-domain
Discretization options;
SubDomain      domain;

void SubDomain::init(int mpi_rank, int mpi_size,
                     Discretization& discretization) {
    // TODO: determine the number of sub-domains in the x and y dimensions
    //       using MPI_Dims_create
    int dims[2] = {0, 0};
    MPI_Dims_create(mpi_size,2,dims);
    ndomy = dims[0];
    ndomx = dims[1];

    // TODO: create a 2D non-periodic Cartesian topology using MPI_Cart_create
    int periods[2] = {0, 0};
    MPI_Cart_create(MPI_COMM_WORLD,2,dims,periods,0,&comm_cart);

    // TODO: retrieve coordinates of the rank in the topology using
    // MPI_Cart_coords
    int coords[2] = {0, 0};
    MPI_Cart_coords(comm_cart, mpi_rank , 2 , coords);
    domy = coords[0] + 1;
    domx = coords[1] + 1;

    // TODO: set neighbours for all directions using MPI_Cart_shift
    MPI_Cart_shift(comm_cart, 0 , 1 , &neighbour_north, &neighbour_south);
    MPI_Cart_shift(comm_cart, 1 , 1 , &neighbour_west, &neighbour_east);

    // get Cartesian coordinates, but use 0-based versions for computations
    int coord_y = coords[0];
    int coord_x = coords[1];

    // distribute grid points in x direction
    int base_nx = discretization.nx / ndomx;
    int rem_x   = discretization.nx % ndomx;

    nx = base_nx + (coord_x < rem_x ? 1 : 0);

    startx = coord_x * base_nx + std::min(coord_x, rem_x);
    endx   = startx + nx - 1;

    // distribute grid points in y direction
    int base_ny = discretization.nx / ndomy;
    int rem_y   = discretization.nx % ndomy;

    ny = base_ny + (coord_y < rem_y ? 1 : 0);

    starty = coord_y * base_ny + std::min(coord_y, rem_y);
    endy   = starty + ny - 1;

    // get total number of grid points in this sub-domain
    N = nx*ny;

    rank = mpi_rank;
    size = mpi_size;
}

// print domain decomposition information to stdout
void SubDomain::print() {
    for (int irank = 0; irank < size; irank++) {
        if (irank == rank) {
            std::cout << "rank " << rank << " / " << size
                      << " : (" << domx << ", " << domy << ")"
                      << " neigh N:S " << neighbour_north
                      << ":"           << neighbour_south
                      << " neigh E:W " << neighbour_east
                      << ":"           << neighbour_west
                      << " local dims " << nx << " x " << ny
                      << std::endl;
        }
        MPI_Barrier(MPI_COMM_WORLD);
    }
}

}
