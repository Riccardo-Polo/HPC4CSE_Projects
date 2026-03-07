#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <omp.h>
#include "walltime.h"

#define NTHREADS 7
#define NREPEAT  5

int main(int argc, char *argv[]) {
    const int threads_list[NTHREADS] = {1, 2, 4, 8, 16, 32, 64};

    /* Constant work per thread for weak scaling */
    uint64_t work_per_thread = 50000000ULL;   /* 5e7 */
    if (argc > 1) {
        work_per_thread = strtoull(argv[1], NULL, 10);
    }

    printf("# weak scaling with OpenMP reduction\n");
    printf("# work_per_thread = %" PRIu64 "\n", work_per_thread);
    printf("# N = work_per_thread * num_threads\n");
    printf("# columns: pi N num_threads avg_time min_time max_time\n");

    for (int t = 0; t < NTHREADS; ++t) {
        int nth = threads_list[t];
        uint64_t N = work_per_thread * (uint64_t) nth;

        omp_set_num_threads(nth);

        double h = 1.0 / (double) N;
        double avg_time = 0.0;
        double min_time = 1e100;
        double max_time = 0.0;
        double pi = 0.0;

        /* warm-up run */
        {
            double tmp_sum = 0.0;
            #pragma omp parallel for reduction(+:tmp_sum)
            for (uint64_t i = 0; i < N; ++i) {
                double x = (i + 0.5) * h;
                tmp_sum += 4.0 / (1.0 + x * x);
            }
            pi = tmp_sum * h;
        }

        for (int r = 0; r < NREPEAT; ++r) {
            double time_start = walltime();
            double sum = 0.0;

            #pragma omp parallel for reduction(+:sum)
            for (uint64_t i = 0; i < N; ++i) {
                double x = (i + 0.5) * h;
                sum += 4.0 / (1.0 + x * x);
            }

            pi = sum * h;
            double elapsed = walltime() - time_start;

            avg_time += elapsed;
            if (elapsed < min_time) min_time = elapsed;
            if (elapsed > max_time) max_time = elapsed;
        }

        avg_time /= (double) NREPEAT;

        printf("%.15f %20" PRIu64 " %3d %.8f %.8f %.8f\n",
               pi, N, nth, avg_time, min_time, max_time);
    }

    return 0;
}