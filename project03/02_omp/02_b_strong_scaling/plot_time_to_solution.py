#!/usr/bin/env python3
import argparse
import csv
import os
from collections import defaultdict
from statistics import mean, stdev

import matplotlib.pyplot as plt


def read_raw_data(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # The raw file produced by the run script uses the column name "threads".
            # In the plot/report we label this quantity as NCPU.
            ncpu = int(row.get("ncpu", row.get("threads")))
            rows.append(
                {
                    "repeat": int(row["repeat"]),
                    "ncpu": ncpu,
                    "n": int(row["n"]),
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
        grouped[(row["n"], row["ncpu"])].append(row["time_s"])

    summary = []
    for (n, ncpu), times in sorted(grouped.items()):
        summary.append(
            {
                "n": n,
                "ncpu": ncpu,
                "repeats": len(times),
                "time_mean_s": mean(times),
                "time_min_s": min(times),
                "time_max_s": max(times),
                "time_std_s": stdev(times) if len(times) > 1 else 0.0,
            }
        )
    return summary


def write_summary(path, summary):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    fieldnames = [
        "n",
        "ncpu",
        "repeats",
        "time_mean_s",
        "time_min_s",
        "time_max_s",
        "time_std_s",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in summary:
            writer.writerow(row)


def plot_time_to_solution(summary, outpath):
    os.makedirs(os.path.dirname(outpath) or ".", exist_ok=True)

    plt.figure(figsize=(8, 5))
    resolutions = sorted({row["n"] for row in summary})
    all_ncpu = sorted({row["ncpu"] for row in summary})

    for n in resolutions:
        subset = [row for row in summary if row["n"] == n]
        subset.sort(key=lambda row: row["ncpu"])

        x = [row["ncpu"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]

        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=rf"$n={n}$")

    plt.yscale("log", base=10)
    plt.xticks(all_ncpu, [str(p) for p in all_ncpu])
    plt.xlabel("NCPU")
    plt.ylabel("Time to solution [s]")
    plt.title(r"Time to solution for $n \times n$ resolutions")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend(title="Resolution")
    plt.tight_layout()
    plt.savefig(outpath, dpi=300)
    plt.close()


def main():
    parser = argparse.ArgumentParser(
        description="Create a time-to-solution plot with log10 y-axis. No speedup plot is produced."
    )
    parser.add_argument("--input", required=True, help="Raw CSV produced by the scaling run")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged timings")
    parser.add_argument("--time-plot", required=True, help="Output figure path, e.g. figures/time_to_solution.pdf")
    args = parser.parse_args()

    rows = read_raw_data(args.input)
    if not rows:
        raise SystemExit("No rows found in input CSV.")

    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_time_to_solution(summary, args.time_plot)


if __name__ == "__main__":
    main()
