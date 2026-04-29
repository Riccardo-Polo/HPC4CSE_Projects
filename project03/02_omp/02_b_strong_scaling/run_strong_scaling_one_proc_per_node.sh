#!/bin/bash
#SBATCH --job-name=fisher_strong_1ppn
#SBATCH --output=outputs/strong_scaling/%x-%j.out
#SBATCH --error=outputs/strong_scaling/%x-%j.err
#SBATCH --nodes=16
#SBATCH --ntasks=16
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1024
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/strong_scaling results figures

module load stack gcc openmpi python

# Build with the MPI compiler wrapper. This overrides CXX ?= g++ in the Makefile.
make clean
make CXX=mpicxx

# Pure MPI scaling: one MPI process per node and one CPU/thread per process.
export OMP_NUM_THREADS=1
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# Strong scaling parameters. You can override these when submitting, e.g.
# sbatch --export=ALL,REPEATS=5 run_strong_scaling_one_proc_per_node.sh
NCPUS=(${NCPUS:-1 2 4 8 16})
RESOLUTIONS=(${RESOLUTIONS:-64 128 256 512 1024})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV="results/strong_scaling_1ppn_raw.csv"
SUMMARY_CSV="results/strong_scaling_1ppn_summary.csv"
PLOT_TIME="figures/strong_scaling_1ppn_time.pdf"

printf 'repeat,ncpu,n,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"

echo "Starting strong scaling study: one MPI process per node"
echo "MPI processes : ${NCPUS[*]}"
echo "Resolutions   : ${RESOLUTIONS[*]}"
echo "Repeats       : $REPEATS"
echo "NT            : $NT"
echo "TFINAL        : $TFINAL"
echo "OMP_NUM_THREADS=$OMP_NUM_THREADS"

for n in "${RESOLUTIONS[@]}"; do
    for p in "${NCPUS[@]}"; do
        echo "============================================================"
        echo "Running n=${n}, MPI processes=${p}, one process per node"
        echo "============================================================"

        for r in $(seq 1 "$REPEATS"); do
            logfile="outputs/strong_scaling/run_n${n}_p${p}_r${r}_1ppn.log"
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

            actual_ncpu=$(echo "$parsed" | cut -d',' -f1)
            actual_n=$(echo "$parsed" | cut -d',' -f2)
            actual_nt=$(echo "$parsed" | cut -d',' -f3)
            cg_iters=$(echo "$parsed" | cut -d',' -f4)
            newton_iters=$(echo "$parsed" | cut -d',' -f5)
            time_s=$(echo "$parsed" | cut -d',' -f6)

            printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$actual_ncpu" "$actual_n" "$actual_nt" "$TFINAL" \
                "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"
        done
    done
done

python3 plot_strong_scaling_time_1ppn.py \
    --input "$RAW_CSV" \
    --summary "$SUMMARY_CSV" \
    --time-plot "$PLOT_TIME"

echo "Strong scaling study completed."
echo "Raw data     : $RAW_CSV"
echo "Summary data : $SUMMARY_CSV"
echo "Time plot    : $PLOT_TIME"
