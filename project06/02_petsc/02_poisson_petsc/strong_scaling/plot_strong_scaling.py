#!/usr/bin/env python3
"""
Post-process strong-scaling runs.

This version intentionally avoids numpy and pandas, because the default Python
on Euler may not have them available in a clean module environment. It writes
summary CSV files with medians over repetitions, speedups, and efficiencies.
It then tries to create the figures using matplotlib; if matplotlib is not
available, it writes and runs a gnuplot script instead.
"""

from __future__ import annotations

import csv
import math
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from statistics import median

raw_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("results/strong_scaling_raw.csv")
summary_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("results/strong_scaling_summary.csv")
figdir = Path("figures")
figdir.mkdir(exist_ok=True)
summary_path.parent.mkdir(exist_ok=True)

if not raw_path.exists():
    raise SystemExit(f"Missing input file: {raw_path}")

records = []
with raw_path.open(newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            records.append({
                "resolution": int(row["resolution"]),
                "nprocs": int(row["nprocs"]),
                "rep": int(row["rep"]),
                "total_time": float(row["total_time"]),
                "setup_time": float(row["setup_time"]),
                "solve_time": float(row["solve_time"]),
                "iterations": float(row["iterations"]),
            })
        except (KeyError, ValueError) as exc:
            raise SystemExit(f"Bad row in {raw_path}: {row}\n{exc}") from exc

if not records:
    raise SystemExit("The raw CSV has no successful runs. Check outputs/strong_n*_p*_rep*.log")

by_np = defaultdict(list)
for r in records:
    by_np[(r["resolution"], r["nprocs"])].append(r)

summary = []
for (n, p), rows in sorted(by_np.items()):
    summary.append({
        "resolution": n,
        "nprocs": p,
        "total_time": median(r["total_time"] for r in rows),
        "setup_time": median(r["setup_time"] for r in rows),
        "solve_time": median(r["solve_time"] for r in rows),
        "iterations": median(r["iterations"] for r in rows),
        "reps": len(rows),
    })

# Strong-scaling speedup and efficiency from the p=1 baseline for each resolution.
baselines = {}
for r in summary:
    if r["nprocs"] == 1:
        baselines[r["resolution"]] = (r["total_time"], r["solve_time"])

summary_with_scaling = []
for r in summary:
    n = r["resolution"]
    if n not in baselines:
        continue
    p = r["nprocs"]
    t1_total, t1_solve = baselines[n]
    out = dict(r)
    out["total_speedup"] = t1_total / r["total_time"]
    out["total_efficiency"] = t1_total / (p * r["total_time"])
    out["solve_speedup"] = t1_solve / r["solve_time"]
    out["solve_efficiency"] = t1_solve / (p * r["solve_time"])
    summary_with_scaling.append(out)

fieldnames = [
    "resolution", "nprocs", "total_time", "setup_time", "solve_time",
    "iterations", "reps", "total_speedup", "total_efficiency",
    "solve_speedup", "solve_efficiency",
]
with summary_path.open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(summary_with_scaling)

# Write helper data files for gnuplot, one file per resolution.
resolutions = sorted({r["resolution"] for r in summary_with_scaling})
for n in resolutions:
    dat = figdir / f"strong_scaling_n{n}.dat"
    with dat.open("w") as f:
        f.write("# nprocs total_time setup_time solve_time total_efficiency solve_efficiency\n")
        for r in sorted((x for x in summary_with_scaling if x["resolution"] == n), key=lambda x: x["nprocs"]):
            f.write(
                f"{r['nprocs']} {r['total_time']:.12e} {r['setup_time']:.12e} "
                f"{r['solve_time']:.12e} {100.0*r['total_efficiency']:.12e} "
                f"{100.0*r['solve_efficiency']:.12e}\n"
            )


def try_matplotlib() -> bool:
    try:
        import matplotlib.pyplot as plt  # type: ignore
    except Exception:
        return False

    def grouped(n: int):
        return sorted((r for r in summary_with_scaling if r["resolution"] == n), key=lambda x: x["nprocs"])

    plt.figure(figsize=(7.0, 4.8))
    for n in resolutions:
        g = grouped(n)
        plt.plot([r["nprocs"] for r in g], [r["total_time"] for r in g], marker="o", label=f"n={n}")
    plt.xscale("log", base=2)
    plt.yscale("log", base=10)
    plt.xlabel("Number of MPI processes / nodes")
    plt.ylabel("Median time to solution [s]")
    plt.title("Strong scaling of PETSc 2D Poisson solver")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend(title="Grid")
    plt.tight_layout()
    plt.savefig(figdir / "strong_scaling_time_to_solution.pdf")
    plt.savefig(figdir / "strong_scaling_time_to_solution.png", dpi=200)
    plt.close()

    plt.figure(figsize=(7.0, 4.8))
    for n in resolutions:
        g = grouped(n)
        plt.plot([r["nprocs"] for r in g], [r["solve_time"] for r in g], marker="o", label=f"n={n}")
    plt.xscale("log", base=2)
    plt.yscale("log", base=10)
    plt.xlabel("Number of MPI processes / nodes")
    plt.ylabel("Median KSPSolve time [s]")
    plt.title("Strong scaling of PETSc 2D Poisson solver: solve phase")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend(title="Grid")
    plt.tight_layout()
    plt.savefig(figdir / "strong_scaling_solve_time.pdf")
    plt.savefig(figdir / "strong_scaling_solve_time.png", dpi=200)
    plt.close()

    plt.figure(figsize=(7.0, 4.8))
    for n in resolutions:
        g = grouped(n)
        plt.plot([r["nprocs"] for r in g], [100.0 * r["total_efficiency"] for r in g], marker="o", label=f"n={n}")
    plt.xscale("log", base=2)
    plt.xlabel("Number of MPI processes / nodes")
    plt.ylabel("Parallel efficiency [%]")
    plt.title("Strong-scaling efficiency based on total time")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend(title="Grid")
    plt.tight_layout()
    plt.savefig(figdir / "strong_scaling_efficiency.pdf")
    plt.savefig(figdir / "strong_scaling_efficiency.png", dpi=200)
    plt.close()
    return True


def write_gnuplot_script() -> Path:
    gp = figdir / "plot_strong_scaling.gnuplot"
    plot_lines_total = []
    plot_lines_solve = []
    plot_lines_eff = []
    for n in resolutions:
        dat = f"strong_scaling_n{n}.dat"
        plot_lines_total.append(f"'{dat}' using 1:2 with linespoints title 'n={n}'")
        plot_lines_solve.append(f"'{dat}' using 1:4 with linespoints title 'n={n}'")
        plot_lines_eff.append(f"'{dat}' using 1:5 with linespoints title 'n={n}'")

    gp.write_text(f"""
set terminal pdfcairo enhanced color size 7.0,4.8
set datafile commentschars '#'
set key left top
set grid
set logscale x 2
set xtics (1,2,4,8,16,32)
set xlabel 'Number of MPI processes / nodes'

set logscale y 10
set ylabel 'Median time to solution [s]'
set title 'Strong scaling of PETSc 2D Poisson solver'
set output 'strong_scaling_time_to_solution.pdf'
plot {', '.join(plot_lines_total)}

set ylabel 'Median KSPSolve time [s]'
set title 'Strong scaling of PETSc 2D Poisson solver: solve phase'
set output 'strong_scaling_solve_time.pdf'
plot {', '.join(plot_lines_solve)}

unset logscale y
set ylabel 'Parallel efficiency [%]'
set title 'Strong-scaling efficiency based on total time'
set output 'strong_scaling_efficiency.pdf'
plot {', '.join(plot_lines_eff)}
""".lstrip())
    return gp

made_figures = try_matplotlib()
if not made_figures:
    gp = write_gnuplot_script()
    if shutil.which("gnuplot") is not None:
        subprocess.run(["gnuplot", gp.name], cwd=figdir, check=True)
        made_figures = True
    else:
        print("matplotlib and gnuplot are unavailable; wrote data files and gnuplot script only.")

print(f"Wrote {summary_path}")
print(f"Wrote per-resolution data files in {figdir}/")
if made_figures:
    print("Wrote figures/strong_scaling_time_to_solution.pdf")
    print("Wrote figures/strong_scaling_solve_time.pdf")
    print("Wrote figures/strong_scaling_efficiency.pdf")
else:
    print("To make the figures later: cd figures && gnuplot plot_strong_scaling.gnuplot")
