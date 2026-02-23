const char* dgemm_desc = "Stride-one, three-loop dgemm.";

/* This routine performs a dgemm operation
 *
 *  C := C + A * B
 *
 * where A, B, and C are lda-by-lda matrices stored in column-major format.
 * On exit, A and B maintain their input values.
 */
void square_dgemm(int n, double* A, double* B, double* C) {
  for (int j = 0; j < n; ++j) {
    double* Ccol = C + j*n;              // C(:,j)
    for (int k = 0; k < n; ++k) {
      const double bkj = B[k + j*n];     // B(k,j) scalar reused for all i
      const double* Acol = A + k*n;      // A(:,k)
      for (int i = 0; i < n; ++i) {
        Ccol[i] += Acol[i] * bkj;        // stride-one on C and A
      }
    }
  }
}
