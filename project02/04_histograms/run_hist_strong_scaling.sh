#!/bin/bash
#SBATCH --job-name=hist_strong_scaling
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1G
#SBATCH --time=01:00:00
#SBATCH --constraint=EPYC_7763

set -e

module load stack gcc
module list

echo "Running on:"
srun hostname

export OMP_PROC_BIND=close
export OMP_PLACES=cores

make clean
make

# strong scaling: fixed total problem size
N_TOTAL=1000000000
NREPEAT=5

OUTFILE=timing_hist_omp_strong.data
echo "==== STRONG SCALING: histogram omp ==================="
echo "# columns: checksum N num_threads avg_time min_time max_time" > ${OUTFILE}

for t in 1 2 4 8 16 32 64
do
  echo "Running with ${t} threads..."
  export OMP_NUM_THREADS=${t}
  stdbuf -oL ./hist_omp_strong ${N_TOTAL} ${NREPEAT} | tail -n 1 >> ${OUTFILE}
done
echo

echo "==== plotting strong scaling ========================="
gnuplot plot_hist_strong.gp