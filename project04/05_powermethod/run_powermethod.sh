#!/bin/bash
#SBATCH --job-name=power_method_test
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=512M
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs

echo "===== Loading modules ====="
module load stack gcc openmpi

echo "===== Compiling ====="
make clean
make

echo "===== Running tests ====="

TEST_CASE=3
N=10000
NITER=300
TOL=-1e-6

PROCS=(1 2 4 8)

for p in "${PROCS[@]}"; do
    echo "----------------------------------------"
    echo "Running with $p MPI processes"
    echo "----------------------------------------"
    
    srun -n "$p" ./powermethod_rows $TEST_CASE $N $NITER $TOL
done

echo "===== Done ====="