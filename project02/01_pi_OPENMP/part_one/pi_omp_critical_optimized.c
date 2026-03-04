#include <stdio.h> /* printf */
#include <stdlib.h> /* strtoull */
#include <stdint.h> /* uint64_t */
#include <inttypes.h> /* PRIu64 */
#include "walltime.h"
#include <omp.h>

int main(int argc, char *argv[]) {
  uint64_t N = 1000000000;
  double time_start, h, sum, pi;

  if ( argc > 1 ) N = strtoull(argv[1], NULL, 10);;

  /* Parallelize with OpenMP using the critical directive */
  time_start = walltime();
  h = 1./N;
  sum = 0.;
  pi = 0.0;
  double x;

  #pragma omp parallel
  {
    double sum = 0.0;

    #pragma omp for
    for (uint64_t i = 0; i < N; ++i) {
      double x = (i + 0.5) * h;
      sum += 4.0 / (1.0 + x*x);
    }

    #pragma omp critical
    pi += sum;     // once per thread
  }
  pi *= h;

  double time = walltime() - time_start;

  int nt = omp_get_max_threads(); 
  printf("# pi N num_threads time [secs]\n");
  printf("%.15f %20"PRIu64" %3d %.8f\n", pi, N, nt, time);

  return 0;
}
