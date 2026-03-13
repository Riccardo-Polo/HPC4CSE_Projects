#!/bin/bash
#SBATCH --job-name=hist_seq    # Job name
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --ntasks=1             # Number of tasks
#SBATCH --constraint=EPYC_7763 # Select node with CPU
#SBATCH --cpus-per-task=4      # Number of CPUs per task
#SBATCH --mem-per-cpu=1024     # Memory per CPU
#SBATCH --time=00:05:00        # Wall clock time limit

mkdir -p outputs

# Load some modules & list loaded modules
module load stack gcc
module list

# Compile
make clean
make

# Run
./hist_seq
