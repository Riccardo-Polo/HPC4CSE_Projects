#!/bin/bash -l
#SBATCH --job-name=pm_correctness
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=2G
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs results

module load stack gcc openmpi

RESULTS=results/correctness_checks.txt
: > "$RESULTS"

run_case() {
  local p=$1
  local tc=$2
  local n=$3
  local niter=$4
  local tol=$5
  echo "Running: p=$p, test_case=$tc, n=$n, niter=$niter, tol=$tol" | tee -a "$RESULTS"
  srun -n "$p" ./powermethod_rows "$tc" "$n" "$niter" "$tol" | tee -a "$RESULTS"
  echo | tee -a "$RESULTS"
}

# Known eigenvalues:
# test 1 -> theta = n
# test 2 -> theta = 1
# test 3 -> theta = n

run_case 1 1 16 100 1e-12
run_case 2 1 16 100 1e-12
run_case 4 1 16 100 1e-12

run_case 1 2 16 100 1e-12
run_case 2 2 16 100 1e-12
run_case 4 2 16 100 1e-12

run_case 1 3 16 100 1e-12
run_case 2 3 16 100 1e-12
run_case 4 3 16 100 1e-12

# Optional unknown-eigenvalue random test
run_case 4 4 16 50 1e-8

echo "Correctness runs completed. Results in $RESULTS"
