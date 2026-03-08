set terminal pngcairo size 1000,700
set datafile separator whitespace

# ------------------------
# Plot 1: execution time
# ------------------------
set output "hist_strong_time.png"
set title "Histogram OpenMP Strong Scaling"
set xlabel "Number of threads"
set ylabel "Execution time (s)"
set grid
set key top right

plot "timing_hist_omp_strong_summary.data" using 1:2 with linespoints lw 2 pt 7 title "Average time"

# ------------------------
# Plot 2: speedup
# ------------------------
stats "timing_hist_omp_strong_summary.data" using 2 every ::0::0 nooutput
t1 = STATS_min

set output "hist_strong_speedup.png"
set title "Histogram OpenMP Strong Scaling Speedup"
set xlabel "Number of threads"
set ylabel "Speedup"
set grid
set key top left

plot \
  "timing_hist_omp_strong_summary.data" using 1:(t1/$2) with linespoints lw 2 pt 7 title "Measured speedup", \
  "timing_hist_omp_strong_summary.data" using 1:1 with lines lw 2 dt 2 title "Ideal speedup"