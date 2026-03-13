set terminal pdfcairo enhanced color size 7,4.8
set output "outputs/strong_scaling.pdf"

set title "Strong scaling of Mandelbrot OpenMP implementation"
set xlabel "Number of threads"
set ylabel "Execution time [s]"
set grid
set key top right
set logscale x 2
set xtics (1,2,4,8,16,32,64)

plot \
    "outputs/timing_strong_avg.data" using 1:4:5 with yerrorlines lw 2 pt 7 title "Average time ± std. dev.", \
    "outputs/timing_strong_avg.data" using 1:6 with lines dt 2 lw 1 title "Min time", \
    "outputs/timing_strong_avg.data" using 1:7 with lines dt 3 lw 1 title "Max time"
