#!/bin/bash
#SBATCH --job-name=fisher_weak_scaling
#SBATCH --output=outputs/weak_scaling/%x-%j.out
#SBATCH --error=outputs/weak_scaling/%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1024
#SBATCH --time=03:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/weak_scaling results figures

module load stack gcc python

make clean
make

export OMP_PLACES=cores
export OMP_PROC_BIND=close

THREADS=(${THREADS:-1 4 16 64})
BASE_RESOLUTIONS=(${BASE_RESOLUTIONS:-64 128 256})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV="results/weak_scaling_raw.csv"
SUMMARY_CSV="results/weak_scaling_summary.csv"
PLOT_THREADS="figures/weak_scaling_time_threads.pdf"
PLOT_PROBLEM_SIZE="figures/weak_scaling_time_problem_size.pdf"

printf 'repeat,base_n,threads,scaled_n,problem_size,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"

sqrt_threads() {
    case "$1" in
        1)  echo 1 ;;
        4)  echo 2 ;;
        16) echo 4 ;;
        64) echo 8 ;;
        *)
            echo "Unsupported thread count for weak scaling: $1" >&2
            echo "Expected one of: 1 4 16 64" >&2
            exit 1
            ;;
    esac
}

echo "Starting weak scaling study"
echo "Threads          : ${THREADS[*]}"
echo "Base resolutions : ${BASE_RESOLUTIONS[*]}"
echo "Repeats          : $REPEATS"
echo "NT               : $NT"
echo "TFINAL           : $TFINAL"

for base_n in "${BASE_RESOLUTIONS[@]}"; do
    for t in "${THREADS[@]}"; do
        factor=$(sqrt_threads "$t")
        n=$(( base_n * factor ))

        echo "============================================================"
        echo "Running base_n=${base_n}, threads=${t}, scaled_n=${n}"
        echo "============================================================"

        export OMP_NUM_THREADS="$t"

        for r in $(seq 1 "$REPEATS"); do
            logfile="outputs/weak_scaling/run_base${base_n}_n${n}_t${t}_r${r}.log"
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
            problem_size=$(( actual_n * actual_n ))

            printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$base_n" "$actual_threads" "$actual_n" "$problem_size" \
                "$actual_nt" "$TFINAL" "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"
        done
    done
done

python3 plot_weak_scaling.py \
    --input "$RAW_CSV" \
    --summary "$SUMMARY_CSV" \
    --threads-plot "$PLOT_THREADS" \
    --problem-size-plot "$PLOT_PROBLEM_SIZE"

echo "Weak scaling study completed."
echo "Raw data          : $RAW_CSV"
echo "Summary data      : $SUMMARY_CSV"
echo "Threads plot      : $PLOT_THREADS"
echo "Problem-size plot : $PLOT_PROBLEM_SIZE"
