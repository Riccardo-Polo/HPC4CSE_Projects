#include "walltime.h"
#include <iostream>
#include <random>
#include <vector>
#include <omp.h>
#include <fstream>
#include <iomanip>
#include <limits>

#define VEC_SIZE 1000000000
#define BINS 16

int main() {
  const int nrepeat = 10;
  const std::vector<int> thread_counts = {1, 2, 4, 8, 16, 32, 64};

  // Initialize random number generator
  unsigned int seed = 123;
  float mean = BINS / 2.0;
  float sigma = BINS / 12.0;
  std::default_random_engine generator(seed);
  std::normal_distribution<float> distribution(mean, sigma);

  // Generate random sequence once
  std::vector<int> vec(VEC_SIZE);
  for (long i = 0; i < VEC_SIZE; ++i) {
    vec[i] = int(distribution(generator));
    if (vec[i] < 0) vec[i] = 0;
    if (vec[i] > BINS - 1) vec[i] = BINS - 1;
  }

  std::ofstream raw_file("timing_hist_omp_strong.data");
  std::ofstream summary_file("timing_hist_omp_strong_summary.data");

  raw_file << "# threads run time_sec\n";
  summary_file << "# threads avg_time min_time max_time\n";

  raw_file << std::fixed << std::setprecision(8);
  summary_file << std::fixed << std::setprecision(8);

  for (int nth : thread_counts) {
    omp_set_num_threads(nth);

    double sum_time = 0.0;
    double min_time = std::numeric_limits<double>::max();
    double max_time = 0.0;

    for (int r = 0; r < nrepeat; ++r) {
      long dist[BINS];
      for (int i = 0; i < BINS; ++i) {
        dist[i] = 0;
      }

      std::vector<std::vector<long>> local_hist(nth, std::vector<long>(BINS, 0));

      double time_start = walltime();

      #pragma omp parallel
      {
        int tid = omp_get_thread_num();

        #pragma omp for schedule(static)
        for (long i = 0; i < VEC_SIZE; ++i) {
          local_hist[tid][vec[i]]++;
        }
      }

      for (int t = 0; t < nth; ++t) {
        for (int b = 0; b < BINS; ++b) {
          dist[b] += local_hist[t][b];
        }
      }

      double elapsed = walltime() - time_start;

      raw_file << nth << " " << r << " " << elapsed << "\n";

      sum_time += elapsed;
      if (elapsed < min_time) min_time = elapsed;
      if (elapsed > max_time) max_time = elapsed;
    }

    double avg_time = sum_time / nrepeat;
    summary_file << nth << " " << avg_time << " " << min_time << " " << max_time << "\n";
  }

  raw_file.close();
  summary_file.close();

  return 0;
}