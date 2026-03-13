#!/bin/bash
#SBATCH --job-name=slurm_job_one # Job name    (default: sbatch)
#SBATCH --output=outputs/%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=outputs/%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=64        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=01:00:00          # Wall clock time limit (H:M:S)
#SBATCH --constraint=EPYC_7763   # Constraint to run on EPYC 7763 CPUs

# exit immediately if any command exits with a non-zero status
set -e

mkdir -p outputs

# load some modules & list loaded modules
module load stack gcc
module list


# run (srun: run job on cluster with provided resources/allocation)
srun hostname

make clean
make
srun ./pi_serial
srun ./pi_omp_critical_naive
srun ./pi_omp_critical_optimized
srun ./pi_omp_reduction
