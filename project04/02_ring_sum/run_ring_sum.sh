#!/bin/bash
#SBATCH --job-name=ring_sum
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --mem-per-cpu=256M

module load stack gcc openmpi

make clean
make

srun -n 4 ./ring_sum
