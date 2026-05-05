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

# Load the same environment used for your successful interactive compilation.
# Do NOT hide module errors: if PETSc is not loaded, the job should stop here.
module purge
module load stack gcc openmpi

# On Euler the exact PETSc module name can vary. If this generic command fails,
# replace it by the exact module printed by: module spider petsc
module load petsc

echo "Loaded modules:"
module list

echo "PETSc-related environment:"
echo "PETSC_ROOT=${PETSC_ROOT:-}"
echo "PETSC_DIR=${PETSC_DIR:-}"
echo "PETSC_ARCH=${PETSC_ARCH:-}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}"

# Compile. The print target is useful because it shows exactly which PETSc
# installation and compiler are used.
make  clean
make  print
make  all

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
      set +e
      line=$(srun -N "$p" -n "$p" --ntasks-per-node=1 --cpu-bind=cores \
        ./poisson2d_benchmark \
        -da_grid_x "$n" -da_grid_y "$n" \
        $PETSC_OPTS \
        2>&1 | tee "outputs/strong_n${n}_p${p}_rep${rep}.log" | grep '^RESULT,' | tail -n 1)
      status=$?
      set -e
      if (( status != 0 )) || [[ -z "${line:-}" ]]; then
        echo "Run failed or no RESULT line: n=$n p=$p rep=$rep" >&2
        continue
      fi
      IFS=',' read -r _ np mx my total setup solve its <<< "$line"
      echo "$n,$np,$rep,$total,$setup,$solve,$its" >> "$RAW"
    done
  done
done

python3 plot_strong_scaling.py "$RAW" "$SUMMARY"
