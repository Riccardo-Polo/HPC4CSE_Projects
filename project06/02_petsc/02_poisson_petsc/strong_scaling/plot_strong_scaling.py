#!/usr/bin/env python3
import sys
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

raw_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("results/strong_scaling_raw.csv")
summary_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("results/strong_scaling_summary.csv")
figdir = Path("figures")
figdir.mkdir(exist_ok=True)

if not raw_path.exists():
    raise SystemExit(f"Missing input file: {raw_path}")

df = pd.read_csv(raw_path)
if df.empty:
    raise SystemExit("The raw CSV is empty. Check the SLURM output logs.")

# Median over repetitions is more robust than the mean for cluster timings.
summary = (
    df.groupby(["resolution", "nprocs"], as_index=False)
      .agg(total_time=("total_time", "median"),
           setup_time=("setup_time", "median"),
           solve_time=("solve_time", "median"),
           iterations=("iterations", "median"),
           reps=("rep", "count"))
      .sort_values(["resolution", "nprocs"])
)

# Strong-scaling speedup and efficiency from the p=1 baseline for each resolution.
rows = []
for n, g in summary.groupby("resolution"):
    g = g.sort_values("nprocs").copy()
    if not (g["nprocs"] == 1).any():
        continue
    t1_total = float(g.loc[g["nprocs"] == 1, "total_time"].iloc[0])
    t1_solve = float(g.loc[g["nprocs"] == 1, "solve_time"].iloc[0])
    for _, r in g.iterrows():
        p = float(r["nprocs"])
        rows.append({
            **r.to_dict(),
            "total_speedup": t1_total / r["total_time"],
            "total_efficiency": t1_total / (p * r["total_time"]),
            "solve_speedup": t1_solve / r["solve_time"],
            "solve_efficiency": t1_solve / (p * r["solve_time"]),
        })
summary = pd.DataFrame(rows)
summary.to_csv(summary_path, index=False)

# Plot total time-to-solution.
plt.figure(figsize=(7.0, 4.8))
for n, g in summary.groupby("resolution"):
    g = g.sort_values("nprocs")
    plt.plot(g["nprocs"], g["total_time"], marker="o", label=f"n={int(n)}")
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

# Plot solve-only time, useful to separate solver scaling from setup costs.
plt.figure(figsize=(7.0, 4.8))
for n, g in summary.groupby("resolution"):
    g = g.sort_values("nprocs")
    plt.plot(g["nprocs"], g["solve_time"], marker="o", label=f"n={int(n)}")
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

# Plot parallel efficiency based on total time.
plt.figure(figsize=(7.0, 4.8))
for n, g in summary.groupby("resolution"):
    g = g.sort_values("nprocs")
    plt.plot(g["nprocs"], 100.0 * g["total_efficiency"], marker="o", label=f"n={int(n)}")
plt.xscale("log", base=2)
plt.xlabel("Number of MPI processes / nodes")
plt.ylabel("Parallel efficiency [%]")
plt.title("Strong-scaling efficiency based on total time")
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
plt.legend(title="Grid")
plt.tight_layout()
plt.savefig(figdir / "strong_scaling_efficiency.pdf")
plt.savefig(figdir / "strong_scaling_efficiency.png", dpi=200)

print(f"Wrote {summary_path}")
print("Wrote figures/strong_scaling_time_to_solution.pdf")
print("Wrote figures/strong_scaling_solve_time.pdf")
print("Wrote figures/strong_scaling_efficiency.pdf")
