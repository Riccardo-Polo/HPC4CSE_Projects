#!/usr/bin/env python3
import sys
import numpy as np
import matplotlib.pyplot as plt


def load_data(path):
    data = np.loadtxt(path, comments="#")
    procs = data[:, 0].astype(int)
    times = data[:, 4]
    uniq = np.array(sorted(set(procs)))
    mean = np.array([times[procs == p].mean() for p in uniq])
    std = np.array([times[procs == p].std(ddof=1) if np.sum(procs == p) > 1 else 0.0 for p in uniq])
    return uniq, mean, std


def plot_strong(path, out_time, out_speedup):
    p, t, s = load_data(path)
    t1 = t[p == 1][0]
    speedup = t1 / t
    ideal = p.astype(float)

    plt.figure(figsize=(6, 4))
    plt.errorbar(p, t, yerr=s, marker='o', capsize=3)
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Time to solution [s]')
    plt.title('Strong scaling')
    plt.grid(True, which='both', alpha=0.3)
    plt.tight_layout()
    plt.savefig(out_time)
    plt.close()

    plt.figure(figsize=(6, 4))
    plt.plot(p, speedup, marker='o', label='Measured speedup')
    plt.plot(p, ideal, linestyle='--', label='Ideal speedup')
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Speedup')
    plt.title('Strong scaling speedup')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(out_speedup)
    plt.close()


def plot_weak(path, out_time, out_eff):
    p, t, s = load_data(path)
    t1 = t[p == 1][0]
    efficiency = t1 / t

    plt.figure(figsize=(6, 4))
    plt.errorbar(p, t, yerr=s, marker='o', capsize=3)
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Time to solution [s]')
    plt.title('Weak scaling')
    plt.grid(True, which='both', alpha=0.3)
    plt.tight_layout()
    plt.savefig(out_time)
    plt.close()

    plt.figure(figsize=(6, 4))
    plt.plot(p, efficiency, marker='o', label='Weak scaling efficiency')
    plt.axhline(1.0, linestyle='--', label='Ideal')
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Efficiency')
    plt.title('Weak scaling efficiency')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(out_eff)
    plt.close()


if __name__ == '__main__':
    mode = sys.argv[1]
    datafile = sys.argv[2]
    out1 = sys.argv[3]
    out2 = sys.argv[4]
    if mode == 'strong':
        plot_strong(datafile, out1, out2)
    elif mode == 'weak':
        plot_weak(datafile, out1, out2)
    else:
        raise SystemExit('Mode must be strong or weak')
