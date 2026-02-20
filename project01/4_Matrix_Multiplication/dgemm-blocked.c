const char* dgemm_desc = "Blocked dgemm.";

/* This routine performs a dgemm operation
 *
 *  C := C + A * B
 *
 * where A, B, and C are lda-by-lda matrices stored in column-major format.
 * On exit, A and B maintain their input values.
 */
#ifndef BS
#define BS 64   
#endif

static inline int imin(int a, int b) { return (a < b) ? a : b; }

void square_dgemm(int n, const double *A, const double *B, double *C)
{
  for (int jj = 0; jj < n; jj += BS) {
    int jmax = imin(jj + BS, n);

    for (int kk = 0; kk < n; kk += BS) {
      int kmax = imin(kk + BS, n);

      for (int ii = 0; ii < n; ii += BS) {
        int imax = imin(ii + BS, n);

        
        for (int j = jj; j < jmax; ++j) {
          for (int k = kk; k < kmax; ++k) {
            double bkj = B[k + j * n];          
            for (int i = ii; i < imax; ++i) {
              C[i + j * n] += A[i + k * n] * bkj; 
            }
          }
        }

      }
    }
  }
}
