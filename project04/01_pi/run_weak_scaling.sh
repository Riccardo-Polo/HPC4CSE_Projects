#!/bin/bash
#SBATCH --job-name=pi_mpi_weak_scaling
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=128
#SBATCH --time=00:20:00
#SBATCH --mem-per-cpu=256M
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs results figures

module load stack gcc openmpi python

make clean
make

THREADS=(1 2 4 8 16 32 64 128)
REPEATS=${REPEATS:-5}
N_PER_PROC=${N_PER_PROC:-1000000000}
OUTFILE="results/weak_scaling.data"

printf "# procs repeat pi N time\n" > "$OUTFILE"

for p in "${THREADS[@]}"; do
  N=$((p * N_PER_PROC))
  for r in $(seq 1 "$REPEATS"); do
    line=$(srun --mpi=pmix -n "$p" ./pi_mpi "$N" | tail -n 1)
    pi=$(awk '{print $1}' <<< "$line")
    n=$(awk '{print $2}' <<< "$line")
    procs=$(awk '{print $3}' <<< "$line")
    time=$(awk '{print $4}' <<< "$line")
    printf "%s %s %s %s %s\n" "$procs" "$r" "$pi" "$n" "$time" >> "$OUTFILE"
  done
done

python3 plot_scaling.py weak "$OUTFILE" figures/weak_scaling_time.pdf figures/weak_scaling_efficiency.pdf
