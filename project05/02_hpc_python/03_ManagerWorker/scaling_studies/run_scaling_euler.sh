#!/bin/bash
#SBATCH --job-name=mandel_mw_1rank_per_node
#SBATCH --output=outputs/scaling_1rank_per_node_%j.out
#SBATCH --error=outputs/scaling_1rank_per_node_%j.err
#SBATCH --time=02:00:00
#SBATCH --nodes=33
#SBATCH --ntasks=33
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --constraint=EPYC_7763

# Strong scaling study for the manager-worker Mandelbrot code on Euler.
# Fixed domain: 4001 x 4001.
# Workers: 2, 4, 8, 16, 32.
# Tasks: 50 and 100.
#
# IMPORTANT:
# The program uses rank 0 as the manager, so total MPI ranks = workers + 1.
# This script enforces one MPI rank per node with --ntasks-per-node=1.
# The largest run has 32 workers + 1 manager = 33 ranks, therefore the job
# reserves 33 nodes. Smaller runs use fewer ranks but still run one rank per node.

set -euo pipefail

mkdir -p outputs results figures

# Load the same software stack you normally use for mpi4py on Euler.
# If your working environment already loads mpi4py differently, edit these lines only.
module purge
module load stack gcc openmpi python || module load stack gcc openmpi || true

NX=4001
NY=4001
WORKERS_LIST="2 4 8 16 32"
TASKS_LIST="50 100"
REPEATS=${REPEATS:-3}
PYTHON=${PYTHON:-python3}
PROGRAM=${PROGRAM:-manager_worker.py}
RESULTS_FILE="results/scaling_4001x4001_one_rank_per_node.csv"

printf "tasks,workers,mpi_processes,nodes_used,repeat,time_seconds\n" > "${RESULTS_FILE}"

for ntasks in ${TASKS_LIST}; do
  for workers in ${WORKERS_LIST}; do
    mpi_procs=$((workers + 1))
    nodes_used=${mpi_procs}

    for rep in $(seq 1 "${REPEATS}"); do
      logfile="outputs/run_1rank_per_node_tasks${ntasks}_workers${workers}_rep${rep}.out"
      echo "============================================================"
      echo "Running one rank per node: nx=${NX}, ny=${NY}, tasks=${ntasks}, workers=${workers}, MPI processes=${mpi_procs}, nodes used=${nodes_used}, repeat=${rep}"
      echo "============================================================"

      # One MPI process per node is enforced here as well as in the SBATCH header.
      # The manager is rank 0 and each worker is one additional rank/node.
      srun -n "${mpi_procs}" --ntasks-per-node=1 \
        "${PYTHON}" "${PROGRAM}" "${NX}" "${NY}" "${ntasks}" | tee "${logfile}"

      time_seconds=$(awk '/Run took/ {print $3}' "${logfile}" | tail -n 1)
      if [[ -z "${time_seconds}" ]]; then
        echo "ERROR: could not parse runtime from ${logfile}" >&2
        exit 1
      fi

      printf "%s,%s,%s,%s,%s,%s\n" \
        "${ntasks}" "${workers}" "${mpi_procs}" "${nodes_used}" "${rep}" "${time_seconds}" >> "${RESULTS_FILE}"

      if [[ -f mandelbrot.pdf ]]; then
        mv mandelbrot.pdf "outputs/mandelbrot_1rank_per_node_tasks${ntasks}_workers${workers}_rep${rep}.pdf"
      fi
    done
  done
done

"${PYTHON}" plot_scaling.py "${RESULTS_FILE}" figures

echo "Scaling study complete."
echo "Raw results: ${RESULTS_FILE}"
echo "Figures: figures/runtime_vs_workers.pdf and figures/speedup_vs_workers.pdf"
