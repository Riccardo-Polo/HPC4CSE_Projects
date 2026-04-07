#!/bin/bash
#SBATCH --job-name=ghost
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=256M

module load stack gcc openmpi

mkdir -p outputs

make clean
make

srun -n 12 ./ghost
