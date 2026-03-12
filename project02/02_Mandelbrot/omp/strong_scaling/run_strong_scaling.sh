#!/bin/bash
#SBATCH --job-name=mandel_strong
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --constraint=EPYC_7763
#SBATCH --time=01:00:00

set -euo pipefail

module load stack gcc gnuplot

echo "===== Loaded modules ====="
module list

echo "===== Cleaning and compiling ====="
make clean
make

RAW_OUT=timing_strong_raw.data
AVG_OUT=timing_strong_avg.data
EXE=./mandelbrot
REPEATSRUNS=${REPEATS:-5}
THREADS_LIST=${THREADS_LIST:-"1 2 4 8 16 32 64"}

rm -f "$RAW_OUT" "$AVG_OUT"
echo "# threads width height run time" > "$RAW_OUT"
echo "# threads width height avg_time stddev min_time max_time n_runs" > "$AVG_OUT"

export OMP_PROC_BIND=close
export OMP_PLACES=cores

echo "===== Running strong scaling benchmark ====="
echo "Threads tested : $THREADS_LIST"
echo "Repetitions    : $REPEATS"

for t in $THREADS_LIST
do
    export OMP_NUM_THREADS=$t
    echo "Running with $t threads..."

    for r in $(seq 1 "$REPEATS")
    do
        echo "  repetition $r/$REPEATS"
        "$EXE" | awk -v run="$r" '{printf "%s %s %s %d %s\n", $1, $2, $3, run, $4}' >> "$RAW_OUT"
    done

done

echo "===== Raw timing data ====="
cat "$RAW_OUT"

awk '
BEGIN {
    OFS = " "
}
/^#/ {next}
{
    t = $1
    width[t] = $2
    height[t] = $3
    n[t]++
    sum[t] += $5
    sumsq[t] += ($5 * $5)
    if (!(t in min) || $5 < min[t]) min[t] = $5
    if (!(t in max) || $5 > max[t]) max[t] = $5
}
END {
    for (t in n) {
        avg = sum[t] / n[t]
        if (n[t] > 1) {
            var = (sumsq[t] - (sum[t] * sum[t]) / n[t]) / (n[t] - 1)
            if (var < 0) var = 0
            std = sqrt(var)
        } else {
            std = 0
        }
        printf "%d %d %d %.8f %.8f %.8f %.8f %d\n", t, width[t], height[t], avg, std, min[t], max[t], n[t]
    }
}' "$RAW_OUT" | sort -n > "$AVG_OUT"

echo "===== Averaged timing data ====="
cat "$AVG_OUT"

echo "===== Creating plots ====="
gnuplot strong_scaling.gp
gnuplot strong_speedup.gp

echo "===== Generated files ====="
ls -lh "$RAW_OUT" "$AVG_OUT" strong_scaling.pdf strong_speedup.pdf
