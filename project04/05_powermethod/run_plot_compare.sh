#!/bin/bash -l
set -euo pipefail

module load stack gcc python

export MPLBACKEND=Agg

mkdir -p figures_compare

python3 common/plot_scaling_compare.py \
  --strong-one 02_strong_scaling/results/strong_scaling.dat \
  --strong-multi 04_strong_scaling_multi_node/results/strong_scaling_multi_node.dat \
  --weak-one 03_weak_scaling/results/weak_scaling.dat \
  --weak-multi 05_weak_scaling_multi_node/results/weak_scaling_multi_node.dat \
  --outdir figures_compare
