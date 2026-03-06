#!/bin/bash
#SBATCH --job-name=slurm_job_two # Job name    (default: sbatch)
#SBATCH --output=%x-%j.out       # Output file (default: slurm-%j.out)
#SBATCH --error=%x-%j.err        # Error file  (default: slurm-%j.out)
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=64        # Number of CPUs per task
#SBATCH --mem-per-cpu=1G         # Memory per CPU
#SBATCH --time=02:00:00          # Wall clock time limit (H:M:S)
#SBATCH --constraint=EPYC_7763   # Constraint to run on EPYC 7763 CPUs

# exit immediately if any command exits with a non-zero status
set -e

# load some modules & list loaded modules
module load stack gcc
module list


# run (srun: run job on cluster with provided resources/allocation)
srun hostname
<<<<<<< HEAD

=======
>>>>>>> 80e9f242c623c92a790d5ae3279e769c5877fe15
# compile
make clean
make

echo "==== benchmark-naive ======================"
stdbuf -oL ./naive_strong | tee timing_naive_strong.data
stdbuf -oL ./naive_weak | tee timing_naive_weak.data
echo
echo "==== benchmark-optimized ========================"
stdbuf -oL ./optimized_strong | tee timing_optimized_strong.data
stdbuf -oL ./optimized_weak | tee timing_optimized_weak.data
echo
echo "==== benchmark-reduction ========================"
stdbuf -oL ./reduction_strong | tee timing_reduction_strong.data
stdbuf -oL ./reduction_weak | tee timing_reduction_weak.data
echo
echo
echo "==== plot results ========================="
gnuplot plot_strong.gp
gnuplot plot_weak_time.gp
