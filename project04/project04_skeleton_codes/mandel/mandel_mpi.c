#include <stdio.h>
#include <stdlib.h>

#include <mpi.h> // MPI

#include "consts.h"
#include "ppmwriter.h"
#include "walltime.h"

#define INDEX(x, y, lda) (y*lda + x)

int main(int argc, char** argv) {

  // Initialize MPI
  MPI_Init(&argc, &argv);

  // Get size and rank
  int mpi_rank, mpi_size;
  MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);
  MPI_Comm_size(MPI_COMM_WORLD, &mpi_size);

  // Create partitioning of the image
  // determine 2D dimensions of the grid of processes
  Partition p = createPartition(mpi_rank, mpi_size);

  // Compute the local domain size and boundaries
  // determine 2D dimensions of the local portion of the image
  Domain d = createDomain(p); 

  if (mpi_rank == 0) printf("Processor grid size (%d, %d)\n", p.nx, p.ny);
  printf("[Process %d] Coordinates: [%d, %d]\n", mpi_rank, p.x, p.y);
  printf("[Process %d] Domain X   : %ld -> %ld\n", mpi_rank, d.startx, d.endx);
  printf("[Process %d] Domain Y   : %ld -> %ld\n", mpi_rank, d.starty, d.endy);

  /****************************************************************************/
  // create image at the MASTER only
  ppm_data_t pPpm;
  if (mpi_rank == 0) {
    ppm_create(&pPpm, IMAGE_WIDTH, IMAGE_HEIGHT);
  }

  // Compute the global domain parameters
  double fDeltaX = (MAX_X - MIN_X) / (double) IMAGE_WIDTH;
  double fDeltaY = (MAX_Y - MIN_Y) / (double) IMAGE_HEIGHT;

  // Allocate local image data
  int *c;
  if (mpi_rank == 0) {
    //allocate extra space at master
    int extrax = IMAGE_WIDTH % p.nx;
    int extray = IMAGE_HEIGHT % p.ny;
    c = malloc((d.nx + extrax) * (d.ny + extray) * sizeof(int));
  } else {
    c = malloc(d.nx*d.ny*sizeof(int));
  }

  /****************************************************************************/
  double time_start = walltime();
  // do the calculation
  double x, y, x2, y2, cx, cy;
  long nTotalIterationsCount = 0;
  long i, j;
  cy = MIN_Y + d.starty*fDeltaY;
  for (j = 0; j < d.ny; j++) {
    cx = MIN_X + d.startx*fDeltaX;
    for (i = 0; i < d.nx; i++) {
      x = cx;
      y = cy;
      x2 = x * x;
      y2 = y * y;
      // compute the orbit z, f(z), f^2(z), f^3(z), ...
      // count the iterations until the orbit leaves the circle |z|=2.
      // stop if the number of iterations exceeds the bound MAX_ITERS.
      int n = 0;
      for ( ; x2 + y2 < 4 && n < MAX_ITERS; n++, nTotalIterationsCount++) {
        // z = z^2 + c, where z = x + iy, c = cx + icy
        y = 2 * x * y + cy;
        x = x2 - y2 + cx;

        x2 = x * x;
        y2 = y * y;
      }
      // write the local pixel [i,j] -> j*d.ny + i
      c[INDEX(i,j,d.nx)] = ((long)n * 255) / MAX_ITERS;
      cx += fDeltaX;
    }
    cy += fDeltaY;
  }

  // Send the data to the master
  if (mpi_rank != 0) {
    // TODO: send local partition c to the master process
    // printf("[Process %d] Sending partition %d of size %ld\n",
    //        mpi_rank, mpi_rank, d.nx*d.ny);
  }
  /****************************************************************************/
  // Write the image
  if (mpi_rank == 0) {
    // first write master's own data
    for (j = 0; j < d.ny; j++) {
      for (i = 0; i < d.nx; i++) {
        int c_ij = c[INDEX(i,j,d.nx)];
        ppm_plot(&pPpm, i+d.startx, j+d.starty, c_ij, c_ij, c_ij);
      }
    }

    // receive and write the data from other processes
    for (int proc = 1; proc < mpi_size; proc++) {
      Partition p1 = updatePartition(p, proc);
      Domain d1 = createDomain(p1);

      // TODO: receive partition of the process proc into array c (overwrite
      //       its data)
      // printf("[MASTER] Receiving partition %d of size %ld\n",
      //        proc, d1.nx*d1.ny);

      // write the partition of the process proc
      for (j = 0; j < d1.ny; j++) {
        for (i = 0; i < d1.nx; i++) {
          int c_ij = c[INDEX(i,j,d1.nx)];
          ppm_plot(&pPpm, i+d1.startx, j+d1.starty, c_ij ,c_ij, c_ij);
        }
      }
    }
  }
  double time_end = walltime();

  // print benchmark data
  printf("[Process %d] Total time                : %g seconds\n",
         mpi_rank, (time_end - time_start));
  printf("[Process %d] Image size                : %ld x %ld = %ld Pixels\n",
         mpi_rank, (long) d.nx, (long) d.ny, (long) (d.nx * d.ny));
  printf("[Process %d] Total number of iterations: %ld\n",
         mpi_rank, nTotalIterationsCount);
  printf("[Process %d] Avg. time per pixel       : %g seconds\n",
         mpi_rank, (time_end - time_start) / (double) (d.nx * d.ny));
  printf("[Process %d] Avg. time per iteration   : %g seconds\n",
         mpi_rank, (time_end - time_start) / (double) nTotalIterationsCount);
  printf("[Process %d] Iterations/second         : %g\n",
         mpi_rank, nTotalIterationsCount / (time_end - time_start));
  // assume there are 8 floating point operations per iteration
  printf("[Process %d] MFlop/s                   : %g\n",
         mpi_rank, nTotalIterationsCount * 8.0 / (time_end - time_start)*1.e-6);

  if (mpi_rank == 0) ppm_write(&pPpm, "mandel.ppm");

  // Free and finalize MPI
  //MPI_Comm_free(&p.comm); TODO: uncomment after you implement createPartition
  free(c);
  MPI_Finalize();

  return 0;
}
