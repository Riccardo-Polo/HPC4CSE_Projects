set terminal pdfcairo enhanced color font "Helvetica,10"
set datafile commentschars "#"

# -----------------------
# Time plot
# -----------------------
set output "quicksort_time.pdf"
set title "Quicksort task-based OpenMP strong scaling"
set xlabel "Number of threads"
set ylabel "Average time [s]"
set logscale x 2
set xtics 1,2,128
set grid

plot \
  "strong_scaling.data" using (($1==1000000)?$2:1/0):3 with linespoints lw 2 pt 7 title "N=10^6", \
  "strong_scaling.data" using (($1==5000000)?$2:1/0):3 with linespoints lw 2 pt 7 title "N=5x10^6", \
  "strong_scaling.data" using (($1==10000000)?$2:1/0):3 with linespoints lw 2 pt 7 title "N=10^7", \
  "strong_scaling.data" using (($1==20000000)?$2:1/0):3 with linespoints lw 2 pt 7 title "N=2x10^7"

# -----------------------
# Speedup plot
# -----------------------
set output "quicksort_speedup.pdf"
set title "Quicksort task-based OpenMP speedup"
set xlabel "Number of threads"
set ylabel "Speedup"
set logscale x 2
set xtics 1,2,128
set grid

plot \
  x with lines lw 2 title "Ideal speedup", \
  "strong_scaling.data" using (($1==1000000)?$2:1/0):4 with linespoints lw 2 pt 7 title "N=10^6", \
  "strong_scaling.data" using (($1==5000000)?$2:1/0):4 with linespoints lw 2 pt 7 title "N=5x10^6", \
  "strong_scaling.data" using (($1==10000000)?$2:1/0):4 with linespoints lw 2 pt 7 title "N=10^7", \
  "strong_scaling.data" using (($1==20000000)?$2:1/0):4 with linespoints lw 2 pt 7 title "N=2x10^7"