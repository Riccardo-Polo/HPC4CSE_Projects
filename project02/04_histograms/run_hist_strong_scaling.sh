#!/bin/bash
#SBATCH --job-name=hist_strong
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --constraint=EPYC_7763
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1024
#SBATCH --time=00:30:00

module load stack gcc
module list

make clean
make

./hist_omp_strong

gnuplot plot_hist_strong.gp