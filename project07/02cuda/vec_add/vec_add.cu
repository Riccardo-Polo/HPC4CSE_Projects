#include <cmath>    // for std::abs
#include <iostream> // for std::cout and std::cerr
#include <limits>   // for std::numeric_limits<T>::epsilon
#include <cuda_runtime.h> // for CUDA API

// Kernel definition
__global__ void vec_add(const float* a, const float* b, float* c, int N) {
  // Compute index with CUDA built-in variables blockIdx, blockDim and threadIdx
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  // Avoid out-of-bound
  if (i < N) {
    c[i] = a[i] + b[i];
  }
}

int main(int argc, char* argv[]) {
  // Size of vectors
  const int N = 512;
  // Host copies of vectors a, b, c (i.e., living on "CPU")
  float *a, *b, *c;
  // Device copies of vectors a, b, c (with arbitrary convention d_*) (i.e.,
  // living on "GPU")
  float *d_a, *d_b, *d_c;

  // Allocate vectors on host and initialize
  a = (float *)malloc(N * sizeof(float));
  b = (float *)malloc(N * sizeof(float));
  c = (float *)malloc(N * sizeof(float));

  // Initialize vectors on host
  for (int i = 0; i < N; ++i) {
    a[i] = i; b[i] = N - i; c[i] = 0.;
  }

  // Allocate vectors on device
  cudaMalloc((void **)&d_a, N * sizeof(float));
  cudaMalloc((void **)&d_b, N * sizeof(float));
  cudaMalloc((void **)&d_c, N * sizeof(float));

  // Copy host vectors to device vectors
  cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_b, b, N * sizeof(float), cudaMemcpyHostToDevice);

  // Launch kernel on device
  int threads = 256;
  int blocks = (N + threads - 1) / threads;
  // "threads" threads will execute vec_add as a block on a SM
  // "blocks" blocks of threads execute as a grid on the device
  vec_add<<<blocks, threads>>>(d_a, d_b, d_c, N);

  // Copy device result c vector to host
  cudaMemcpy(c, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

  // Check results
  bool success = true;
  float feps = std::numeric_limits<float>::epsilon();
  for (int i = 0; i < N; ++i) {
    if (std::abs(a[i] + b[i] - c[i]) > feps) {
      std::cerr << "Mismatch at index " << i << ": GPU result " << c[i]
                << ", expected " << a[i] + b[i] << "\n";
      success = false;
    }
  }
  if (success) {
    std::cout << "Results match! GPU computation is correct :-).\n";
  } else {
    std::cerr << "Results do not match :-(!\n";
  }

  // Deallocate device vectors
  cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);

  // Deallocate host vectors
  free(a); free(b); free(c);

  return 0;
}
