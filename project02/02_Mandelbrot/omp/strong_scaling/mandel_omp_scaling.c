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
  double total_time = time_end - time_start;

  /* Machine-friendly output for benchmarking */
  printf("%d %ld %ld %.8f\n",
         omp_get_max_threads(),
         (long)IMAGE_WIDTH,
         (long)IMAGE_HEIGHT,
         total_time);

  /* Write image only if explicitly requested */
  if (argc > 1) {
    ppm_write(&pPpm, "outputs/mandel.ppm");
  }

  return 0;
}