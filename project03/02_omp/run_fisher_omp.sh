#!/bin/bash
#SBATCH --job-name=parallel_fisher
#SBATCH --output=outputs/%x-%j.out
#SBATCH --error=outputs/%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=3
#SBATCH --mem-per-cpu=1024
#SBATCH --time=01:00:00
#SBATCH --constraint=EPYC_7763

set -e

mkdir -p outputs

module load stack gcc python eth_proxy
module load python

make clean
make

./main 128 100 0.005 

echo "Done running the program, now plotting the results..."
python plot.py
