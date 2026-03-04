set title "Strong scaling for pi evaluation"
set xlabel "Threads"
set ylabel "Time"
set grid

set terminal pdf
set output "timing_strong.pdf"

plot "timing_naive_strong.data" using 3:4 title "Naive critical" with linespoints, \
     "timing_optimized_strong.data" using 3:4 title "Optimized critical" with linespoints, \
     "timing_reduction_strong.data" using 3:4 title "Reduction" with linespoints