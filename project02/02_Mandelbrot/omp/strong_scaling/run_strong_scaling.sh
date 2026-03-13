#!/bin/bash
#SBATCH --job-name=mandel_strong
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --constraint=EPYC_7763
#SBATCH --time=01:00:00

set -eo pipefail

module load stack gcc gnuplot

make clean
make

EXE=./mandelbrot
RAW=timing_strong_raw.data
AVG=timing_strong_avg.data

REPEATS=${REPEATS:-5}
THREADS="${THREADS_LIST:-1 2 4 8 16 32 64}"

export OMP_PROC_BIND=close
export OMP_PLACES=cores

rm -f "$RAW" "$AVG"
echo "# threads width height run time" > "$RAW"

for t in $THREADS; do
    export OMP_NUM_THREADS=$t
    for r in $(seq 1 "$REPEATS"); do
        "$EXE" | awk -v run="$r" '{print $1, $2, $3, run, $4}' >> "$RAW"
    done
done

awk '
BEGIN { OFS=" " }
!/^#/ {
    t = $1
    w[t] = $2
    h[t] = $3
    n[t]++
    sum[t] += $5
    sumsq[t] += $5*$5
    if (!(t in min) || $5 < min[t]) min[t] = $5
    if (!(t in max) || $5 > max[t]) max[t] = $5
}
END {
    for (t in n) {
        avg = sum[t] / n[t]
        std = (n[t] > 1) ? sqrt((sumsq[t] - sum[t]*sum[t]/n[t]) / (n[t]-1)) : 0
        print t, w[t], h[t], avg, std, min[t], max[t], n[t]
    }
}
' "$RAW" | sort -n > "$AVG"

gnuplot strong_scaling.gp
gnuplot strong_speedup.gp
