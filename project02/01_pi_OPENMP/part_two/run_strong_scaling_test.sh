#!/bin/bash
#SBATCH --job-name=omp_strong_scaling
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1G
#SBATCH --time=03:00:00
#SBATCH --constraint=EPYC_7763

set -e

mkdir -p outputs

module load stack gcc
module list

echo "Running on:"
srun hostname

export OMP_PROC_BIND=close
export OMP_PLACES=cores

make clean
make

# strong scaling: fixed total problem size
N_TOTAL=1000000000

echo "==== STRONG SCALING: naive critical ==================="
stdbuf -oL ./naive_strong      ${N_TOTAL} | tee outputs/timing_naive_strong.data
echo

echo "==== STRONG SCALING: optimized critical =============="
stdbuf -oL ./optimized_strong  ${N_TOTAL} | tee outputs/timing_optimized_strong.data
echo

echo "==== STRONG SCALING: reduction ======================="
stdbuf -oL ./reduction_strong  ${N_TOTAL} | tee outputs/timing_reduction_strong.data
echo

echo "==== plotting strong scaling ========================="
gnuplot plot_strong.gp