#!/usr/bin/env python3
"""Create weak-scaling time-to-solution plots from an existing/raw CSV.

This script is intentionally independent of the Slurm run.  It can be run after
an interrupted job and it will still create the plots from the data already
available in results/weak_scaling_1ppn_raw.csv.  It also reports missing
(base_n, ncpu, repeat) combinations, so that the companion resume script can run
only those missing simulations.
"""

import argparse
import csv
from collections import defaultdict
from pathlib import Path
from statistics import mean, stdev

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

EXPECTED_COLUMNS = [
    "repeat", "base_n", "ncpu", "scaled_n", "problem_size", "nt", "tfinal",
    "cg_iters", "newton_iters", "time_s",
]


def parse_int_list(text):
    return [int(x) for x in str(text).replace(",", " ").split()]


def read_rows(path):
    path = Path(path)
    if not path.exists():
        raise SystemExit(f"Input CSV not found: {path}")

    rows = []
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        missing_cols = [c for c in EXPECTED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing_cols:
            raise SystemExit(f"CSV is missing columns: {missing_cols}")
        for raw in reader:
            # Skip fully empty lines, if any.
            if not any((raw.get(c) or "").strip() for c in EXPECTED_COLUMNS):
                continue
            rows.append({
                "repeat": int(raw["repeat"]),
                "base_n": int(raw["base_n"]),
                "ncpu": int(raw["ncpu"]),
                "scaled_n": int(raw["scaled_n"]),
                "problem_size": int(raw["problem_size"]),
                "nt": int(raw["nt"]),
                "tfinal": float(raw["tfinal"]),
                "cg_iters": int(raw["cg_iters"]),
                "newton_iters": int(raw["newton_iters"]),
                "time_s": float(raw["time_s"]),
            })
    if not rows:
        raise SystemExit(f"No data rows found in {path}")
    return rows


def expected_missing(rows, base_resolutions, ncpus, repeats):
    existing = {(r["base_n"], r["ncpu"], r["repeat"]) for r in rows}
    missing = []
    for base_n in base_resolutions:
        for ncpu in ncpus:
            for repeat in range(1, repeats + 1):
                if (base_n, ncpu, repeat) not in existing:
                    missing.append((base_n, ncpu, repeat))
    return missing


def summarize(rows):
    grouped = defaultdict(list)
    for row in rows:
        key = (row["base_n"], row["ncpu"], row["scaled_n"], row["problem_size"])
        grouped[key].append(row)

    summary = []
    for (base_n, ncpu, scaled_n, problem_size), entries in sorted(grouped.items()):
        times = [e["time_s"] for e in entries]
        cg_iters = [e["cg_iters"] for e in entries]
        newton_iters = [e["newton_iters"] for e in entries]
        summary.append({
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
        })
    return summary


def write_summary(path, summary):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "base_n", "ncpu", "scaled_n", "problem_size", "repeats",
        "time_mean_s", "time_min_s", "time_max_s", "time_std_s",
        "cg_iters_mean", "newton_iters_mean",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary)


def configure_axes(ax, x_values):
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_xticks(sorted(x_values))
    ax.xaxis.set_major_formatter(ticker.ScalarFormatter())
    ax.yaxis.set_major_locator(ticker.LogLocator(base=2))
    ax.yaxis.set_major_formatter(ticker.LogFormatterMathtext(base=2))
    ax.grid(True, which="both", linestyle=":", linewidth=0.7, alpha=0.8)


def save(fig, outpath):
    outpath = Path(outpath)
    outpath.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(outpath, bbox_inches="tight")
    if outpath.suffix.lower() == ".pdf":
        fig.savefig(outpath.with_suffix(".png"), dpi=300, bbox_inches="tight")
    plt.close(fig)


def plot_vs_ncpu(summary, outpath):
    fig, ax = plt.subplots(figsize=(8, 5))
    for base_n in sorted({r["base_n"] for r in summary}):
        subset = sorted([r for r in summary if r["base_n"] == base_n], key=lambda r: r["ncpu"])
        ax.errorbar(
            [r["ncpu"] for r in subset],
            [r["time_mean_s"] for r in subset],
            yerr=[r["time_std_s"] for r in subset],
            marker="o", capsize=3, label=fr"$n_0={base_n}$",
        )
    configure_axes(ax, {r["ncpu"] for r in summary})
    ax.set_xlabel(r"Number of MPI processes $N_{CPU}$")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Weak scaling, one MPI process per node")
    ax.legend(title="Base resolution")
    save(fig, outpath)


def plot_vs_problem_size(summary, outpath):
    fig, ax = plt.subplots(figsize=(8, 5))
    for base_n in sorted({r["base_n"] for r in summary}):
        subset = sorted([r for r in summary if r["base_n"] == base_n], key=lambda r: r["problem_size"])
        ax.errorbar(
            [r["problem_size"] for r in subset],
            [r["time_mean_s"] for r in subset],
            yerr=[r["time_std_s"] for r in subset],
            marker="o", capsize=3, label=fr"$n_0={base_n}$",
        )
    configure_axes(ax, {r["problem_size"] for r in summary})
    ax.set_xlabel(r"Total problem size $n^2$ grid points")
    ax.set_ylabel("Time to solution [s]")
    ax.set_title("Weak scaling, one MPI process per node")
    ax.legend(title="Base resolution")
    save(fig, outpath)


def main():
    parser = argparse.ArgumentParser(description="Plot weak-scaling time-to-solution results.")
    parser.add_argument("--input", default="results/weak_scaling_1ppn_raw.csv")
    parser.add_argument("--summary", default="results/weak_scaling_1ppn_summary.csv")
    parser.add_argument("--ncpu-plot", default="figures/weak_time_to_solution_1ppn.pdf")
    parser.add_argument("--problem-size-plot", default="figures/weak_time_to_solution_problem_size_1ppn.pdf")
    parser.add_argument("--base-resolutions", default="64 128 256")
    parser.add_argument("--ncpus", default="1 4 16 64")
    parser.add_argument("--repeats", type=int, default=3)
    args = parser.parse_args()

    rows = read_rows(args.input)
    summary = summarize(rows)
    write_summary(args.summary, summary)
    plot_vs_ncpu(summary, args.ncpu_plot)
    plot_vs_problem_size(summary, args.problem_size_plot)

    base_resolutions = parse_int_list(args.base_resolutions)
    ncpus = parse_int_list(args.ncpus)
    missing = expected_missing(rows, base_resolutions, ncpus, args.repeats)

    print(f"Read {len(rows)} raw rows.")
    print(f"Wrote {args.summary}")
    print(f"Wrote {args.ncpu_plot}")
    print(f"Wrote {args.problem_size_plot}")
    if missing:
        print("Missing runs:")
        for base_n, ncpu, repeat in missing:
            print(f"  base_n={base_n}, ncpu={ncpu}, repeat={repeat}")
    else:
        print("No missing runs for the requested parameter grid.")


if __name__ == "__main__":
    main()
