#!/usr/bin/env python3
"""Plot manager-worker Mandelbrot scaling results.

Input CSV columns expected:
    tasks,workers,mpi_processes,repeat,time_seconds
"""

import csv
import math
import statistics as stats
import sys
from collections import defaultdict
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt


def read_rows(path: Path):
    with path.open(newline="") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            rows.append({
                "tasks": int(row["tasks"]),
                "workers": int(row["workers"]),
                "mpi_processes": int(row["mpi_processes"]),
                "repeat": int(row["repeat"]),
                "time_seconds": float(row["time_seconds"]),
            })
    if not rows:
        raise ValueError(f"No rows found in {path}")
    return rows


def aggregate(rows):
    grouped = defaultdict(list)
    for r in rows:
        grouped[(r["tasks"], r["workers"], r["mpi_processes"])].append(r["time_seconds"])

    summary = []
    for (tasks, workers, mpi_processes), values in sorted(grouped.items()):
        mean = stats.mean(values)
        std = stats.stdev(values) if len(values) > 1 else 0.0
        summary.append({
            "tasks": tasks,
            "workers": workers,
            "mpi_processes": mpi_processes,
            "mean_time": mean,
            "std_time": std,
            "nrepeats": len(values),
        })
    return summary


def write_summary(summary, outdir: Path):
    outpath = outdir / "scaling_4001x4001_summary.csv"
    with outpath.open("w", newline="") as f:
        fieldnames = ["tasks", "workers", "mpi_processes", "mean_time", "std_time", "nrepeats"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary)
    return outpath


def plot_runtime(summary, outdir: Path):
    plt.figure()
    for tasks in sorted({s["tasks"] for s in summary}):
        data = [s for s in summary if s["tasks"] == tasks]
        workers = [s["workers"] for s in data]
        means = [s["mean_time"] for s in data]
        stds = [s["std_time"] for s in data]
        plt.errorbar(workers, means, yerr=stds, marker="o", capsize=3, label=f"{tasks} tasks")

    plt.xscale("log", base=2)
    plt.xticks([2, 4, 8, 16, 32], ["2", "4", "8", "16", "32"])
    plt.xlabel("Number of workers")
    plt.ylabel("Time to solution [s]")
    plt.title("Manager-worker Mandelbrot scaling, 4001x4001 domain")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / "runtime_vs_workers.pdf")
    plt.savefig(outdir / "runtime_vs_workers.png", dpi=200)
    plt.close()


def plot_speedup(summary, outdir: Path):
    plt.figure()
    for tasks in sorted({s["tasks"] for s in summary}):
        data = [s for s in summary if s["tasks"] == tasks]
        base = next((s["mean_time"] for s in data if s["workers"] == 2), None)
        if base is None:
            continue
        workers = [s["workers"] for s in data]
        speedup = [base / s["mean_time"] for s in data]
        plt.plot(workers, speedup, marker="o", label=f"{tasks} tasks")

    ideal_workers = [2, 4, 8, 16, 32]
    # Normalized to the 2-worker run, because this study starts at 2 workers.
    ideal_speedup = [w / 2 for w in ideal_workers]
    plt.plot(ideal_workers, ideal_speedup, linestyle="--", label="ideal from 2 workers")

    plt.xscale("log", base=2)
    plt.xticks(ideal_workers, [str(w) for w in ideal_workers])
    plt.xlabel("Number of workers")
    plt.ylabel("Speedup relative to 2 workers")
    plt.title("Manager-worker Mandelbrot speedup, 4001x4001 domain")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / "speedup_vs_workers.pdf")
    plt.savefig(outdir / "speedup_vs_workers.png", dpi=200)
    plt.close()


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: plot_scaling.py results/scaling_4001x4001.csv figures")

    input_csv = Path(sys.argv[1])
    outdir = Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)

    rows = read_rows(input_csv)
    summary = aggregate(rows)
    summary_path = write_summary(summary, outdir)
    plot_runtime(summary, outdir)
    plot_speedup(summary, outdir)

    print(f"Wrote summary to {summary_path}")
    print(f"Wrote figures to {outdir}")


if __name__ == "__main__":
    main()
