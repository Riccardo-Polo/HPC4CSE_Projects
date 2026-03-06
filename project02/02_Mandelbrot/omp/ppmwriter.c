#include "ppmwriter.h"

#include <stdlib.h>
#include <stdio.h>

void ppm_create(ppm_data_t* ppm_data,
                unsigned int nWidth, unsigned int nHeight) {
  ppm_data->nWidth  = nWidth;
  ppm_data->nHeight = nHeight;
  ppm_data->data    = (ppm_pixel_t*) malloc(3 * nWidth
                                              * nHeight
                                              * sizeof(ppm_pixel_t));
  // Handle allocation failure
  if (!ppm_data->data) {
    ppm_data->nWidth = 0;
    ppm_data->nHeight = 0;
  }
}

void ppm_destroy(ppm_data_t* ppm_data) {
  if (ppm_data->data) {
    free(ppm_data->data);
    ppm_data->data = NULL;
  }
  ppm_data->nWidth  = 0;
  ppm_data->nHeight = 0;
}

void ppm_plot(ppm_data_t* ppm_data, ppm_size_t x, ppm_size_t y,
              ppm_pixel_t r, ppm_pixel_t g, ppm_pixel_t b) {
  if (x >= ppm_data->nWidth || y >= ppm_data->nHeight) {
    return;  // Avoid out-of-bounds access; Do nothing.
  }
  ppm_size_t idx = 3 * (y * ppm_data->nWidth + x);
  ppm_data->data[idx + 0] = r;
  ppm_data->data[idx + 1] = g;
  ppm_data->data[idx + 2] = b;
}

void ppm_write(ppm_data_t* ppm_data, char const* fname) {
  FILE* fp = fopen(fname, "wb");
  if (!fp) {
    perror("Failed to open file");
    return;
  }

  // Write PPM header
  fprintf(fp, "P6\n%u %u\n255\n", ppm_data->nWidth, ppm_data->nHeight);

  // Write pixel data
  fwrite(ppm_data->data,
         sizeof(ppm_pixel_t),
         3 * ppm_data->nWidth * ppm_data->nHeight,
         fp);

  fclose(fp);
}
