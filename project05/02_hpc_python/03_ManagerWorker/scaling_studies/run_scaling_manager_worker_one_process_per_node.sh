#!/bin/bash
#SBATCH --job-name=mw_scaling_nodes
#SBATCH --output=outputs/scaling_nodes_%j.out
#SBATCH --error=outputs/scaling_nodes_%j.err
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763
#SBATCH --nodes=33
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G

set -euo pipefail

# -----------------------------------------------------------------------------
# Same scaling study as run_scaling_manager_worker.sh, but forces one MPI process
# per node. This is useful only if your instructor explicitly wants this layout.
#
# Rank 0 is still the manager, so for W workers the run uses W+1 nodes/processes.
# -----------------------------------------------------------------------------

mkdir -p outputs figures

module purge
module load stack gcc openmpi python || true

NX=4001
NY=4001
WORKERS_LIST=(2 4 8 16 32)
TASKS_LIST=(50 100)
REPEATS=3

RESULTS="outputs/results_manager_worker_scaling_one_process_per_node.dat"
echo "# ntasks workers nprocs nx ny repeat time_seconds" > "${RESULTS}"

for ntasks in "${TASKS_LIST[@]}"; do
  for workers in "${WORKERS_LIST[@]}"; do
    nprocs=$((workers + 1))

    for rep in $(seq 1 "${REPEATS}"); do
      logfile="outputs/run_nodes_w${workers}_t${ntasks}_r${rep}.out"

      echo "============================================================"
      echo "Running one process per node: workers=${workers}, nprocs=${nprocs}, ntasks=${ntasks}, repeat=${rep}"
      echo "Domain: ${NX} x ${NY}"
      echo "============================================================"

      srun --nodes="${nprocs}" --ntasks="${nprocs}" --ntasks-per-node=1 --cpus-per-task=1 \
           python3 manager_worker.py "${NX}" "${NY}" "${ntasks}" \
           | tee "${logfile}"

      runtime=$(awk '/Run took/ {print $3}' "${logfile}" | tail -n 1)

      if [[ -z "${runtime}" ]]; then
        echo "ERROR: could not parse runtime from ${logfile}" >&2
        exit 1
      fi

      echo "${ntasks} ${workers} ${nprocs} ${NX} ${NY} ${rep} ${runtime}" >> "${RESULTS}"

      if [[ -f mandelbrot.pdf ]]; then
        mv mandelbrot.pdf "outputs/mandelbrot_nodes_w${workers}_t${ntasks}_r${rep}.pdf"
      fi
    done
  done
done

echo "Scaling data written to ${RESULTS}"
echo "To plot this file, run:"
echo "python3 plot_scaling_manager_worker.py outputs/results_manager_worker_scaling_one_process_per_node.dat figures/manager_worker_time_log10_one_process_per_node.pdf"
