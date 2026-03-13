set title "Strong scaling for pi evaluation"
set xlabel "Threads"
set ylabel "Time"
set grid

set terminal pdf
set output "outputs/timing_strong.pdf"

plot "outputs/timing_naive_strong.data" using 3:4 title "Naive critical" with linespoints, \
     "outputs/timing_optimized_strong.data" using 3:4 title "Optimized critical" with linespoints, \
     "outputs/timing_reduction_strong.data" using 3:4 title "Reduction" with linespoints