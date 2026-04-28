#!/bin/bash
#SBATCH --job-name=mini_weak
#SBATCH --output=outputs/weak_%j.out
#SBATCH --error=outputs/weak_%j.err
#SBATCH --constraint=EPYC_7763
#SBATCH --nodes=64
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem-per-cpu=512M

set -euo pipefail

# Run from the directory containing Makefile and main.cpp:
#   sbatch run_weak_scaling.sh

module purge
module load stack gcc openmpi || module load stack gcc

mkdir -p outputs results figures

make clean
make -j

# Weak scaling: keep local work approximately constant.
# One MPI process per node: each srun uses p nodes and one task on each node.
# For a 2D problem, p = 1,4,16,64 and global n = base_n * sqrt(p).
PROCS=(1 4 16 64)
BASE_NS=(64 128 256)
NT=${NT:-100}
T_FINAL=${T_FINAL:-0.005}
REPEATS=${REPEATS:-3}

RAW="results/weak_scaling_raw.dat"
AVG="results/weak_scaling_avg.dat"

cat > "$RAW" <<HEADER
# base_n global_n ncpu repeat nt cg_iters newton_iters time_seconds
HEADER

for base_n in "${BASE_NS[@]}"; do
  for p in "${PROCS[@]}"; do
    sqrt_p=$(python3 - <<PY
import math
p = int("$p")
r = int(math.isqrt(p))
assert r*r == p
print(r)
PY
)
    n=$((base_n * sqrt_p))

    for r in $(seq 1 "$REPEATS"); do
      echo "===== WEAK base_n=${base_n} global_n=${n} p=${p} repeat=${r}/${REPEATS} ====="
      log="outputs/weak_base${base_n}_n${n}_p${p}_r${r}.out"
      srun --nodes="$p" --ntasks="$p" --ntasks-per-node=1 --cpu-bind=cores ./main "$n" "$NT" "$T_FINAL" > "$log" 2>&1

      line=$(grep '###' "$log" | tail -n 1 || true)
      if [[ -z "$line" ]]; then
        echo "ERROR: no timing line found in $log" >&2
        exit 1
      fi

      # Expected timing line from main.cpp:
      # ### size, nx, nt, tot_iters_cg, tot_iters_newton, timespent ###
      echo "$line" | sed 's/#//g' | awk -F',' -v base="$base_n" -v rep="$r" '{
        gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3);
        gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $5); gsub(/^ +| +$/, "", $6);
        print base, $2, $1, rep, $3, $4, $5, $6
      }' >> "$RAW"
    done
  done
done

python3 plot_scaling.py --weak "$RAW" --weak-avg "$AVG" --outdir figures
