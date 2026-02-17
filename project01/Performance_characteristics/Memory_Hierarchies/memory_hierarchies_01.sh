#!/bin/bash
#SBATCH --job-name=memory_hierarchies # Job name    (default: sbatch)
#SBATCH --output=build_1/%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=build_1/%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=1        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=00:01:00          # Wall clock time limit (H:M:S)
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

lscpu
free -h --si
hwloc-ls --whole-system --no-io --of console
hwloc-ls --whole-system --no-io --of pdf build_1/EPYC_7H12.pdf
