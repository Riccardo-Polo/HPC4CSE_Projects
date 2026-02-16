#!/bin/bash
#SBATCH --job-name=slurm_job_one # Job name    (default: sbatch)
#SBATCH --output=%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=1        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=00:01:00          # Wall clock time limit (H:M:S)
#SBATCH --constraint=EPYC_9654   # Constraint to run on EPYC 9654 CPUs

# exit immediately if any command exits with a non-zero status
set -e

# load some modules & list loaded modules
module load stack gcc
module list

# print CPU model
lscpu | grep "Model name"

# run (srun: run job on cluster with provided resources/allocation)
srun hostname
