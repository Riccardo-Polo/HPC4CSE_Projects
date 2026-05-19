#!/bin/bash
#SBATCH --job-name=vec_add # Job name    (default: sbatch)
#SBATCH --output=%x-%j.out # Output file (default: slurm-%j.out)
#SBATCH --error=%x-%j.err  # Error file  (default: slurm-%j.out)
#SBATCH --gpus=rtx_2080:1  # Select GPU
#SBATCH --time=00:00:30    # Wall clock time limit


# load modules
module load stack gcc cuda

# compile
make

# run
./vec_add
