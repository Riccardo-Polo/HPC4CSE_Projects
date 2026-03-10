#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "walltime.h"
#include <omp.h>
#include <math.h>
/*
  This example is taken from Hager & Wellein (2010), who trace it back to the
  OpenMP mailinglist from 2007:
  https://web.archive.org/web/20080725120007/http://openmp.org/pipermail/omp/2007/000744.html
*/

int main(int argc, char *argv[]) {
  int N = 2000000000;
  double up = 1.00000001;
  double Sn = 1.00000001;
  int n;

  /* allocate memory for the recursion */
  double *opt = (double *)malloc((N + 1) * sizeof(double));
  if (opt == NULL) {
    perror("failed to allocate problem size");
    exit(EXIT_FAILURE);
  }

  double time_start = walltime();
  // TODO: YOU NEED TO PARALLELIZE THIS LOOP
  #pragma omp parallel firstprivate(Sn)
  {
    #pragma omp for
    for (n = 0; n <= N; ++n) {
      opt[n] = pow(up, n);
    }
}
  printf("Parallel RunTime  :  %f seconds\n", walltime() - time_start);
  printf("Final Result Sn   :  %.17g \n", Sn);

  double temp = 0.0;
  for (n = 0; n <= N; ++n) {
    temp += opt[n] * opt[n];
  }
  printf("Result ||opt||^2_2 :  %f\n", temp / (double)N);
  printf("\n");

  return 0;
}
