#include "walltime.h"
#include <iostream>
#include <random>
#include <vector>
#include <omp.h>
#include <cstdlib>
#include <iomanip>
#include <limits>

#define BINS 16

int main(int argc, char** argv) {
  long N = 1000000000;
  int nrepeat = 5;

  if (argc > 1) N = std::atol(argv[1]);
  if (argc > 2) nrepeat = std::atoi(argv[2]);

  // Initialize random number generator
  unsigned int seed = 123;
  float mean = BINS / 2.0;
  float sigma = BINS / 12.0;
  std::default_random_engine generator(seed);
  std::normal_distribution<float> distribution(mean, sigma);

  // Generate random sequence once
  std::vector<int> vec(N);
  for (long i = 0; i < N; ++i) {
    vec[i] = int(distribution(generator));
    if (vec[i] < 0) vec[i] = 0;
    if (vec[i] > BINS - 1) vec[i] = BINS - 1;
  }

  double avg_time = 0.0;
  double min_time = std::numeric_limits<double>::max();
  double max_time = 0.0;
  long checksum = 0;

  for (int r = 0; r < nrepeat; ++r) {
    int nthreads = omp_get_max_threads();

    long dist[BINS];
    for (int i = 0; i < BINS; ++i) dist[i] = 0;

    std::vector<std::vector<long>> local_hist(nthreads, std::vector<long>(BINS, 0));

    double time_start = walltime();

    #pragma omp parallel
    {
      int tid = omp_get_thread_num();

      #pragma omp for
      for (long i = 0; i < N; ++i) {
        local_hist[tid][vec[i]]++;
      }
    }

    for (int t = 0; t < nthreads; ++t) {
      for (int b = 0; b < BINS; ++b) {
        dist[b] += local_hist[t][b];
      }
    }

    double elapsed = walltime() - time_start;

    avg_time += elapsed;
    if (elapsed < min_time) min_time = elapsed;
    if (elapsed > max_time) max_time = elapsed;

    checksum = 0;
    for (int b = 0; b < BINS; ++b) checksum += dist[b];
  }

  avg_time /= nrepeat;

  std::cout << std::fixed << std::setprecision(8);
  std::cout << "# columns: checksum N num_threads avg_time min_time max_time\n";
  std::cout << checksum << " "
            << N << " "
            << omp_get_max_threads() << " "
            << avg_time << " "
            << min_time << " "
            << max_time << "\n";

  return 0;
}
