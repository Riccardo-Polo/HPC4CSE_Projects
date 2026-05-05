#!/bin/bash
#SBATCH --job-name=poisson2d
#SBATCH --output=poisson2d-%j.out
#SBATCH --error=poisson2d-%j.err
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G
#SBATCH --constraint=EPYC_7763

module purge
module load stack gcc openmpi petsc

make clean
make

srun ./poisson2d -da_grid_x 129 -da_grid_y 129 \
  -ksp_type cg \
  -pc_type gamg \
  -ksp_rtol 1e-10 \
  -ksp_converged_reason \
  -ksp_monitor_short \
  -solution_file solution.dat

python3 plot_solution.py
