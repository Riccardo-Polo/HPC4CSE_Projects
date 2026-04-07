#!/bin/bash -l
#SBATCH --job-name=mandel
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --constraint=EPYC_7763
#SBATCH --time=00:20:00

module load stack gcc openmpi

make clean
make

echo "List of node(s): $SLURM_JOB_NODELIST"

#offset added to x coordinate so that gnuplot does not overlap the bars
offset=0

rm -f perf.data
for np in 1 2 4 8 16
do
  printf "Computing Mandelbrot set with %3d proc(s)...\n" $np
  srun -n $np ./mandel_mpi > tmp.txt

  for i in `seq 0 $((np-1))`
  do
    t=$(cat tmp.txt | grep "\[Process $i\] Total time" \
                    | cut -d ":" -f2                   \
                    | cut -d " " -f2)
    idx=$(echo $i + $offset | bc -l)
    printf "%3d %3.1f %10.4f\n" $np $idx $t >> perf.data
  done
  rm tmp.txt

  offset=$(echo $offset + 0.2 | bc -l)
  printf "\n\n" >> perf.data
done

gnuplot -e "filename = 'perf.pdf'" perf.gp

echo "Done."
