set terminal pdfcairo enhanced color size 7,4.8
set output "outputs/strong_speedup.pdf"

set title "Strong scaling speedup of Mandelbrot OpenMP implementation"
set xlabel "Number of threads"
set ylabel "Speedup"
set grid
set key top left
set logscale x 2
set xtics (1,2,4,8,16,32,64)

T1 = system("awk '$1==1 {print $4}' outputs/timing_strong_avg.data")

plot \
    "outputs/timing_strong_avg.data" using 1:(T1/$4) with linespoints lw 2 pt 7 title "Speedup from average time", \
    x with lines dt 2 lw 2 title "Ideal speedup"
