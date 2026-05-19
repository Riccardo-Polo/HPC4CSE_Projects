#include <cmath>    // for std::abs
#include <iostream> // for std::cout and std::cerr
#include <limits>   // for std::numeric_limits<T>::epsilon
#include <cuda_runtime.h> // for CUDA API

// Kernel definition
__global__ void mat_add(const float *A, const float *B, float *C, int N) {
  // Compute index with CUDA built-in variables blockIdx, blockDim and threadIdx
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  int j = blockIdx.y * blockDim.y + threadIdx.y;
  // Avoid out-of-bound
  if (i < N && j < N) {
    C[j * N + i] = A[j * N + i] + B[j * N + i]; // column-major ordering
  }
}

int main(int argc, char* argv[]) {
  // Size of vectors
  const int N = 512;
  // Host copies of square Matrices A, B, C (i.e., living on "CPU")
  float *A, *B, *C;
  // Device copies of square matrices A, B, C (with arbitrary convention d_*)
  // (i.e., living on "GPU")
  float *d_A, *d_B, *d_C;

  // Allocate matrices on host and initialize
  A = (float *)malloc(N * N * sizeof(float));
  B = (float *)malloc(N * N * sizeof(float));
  C = (float *)malloc(N * N * sizeof(float));

  // Initialize matrices on host (column-major ordering)
  for (int j = 0; j < N; ++j) {
    for (int i = 0; i < N; ++i) {
      A[j * N + i] = i + j;
      B[j * N + i] = N - i + j;
      C[j * N + i] = 0.;
    }
  }

  // Allocate vectors on device
  cudaMalloc((void **)&d_A, N * N * sizeof(float));
  cudaMalloc((void **)&d_B, N * N * sizeof(float));
  cudaMalloc((void **)&d_C, N * N * sizeof(float));

  // Copy host vectors to device vectors
  cudaMemcpy(d_A, A, N * N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, B, N * N * sizeof(float), cudaMemcpyHostToDevice);

  // Launch kernel on device
  dim3 threads(16, 16);
  dim3 blocks((N + threads.x - 1) / threads.x,
              (N + threads.y - 1) / threads.y);
  // "threads.x * threads.y" threads will execute mat_add as a block on a SM
  // "blocks.x * blocks.y" blocks of threads execute as a grid on the device
  mat_add<<<blocks, threads>>>(d_A, d_B, d_C, N);

  // Copy device result C matrix to host
  cudaMemcpy(C, d_C, N * N * sizeof(float), cudaMemcpyDeviceToHost);

  // Check results
  bool success = true;
  float feps = std::numeric_limits<float>::epsilon();
  for (int j = 0; j < N; ++j) {
    for (int i = 0; i < N; ++i) {
      int idx = j * N + i;
      if (std::abs(A[idx] + B[idx] - C[idx]) > feps) {
        std::cerr << "Mismatch at index (" << i << ", " << j << ") "
                  << ": GPU result " << C[idx]
                  << ", expected " << A[idx] + B[idx] << "\n";
        success = false;
      }
    }
  }
  if (success) {
    std::cout << "Results match! GPU computation is correct :-).\n";
  } else {
    std::cerr << "Results do not match :-(!\n";
  }

  // Deallocate device matrices
  cudaFree(d_A); cudaFree(d_B); cudaFree(d_B);

  // Deallocate host vectors
  free(A); free(B); free(C);

  return 0;
}
