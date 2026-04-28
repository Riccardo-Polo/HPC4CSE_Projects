#!/usr/bin/env python3
import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


def read_table(path: str, columns):
    return pd.read_csv(
        path,
        comment="#",
        sep=r"\s+",
        names=columns,
        engine="python",
    )


def add_errorbars(ax, x, y, yerr, label):
    if yerr is not None and (yerr.fillna(0) > 0).any():
        ax.errorbar(x, y, yerr=yerr, marker="o", capsize=3, label=label)
    else:
        ax.plot(x, y, marker="o", label=label)


def plot_strong(raw_path: str, avg_path: str, outdir: Path):
    cols = ["n", "ncpu", "repeat", "nt", "cg_iters", "newton_iters", "time_seconds"]
    df = read_table(raw_path, cols)
    avg = (
        df.groupby(["n", "ncpu"], as_index=False)
          .agg(time_mean=("time_seconds", "mean"),
               time_std=("time_seconds", "std"),
               repeats=("time_seconds", "count"),
               cg_iters_mean=("cg_iters", "mean"),
               newton_iters_mean=("newton_iters", "mean"))
    )
    avg.to_csv(avg_path, sep=" ", index=False)

    fig, ax = plt.subplots(figsize=(7.0, 4.8))
    for n, g in avg.groupby("n"):
        g = g.sort_values("ncpu")
        add_errorbars(ax, g["ncpu"], g["time_mean"], g["time_std"], label=f"n={n}")
    ax.set_xlabel("MPI processes")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Strong scaling")
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xticks(sorted(avg["ncpu"].unique()))
    ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
    ax.grid(True, which="both", linestyle=":", linewidth=0.7)
    ax.legend(title="Resolution")
    fig.tight_layout()
    fig.savefig(outdir / "strong_time_to_solution.pdf", bbox_inches="tight")
    fig.savefig(outdir / "strong_time_to_solution.png", dpi=300, bbox_inches="tight")
    plt.close(fig)


def plot_weak(raw_path: str, avg_path: str, outdir: Path):
    cols = ["base_n", "global_n", "ncpu", "repeat", "nt", "cg_iters", "newton_iters", "time_seconds"]
    df = read_table(raw_path, cols)
    avg = (
        df.groupby(["base_n", "global_n", "ncpu"], as_index=False)
          .agg(time_mean=("time_seconds", "mean"),
               time_std=("time_seconds", "std"),
               repeats=("time_seconds", "count"),
               cg_iters_mean=("cg_iters", "mean"),
               newton_iters_mean=("newton_iters", "mean"))
    )
    avg.to_csv(avg_path, sep=" ", index=False)

    fig, ax = plt.subplots(figsize=(7.0, 4.8))
    for base_n, g in avg.groupby("base_n"):
        g = g.sort_values("ncpu")
        labels = [f"{int(p)}\n(n={int(n)})" for p, n in zip(g["ncpu"], g["global_n"])]
        add_errorbars(ax, g["ncpu"], g["time_mean"], g["time_std"], label=f"base n={base_n}")
    ax.set_xlabel("MPI processes")
    ax.set_ylabel("Time to solution [s]")
    ax.set_yscale("log", base=2)
    ax.yaxis.set_major_locator(matplotlib.ticker.LogLocator(base=2))
    ax.yaxis.set_major_formatter(matplotlib.ticker.LogFormatterMathtext(base=2))
    ax.set_title("Weak scaling")
    ax.set_xscale("log", base=4)
    ax.set_xticks(sorted(avg["ncpu"].unique()))
    ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
    ax.grid(True, which="both", linestyle=":", linewidth=0.7)
    ax.legend(title="Local base resolution")
    fig.tight_layout()
    fig.savefig(outdir / "weak_time_to_solution.pdf", bbox_inches="tight")
    fig.savefig(outdir / "weak_time_to_solution.png", dpi=300, bbox_inches="tight")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description="Plot mini-stencil scaling results.")
    parser.add_argument("--strong", help="Raw strong scaling data file")
    parser.add_argument("--strong-avg", default="results/strong_scaling_avg.dat")
    parser.add_argument("--weak", help="Raw weak scaling data file")
    parser.add_argument("--weak-avg", default="results/weak_scaling_avg.dat")
    parser.add_argument("--outdir", default="figures")
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    if args.strong:
        plot_strong(args.strong, args.strong_avg, outdir)
    if args.weak:
        plot_weak(args.weak, args.weak_avg, outdir)
    if not args.strong and not args.weak:
        raise SystemExit("Nothing to plot: pass --strong and/or --weak")


if __name__ == "__main__":
    main()
