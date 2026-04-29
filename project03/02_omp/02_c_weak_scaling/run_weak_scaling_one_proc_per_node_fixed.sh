#!/bin/bash
#SBATCH --job-name=fisher_weak_1ppn
#SBATCH --output=outputs/weak_scaling_1ppn/%x-%j.out
#SBATCH --error=outputs/weak_scaling_1ppn/%x-%j.err
#SBATCH --nodes=64
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1024
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/weak_scaling_1ppn results figures

module load stack gcc openmpi python

# Build with the MPI compiler wrapper, as in the one-process-per-node strong-scaling script.
# This overrides CXX ?= g++ in the Makefile.
make clean
make CXX=mpicxx

# Pure MPI layout: one MPI process per node and one CPU core per process.
# No OpenMP parallelism inside each MPI process.
export OMP_NUM_THREADS=1
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# Weak scaling parameters. For a 2D n x n problem, keeping the workload per process
# approximately constant requires global_n = base_n * sqrt(NCPU).
NCPUS=(${NCPUS:-1 4 16 64})
BASE_RESOLUTIONS=(${BASE_RESOLUTIONS:-64 128 256})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV="results/weak_scaling_1ppn_raw.csv"
SUMMARY_CSV="results/weak_scaling_1ppn_summary.csv"
PLOT_NCPU="figures/weak_time_to_solution_1ppn.pdf"
PLOT_PROBLEM_SIZE="figures/weak_time_to_solution_problem_size_1ppn.pdf"

printf 'repeat,base_n,ncpu,scaled_n,problem_size,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"

sqrt_ncpu() {
    case "$1" in
        1)  echo 1 ;;
        4)  echo 2 ;;
        16) echo 4 ;;
        64) echo 8 ;;
        *)
            echo "Unsupported NCPU for weak scaling: $1" >&2
            echo "Expected one of: 1 4 16 64" >&2
            exit 1
            ;;
    esac
}

echo "Starting weak scaling study: one MPI process per node"
echo "MPI processes     : ${NCPUS[*]}"
echo "Base resolutions  : ${BASE_RESOLUTIONS[*]}"
echo "Repeats           : $REPEATS"
echo "NT                : $NT"
echo "TFINAL            : $TFINAL"
echo "Slurm layout      : --nodes=p, --ntasks=p, --ntasks-per-node=1"
echo "OMP_NUM_THREADS   : $OMP_NUM_THREADS"

for base_n in "${BASE_RESOLUTIONS[@]}"; do
    for p in "${NCPUS[@]}"; do
        factor=$(sqrt_ncpu "$p")
        n=$(( base_n * factor ))
        problem_size=$(( n * n ))

        echo "============================================================"
        echo "Running base_n=${base_n}, MPI processes=${p}, scaled_n=${n}, problem_size=${problem_size}"
        echo "Layout: ${p} MPI process(es) on ${p} node(s), one process per node"
        echo "============================================================"

        for r in $(seq 1 "$REPEATS"); do
            logfile="outputs/weak_scaling_1ppn/run_base${base_n}_n${n}_p${p}_r${r}.log"
            echo "  -> repeat ${r}/${REPEATS}"

            srun --nodes="$p" \
                 --ntasks="$p" \
                 --ntasks-per-node=1 \
                 --cpus-per-task=1 \
                 ./main "$n" "$NT" "$TFINAL" | tee "$logfile"

            summary_line=$(grep '###' "$logfile" | tail -n 1 | tr -d '#')
            if [[ -z "$summary_line" ]]; then
                echo "Could not find summary line in $logfile" >&2
                exit 1
            fi

            parsed=$(echo "$summary_line" | awk -F',' '
                {
                    for (i = 1; i <= NF; ++i) {
                        gsub(/^[ \t]+|[ \t]+$/, "", $i)
                    }
                    printf "%s,%s,%s,%s,%s,%s", $1, $2, $3, $4, $5, $6
                }
            ')

            # The executable summary line has the format
            #   ### threads_or_ncpu, n, nt, cg_iters, newton_iters, time_s ###
            # In this pure-MPI 1ppn study OMP_NUM_THREADS=1, so the first field may be 1.
            # The correct x-axis variable is the Slurm/MPI process count p.
            actual_n=$(echo "$parsed" | cut -d',' -f2)
            actual_nt=$(echo "$parsed" | cut -d',' -f3)
            cg_iters=$(echo "$parsed" | cut -d',' -f4)
            newton_iters=$(echo "$parsed" | cut -d',' -f5)
            time_s=$(echo "$parsed" | cut -d',' -f6)
            actual_problem_size=$(( actual_n * actual_n ))

            printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$base_n" "$p" "$actual_n" "$actual_problem_size" \
                "$actual_nt" "$TFINAL" "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"
        done
    done
done

python3 plot_weak_scaling_time_1ppn_fixed.py \
    --input "$RAW_CSV" \
    --summary "$SUMMARY_CSV" \
    --ncpu-plot "$PLOT_NCPU" \
    --problem-size-plot "$PLOT_PROBLEM_SIZE"

echo "Weak scaling study completed."
echo "Raw data          : $RAW_CSV"
echo "Summary data      : $SUMMARY_CSV"
echo "NCPU plot         : $PLOT_NCPU"
echo "Problem-size plot : $PLOT_PROBLEM_SIZE"
