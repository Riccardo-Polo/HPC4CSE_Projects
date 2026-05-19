#include <algorithm> // for std::max
#include <cmath>     // for std::abs
#include <iostream>  // for std::cout and std::cerr
#include <limits>    // for std::numeric_limits<T>::epsilon
#include <cuda_runtime.h> // for CUDA API

// computes the maximum in vector x
// x is a vector of length N
// naive version
__global__ void vec_max_naive(const int *x, int *max_val, int N) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < N) {
    atomicMax(max_val, x[i]);
  }
}

// grid-stride version
__global__ void vec_max_gridstride(const int *x, int *max_val, int N) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;

  int max_local = INT_MIN;

  while (i < N) {
    max_local = max(max_local, x[i]); // using max in CUDA API
    i += stride;
  }

  atomicMax(max_val, max_local);
}

int main(int argc, char* argv[]) {
  // Size of vectors
  const int N = 512;
  // Host copy of vector a (i.e., living on "CPU")
  int *a;
  // Host copy of maximum in vector
  int max;
  // Device copy of vector a (with arbitrary convention d_*) (i.e.,
  // living on "GPU")
  int *d_a;
  // Device copy of maximum in vector
  int *d_max;

  // Allocate vector on host and initialize
  a = (int *)malloc(N * sizeof(int));

  // Initialize vectors on host
  for (int i = 0; i < N; ++i) {
    a[i] = i * 10;
  }

  // Allocate vector and maximum on device
  cudaMalloc((void **)&d_a, N * sizeof(int));
  cudaMalloc((void **)&d_max, sizeof(int));

  // Copy host vector to device vector
  cudaMemcpy(d_a, a, N * sizeof(int), cudaMemcpyHostToDevice);

  // Launch "naive" kernel on device
  int threads = 256;
  int blocks = (N + threads - 1) / threads;
  // "threads" threads will execute vec_max_naive as a block on a SM
  // "blocks" blocks of threads execute as a grid on the device
  vec_max_naive<<<blocks, threads>>>(d_a, d_max, N);

  // Copy device maximum to host
  cudaMemcpy(&max, d_max, sizeof(int), cudaMemcpyDeviceToHost);

  // Check result for naive version
  int max_check = INT_MIN;
  for (int i = 0; i < N; ++i) {
    max_check = std::max(max_check, a[i]);
  }
  if (max == max_check) {
    std::cout << "Results match for naive version! "
              << "GPU computation is correct :-).\n";
  } else {
    std::cerr << "Results do not match for naive version :-(!\n";
  }

  // Launch "grid-stride" kernel on device
  threads = 256;
  blocks = 7 * 68; // 7 x (#SMs on RTX 2080 Ti)
  // "threads" threads will execute vec_max_gridstride as a block on a SM
  // "blocks" blocks of threads execute as a grid on the device
  cudaMemset(d_max, 0, sizeof(int)); // reset maximum on device
  vec_max_gridstride<<<blocks, threads>>>(d_a, d_max, N);

  // Check result for grid-stride version
  if (max == max_check) {
    std::cout << "Results match for grid-stride version! "
              << "GPU computation is correct :-).\n";
  } else {
    std::cerr << "Results do not match for grid-stride version :-(!\n";
  }
  // Deallocate device vector and maximum
  cudaFree(d_a); cudaFree(d_max);

  // Deallocate host vector
  free(a);

  return 0;
}
