#include <cmath>
#include <cstdio>

#include <functional>
#include <iostream>
#include <string>

#include <cuda_runtime.h>

#define SIZE 4096U * 4096U

// typedef for real type
typedef float real_t;

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

// fill constant value in a vector x
__global__ void hpc_fill(real_t* x, const real_t value, const size_t N) {
    int thread = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; thread < N; thread += stride) {
        x[thread] = value;
    }
}

////////////////////////////////////////////////////////////////////////////////
//  dot product implementations
////////////////////////////////////////////////////////////////////////////////

// computes the inner product of x and y
// x and y are vectors of length N
__global__ void hpc_dot(real_t* const x, real_t* const y, real_t* result,
                        size_t const N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (; i < N; i += stride) {
        atomicAdd(result, x[i] * y[i]);
    }
}


int main(int argc, char* argv[]) {

    const int warmup = 5, timed = 25;

    real_t *d_x, *d_y, *d_result;
    cudaMalloc(&d_x, SIZE * sizeof(real_t));
    cudaMalloc(&d_y, SIZE * sizeof(real_t));
    cudaMalloc(&d_result, sizeof(real_t));

    cudaMemset(d_result, 0, sizeof(real_t));

    int threads = 256;
    int blocks = 7*68;

    /* Fill data into arrays */
    real_t constant_x = 1;
    real_t constant_y = 1;

    hpc_fill<<<(SIZE + threads - 1) / threads, threads>>>(d_x, constant_x, SIZE);
    hpc_fill<<<(SIZE + threads - 1) / threads, threads>>>(d_y, constant_y, SIZE);
    cudaDeviceSynchronize();

    // Benchmark hpc_dot
    benchmark_kernel(
        "hpc_dot",
        [&]() {
            cudaMemset(d_result, 0, sizeof(real_t));
            hpc_dot<<<blocks, threads>>>(d_x, d_y, d_result, SIZE);
        },
        warmup,
        timed,
        2 * SIZE,
        2 * SIZE * sizeof(real_t)
    );

    real_t result = 0;
    cudaMemcpy(&result,
               d_result,
               sizeof(real_t),
               cudaMemcpyDeviceToHost);

    std::cout << "Got: " << (unsigned)result << ", expected: "  << SIZE
              << std::endl;

    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_result);

    return 0;
}
