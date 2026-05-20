#include <iostream>
#include <functional>
#include <string>

#include <cuda_runtime.h>

#include "linalg.h"

#define SIZE 8388608

void benchmark_kernel(const std::string&            name,
                      const std::function<void()>&  launch,
                      int                           warmup_runs,
                      int                           timed_runs,
                      int                           FLOPS,
                      int                           Bytes) {
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warmup
    for (int i = 0; i < warmup_runs; ++i) {
        launch();
    }
    cudaDeviceSynchronize();

    // Benchmarks
    cudaEventRecord(start);
    for (int i = 0; i < timed_runs; ++i) {
        launch();
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    float avg = ms / timed_runs;
    std::cout << "[benchmark] " << name
              << ": warmup=" << warmup_runs
              << " runs="   << timed_runs
              << " avg_time=" << avg << " ms\n"
              << "Compute utilization = " << (FLOPS / 1e9) / (avg / 1e3)
                                          << " GFLOPS/s\n"
              << "Memory utilization = " << (Bytes/1e9) / (avg / 1e3)
                                         << " GB/s"
              << std::endl;
}

void printFirstLast(const real_t* d_arr, size_t N, const real_t expected) {

    if (N == 0) {
        std::cout << "Array is empty\n";
        return;
    }

    real_t first = 0.0, last = 0.0;

    cudaMemcpy(&first,
               d_arr,
               sizeof(real_t),
               cudaMemcpyDeviceToHost);

    cudaMemcpy(&last,
               d_arr + (N-1),
               sizeof(real_t),
               cudaMemcpyDeviceToHost);

    std::cout << "first = " << first
              << ", last = "  << last
              << ", expected = " << expected << "\n";
}

int main(int argc, char* argv[]) {

    const int warmup = 5, timed = 25;

    real_t *d_x, *d_y, *d_z;
    real_t *d_l, *d_r;
    real_t alpha=0.1, beta=0.2;

    real_t *d_result;
    cudaMalloc(&d_result, sizeof(real_t));
    cudaMemset(d_result, 0, sizeof(real_t));

    int threads = 256;
    int blocks = (SIZE + threads - 1) / threads;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    /* Allocate Memory */
    cudaMalloc(&d_x, SIZE * sizeof(real_t));
    cudaMalloc(&d_y, SIZE * sizeof(real_t));
    cudaMalloc(&d_z, SIZE * sizeof(real_t));
    cudaMalloc(&d_l, SIZE * sizeof(real_t));
    cudaMalloc(&d_r, SIZE * sizeof(real_t));

    /* Fill data into arrays */
    real_t constant_x = 1;
    real_t constant_y = 1;
    real_t constant_z = 7;
    real_t constant_l = 10;
    real_t constant_r = 4;

    hpc_fill<<<blocks, threads>>>(d_x, constant_x, SIZE);
    hpc_fill<<<blocks, threads>>>(d_y, constant_y, SIZE);
    hpc_fill<<<blocks, threads>>>(d_z, constant_z, SIZE);
    hpc_fill<<<blocks, threads>>>(d_l, constant_l, SIZE);
    hpc_fill<<<blocks, threads>>>(d_r, constant_r, SIZE);


    /* Benchmark kernels */
    benchmark_kernel("axpy",
        [&](){
            hpc_axpy<<<blocks, threads>>>(
                d_y, alpha, d_x, SIZE
            );
        }, warmup, timed, 2*SIZE, 3*SIZE*sizeof(real_t)
    );

    printFirstLast(d_y, SIZE, (warmup+timed) * alpha * constant_x + constant_y);

    // y is modified
    hpc_fill<<<blocks, threads>>>(d_y, constant_y, SIZE);

    benchmark_kernel("add scaled diff",
        [&](){
            hpc_add_scaled_diff<<<blocks, threads>>>(
                d_y, d_x, alpha, d_l, d_r, SIZE
            );
        }, warmup, timed, 3*SIZE, 4*SIZE*sizeof(real_t)
    );

    printFirstLast(d_y, SIZE, constant_x + alpha * (constant_l - constant_r));

    benchmark_kernel("scaled diff",
        [&](){
            hpc_scaled_diff<<<blocks, threads>>>(
                d_y, alpha, d_l, d_r, SIZE
            );
        }, warmup, timed, 2*SIZE, 3*SIZE*sizeof(real_t)
    );

    printFirstLast(d_y, SIZE, alpha * (constant_l - constant_r));

    // y is modified
    hpc_fill<<<blocks, threads>>>(d_y, constant_y, SIZE);

    benchmark_kernel("scale",
        [&](){
            hpc_scale<<<blocks, threads>>>(
                d_y, alpha, d_x, SIZE
            );
        }, warmup, timed, 1*SIZE, 2*SIZE*sizeof(real_t)
    );

    printFirstLast(d_y, SIZE, alpha * constant_x);

    // y is modified
    hpc_fill<<<blocks, threads>>>(d_y, constant_y, SIZE);

    benchmark_kernel("linear combination",
        [&](){
            hpc_lcomb<<<blocks, threads>>>(
                d_y, alpha, d_x, beta, d_z, SIZE
            );
        }, warmup, timed, 3*SIZE, 3*SIZE*sizeof(real_t)
    );

    printFirstLast(d_y, SIZE, alpha * constant_x + beta * constant_z);

    // y is modified
    hpc_fill<<<blocks, threads>>>(d_y, constant_y, SIZE);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
