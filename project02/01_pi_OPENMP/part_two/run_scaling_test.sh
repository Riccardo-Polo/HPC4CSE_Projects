# compile
make clean
make

echo "==== benchmark-naive ======================"
stdbuf -oL ./naive_strong | tee timing_naive_strong.data
stdbuf -oL ./naive_weak | tee timing_naive_weak.data
echo
echo "==== benchmark-optimized ========================"
stdbuf -oL ./optimized_strong | tee timing_optimized_strong.data
stdbuf -oL ./optimized_weak | tee timing_optimized_weak.data
echo
echo "==== benchmark-reduction ========================"
stdbuf -oL ./reduction_strong | tee timing_reduction_strong.data
stdbuf -oL ./reduction_weak | tee timing_reduction_weak.data
echo
echo
echo "==== plot results ========================="
gnuplot plot_strong.gp
gnuplot plot_weak_time.gp