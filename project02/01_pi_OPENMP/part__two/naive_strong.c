#include <stdio.h> /* printf */
#include <stdlib.h> /* strtoull */
#include <stdint.h> /* uint64_t */
#include <inttypes.h> /* PRIu64 */
#include "walltime.h"
#include <omp.h>

int main(int argc, char *argv[]) {
  uint64_t N = 1000000000;
  double time_start, h, sum, pi;

  int n_threads_list[7] = {1 , 2, 4, 8, 16, 32, 64};
  double time_list[7];
  double x;

  if ( argc > 1 ) N = strtoull(argv[1], NULL, 10);;

  
  // STRONG SCALING TEST
  for(int i = 0; i < 7; i++) 
  {
    omp_set_num_threads(n_threads_list[i]);
    time_start = walltime();
    h = 1./N;
    sum = 0.;
    pi = 0.;
    #pragma omp parallel for
    for (uint64_t i = 0; i < N; ++i) 
    {
      double x = (i + 0.5) * h;
      double term = 4.0 / (1.0 + x*x);

      #pragma omp critical
      pi += term;
    }
    pi *= h;

    double time = walltime() - time_start;
    time_list[i] = time;
  }



  printf("# pi N num_threads time [secs]\n");
  for(int i = 0; i < 7; i++) {
    printf("%.15f %20"PRIu64" %3d %.8f\n", pi, N, n_threads_list[i], time_list[i]);
  }
  
  return 0;
}
