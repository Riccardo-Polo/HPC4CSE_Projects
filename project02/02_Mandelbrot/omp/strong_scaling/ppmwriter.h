#ifndef PPMWRITER_H

typedef unsigned int  ppm_size_t;
typedef unsigned char ppm_pixel_t;

typedef struct {
  ppm_size_t nWidth;
  ppm_size_t nHeight;
  ppm_pixel_t* data;
} ppm_data_t;

void ppm_create(ppm_data_t* ppm_data, ppm_size_t nWidth, ppm_size_t nHeight);

void ppm_destroy(ppm_data_t* ppm_data);

void ppm_plot(ppm_data_t* ppm_data, ppm_size_t x, ppm_size_t y,
              ppm_pixel_t r, ppm_pixel_t g, ppm_pixel_t b);

void ppm_write(ppm_data_t* ppm_data, char const* fname);

#endif /* PPMWRITER_H */
