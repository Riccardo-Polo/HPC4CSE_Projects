#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "consts.h"
#include "ppmwriter.h"
#include "walltime.h"

int main(int argc, char **argv) {
  ppm_data_t pPpm;
  ppm_create(&pPpm, IMAGE_WIDTH, IMAGE_HEIGHT);

  double fDeltaX = (MAX_X - MIN_X) / (double)IMAGE_WIDTH;
  double fDeltaY = (MAX_Y - MIN_Y) / (double)IMAGE_HEIGHT;

  long nTotalIterationsCount = 0;

  double time_start = walltime();
  // do the calculation
  #pragma omp parallel for reduction(+:nTotalIterationsCount) schedule(dynamic)
  for (long j = 0; j < IMAGE_HEIGHT; j++) {
    double cy = MIN_Y + j * fDeltaY;

    for (long i = 0; i < IMAGE_WIDTH; i++) {
      double cx = MIN_X + i * fDeltaX;

      double x = cx;
      double y = cy;
      double x2 = x * x;
      double y2 = y * y;

      int n = 0;
      while (x2 + y2 <= 4.0 && n < MAX_ITERS) {
        y = 2.0 * x * y + cy;
        x = x2 - y2 + cx;
        x2 = x * x;
        y2 = y * y;
        n++;
      }

      nTotalIterationsCount += n;

      int c = ((long)n * 255) / MAX_ITERS;
      ppm_plot(&pPpm, i, j, c, c, c);
    }
  }
  double time_end = walltime();

  // print benchmark data
  printf("Total time:                 %g seconds\n",
         (time_end - time_start));
  printf("Image size:                 %ld x %ld = %ld Pixels\n",
         (long)IMAGE_WIDTH, (long)IMAGE_HEIGHT,
         (long)(IMAGE_WIDTH * IMAGE_HEIGHT));
  printf("Total number of iterations: %ld\n", nTotalIterationsCount);
  printf("Avg. time per pixel:        %g seconds\n",
         (time_end - time_start) / (double)(IMAGE_WIDTH * IMAGE_HEIGHT));
  printf("Avg. time per iteration:    %g seconds\n",
         (time_end - time_start) / (double)nTotalIterationsCount);
  printf("Iterations/second:          %g\n",
         nTotalIterationsCount / (time_end - time_start));
  // assume there are 8 floating point operations per iteration
  printf("MFlop/s:                    %g\n",
         nTotalIterationsCount * 8.0 / (time_end - time_start) * 1.e-6);

  ppm_write(&pPpm, "mandel.ppm");
  return 0;
}