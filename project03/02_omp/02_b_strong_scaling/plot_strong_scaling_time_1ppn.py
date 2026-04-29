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
                    "ncpu": int(row["ncpu"]),
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


def plot_time(summary, outpath):
    fig, ax = plt.subplots(figsize=(8, 5))
    resolutions = sorted({row["n"] for row in summary})

    for n in resolutions:
        subset = [row for row in summary if row["n"] == n]
        subset.sort(key=lambda row: row["ncpu"])
        x = [row["ncpu"] for row in subset]
        y = [row["time_mean_s"] for row in subset]
        yerr = [row["time_std_s"] for row in subset]
        ax.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=f"n={n}")

    all_ncpu = sorted({row["ncpu"] for row in summary})
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=10)
    ax.set_xticks(all_ncpu)
    ax.xaxis.set_major_formatter(ticker.ScalarFormatter())
    ax.yaxis.set_major_locator(ticker.LogLocator(base=10))
    ax.yaxis.set_major_formatter(ticker.LogFormatterMathtext(base=10))

    ax.set_xlabel("MPI processes")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Strong scaling")
    ax.grid(True, which="both", linestyle=":", linewidth=0.7, alpha=0.8)
    ax.legend(title="Resolution")
    fig.tight_layout()
    fig.savefig(outpath, bbox_inches="tight")

    png_outpath = outpath.rsplit(".", 1)[0] + ".png"
    fig.savefig(png_outpath, dpi=300, bbox_inches="tight")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(
        description="Plot strong scaling time to solution with one MPI process per node."
    )
    parser.add_argument("--input", required=True, help="Raw CSV produced by the strong-scaling script")
    parser.add_argument("--summary", required=True, help="Output CSV with averaged timings")
    parser.add_argument("--time-plot", required=True, help="Output PDF/PNG path for the time-to-solution plot")
    args = parser.parse_args()

    rows = read_raw_data(args.input)
    if not rows:
        raise SystemExit("No rows found in input CSV.")

    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_time(summary, args.time_plot)


if __name__ == "__main__":
    main()
