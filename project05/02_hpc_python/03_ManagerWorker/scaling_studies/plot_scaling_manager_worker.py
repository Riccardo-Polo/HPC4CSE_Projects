#!/usr/bin/env python3
"""
Plot the manager-worker Mandelbrot scaling study.

Default input:
    outputs/results_manager_worker_scaling.dat

Default output:
    figures/manager_worker_time_log10.pdf
    figures/manager_worker_time_log10.png

Optional usage:
    python3 plot_scaling_manager_worker.py INPUT_DAT OUTPUT_PDF

The y-axis is logarithmic with base 10, as requested.
"""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def read_results(path: Path) -> np.ndarray:
    if not path.exists():
        raise FileNotFoundError(f"Missing results file: {path}")

    data = np.genfromtxt(path, comments="#")
    if data.size == 0:
        raise RuntimeError(f"No numerical data found in {path}")

    if data.ndim == 1:
        data = data.reshape(1, -1)

    # columns: ntasks workers nprocs nx ny repeat time_seconds
    if data.shape[1] != 7:
        raise RuntimeError(
            f"Expected 7 columns in {path}, got {data.shape[1]} columns."
        )
    return data


def main() -> int:
    results_path = Path(sys.argv[1]) if len(sys.argv) >= 2 else Path("outputs/results_manager_worker_scaling.dat")
    output_pdf = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path("figures/manager_worker_time_log10.pdf")
    output_png = output_pdf.with_suffix(".png")
    output_pdf.parent.mkdir(parents=True, exist_ok=True)

    data = read_results(results_path)

    ntasks_col = data[:, 0].astype(int)
    workers_col = data[:, 1].astype(int)
    time_col = data[:, 6]

    fig, ax = plt.subplots(figsize=(6.5, 4.5))

    for ntasks in sorted(set(ntasks_col)):
        workers = []
        means = []
        stds = []

        for w in sorted(set(workers_col)):
            mask = (ntasks_col == ntasks) & (workers_col == w)
            if not np.any(mask):
                continue
            samples = time_col[mask]
            workers.append(w)
            means.append(float(np.mean(samples)))
            stds.append(float(np.std(samples, ddof=1)) if len(samples) > 1 else 0.0)

        workers_arr = np.array(workers)
        means_arr = np.array(means)
        stds_arr = np.array(stds)

        if np.any(stds_arr > 0.0):
            ax.errorbar(
                workers_arr,
                means_arr,
                yerr=stds_arr,
                marker="o",
                capsize=3,
                label=f"{ntasks} tasks",
            )
        else:
            ax.plot(workers_arr, means_arr, marker="o", label=f"{ntasks} tasks")

    ax.set_xlabel("Number of workers")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Manager-worker Mandelbrot scaling, 4001 x 4001 domain")
    ax.set_yscale("log", base=10)
    ax.set_xticks(sorted(set(workers_col)))
    ax.grid(True, which="both", linestyle="--", linewidth=0.5)
    ax.legend()
    fig.tight_layout()

    fig.savefig(output_pdf)
    fig.savefig(output_png, dpi=300)

    print(f"Saved {output_pdf}")
    print(f"Saved {output_png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
