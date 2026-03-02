#include <stdio.h>

int fib(int n) {
  int Fnm, Fnmm;
  if (n < 2) return n;
  #pragma omp task shared(Fnmm)
  Fnmm = fib(n - 2);
  #pragma omp task shared(Fnm)
  Fnm  = fib(n - 1);
  #pragma omp taskwait
  return Fnmm + Fnm;
}

int main() {
  int n = 42;
  int fibn;
  #pragma omp parallel
  {
    #pragma omp single
    fibn = fib(n);
  }
  printf("Fibonacci fib(%2d) = %d\n", n, fibn);
  return 0;
}
