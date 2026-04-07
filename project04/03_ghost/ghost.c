/****************************************************************
 *                                                              *
 * This file has been written as a sample solution to an        *
 * exercise in a course given at the CSCS-USI Summer School     *
 * It is made freely available with the understanding that      *
 * every copy of this file must include this header and that    *
 * CSCS/USI take no responsibility for the use of the enclosed  *
 * teaching material.                                           *
 *                                                              *
 * Purpose: Exchange ghost cell in 2 directions using a topology*
 *                                                              *
 * Contents: C-Source                                           *
 *                                                              *
 ****************************************************************/

/* Use only 12 processes for this exercise
 * Send the ghost cell in two directions: west<->east and north<->south
 * ranks are connected in a cyclic manner, for instance, rank 0 and 12 are
 * connected
 *
 * process decomposition on 3 * 4 grid
 *
 * |--------|
 * | 3| 7|11|
 * |--------|
 * | 2| 6|10|
 * |--------|
 * | 1| 5| 9|
 * |--------|
 * | 0| 4| 8|
 * |--------|
 *
 * Each process works on a 6*6 (SUBDOMAIN) block of data
 * the D corresponds to data, g corresponds to "ghost cells"
 * x g g g g g g x
 * g D D D D D D g
 * g D D D D D D g
 * g D D D D D D g
 * g D D D D D D g
 * g D D D D D D g
 * g D D D D D D g
 * x g g g g g g x
 */

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define SUBDOMAIN 6
#define DOMAINSIZE (SUBDOMAIN+2)

int main(int argc, char *argv[]) {
    int rank, size, i, j, dims[2], periods[2], rank_north, rank_south,
        rank_west, rank_east;
    double data[DOMAINSIZE*DOMAINSIZE];
    MPI_Request request;
    MPI_Status status;
    MPI_Comm comm_cart;
    MPI_Datatype data_ghost;

    // Initialize MPI
    MPI_Init(&argc, &argv);

    // Get size and rank
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size!=12) {
        printf("Please run this with 12 processors\n");
        MPI_Finalize();
        exit(1);
    }

    // initialize the domain
    for (i=0; i<DOMAINSIZE; i++) {
        for (j=0; j<DOMAINSIZE; j++) {
            data[j + i * DOMAINSIZE] = rank;
        }
    }
    // set corners to dummy value
    data[(0             ) + (0             ) * DOMAINSIZE] = -1;
    data[(0             ) + (DOMAINSIZE - 1) * DOMAINSIZE] = -1;
    data[(DOMAINSIZE - 1) + (0             ) * DOMAINSIZE] = -1;
    data[(DOMAINSIZE - 1) + (DOMAINSIZE - 1) * DOMAINSIZE] = -1;

    // TODO: set the dimensions of the processor grid and periodic boundaries
    // in both dimensions 
    dims[0]= 3;
    dims[1]= 4;
    periods[0]= 1;
    periods[1]= 1;

    // TODO: Create a Cartesian communicator (3*4) with periodic boundaries and
    //       use it to find your neighboring ranks in all dimensions in a
    //       cyclic manner. Use MPI_Cart_create for example.
    MPI_Comm comm_cart;
    MPI_Cart_create(MPI_COMM_WORLD, 2 ,dims , periods , 0 , &comm_cart);
    
    // TODO: find your North/South/West/East neighbor using the new
    //       communicator, see MPI_Cart_shift()
    MPI_Cart_shift(comm_cart, 0 , 1 , &rank_north , &rank_south);
    MPI_Cart_shift(comm_cart, 1 , 1 , &rank_west , &rank_east);

    // TODO: create derived datatype data_ghost, create a datatype for sending
    //       the column, see MPI_Type_vector() and MPI_Type_commit()

    MPI_Datatype data_ghost;
    MPI_Type(DOMAINSIZE ,1 , DOMAINSIZE , MPI_DOUBLE , &data_ghost);
    MPI_Type_commit(&data_ghost);

    // TODO: ghost cell exchange with the neighbouring cells in all directions
    //        Use MPI_Sendrecv for example.

    // Send my top row to north, receive from south into bottom ghost row
    MPI_Sendrecv(&data[DOMAINSIZE], DOMAINSIZE, MPI_DOUBLE, rank_north, 0,
                 &data[DOMAINSIZE*(DOMAINSIZE-1)], DOMAINSIZE, MPI_DOUBLE, rank_south, 0,
                 comm_cart, MPI_STATUS_IGNORE);

    // Send my bottom row to south, receive from north into top ghost row
    MPI_Sendrecv(&data[DOMAINSIZE*(DOMAINSIZE-2)], DOMAINSIZE, MPI_DOUBLE, rank_south, 0,
                 &data[0], DOMAINSIZE, MPI_DOUBLE, rank_north, 0,
                 comm_cart, MPI_STATUS_IGNORE);

    // Send my right col to east, receive from west into left ghost col
    MPI_Sendrecv(&data[DOMAINSIZE-2], 1 , data_ghost , rank_east, 0,
                 &data[0], 1 , data_ghost , rank_west, 0,
                 comm_cart, MPI_STATUS_IGNORE);

    // Send my left col to west, receive from east into right ghost col
    MPI_Sendrecv(&data[1], 1 , data_ghost , rank_west, 0,
                 &data[DOMAINSIZE-1], 1 , data_ghost , rank_east, 0,
                 comm_cart, MPI_STATUS_IGNORE);
    
    // print
    int io_rank = 5;
    if (rank == io_rank) {
        printf("North rank %d, South rank %d, West rank %d, East rank %d\n",
               rank_north, rank_south, rank_west, rank_east);
        printf("data of rank %d after communication\n", io_rank);
        printf("j\n");
        printf("^\n");
        for (j=DOMAINSIZE-1; j>=0; j--) {
            printf("| ");
            for (i=0; i<DOMAINSIZE; i++) {
                printf("%4.1f ", data[j+i*DOMAINSIZE]);
            }
            printf("\n");
        }
        printf("--");
        for (i=0; i<DOMAINSIZE; i++) printf("-----");
        printf("> i\n");
    }

    // Free MPI resources (e.g., types and communicators)
    // TODO
    MPI_Type_free(&data_ghost);
    MPI_Comm_free(&comm_cart);

    // Finalize MPI
    MPI_Finalize();

    return 0;
}
