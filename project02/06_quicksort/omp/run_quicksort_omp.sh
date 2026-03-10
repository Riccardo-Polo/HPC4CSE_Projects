#!/bin/bash
#SBATCH --job-name=quicksort_omp    # Job name
#SBATCH --output=%x-%j.out     # Output file
#SBATCH --error=%x-%j.err      # Error file
#SBATCH --ntasks=1             # Number of tasks
#SBATCH --constraint=EPYC_7763 # Select node with CPU
#SBATCH --cpus-per-task=8      # Number of CPUs per task
#SBATCH --mem-per-cpu=4096     # Memory per CPU (MB)
#SBATCH --time=00:15:00        # Wall clock time limit

# Load some modules & list loaded modules
module load stack gcc
module list

# Thread pinning for NUMA
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_PROC_BIND=close
export OMP_PLACES=cores

# Compile
make clean
make

# Run parallel version
echo "==== OpenMP (${OMP_NUM_THREADS} threads) ===="
./quicksort_omp