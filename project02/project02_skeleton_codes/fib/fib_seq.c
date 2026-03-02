#include <stdio.h>

int fib(int n) {
  if (n < 2) return n;
  return fib(n - 2) + fib(n - 1);
}

int main() {
  int n = 42;
  printf("Fibonacci fib(%2d) = %d\n", n, fib(n));
  return 0;
}
