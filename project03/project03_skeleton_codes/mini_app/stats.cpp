#include "stats.h"

namespace stats {

unsigned long long flops_diff;
unsigned long long flops_bc;
unsigned long long flops_blas1;
unsigned int tot_iters_cg;
unsigned int tot_iters_newton;
bool verbose_output;

} // namespace stats
