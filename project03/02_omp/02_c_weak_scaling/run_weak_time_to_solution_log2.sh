#!/bin/bash
#SBATCH --job-name=fisher_weak_time_log2
#SBATCH --output=outputs/weak_scaling/%x-%j.out
#SBATCH --error=outputs/weak_scaling/%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=1024
#SBATCH --time=02:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/weak_scaling results figures

module load stack gcc python

make clean
make

# OpenMP binding for more reproducible timing.
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# Weak scaling parameters.
# The global resolution is scaled as scaled_n = base_n * sqrt(NCPU),
# so scaled_n^2 / NCPU = base_n^2 remains constant.
NCPUS=(${NCPUS:-1 4 16 64})
BASE_RESOLUTIONS=(${BASE_RESOLUTIONS:-64 128 256})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV="results/weak_time_to_solution_raw.csv"
SUMMARY_CSV="results/weak_time_to_solution_summary.csv"
PLOT_NCPU="figures/weak_time_to_solution_vs_ncpu_log2.pdf"
PLOT_PROBLEM_SIZE="figures/weak_time_to_solution_vs_problem_size_log2.pdf"

printf 'repeat,base_n,ncpu,scaled_n,problem_size,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"

sqrt_ncpu() {
    case "$1" in
        1)  echo 1 ;;
        4)  echo 2 ;;
        16) echo 4 ;;
        64) echo 8 ;;
        *)
            echo "Unsupported NCPU for this weak-scaling study: $1" >&2
            echo "Expected one of: 1 4 16 64" >&2
            exit 1
            ;;
    esac
}

echo "Starting weak-scaling time-to-solution study"
echo "NCPU             : ${NCPUS[*]}"
echo "Base resolutions : ${BASE_RESOLUTIONS[*]}"
echo "Repeats          : $REPEATS"
echo "NT               : $NT"
echo "TFINAL           : $TFINAL"
echo "Output y-axis    : log base 2"

for base_n in "${BASE_RESOLUTIONS[@]}"; do
    for ncpu in "${NCPUS[@]}"; do
        factor=$(sqrt_ncpu "$ncpu")
        scaled_n=$(( base_n * factor ))

        echo "============================================================"
        echo "Running base_n=${base_n}, NCPU=${ncpu}, scaled_n=${scaled_n}"
        echo "Work per CPU: scaled_n^2 / NCPU = $(( scaled_n * scaled_n / ncpu )) grid points"
        echo "============================================================"

        export OMP_NUM_THREADS="$ncpu"

        for r in $(seq 1 "$REPEATS"); do
            logfile="outputs/weak_scaling/run_base${base_n}_n${scaled_n}_ncpu${ncpu}_r${r}.log"
            echo "  -> repeat ${r}/${REPEATS}"

            ./main "$scaled_n" "$NT" "$TFINAL" | tee "$logfile"

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
            problem_size=$(( actual_n * actual_n ))

            printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$base_n" "$actual_ncpu" "$actual_n" "$problem_size" \
                "$actual_nt" "$TFINAL" "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"
        done
    done
done

python3 plot_weak_time_to_solution_log2.py \
    --input "$RAW_CSV" \
    --summary "$SUMMARY_CSV" \
    --ncpu-plot "$PLOT_NCPU" \
    --problem-size-plot "$PLOT_PROBLEM_SIZE"

echo "Weak-scaling study completed."
echo "Raw data          : $RAW_CSV"
echo "Summary data      : $SUMMARY_CSV"
echo "NCPU plot         : $PLOT_NCPU"
echo "Problem-size plot : $PLOT_PROBLEM_SIZE"
