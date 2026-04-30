#!/bin/bash
#SBATCH --job-name=mpi_async_test
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --constraint=EPYC_7763
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=2G
#SBATCH --output=outputs/async_progress_%j.out
#SBATCH --error=outputs/async_progress_%j.err

set -euo pipefail
mkdir -p outputs results figures
module load stack gcc openmpi || module load stack gcc

mpicxx -O3 async_progress_benchmark.cpp -o async_progress_benchmark
srun -n 2 --ntasks-per-node=1 ./async_progress_benchmark 80000000 > results/async_progress.dat
python3 plot_async_progress.py results/async_progress.dat figures/async_progress.pdf
