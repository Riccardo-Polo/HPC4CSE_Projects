#!/bin/bash
#SBATCH --job-name=fisher_weak_1ppn_resume
#SBATCH --output=outputs/weak_scaling_1ppn/%x-%j.out
#SBATCH --error=outputs/weak_scaling_1ppn/%x-%j.err
#SBATCH --nodes=64
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1024
#SBATCH --time=04:00:00
#SBATCH --constraint=EPYC_7763

set -euo pipefail

mkdir -p outputs/weak_scaling_1ppn results figures

module load stack gcc openmpi python

# Rebuild. If you are absolutely sure the executable is already up to date, run with BUILD=0.
BUILD=${BUILD:-1}
if [[ "$BUILD" == "1" ]]; then
    make clean
    make CXX=mpicxx
fi

export OMP_NUM_THREADS=1
export OMP_PLACES=cores
export OMP_PROC_BIND=close

NCPUS=(${NCPUS:-1 4 16 64})
BASE_RESOLUTIONS=(${BASE_RESOLUTIONS:-64 128 256})
REPEATS=${REPEATS:-3}
NT=${NT:-100}
TFINAL=${TFINAL:-0.005}

RAW_CSV=${RAW_CSV:-results/weak_scaling_1ppn_raw.csv}
SUMMARY_CSV=${SUMMARY_CSV:-results/weak_scaling_1ppn_summary.csv}
PLOT_NCPU=${PLOT_NCPU:-figures/weak_time_to_solution_1ppn.pdf}
PLOT_PROBLEM_SIZE=${PLOT_PROBLEM_SIZE:-figures/weak_time_to_solution_problem_size_1ppn.pdf}
PLOT_SCRIPT=${PLOT_SCRIPT:-plot_weak_scaling_time_1ppn_resume.py}

if [[ ! -f "$RAW_CSV" ]]; then
    printf 'repeat,base_n,ncpu,scaled_n,problem_size,nt,tfinal,cg_iters,newton_iters,time_s\n' > "$RAW_CSV"
fi

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

row_exists() {
    local base_n="$1"
    local p="$2"
    local repeat="$3"
    python3 - "$RAW_CSV" "$base_n" "$p" "$repeat" <<'PY'
import csv, sys
path, base_n, p, repeat = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
try:
    with open(path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            if int(row['base_n']) == base_n and int(row['ncpu']) == p and int(row['repeat']) == repeat:
                raise SystemExit(0)
except FileNotFoundError:
    pass
raise SystemExit(1)
PY
}

plot_now() {
    python3 "$PLOT_SCRIPT" \
        --input "$RAW_CSV" \
        --summary "$SUMMARY_CSV" \
        --ncpu-plot "$PLOT_NCPU" \
        --problem-size-plot "$PLOT_PROBLEM_SIZE" \
        --base-resolutions "${BASE_RESOLUTIONS[*]}" \
        --ncpus "${NCPUS[*]}" \
        --repeats "$REPEATS"
}

echo "Resume weak scaling study: one MPI process per node"
echo "Existing raw CSV : $RAW_CSV"
echo "This script skips rows already present in the CSV."
echo "It will also create plots from whatever data are available."

# First create figures from the already available data. This is useful even if no rerun is needed.
plot_now

missing_count=0
for base_n in "${BASE_RESOLUTIONS[@]}"; do
    for p in "${NCPUS[@]}"; do
        factor=$(sqrt_ncpu "$p")
        n=$(( base_n * factor ))
        for r in $(seq 1 "$REPEATS"); do
            if row_exists "$base_n" "$p" "$r"; then
                echo "Skipping existing row: base_n=${base_n}, p=${p}, repeat=${r}"
                continue
            fi

            missing_count=$((missing_count + 1))
            logfile="outputs/weak_scaling_1ppn/run_base${base_n}_n${n}_p${p}_r${r}.log"
            echo "============================================================"
            echo "Running missing case: base_n=${base_n}, p=${p}, scaled_n=${n}, repeat=${r}"
            echo "Layout: ${p} MPI process(es) on ${p} node(s), one process per node"
            echo "============================================================"

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

            actual_n=$(echo "$parsed" | cut -d',' -f2)
            actual_nt=$(echo "$parsed" | cut -d',' -f3)
            cg_iters=$(echo "$parsed" | cut -d',' -f4)
            newton_iters=$(echo "$parsed" | cut -d',' -f5)
            time_s=$(echo "$parsed" | cut -d',' -f6)
            actual_problem_size=$(( actual_n * actual_n ))

            printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
                "$r" "$base_n" "$p" "$actual_n" "$actual_problem_size" \
                "$actual_nt" "$TFINAL" "$cg_iters" "$newton_iters" "$time_s" >> "$RAW_CSV"

            # Refresh figures after each missing case, so an interrupted job still leaves a plot.
            plot_now
        done
    done
done

if [[ "$missing_count" -eq 0 ]]; then
    echo "No missing simulations were found. Only regenerated the plots."
else
    echo "Completed $missing_count missing simulation(s)."
fi

plot_now

echo "Weak scaling resume completed."
echo "Raw data          : $RAW_CSV"
echo "Summary data      : $SUMMARY_CSV"
echo "NCPU plot         : $PLOT_NCPU"
echo "Problem-size plot : $PLOT_PROBLEM_SIZE"
