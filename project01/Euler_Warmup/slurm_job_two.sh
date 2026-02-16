#!/bin/bash
#SBATCH --job-name=slurm_job_two # Job name    (default: sbatch)
#SBATCH --output=build/%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=build/%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --nodes=2                # Number of nodes
#SBATCH --ntasks-per-node=1      # One task per node  -> total tasks = 2
#SBATCH --cpus-per-task=1        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=00:01:00          # Wall clock time limit (H:M:S)

# exit immediately if any command exits with a non-zero status
set -e

# load some modules & list loaded modules
module load stack gcc
module list

# print CPU model per node
lscpu | grep "Model name"

# run (srun: run job on cluster with provided resources/allocation)
srun hostname

srun ./build/hello_world
