#!/bin/bash
#SBATCH --job-name=mw_scaling
#SBATCH --output=outputs/scaling_%j.out
#SBATCH --error=outputs/scaling_%j.err
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763
#SBATCH --nodes=1
#SBATCH --ntasks=33
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G

set -euo pipefail

# -----------------------------------------------------------------------------
# Manager-worker Mandelbrot scaling study
# -----------------------------------------------------------------------------
# Study requested by the exercise:
#   - fixed global domain: 4001 x 4001
#   - workers: 2, 4, 8, 16, 32
#   - total MPI processes = workers + 1 manager
#   - task decompositions: 50 and 100 tasks
#
# Submit with:
#   sbatch run_scaling_manager_worker.sh
#
# The script writes:
#   outputs/results_manager_worker_scaling.dat
#   outputs/run_w<W>_t<T>.out
#   outputs/mandelbrot_w<W>_t<T>.pdf
# -----------------------------------------------------------------------------

mkdir -p outputs figures

# Load your Euler software stack. Adjust these module names if your environment
# uses different Python / MPI modules.
module purge
module load stack gcc openmpi python || true

NX=4001
NY=4001
WORKERS_LIST=(2 4 8 16 32)
TASKS_LIST=(50 100)
REPEATS=1

RESULTS="outputs/results_manager_worker_scaling.dat"
echo "# ntasks workers nprocs nx ny repeat time_seconds" > "${RESULTS}"

for ntasks in "${TASKS_LIST[@]}"; do
  for workers in "${WORKERS_LIST[@]}"; do
    nprocs=$((workers + 1))

    for rep in $(seq 1 "${REPEATS}"); do
      logfile="outputs/run_w${workers}_t${ntasks}_r${rep}.out"

      echo "============================================================"
      echo "Running: workers=${workers}, nprocs=${nprocs}, ntasks=${ntasks}, repeat=${rep}"
      echo "Domain: ${NX} x ${NY}"
      echo "============================================================"

      # Rank 0 is the manager; the remaining ranks are workers.
      srun --ntasks="${nprocs}" --cpus-per-task=1 \
           python3 manager_worker.py "${NX}" "${NY}" "${ntasks}" \
           | tee "${logfile}"

      runtime=$(awk '/Run took/ {print $3}' "${logfile}" | tail -n 1)

      if [[ -z "${runtime}" ]]; then
        echo "ERROR: could not parse runtime from ${logfile}" >&2
        exit 1
      fi

      echo "${ntasks} ${workers} ${nprocs} ${NX} ${NY} ${rep} ${runtime}" >> "${RESULTS}"

      # manager_worker.py always writes mandelbrot.pdf in the working directory.
      # Rename it so every run keeps its own image.
      if [[ -f mandelbrot.pdf ]]; then
        mv mandelbrot.pdf "outputs/mandelbrot_w${workers}_t${ntasks}_r${rep}.pdf"
      fi
    done
  done
done

echo "Scaling data written to ${RESULTS}"
echo "Now generate the plot with: python3 plot_scaling_manager_worker.py"
