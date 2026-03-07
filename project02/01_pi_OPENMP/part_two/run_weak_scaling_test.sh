#!/bin/bash
#SBATCH --job-name=omp_scaling
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1G
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -e

module load stack gcc
module list

echo "Running on:"
srun hostname

export OMP_PROC_BIND=close
export OMP_PLACES=cores

make clean
make

# weak scaling: constant work per thread
WORK_PER_THREAD=50000000

echo "==== WEAK SCALING: naive critical ======================"
stdbuf -oL ./naive_weak      ${WORK_PER_THREAD} | tee timing_naive_weak.data
echo

echo "==== WEAK SCALING: optimized critical ================="
stdbuf -oL ./optimized_weak  ${WORK_PER_THREAD} | tee timing_optimized_weak.data
echo

echo "==== WEAK SCALING: reduction =========================="
stdbuf -oL ./reduction_weak  ${WORK_PER_THREAD} | tee timing_reduction_weak.data
echo

echo "==== plotting weak scaling ============================"
gnuplot plot_weak_time.gp
