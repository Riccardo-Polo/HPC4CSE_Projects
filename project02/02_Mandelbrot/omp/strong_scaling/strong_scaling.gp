set terminal pdfcairo enhanced color
set output "strong_scaling.pdf"

set title "Strong scaling of Mandelbrot OpenMP implementation"
set xlabel "Number of threads"
set ylabel "Execution time [s]"
set grid
set logscale x 2
set xtics (1,2,4,8,16,32,64)

plot "timing_strong.data" using 1:4 with linespoints lw 2 pt 7 title "Measured time"