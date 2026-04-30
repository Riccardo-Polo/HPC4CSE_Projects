#!/usr/bin/env python3
import sys
import numpy as np
import matplotlib.pyplot as plt

if len(sys.argv) != 3:
    raise SystemExit("usage: plot_async_progress.py input.dat output.pdf")

inp, out = sys.argv[1], sys.argv[2]
data = np.loadtxt(inp, comments="#")
delay = data[:, 0]
overall = data[:, 1]
comm0 = overall[0]

plt.figure()
plt.plot(delay, overall, marker="o", markersize=2, linewidth=1, label="measured")
plt.plot(delay, comm0 + delay, linestyle="--", label=r"no async: $T_{comm}(0)+delay$")
plt.plot(delay, np.maximum(comm0, delay), linestyle=":", label=r"ideal async: $max(T_{comm}(0),delay)$")
plt.xlabel("Delay time [s]")
plt.ylabel("Overall time [s]")
plt.legend()
plt.grid(True, which="both")
plt.savefig(out, bbox_inches="tight")
