#include <stdio.h> /* printf */
#include <stdlib.h> /* strtoull */
#include <stdint.h> /* uint64_t */
#include <inttypes.h> /* PRIu64 */
#include "walltime.h"

int main(int argc, char *argv[]) {
  uint64_t N = 1000000000;
  double time_start, h, sum, pi;

  if ( argc > 1 ) N = strtoull(argv[1], NULL, 10);;

  /* Parallelize with OpenMP using the reduction clause */
  time_start = walltime();
  h = 1./N;
  sum = 0.;
  for (uint64_t i = 0; i < N; ++i) {
    double x = (i + 0.5)*h;
    sum += 4.0 / (1.0 + x*x);
  }
  pi = sum*h;
  double time = walltime() - time_start;

  printf("# pi N num_threads time [secs]\n");
  printf("%.15f %20"PRIu64" %3d %.8f\n", pi, N, 1, time);

  return 0;
}
