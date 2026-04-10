#!/bin/bash -l
#SBATCH --job-name=pm_strong_mnode
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=64
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=2G
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs results figures

module load stack gcc openmpi python

cp ../common/powermethod_rows .

TEST_CASE=3
N=10000
NITER=300
TOL=-1e-6
REPEATS=${REPEATS:-5}
PROCS=(1 2 4 8 16 32 64)
OUTFILE=results/strong_scaling_multi_node.dat

printf "# procs repeat n iter theta time\n" > "$OUTFILE"

for p in "${PROCS[@]}"; do
  for r in $(seq 1 "$REPEATS"); do
    line=$(srun -N "$p" -n "$p" --ntasks-per-node=1 ./powermethod_rows "$TEST_CASE" "$N" "$NITER" "$TOL" | grep '###')
    clean=$(echo "$line" | tr -d '#')
    p_out=$(echo "$clean" | awk -F',' '{gsub(/ /, "", $1); print $1}')
    n_out=$(echo "$clean" | awk -F',' '{gsub(/ /, "", $2); print $2}')
    it_out=$(echo "$clean" | awk -F',' '{gsub(/ /, "", $3); print $3}')
    th_out=$(echo "$clean" | awk -F',' '{gsub(/ /, "", $4); print $4}')
    tm_out=$(echo "$clean" | awk -F',' '{gsub(/ /, "", $5); print $5}')
    printf "%d %d %d %d %.15f %.15f\n" "$p_out" "$r" "$n_out" "$it_out" "$th_out" "$tm_out" >> "$OUTFILE"
  done
done