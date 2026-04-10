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


def strong_efficiency(p, t):
    t1 = t[p == 1][0]
    return t1 / (p * t)


def weak_efficiency(p, t):
    t1 = t[p == 1][0]
    return t1 / t


def write_summary(path, p, nvals, t, s, e):
    with path.open("w") as f:
        f.write("# p n mean_time std_time efficiency\n")
        for pi, ni, ti, si, ei in zip(p, nvals, t, s, e):
            f.write(f"{pi} {ni} {ti:.8f} {si:.8f} {ei:.8f}\n")


def plot_strong_compare(one_node_path, multi_node_path, outdir):
    p1, n1, t1, s1 = load_data(one_node_path)
    p2, n2, t2, s2 = load_data(multi_node_path)

    if not np.array_equal(p1, p2):
        raise ValueError("Strong-scaling datasets do not use the same process counts.")

    e1 = strong_efficiency(p1, t1)
    e2 = strong_efficiency(p2, t2)

    plt.figure(figsize=(6.5, 4.5))
    plt.errorbar(p1, t1, yerr=s1, marker='o', capsize=3, label='One node')
    plt.errorbar(p2, t2, yerr=s2, marker='s', capsize=3, label='Different nodes')
    plt.xscale('log', base=2)
    plt.yscale('log')
    plt.xlabel('MPI processes')
    plt.ylabel('Runtime [s]')
    plt.title('Strong scaling runtime')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'strong_runtime_compare.pdf')
    plt.close()

    plt.figure(figsize=(6.5, 4.5))
    plt.plot(p1, e1, marker='o', label='One node')
    plt.plot(p2, e2, marker='s', label='Different nodes')
    plt.axhline(1.0, linestyle='--', label='Ideal efficiency')
    plt.xscale('log', base=2)
    plt.xlabel('MPI processes')
    plt.ylabel('Parallel efficiency')
    plt.title('Strong scaling efficiency')
    plt.ylim(0.0, 1.1)
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'strong_efficiency_compare.pdf')
    plt.close()

    write_summary(outdir / 'strong_summary_one_node.txt', p1, n1, t1, s1, e1)
    write_summary(outdir / 'strong_summary_multi_node.txt', p2, n2, t2, s2, e2)


def plot_weak_compare(one_node_path, multi_node_path, outdir):
    p1, n1, t1, s1 = load_data(one_node_path)
    p2, n2, t2, s2 = load_data(multi_node_path)

    if not np.array_equal(p1, p2):
        raise ValueError("Weak-scaling datasets do not use the same process counts.")
    if not np.array_equal(n1, n2):
        raise ValueError("Weak-scaling datasets do not use the same matrix sizes.")

    e1 = weak_efficiency(p1, t1)
    e2 = weak_efficiency(p2, t2)

    labels = [f'{pi}\n(n={ni})' for pi, ni in zip(p1, n1)]
    xpos = np.arange(len(p1))

    plt.figure(figsize=(7.5, 4.8))
    plt.errorbar(xpos, t1, yerr=s1, marker='o', capsize=3, label='One node')
    plt.errorbar(xpos, t2, yerr=s2, marker='s', capsize=3, label='Different nodes')
    plt.xticks(xpos, labels)
    plt.yscale('log')
    plt.xlabel('MPI processes and matrix size')
    plt.ylabel('Runtime [s]')
    plt.title('Weak scaling runtime')
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'weak_runtime_compare.pdf')
    plt.close()

    plt.figure(figsize=(7.5, 4.8))
    plt.plot(xpos, e1, marker='o', label='One node')
    plt.plot(xpos, e2, marker='s', label='Different nodes')
    plt.axhline(1.0, linestyle='--', label='Ideal efficiency')
    plt.xticks(xpos, labels)
    plt.xlabel('MPI processes and matrix size')
    plt.ylabel('Parallel efficiency')
    plt.title('Weak scaling efficiency')
    plt.ylim(0.0, 1.1)
    plt.grid(True, which='both', alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / 'weak_efficiency_compare.pdf')
    plt.close()

    write_summary(outdir / 'weak_summary_one_node.txt', p1, n1, t1, s1, e1)
    write_summary(outdir / 'weak_summary_multi_node.txt', p2, n2, t2, s2, e2)


def main():
    parser = argparse.ArgumentParser(
        description='Compare one-node and multi-node strong/weak scaling results.'
    )
    parser.add_argument('--strong-one', type=Path, help='Strong scaling data for one-node runs')
    parser.add_argument('--strong-multi', type=Path, help='Strong scaling data for multi-node runs')
    parser.add_argument('--weak-one', type=Path, help='Weak scaling data for one-node runs')
    parser.add_argument('--weak-multi', type=Path, help='Weak scaling data for multi-node runs')
    parser.add_argument('--outdir', type=Path, default=Path('figures'))
    args = parser.parse_args()

    args.outdir.mkdir(parents=True, exist_ok=True)

    if (args.strong_one is None) != (args.strong_multi is None):
        raise ValueError('Provide both --strong-one and --strong-multi, or neither.')
    if (args.weak_one is None) != (args.weak_multi is None):
        raise ValueError('Provide both --weak-one and --weak-multi, or neither.')

    if args.strong_one and args.strong_multi:
        plot_strong_compare(args.strong_one, args.strong_multi, args.outdir)

    if args.weak_one and args.weak_multi:
        plot_weak_compare(args.weak_one, args.weak_multi, args.outdir)


if __name__ == '__main__':
    main()
