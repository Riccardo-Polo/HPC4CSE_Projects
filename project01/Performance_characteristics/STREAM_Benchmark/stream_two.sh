#!/bin/bash
#SBATCH --job-name=stream_two # Job name    (default: sbatch)
#SBATCH --output=build_2/%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=build_2/%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=1        # Number of CPUs per task
#SBATCH --mem-per-cpu=8G         # Memory per CPU
#SBATCH --time=00:10:00          # Wall clock time limit (H:M:S)
#SBATCH --constraint=EPYC_7H12   # Constraint to run on EPYC 7H12 CPUs

# exit immediately if any command exits with a non-zero status
set -e

# load some modules & list loaded modules
module load stack gcc
module list

# print CPU model
lscpu | grep "Model name"

# run (srun: run job on cluster with provided resources/allocation)
srun hostname

gcc -O3 -march=native -mcmodel=medium -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=20000000 -DNTIMES=20 stream.c -o build_2/stream_two_c.exe

srun build_2/stream_two_c.exe