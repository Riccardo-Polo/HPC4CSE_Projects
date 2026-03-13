#!/bin/bash
#SBATCH --job-name=dependencies
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --constraint=EPYC_7763
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=4096
#SBATCH --time=02:00:00

set -euo pipefail

REPEATS=${REPEATS:-10}
RESULTS_FILE=${RESULTS_FILE:-dependencies_results.dat}
SUMMARY_FILE=${SUMMARY_FILE:-dependencies_summary.dat}

module load stack gcc
module list

export OMP_NUM_THREADS=64
export OMP_PROC_BIND=close
export OMP_PLACES=cores

make clean
make

rm -f "$RESULTS_FILE" "$SUMMARY_FILE"
echo "# run seq_time par_time speedup seq_Sn par_Sn seq_norm2 par_norm2" > "$RESULTS_FILE"

echo "Running $REPEATS sequential measurements..."
for run in $(seq 1 "$REPEATS"); do
  echo "==== Sequential run $run/$REPEATS ===="
  seq_out=$(./recur_seq)
  echo "$seq_out"

  seq_time=$(echo "$seq_out" | awk '/Sequential RunTime/ {print $(NF-1)}')
  seq_sn=$(echo "$seq_out" | awk '/Final Result Sn/ {print $NF}')
  seq_norm=$(echo "$seq_out" | awk '/Result \|\|opt\|\|\^2_2/ {print $NF}')

  echo "==== OpenMP (${OMP_NUM_THREADS} threads) run $run/$REPEATS ===="
  par_out=$(./recur_omp)
  echo "$par_out"

  par_time=$(echo "$par_out" | awk '/Parallel RunTime/ {print $(NF-1)}')
  par_sn=$(echo "$par_out" | awk '/Final Result Sn/ {print $NF}')
  par_norm=$(echo "$par_out" | awk '/Result \|\|opt\|\|\^2_2/ {print $NF}')
  speedup=$(awk -v s="$seq_time" -v p="$par_time" 'BEGIN {printf "%.10f", s/p}')

  echo "$run $seq_time $par_time $speedup $seq_sn $par_sn $seq_norm $par_norm" >> "$RESULTS_FILE"
done

awk '
BEGIN {
  seq_sum = par_sum = speed_sum = 0.0;
  print "# repeats avg_seq_time avg_par_time avg_speedup seq_Sn_avg par_Sn_avg seq_norm2_avg par_norm2_avg";
}
NR > 1 {
  n++;
  seq_sum += $2;
  par_sum += $3;
  speed_sum += $4;
  seq_sn_sum += $5;
  par_sn_sum += $6;
  seq_norm_sum += $7;
  par_norm_sum += $8;
}
END {
  if (n > 0) {
    printf "%d %.10f %.10f %.10f %.17g %.17g %.10f %.10f\n", \
           n, seq_sum/n, par_sum/n, speed_sum/n, \
           seq_sn_sum/n, par_sn_sum/n, seq_norm_sum/n, par_norm_sum/n;
  }
}
' "$RESULTS_FILE" > "$SUMMARY_FILE"

echo
echo "==== Per-run results saved to $RESULTS_FILE ===="
cat "$RESULTS_FILE"
echo
echo "==== Summary saved to $SUMMARY_FILE ===="
cat "$SUMMARY_FILE"
