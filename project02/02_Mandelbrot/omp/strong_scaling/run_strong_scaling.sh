#!/bin/bash
#SBATCH --job-name=mandel_strong
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --constraint=EPYC_7763
#SBATCH --time=01:00:00

module load stack gcc gnuplot

echo "===== Loaded modules ====="
module list

echo "===== Cleaning and compiling ====="
make clean
make

OUT=timing_strong.data
EXE=./mandelbrot

rm -f $OUT
echo "# threads width height time" > $OUT

export OMP_PROC_BIND=close
export OMP_PLACES=cores

echo "===== Running strong scaling benchmark ====="
for t in 1 2 4 8 16 32 64
do
    export OMP_NUM_THREADS=$t
    echo "Running with $t threads..."
    $EXE >> $OUT
done

echo "===== Timing data ====="
cat $OUT

echo "===== Creating plots ====="
gnuplot strong_scaling.gp
gnuplot strong_speedup.gp

echo "===== Generated files ====="
ls -lh timing_strong.data strong_scaling.pdf strong_speedup.pdf