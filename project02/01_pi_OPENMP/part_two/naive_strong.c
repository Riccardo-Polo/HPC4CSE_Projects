#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <omp.h>
#include "walltime.h"

/* ORIGINAL */
// #define NTHREADS 7
// #define NREPEAT  5

/* TEMPORARY RECOVERY VERSION: run only the missing 64-thread point once */
#define NTHREADS 1
#define NREPEAT  5
int main(int argc, char *argv[]) {
    /* ORIGINAL */
    // const int threads_list[NTHREADS] = {1, 2, 4, 8, 16, 32, 64};

    /* TEMPORARY RECOVERY VERSION: only missing point */
    const int threads_list[NTHREADS] = {64};

    uint64_t N = 1000000000ULL;
    if (argc > 1) {
        N = strtoull(argv[1], NULL, 10);
    }

    printf("# naive strong scaling with critical at every update\n");
    printf("# columns: pi N num_threads avg_time min_time max_time\n");

    for (int t = 0; t < NTHREADS; ++t) {
        
        int nth = threads_list[t];
        omp_set_num_threads(nth);

        double h = 1.0 / (double) N;
        double avg_time = 0.0;
        double min_time = 1e100;
        double max_time = 0.0;
        double pi = 0.0;

        /* warm-up run */
        {
            double tmp_pi = 0.0;
            #pragma omp parallel for
            for (uint64_t i = 0; i < N; ++i) {
                double x = (i + 0.5) * h;
                double term = 4.0 / (1.0 + x * x);

                #pragma omp critical
                tmp_pi += term;
            }
            pi = tmp_pi * h;
        }

        for (int r = 0; r < NREPEAT; ++r) {
            double sum = 0.0;
            double start = walltime();

            #pragma omp parallel for
            for (uint64_t i = 0; i < N; ++i) {
                double x = (i + 0.5) * h;
                double term = 4.0 / (1.0 + x * x);

                #pragma omp critical
                sum += term;
            }

            double elapsed = walltime() - start;
            pi = sum * h;

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
