#include <omp.h>

#include <stdio.h>

// Example runs
// 0.008s ~0.8MB
// #define N 100000
// 0.1s ~8MB
// #define N 1000000
// 1.1s ~80MB
// #define N 10000000
// 13s ~800MB
 #define N 100000000
// 127s 16GB
//#define N 1000000000


double dot_serial(int n, double *a, double *b) {
  double dot = 0.;
  for (int i = 0; i < n; ++i) {
    dot += a[i] * b[i];
  }
  return dot;
}

double dot_parallel_wrong(int n, double *a, double *b) {
  double dot = 0.;
  #pragma omp parallel
  {
    for (int i = 0; i < n; ++i) {
      dot += a[i] * b[i];
    }
  }
  return dot;
}

double dot_parallel_critical(int n, double *a, double *b) {
  double dot = 0.;
  #pragma omp parallel
  {
    double partial_dot = 0.;
    int nthreads = omp_get_num_threads();
    int tid = omp_get_thread_num();
    int i_beg =  tid      * n / nthreads;
    int i_end = (tid + 1) * n / nthreads;
    for (int i = i_beg; i < i_end; ++i) {
      partial_dot += a[i] * b[i];
    }
    #pragma omp critical
    dot += partial_dot;
  }
  return dot;
}

double dot_parallel_critical_explicit(int n, double *a, double *b) {
  double dot = 0.;
  double partial_dot = 0.;
  int nthreads, tid, i_beg, i_end;
  #pragma omp parallel                         \
          default(none)                        \
          shared(n, a, b, dot)                 \
          private(nthreads, tid, i_beg, i_end) \
          firstprivate(partial_dot)
  {
    nthreads = omp_get_num_threads();
    tid = omp_get_thread_num();
    i_beg =  tid      * n / nthreads;
    i_end = (tid + 1) * n / nthreads;
    for (int i = i_beg; i < i_end; ++i) {
      partial_dot += a[i] * b[i];
    }
    #pragma omp critical
    dot += partial_dot;
  }
  return dot;
}

double dot_parallel_reduction(int n, double *a, double *b) {
  double dot = 0.;
  #pragma omp parallel
  {
    #pragma omp for reduction(+:dot)
    for (int i = 0; i < n; ++i) {
      dot += a[i] * b[i];
    }
  }
  return dot;
}

double dot_parallel_reduction2(int n, double *a, double *b) {
  double dot = 0.;
  #pragma omp parallel for reduction(+:dot)
  for (int i = 0; i < n; ++i) {
    dot += a[i] * b[i];
  }
  return dot;
}

double dot_parallel_reduction3(int n, double *a, double *b) {
  double dot = 0.;
  #pragma omp parallel for reduction(+:dot) \
              default(none)                 \
              shared(a, b, n)
  for (int i = 0; i < n; ++i) {
    dot += a[i] * b[i];
  }
  return dot;
}

int main() {

  return 0;
}
