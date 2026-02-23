#!/bin/bash
#SBATCH --job-name=matrixmult
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --constraint=EPYC_7763
#SBATCH --time=01:30:00

# load some modules & list loaded modules
# GCC
module load stack gcc openblas
# INTEL
# module load stack/2024-06 intel-oneapi-compilers intel-oneapi-mkl
module list

# set some environment variables
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

# compile
make clean
make

#echo "==== benchmark-naive ======================"
#stdbuf -oL ./benchmark-naive | tee timing_naive_dgemm.data
echo
echo "==== benchmark-jki ========================"
stdbuf -oL ./benchmark-jki | tee timing_jki_dgemm.data
echo
echo "==== benchmark-blas ======================="
stdbuf -oL ./benchmark-blas | tee timing_blas_dgemm.data
echo
echo "==== benchmark-blocked ===================="
stdbuf -oL ./benchmark-blocked | tee timing_blocked_dgemm.data

echo
echo "==== plot results ========================="
gnuplot timing.gp
