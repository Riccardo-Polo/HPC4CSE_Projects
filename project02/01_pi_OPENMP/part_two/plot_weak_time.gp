set title "Weak scaling for pi evaluation"
set xlabel "Problem size"
set ylabel "Time"
set grid

set terminal pdf
set output "timing_weak.pdf"

plot "timing_naive_weak.data" using 2:4 title "Naive critical" with linespoints, \
     "timing_optimized_weak.data" using 2:4 title "Optimized critical" with linespoints, \
     "timing_reduction_weak.data" using 2:4 title "Reduction" with linespoints