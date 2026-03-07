set terminal pdfcairo enhanced color
set output "strong_speedup.pdf"

set title "Strong scaling speedup of Mandelbrot OpenMP implementation"
set xlabel "Number of threads"
set ylabel "Speedup"
set grid
set logscale x 2
set xtics (1,2,4,8,16,32,64)

T1 = system("awk '$1==1 {print $4}' timing_strong.data")

plot "timing_strong.data" using 1:(T1/$4) with linespoints lw 2 pt 7 title "Measured speedup", \
     x with lines dt 2 lw 2 title "Ideal speedup"