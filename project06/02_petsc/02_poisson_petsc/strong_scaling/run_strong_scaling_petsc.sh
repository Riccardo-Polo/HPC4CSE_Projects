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

# Load the same PETSc/OpenMPI environment you used for compiling interactively.
# If your Euler environment already sets PETSC_ROOT correctly, these can be left unchanged.
module load stack gcc openmpi 2>/dev/null || true
module load petsc 2>/dev/null || true

make clean
make poisson2d_benchmark

# Representative resolutions: small, medium, large, very large.
# For final runs, 512/1024/2048 are usually the most meaningful.
RESOLUTIONS=(256 512 1024 2048)
PROCS=(1 2 4 8 16 32)
REPS=3

# Solver options: CG is appropriate because the assembled matrix is symmetric positive definite.
# GAMG makes the problem scalable enough for larger grids. You can override with:
#   sbatch --export=ALL,PETSC_OPTS="-ksp_type cg -pc_type jacobi -ksp_rtol 1e-8" run_strong_scaling_petsc.sh
PETSC_OPTS=${PETSC_OPTS:-"-ksp_type cg -pc_type gamg -ksp_rtol 1e-8 -ksp_converged_reason"}

RAW=results/strong_scaling_raw.csv
SUMMARY=results/strong_scaling_summary.csv

echo "resolution,nprocs,rep,total_time,setup_time,solve_time,iterations" > "$RAW"

echo "Running on nodes: $SLURM_JOB_NODELIST"
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
      # RESULT,nprocs,mx,my,total,setup,solve,its
      IFS=',' read -r _ np mx my total setup solve its <<< "$line"
      echo "$n,$np,$rep,$total,$setup,$solve,$its" >> "$RAW"
    done
  done
done

python3 plot_strong_scaling.py "$RAW" "$SUMMARY"
