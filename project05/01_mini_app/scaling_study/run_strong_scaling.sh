#!/bin/bash
#SBATCH --job-name=mini_strong
#SBATCH --output=outputs/strong_%j.out
#SBATCH --error=outputs/strong_%j.err
#SBATCH --constraint=EPYC_7763
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem-per-cpu=512M

set -euo pipefail

# Run from the directory containing Makefile and main.cpp:
#   sbatch run_strong_scaling.sh

module purge
module load stack gcc openmpi || module load stack gcc

mkdir -p outputs results figures

make clean
make -j

# Strong scaling: fixed global problem size n x n, increasing MPI processes.
PROCS=(1 2 4 8 16)
NS=(64 128 256 512 1024)
NT=${NT:-100}
T_FINAL=${T_FINAL:-0.005}
REPEATS=${REPEATS:-3}

RAW="results/strong_scaling_raw.dat"
AVG="results/strong_scaling_avg.dat"

cat > "$RAW" <<HEADER
# n ncpu repeat nt cg_iters newton_iters time_seconds
HEADER

for n in "${NS[@]}"; do
  for p in "${PROCS[@]}"; do
    for r in $(seq 1 "$REPEATS"); do
      echo "===== STRONG n=${n} p=${p} repeat=${r}/${REPEATS} ====="
      log="outputs/strong_n${n}_p${p}_r${r}.out"
      srun -n "$p" --cpu-bind=cores ./main "$n" "$NT" "$T_FINAL" > "$log" 2>&1

      line=$(grep '###' "$log" | tail -n 1 || true)
      if [[ -z "$line" ]]; then
        echo "ERROR: no timing line found in $log" >&2
        exit 1
      fi

      # Expected timing line from main.cpp:
      # ### size, nx, nt, tot_iters_cg, tot_iters_newton, timespent ###
      echo "$line" | sed 's/#//g' | awk -F',' -v rep="$r" '{
        gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3);
        gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $5); gsub(/^ +| +$/, "", $6);
        print $2, $1, rep, $3, $4, $5, $6
      }' >> "$RAW"
    done
  done
done

python3 plot_scaling.py --strong "$RAW" --strong-avg "$AVG" --outdir figures
