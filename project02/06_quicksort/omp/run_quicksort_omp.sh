#!/bin/bash
#SBATCH --job-name=qs_task_scaling
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=03:00:00
#SBATCH --constraint=EPYC_7763

set -e

module load stack/2024-06 gcc/12.2.0
module list

echo "Running on:"
hostname
lscpu | grep "Model name" || true

export OMP_PROC_BIND=close
export OMP_PLACES=cores

make clean
make

# -------------------------------
# Experiment parameters
# -------------------------------
REPEAT=5

# Candidate cutoffs for final clause tuning
CUTOFFS=(100 500 1000 5000 10000 20000 50000 100000)

# Problem size used for cutoff tuning
TUNE_N=10000000

# Strong scaling study
THREADS=(1 2 4 8 16 32 64 128)
SIZES=(1000000 5000000 10000000 20000000)

# -------------------------------
# Helper function: average over REPEAT runs
# -------------------------------
run_avg() {
  local n=$1
  local cutoff=$2
  local threads=$3

  export OMP_NUM_THREADS=$threads

  local sum=0.0
  local wrong=0

  for ((r=1; r<=REPEAT; r++)); do
    line=$(./quicksort_omp $n $cutoff)
    # output format:
    # length cutoff threads time wrong
    t=$(echo "$line" | awk '{print $4}')
    w=$(echo "$line" | awk '{print $5}')
    wrong=$w
    sum=$(awk -v a="$sum" -v b="$t" 'BEGIN{printf "%.10f", a+b}')
  done

  avg=$(awk -v s="$sum" -v r="$REPEAT" 'BEGIN{printf "%.10f", s/r}')
  echo "$avg $wrong"
}

# -------------------------------
# 1) Tune cutoff scientifically
# -------------------------------
echo "# N cutoff threads avg_time wrong" > cutoff_tuning.data

echo "===== CUTOFF TUNING ====="
for cutoff in "${CUTOFFS[@]}"; do
  result=$(run_avg $TUNE_N $cutoff 128)
  avg=$(echo "$result" | awk '{print $1}')
  wrong=$(echo "$result" | awk '{print $2}')
  echo "$TUNE_N $cutoff 128 $avg $wrong" | tee -a cutoff_tuning.data
done

BEST_CUTOFF=$(awk '
BEGIN {best_t = 1e99; best_c = -1}
$5 == 0 && $4 < best_t {best_t = $4; best_c = $2}
END {print best_c}
' cutoff_tuning.data)

echo "Best cutoff found: $BEST_CUTOFF"

# -------------------------------
# 2) Strong scaling study
# -------------------------------
echo "# N threads avg_time speedup efficiency cutoff wrong" > strong_scaling.data

echo "===== STRONG SCALING ====="
for N in "${SIZES[@]}"; do
  # baseline with 1 thread
  base_result=$(run_avg $N $BEST_CUTOFF 1)
  T1=$(echo "$base_result" | awk '{print $1}')
  wrong=$(echo "$base_result" | awk '{print $2}')

  S=1.0
  E=1.0
  echo "$N 1 $T1 $S $E $BEST_CUTOFF $wrong" | tee -a strong_scaling.data

  for t in 2 4 8 16 32 64 128; do
    result=$(run_avg $N $BEST_CUTOFF $t)
    Tt=$(echo "$result" | awk '{print $1}')
    wrong=$(echo "$result" | awk '{print $2}')

    S=$(awk -v t1="$T1" -v tt="$Tt" 'BEGIN{printf "%.8f", t1/tt}')
    E=$(awk -v s="$S" -v p="$t" 'BEGIN{printf "%.8f", s/p}')

    echo "$N $t $Tt $S $E $BEST_CUTOFF $wrong" | tee -a strong_scaling.data
  done
done

echo "All experiments completed."
echo "Results written to:"
echo "  cutoff_tuning.data"
echo "  strong_scaling.data"