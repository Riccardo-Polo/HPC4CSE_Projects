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
                    "threads": int(row["threads"]),
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
        key = (row["base_n"], row["threads"], row["scaled_n"], row["problem_size"])
        grouped[key].append(row)

    summary = []
    for (base_n, threads, scaled_n, problem_size), entries in sorted(grouped.items()):
        times = [entry["time_s"] for entry in entries]
        cg_iters = [entry["cg_iters"] for entry in entries]
        newton_iters = [entry["newton_iters"] for entry in entries]

        summary.append(
            {
                "base_n": base_n,
                "threads": threads,
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

    baseline = {
        row["base_n"]: row["time_mean_s"]
        for row in summary
        if row["threads"] == 1
    }
    for row in summary:
        row["weak_scaling_efficiency"] = baseline[row["base_n"]] / row["time_mean_s"]

    return summary


def write_summary(path, summary):
    fieldnames = [
        "base_n",
        "threads",
        "scaled_n",
        "problem_size",
        "repeats",
        "time_mean_s",
        "time_min_s",
        "time_max_s",
        "time_std_s",
        "cg_iters_mean",
        "newton_iters_mean",
        "weak_scaling_efficiency",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in summary:
            writer.writerow(row)


def plot_time_vs_threads(summary, outpath):
    plt.figure(figsize=(8, 5))
    base_resolutions = sorted({row["base_n"] for row in summary})

    for base_n in base_resolutions:
        subset = [row for row in summary if row["base_n"] == base_n]
        subset.sort(key=lambda row: row["threads"])
        x = [row["threads"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]
        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"base n={base_n}")

        for row in subset:
            plt.annotate(
                f"n={row['scaled_n']}",
                (row["threads"], row["time_mean_s"]),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    plt.xscale("log", base=2)
    plt.xticks(sorted({row["threads"] for row in summary}))
    plt.xlabel("OpenMP threads")
    plt.ylabel("Time to solution [s]")
    plt.title("Weak scaling of Fisher mini-app")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
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
        labels = [f"{row['scaled_n']}×{row['scaled_n']} / {row['threads']}" for row in subset]

        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"base n={base_n}")

        for xi, yi, label in zip(x, y, labels):
            plt.annotate(
                label,
                (xi, yi),
                textcoords="offset points",
                xytext=(0, 6),
                ha="center",
                fontsize=8,
            )

    plt.xscale("log", base=2)
    plt.xticks(sorted({row["problem_size"] for row in summary}))
    plt.xlabel("Total problem size (n² grid points)")
    plt.ylabel("Time to solution [s]")
    plt.title("Weak scaling time vs total problem size")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def main():
    parser = argparse.ArgumentParser(description="Plot weak scaling results.")
    parser.add_argument("--input", required=True, help="Raw CSV produced by run_weak_scaling.sh")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged results")
    parser.add_argument("--threads-plot", required=True, help="Output PNG for time-vs-threads plot")
    parser.add_argument(
        "--problem-size-plot",
        required=True,
        help="Output PNG for time-vs-problem-size plot",
    )
    args = parser.parse_args()

    rows = read_raw_data(args.input)
    if not rows:
        raise SystemExit("No rows found in input CSV.")

    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_time_vs_threads(summary, args.threads_plot)
    plot_time_vs_problem_size(summary, args.problem_size_plot)


if __name__ == "__main__":
    main()
