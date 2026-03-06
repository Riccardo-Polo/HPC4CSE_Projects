#!/bin/bash
#SBATCH --job-name=slurm_mandelbrot # Job name    (default: sbatch)
#SBATCH --output=%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=64        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=01:00:00          # Wall clock time limit (H:M:S)
#SBATCH --constraint=EPYC_7763   # Constraint to run on EPYC 7763 CPUs

# exit immediately if any command exits with a non-zero status
set -e

# load some modules & list loaded modules
module load stack ghostscript imagemagick
module list

# run (srun: run job on cluster with provided resources/allocation)
srun hostname

make clean
make cleanall
make
<<<<<<< HEAD
srun ./mandelbrot
=======
srun ./mandel_seq
>>>>>>> 80e9f242c623c92a790d5ae3279e769c5877fe15
srun magick mandel.ppm mandel.png
