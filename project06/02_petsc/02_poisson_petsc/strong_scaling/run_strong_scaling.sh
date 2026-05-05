#!/bin/bash
#SBATCH --job-name=poisson_strong_petsc
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --nodes=32
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs results figures

echo "Running on nodes: ${SLURM_JOB_NODELIST:-unknown}"
echo "Working directory: $PWD"

# Load PETSc-compatible environment on Euler
module purge
module load stack/2025-06
module load gcc/12.2.0
module load openmpi/5.0.5
module load petsc/3.22.1

echo "Loaded modules:"
module list

echo "PETSc-related environment:"
echo "PETSC_ROOT=${PETSC_ROOT:-}"
echo "PETSC_DIR=${PETSC_DIR:-}"
echo "PETSC_ARCH=${PETSC_ARCH:-}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}"
echo "mpicc=$(which mpicc)"

make clean
make print
make all
RESOLUTIONS=(256 512 1024 2048)
PROCS=(1 2 4 8 16 32)
REPS=3

PETSC_OPTS=${PETSC_OPTS:-"-ksp_type cg -pc_type gamg -ksp_rtol 1e-8 -ksp_converged_reason"}

RAW=results/strong_scaling_raw.csv
SUMMARY=results/strong_scaling_summary.csv

echo "resolution,nprocs,rep,total_time,setup_time,solve_time,iterations" > "$RAW"
echo "PETSC_OPTS=$PETSC_OPTS"

for n in "${RESOLUTIONS[@]}"; do
  for p in "${PROCS[@]}"; do
    if (( p > SLURM_NNODES )); then
      echo "Skipping p=$p because only $SLURM_NNODES nodes were allocated."
      continue
    fi

    for rep in $(seq 1 "$REPS"); do
      echo "n=$n p=$p rep=$rep"

      LOG="outputs/strong_n${n}_p${p}_rep${rep}.log"
      set +e
      srun -N "$p" -n "$p" --ntasks-per-node=1 --cpu-bind=cores \
        ./poisson2d_benchmark \
        -da_grid_x "$n" -da_grid_y "$n" \
        $PETSC_OPTS \
        > "$LOG" 2>&1
      status=$?
      set -e

      line=$(grep '^RESULT,' "$LOG" | tail -n 1 || true)
      if (( status != 0 )) || [[ -z "${line:-}" ]]; then
        echo "Run failed or no RESULT line: n=$n p=$p rep=$rep. See $LOG" >&2
        continue
      fi

      IFS=',' read -r _ np mx my total setup solve its <<< "$line"
      echo "$n,$np,$rep,$total,$setup,$solve,$its" >> "$RAW"
    done
  done
done

python3 plot_strong_scaling.py "$RAW" "$SUMMARY"
