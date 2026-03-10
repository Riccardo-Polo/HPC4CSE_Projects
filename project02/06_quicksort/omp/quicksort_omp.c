#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "walltime.h"

#define FINAL_CUTOFF 10000

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

/* task-based quicksort */
void quicksort_omp(double *data, int length) {
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

  /* if we are already inside a final task, continue sequentially */
  if (omp_in_final()) {
    quicksort_seq(data, right);
    quicksort_seq(&(data[left]), length - left);
    return;
  }

  #pragma omp task shared(data) firstprivate(right) final(right < FINAL_CUTOFF)
  quicksort_omp(data, right);

  #pragma omp task shared(data) firstprivate(left, length) final((length - left) < FINAL_CUTOFF)
  quicksort_omp(&(data[left]), length - left);

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
  if (argc > 1) length = atoi(argv[1]);

  double *data = (double*)malloc(length * sizeof(double));
  if (data == NULL) {
    printf("memory allocation failed\n");
    return 0;
  }

  srand(0);
  for (int i = 0; i < length; i++) {
    data[i] = (double)rand() / (double)RAND_MAX;
  }

  double time_start = walltime();

  #pragma omp parallel
  {
    #pragma omp single
    quicksort_omp(data, length);
  }

  double time = walltime() - time_start;

  printf("Size of dataset: %d, elapsed time[s] %e\n", length, time);

  if (check(data, length) != 0)
    printf("Quicksort incorrect.\n");

  free(data);
  return 0;
}