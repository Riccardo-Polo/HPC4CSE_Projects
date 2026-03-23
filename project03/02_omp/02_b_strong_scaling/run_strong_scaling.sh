#!/bin/bash
#SBATCH --job-name=fisher_strong_scaling
#SBATCH --output=outputs/strong_scaling/%x-%j.out
#SBATCH --error=outputs/strong_scaling/%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1024
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/strong_scaling results figures

module load stack gcc python

# Build the executable once before the scaling runs.
make clean
make

# OpenMP settings: use core binding for more stable timings.
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# Study parameters (can be overridden from the shell before sbatch).
THREADS=(${THREADS:-1 2 4 8 16})
RESOLUTIONS=(${RESOLUTIONS:-64 128 256 512 1024})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV="results/strong_scaling_raw.csv"
SUMMARY_CSV="results/strong_scaling_summary.csv"
PLOT_TIME="figures/strong_scaling_time.pdf"
PLOT_SPEEDUP="figures/strong_scaling_speedup.pdf"

printf 'repeat,threads,n,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"

echo "Starting strong scaling study"
echo "Threads     : ${THREADS[*]}"
echo "Resolutions : ${RESOLUTIONS[*]}"
echo "Repeats     : $REPEATS"
echo "NT          : $NT"
echo "TFINAL      : $TFINAL"


for n in "${RESOLUTIONS[@]}"; do
    for t in "${THREADS[@]}"; do
        echo "============================================================"
        echo "Running n=${n}, threads=${t}"
        echo "============================================================"

        export OMP_NUM_THREADS="$t"

        for r in $(seq 1 "$REPEATS"); do
            logfile="outputs/strong_scaling/run_n${n}_t${t}_r${r}.log"
            echo "  -> repeat ${r}/${REPEATS}"

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

            actual_threads=$(echo "$parsed" | cut -d',' -f1)
            actual_n=$(echo "$parsed" | cut -d',' -f2)
            actual_nt=$(echo "$parsed" | cut -d',' -f3)
            cg_iters=$(echo "$parsed" | cut -d',' -f4)
            newton_iters=$(echo "$parsed" | cut -d',' -f5)
            time_s=$(echo "$parsed" | cut -d',' -f6)

            printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$actual_threads" "$actual_n" "$actual_nt" "$TFINAL" \
                "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"
        done
    done
done

python3 plot_strong_scaling.py \
    --input "$RAW_CSV" \
    --summary "$SUMMARY_CSV" \
    --time-plot "$PLOT_TIME" \
    --speedup-plot "$PLOT_SPEEDUP"

echo "Strong scaling study completed."
echo "Raw data     : $RAW_CSV"
echo "Summary data : $SUMMARY_CSV"
echo "Time plot    : $PLOT_TIME"
echo "Speedup plot : $PLOT_SPEEDUP"