#!/usr/bin/env python
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
                    "threads": int(row["threads"]),
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
        grouped[(row["n"], row["threads"])].append(row["time_s"])

    summary = []
    for (n, threads), times in sorted(grouped.items()):
        row = {
            "n": n,
            "threads": threads,
            "repeats": len(times),
            "time_mean_s": mean(times),
            "time_min_s": min(times),
            "time_max_s": max(times),
            "time_std_s": stdev(times) if len(times) > 1 else 0.0,
        }
        summary.append(row)

    # Add speedup and efficiency using the mean time at 1 thread as baseline.
    baseline = {row["n"]: row["time_mean_s"] for row in summary if row["threads"] == 1}
    for row in summary:
        t1 = baseline[row["n"]]
        row["speedup"] = t1 / row["time_mean_s"]
        row["efficiency"] = row["speedup"] / row["threads"]

    return summary


def write_summary(path, summary):
    fieldnames = [
        "n",
        "threads",
        "repeats",
        "time_mean_s",
        "time_min_s",
        "time_max_s",
        "time_std_s",
        "speedup",
        "efficiency",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in summary:
            writer.writerow(row)


def plot_time(summary, outpath):
    plt.figure(figsize=(8, 5))
    resolutions = sorted({row["n"] for row in summary})

    for n in resolutions:
        subset = [row for row in summary if row["n"] == n]
        subset.sort(key=lambda row: row["threads"])
        x = [row["threads"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]
        plt.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"n={n}")

    plt.xscale("log", base=2)
    plt.xticks(sorted({row["threads"] for row in summary}))
    plt.xlabel("OpenMP threads")
    plt.ylabel("Time to solution [s]")
    plt.title("Strong scaling of Fisher mini-app")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def plot_speedup(summary, outpath):
    plt.figure(figsize=(8, 5))
    resolutions = sorted({row["n"] for row in summary})
    all_threads = sorted({row["threads"] for row in summary})

    for n in resolutions:
        subset = [row for row in summary if row["n"] == n]
        subset.sort(key=lambda row: row["threads"])
        x = [row["threads"] for row in subset]
        y = [row["speedup"] for row in subset]
        plt.plot(x, y, marker="o", label=f"n={n}")

    plt.plot(all_threads, all_threads, linestyle="--", label="ideal")
    plt.xscale("log", base=2)
    plt.yscale("log", base=2)
    plt.xticks(all_threads)
    plt.yticks(all_threads)
    plt.xlabel("OpenMP threads")
    plt.ylabel("Speedup")
    plt.title("Strong scaling speedup of Fisher mini-app")
    plt.grid(True, which="both", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def main():
    parser = argparse.ArgumentParser(description="Plot strong scaling results.")
    parser.add_argument("--input", required=True, help="Raw CSV produced by run_strong_scaling.sh")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged results")
    parser.add_argument("--time-plot", required=True, help="Output PNG for time-to-solution plot")
    parser.add_argument("--speedup-plot", required=True, help="Output PNG for speedup plot")
    args = parser.parse_args()

    rows = read_raw_data(args.input)
    if not rows:
        raise SystemExit("No rows found in input CSV.")

    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_time(summary, args.time_plot)
    plot_speedup(summary, args.speedup_plot)


if __name__ == "__main__":
    main()
