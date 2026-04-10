#!/usr/bin/env python3
import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def load_data(path):
    data = np.loadtxt(path, comments="#")
    if data.ndim == 1:
        data = data[None, :]
    procs = data[:, 0].astype(int)
    nvals = data[:, 2].astype(int)
    times = data[:, 5]

    uniq = np.array(sorted(set(procs)))
    mean_t = np.array([times[procs == p].mean() for p in uniq])
    std_t = np.array([
        times[procs == p].std(ddof=1) if np.sum(procs == p) > 1 else 0.0
        for p in uniq
    ])
    mean_n = np.array([int(round(nvals[procs == p].mean())) for p in uniq])
    return uniq, mean_n, mean_t, std_t


def plot_strong(path, outdir):
    p, nvals, t, s = load_data(path)
    t1 = t[p == 1][0]
    efficiency = t1 / (p * t)

    plt.figure(figsize=(6, 4))
    plt.errorbar(p, t, yerr=s, marker='o', capsize=3)
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Runtime [s]')
    plt.title('Strong scaling runtime')
    plt.grid(True, which='both', alpha=0.3)
    plt.tight_layout()
    plt.savefig(outdir / 'strong_runtime.pdf')
    plt.close()

    plt.figure(figsize=(6, 4))
    plt.plot(p, efficiency, marker='o', label='Measured efficiency')
    plt.axhline(1.0, linestyle='--', label='Ideal efficiency')
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Parallel efficiency')
    plt.title('Strong scaling efficiency')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'strong_efficiency.pdf')
    plt.close()

    summary = outdir / 'strong_summary.txt'
    with summary.open('w') as f:
        f.write('# p n mean_time std_time efficiency\n')
        for pi, ni, ti, si, ei in zip(p, nvals, t, s, efficiency):
            f.write(f'{pi} {ni} {ti:.8f} {si:.8f} {ei:.8f}\n')


def plot_weak(path, outdir):
    p, nvals, t, s = load_data(path)
    t1 = t[p == 1][0]
    efficiency = t1 / t

    labels = [f'{pi}\n(n={ni})' for pi, ni in zip(p, nvals)]
    xpos = np.arange(len(p))

    plt.figure(figsize=(7, 4.5))
    plt.errorbar(xpos, t, yerr=s, marker='o', capsize=3)
    plt.xticks(xpos, labels)
    plt.xlabel('MPI processes and matrix size')
    plt.ylabel('Runtime [s]')
    plt.title('Weak scaling runtime')
    plt.grid(True, which='both', alpha=0.3)
    plt.tight_layout()
    plt.savefig(outdir / 'weak_runtime.pdf')
    plt.close()

    plt.figure(figsize=(7, 4.5))
    plt.plot(xpos, efficiency, marker='o', label='Measured efficiency')
    plt.axhline(1.0, linestyle='--', label='Ideal efficiency')
    plt.xticks(xpos, labels)
    plt.xlabel('MPI processes and matrix size')
    plt.ylabel('Parallel efficiency')
    plt.title('Weak scaling efficiency')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'weak_efficiency.pdf')
    plt.close()

    summary = outdir / 'weak_summary.txt'
    with summary.open('w') as f:
        f.write('# p n mean_time std_time efficiency\n')
        for pi, ni, ti, si, ei in zip(p, nvals, t, s, efficiency):
            f.write(f'{pi} {ni} {ti:.8f} {si:.8f} {ei:.8f}\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--strong', type=Path)
    parser.add_argument('--weak', type=Path)
    parser.add_argument('--outdir', type=Path, default=Path('figures'))
    args = parser.parse_args()

    args.outdir.mkdir(parents=True, exist_ok=True)

    if args.strong:
        plot_strong(args.strong, args.outdir)
    if args.weak:
        plot_weak(args.weak, args.outdir)


if __name__ == '__main__':
    main()
