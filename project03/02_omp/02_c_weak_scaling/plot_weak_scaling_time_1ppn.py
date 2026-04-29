#!/usr/bin/env python3
import argparse
import csv
from collections import defaultdict
from statistics import mean, stdev

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker


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


def set_common_log_axes(ax, x_values):
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_xticks(sorted(x_values))
    ax.xaxis.set_major_formatter(ticker.ScalarFormatter())
    ax.yaxis.set_major_locator(ticker.LogLocator(base=2))
    ax.yaxis.set_major_formatter(ticker.LogFormatterMathtext(base=2))
    ax.grid(True, which="both", linestyle=":", linewidth=0.7, alpha=0.8)


def plot_time_vs_ncpu(summary, outpath):
    fig, ax = plt.subplots(figsize=(8, 5))
    base_resolutions = sorted({row["base_n"] for row in summary})

    for base_n in base_resolutions:
        subset = [row for row in summary if row["base_n"] == base_n]
        subset.sort(key=lambda row: row["ncpu"])
        x = [row["ncpu"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]
        ax.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"base n={base_n}")

        for row in subset:
            ax.annotate(
                f"n={row['scaled_n']}",
                (row["ncpu"], row["time_mean_s"]),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    set_common_log_axes(ax, {row["ncpu"] for row in summary})
    ax.set_xlabel("MPI processes / NCPU")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Weak scaling, one process per node")
    ax.legend(title="Base resolution")
    fig.tight_layout()
    fig.savefig(outpath, bbox_inches="tight")
    fig.savefig(outpath.replace(".pdf", ".png"), dpi=300, bbox_inches="tight")
    plt.close(fig)


def plot_time_vs_problem_size(summary, outpath):
    fig, ax = plt.subplots(figsize=(8, 5))
    base_resolutions = sorted({row["base_n"] for row in summary})

    for base_n in base_resolutions:
        subset = [row for row in summary if row["base_n"] == base_n]
        subset.sort(key=lambda row: row["problem_size"])
        x = [row["problem_size"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]
        ax.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"base n={base_n}")

        for row in subset:
            label = f"{row['scaled_n']}×{row['scaled_n']} / {row['ncpu']}"
            ax.annotate(
                label,
                (row["problem_size"], row["time_mean_s"]),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    set_common_log_axes(ax, {row["problem_size"] for row in summary})
    ax.set_xlabel(r"Total problem size $n^2$ grid points")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Weak scaling time vs total problem size")
    ax.legend(title="Base resolution")
    fig.tight_layout()
    fig.savefig(outpath, bbox_inches="tight")
    fig.savefig(outpath.replace(".pdf", ".png"), dpi=300, bbox_inches="tight")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description="Plot weak scaling time-to-solution results.")
    parser.add_argument("--input", required=True, help="Raw CSV produced by the weak-scaling Slurm script")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged results")
    parser.add_argument("--ncpu-plot", required=True, help="Output PDF for time-vs-NCPU plot")
    parser.add_argument("--problem-size-plot", required=True, help="Output PDF for time-vs-problem-size plot")
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
