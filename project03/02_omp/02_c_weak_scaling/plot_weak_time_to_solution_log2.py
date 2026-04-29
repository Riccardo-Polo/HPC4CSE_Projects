#!/usr/bin/env python3
import argparse
import csv
from collections import defaultdict
from statistics import mean, stdev

import matplotlib.pyplot as plt


def read_raw_data(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(
                {
                    "repeat": int(row["repeat"]),
                    "base_n": int(row["base_n"]),
                    "ncpu": int(row["ncpu"]),
                    "scaled_n": int(row["scaled_n"]),
                    "problem_size": int(row["problem_size"]),
                    "nt": int(row["nt"]),
                    "tfinal": float(row["tfinal"]),
                    "cg_iters": int(row["cg_iters"]),
                    "newton_iters": int(row["newton_iters"]),
                    "time_s": float(row["time_s"]),
                }
            )
    return rows


def summarize(rows):
    grouped = defaultdict(list)
    for row in rows:
        key = (row["base_n"], row["ncpu"], row["scaled_n"], row["problem_size"])
        grouped[key].append(row)

    summary = []
    for (base_n, ncpu, scaled_n, problem_size), entries in sorted(grouped.items()):
        times = [entry["time_s"] for entry in entries]
        cg_iters = [entry["cg_iters"] for entry in entries]
        newton_iters = [entry["newton_iters"] for entry in entries]

        summary.append(
            {
                "base_n": base_n,
                "ncpu": ncpu,
                "scaled_n": scaled_n,
                "problem_size": problem_size,
                "repeats": len(entries),
                "time_mean_s": mean(times),
                "time_min_s": min(times),
                "time_max_s": max(times),
                "time_std_s": stdev(times) if len(times) > 1 else 0.0,
                "cg_iters_mean": mean(cg_iters),
                "newton_iters_mean": mean(newton_iters),
            }
        )

    return summary


def write_summary(path, summary):
    fieldnames = [
        "base_n",
        "ncpu",
        "scaled_n",
        "problem_size",
        "repeats",
        "time_mean_s",
        "time_min_s",
        "time_max_s",
        "time_std_s",
        "cg_iters_mean",
        "newton_iters_mean",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in summary:
            writer.writerow(row)


def set_log2_y_axis():
    # Time-to-solution is the quantity of interest, so the y-axis is log base 2.
    plt.yscale("log", base=2)


def plot_time_vs_ncpu(summary, outpath):
    plt.figure(figsize=(8, 5))
    base_resolutions = sorted({row["base_n"] for row in summary})

    for base_n in base_resolutions:
        subset = [row for row in summary if row["base_n"] == base_n]
        subset.sort(key=lambda row: row["ncpu"])

        x = [row["ncpu"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]

        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=rf"base $n={base_n}$")

        for row in subset:
            plt.annotate(
                rf"$n={row['scaled_n']}$",
                (row["ncpu"], row["time_mean_s"]),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    plt.xscale("log", base=2)
    set_log2_y_axis()
    ncpu_values = sorted({row["ncpu"] for row in summary})
    plt.xticks(ncpu_values, [str(v) for v in ncpu_values])
    plt.xlabel("NCPU")
    plt.ylabel("Time to solution [s]")
    plt.title("Weak scaling: time to solution vs NCPU")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath)
    plt.close()


def plot_time_vs_problem_size(summary, outpath):
    plt.figure(figsize=(8, 5))
    base_resolutions = sorted({row["base_n"] for row in summary})

    for base_n in base_resolutions:
        subset = [row for row in summary if row["base_n"] == base_n]
        subset.sort(key=lambda row: row["problem_size"])

        x = [row["problem_size"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]

        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=rf"base $n={base_n}$")

        for row in subset:
            label = rf"${row['scaled_n']}^2$, {row['ncpu']} CPU"
            plt.annotate(
                label,
                (row["problem_size"], row["time_mean_s"]),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    plt.xscale("log", base=2)
    set_log2_y_axis()
    problem_sizes = sorted({row["problem_size"] for row in summary})
    plt.xticks(problem_sizes, [str(v) for v in problem_sizes], rotation=35, ha="right")
    plt.xlabel(r"Total problem size $n^2$ grid points")
    plt.ylabel("Time to solution [s]")
    plt.title("Weak scaling: time to solution vs total problem size")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath)
    plt.close()


def main():
    parser = argparse.ArgumentParser(description="Plot weak-scaling time-to-solution results using log2 scale.")
    parser.add_argument("--input", required=True, help="Raw CSV produced by run_weak_time_to_solution_log2.sh")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged timings")
    parser.add_argument("--ncpu-plot", required=True, help="Output PDF for time-to-solution vs NCPU")
    parser.add_argument("--problem-size-plot", required=True, help="Output PDF for time-to-solution vs total problem size")
    args = parser.parse_args()

    rows = read_raw_data(args.input)
    if not rows:
        raise SystemExit("No rows found in input CSV.")

    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_time_vs_ncpu(summary, args.ncpu_plot)
    plot_time_vs_problem_size(summary, args.problem_size_plot)


if __name__ == "__main__":
    main()
