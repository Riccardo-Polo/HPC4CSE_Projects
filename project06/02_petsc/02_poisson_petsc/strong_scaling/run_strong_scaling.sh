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

echo "Loading Euler modules..."
module purge
module load stack gcc openmpi

# -----------------------------------------------------------------------------
# PETSc module loading on Euler
# -----------------------------------------------------------------------------
# On Euler, `module load petsc` may fail because PETSc is usually exposed as a
# versioned module, e.g. petsc/<version>, under the loaded compiler/MPI stack.
# Therefore we first try the generic name, then automatically select the first
# versioned PETSc module visible in the current module hierarchy.
#
# If this still fails, run manually:
#     module purge
#     module load stack gcc openmpi
#     module avail petsc
#     module spider petsc
# and replace PETSC_MODULE below with the exact module name.
# -----------------------------------------------------------------------------

PETSC_MODULE=${PETSC_MODULE:-}

if [[ -n "$PETSC_MODULE" ]]; then
  echo "Loading PETSc module requested by PETSC_MODULE=$PETSC_MODULE"
  module load "$PETSC_MODULE"
else
  echo "Trying generic PETSc module name: petsc"
  if module load petsc 2>/dev/null; then
    echo "Loaded PETSc with generic name: petsc"
  else
    echo "Generic 'module load petsc' failed. Searching for a versioned PETSc module..."

    # module avail writes to stderr on many Lmod installations, so capture both.
    # We keep only tokens of the form petsc/<version> and choose the first one.
    CANDIDATE=$(module -t avail petsc 2>&1 \
      | tr ' ' '\n' \
      | sed 's/(D)//g; s/:$//g' \
      | grep -E '^petsc/|^PETSc/' \
      | head -n 1 || true)

    if [[ -z "$CANDIDATE" ]]; then
      echo "ERROR: No loadable PETSc module was found after loading stack gcc openmpi." >&2
      echo "Run these commands interactively to identify the exact module name:" >&2
      echo "  module purge" >&2
      echo "  module load stack gcc openmpi" >&2
      echo "  module avail petsc" >&2
      echo "  module spider petsc" >&2
      echo "Then submit with, for example:" >&2
      echo "  sbatch --export=ALL,PETSC_MODULE=petsc/<version> run_strong_scaling.sh" >&2
      exit 1
    fi

    echo "Loading detected PETSc module: $CANDIDATE"
    module load "$CANDIDATE"
  fi
fi

echo "Loaded modules:"
module list

echo "PETSc-related environment:"
echo "PETSC_ROOT=${PETSC_ROOT:-}"
echo "PETSC_DIR=${PETSC_DIR:-}"
echo "PETSC_ARCH=${PETSC_ARCH:-}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}"
echo "Available PETSc pkg-config entries:"
pkg-config --list-all 2>/dev/null | grep -i petsc || true

# Compile. Stop immediately if compilation fails.
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
