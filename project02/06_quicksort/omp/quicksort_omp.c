#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "walltime.h"

void print_list(double *data, int length) {
  for (int i = 0; i < length; i++) {
    printf("%e\t", data[i]);
  }
  printf("\n");
}

/* purely sequential quicksort */
void quicksort_seq(double *data, int length) {
  if (length <= 1) return;

  double pivot = data[0];
  double temp;
  int left = 1;
  int right = length - 1;

  do {
    while (left  < (length - 1) && data[left]  <= pivot) left++;
    while (right > 0            && data[right] >= pivot) right--;

    if (left < right) {
      temp = data[left];
      data[left] = data[right];
      data[right] = temp;
    }
  } while (left < right);

  if (data[right] < pivot) {
    data[0] = data[right];
    data[right] = pivot;
  }

  quicksort_seq(data, right);
  quicksort_seq(&(data[left]), length - left);
}

/* task-based quicksort with final clause */
void quicksort_omp(double *data, int length, int cutoff) {
  if (length <= 1) return;

  double pivot = data[0];
  double temp;
  int left = 1;
  int right = length - 1;

  do {
    while (left  < (length - 1) && data[left]  <= pivot) left++;
    while (right > 0            && data[right] >= pivot) right--;

    if (left < right) {
      temp = data[left];
      data[left] = data[right];
      data[right] = temp;
    }
  } while (left < right);

  if (data[right] < pivot) {
    data[0] = data[right];
    data[right] = pivot;
  }

  /* Once in a final task, continue recursively in sequential mode */
  if (omp_in_final()) {
    quicksort_seq(data, right);
    quicksort_seq(&(data[left]), length - left);
    return;
  }

  #pragma omp task shared(data) firstprivate(right, cutoff) final(right <= cutoff)
  quicksort_omp(data, right, cutoff);

  #pragma omp task shared(data) firstprivate(left, length, cutoff) final((length - left) <= cutoff)
  quicksort_omp(&(data[left]), length - left, cutoff);

  #pragma omp taskwait
}

int check(double *data, int length) {
  for (int i = 1; i < length; i++) {
    if (data[i] < data[i - 1]) return 1;
  }
  return 0;
}

int main(int argc, char **argv) {
  int length = 10000000;
  int cutoff = 10000;

  if (argc > 1) length = atoi(argv[1]);
  if (argc > 2) cutoff = atoi(argv[2]);

  double *data = (double*)malloc((size_t)length * sizeof(double));
  if (data == NULL) {
    printf("memory allocation failed\n");
    return 1;
  }

  srand(0);
  for (int i = 0; i < length; i++) {
    data[i] = (double)rand() / (double)RAND_MAX;
  }

  double time_start = walltime();

  #pragma omp parallel
  {
    #pragma omp single
    quicksort_omp(data, length, cutoff);
  }

  double time = walltime() - time_start;

  int wrong = check(data, length);

  /* machine-readable output */
  printf("%d %d %d %.8f %d\n",
         length, cutoff, omp_get_max_threads(), time, wrong);

  free(data);
  return 0;
}
