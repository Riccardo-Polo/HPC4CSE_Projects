set terminal pdfcairo enhanced color
set output "outputs/timing_weak.pdf"

set title "Weak scaling of OpenMP implementations"
set xlabel "Number of threads"
set ylabel "Average time [s]"
set grid
set key top left
set logscale x 2
set xtics ("1" 1, "2" 2, "4" 4, "8" 8, "16" 16, "32" 32, "64" 64)

plot \
    "outputs/timing_naive_weak.data" using 3:4    with linespoints title "Naive critical", \
    "outputs/timing_optimized_weak.data" using 3:4 with linespoints title "Optimized critical", \
    "outputs/timing_reduction_weak.data" using 3:4 with linespoints title "Reduction"