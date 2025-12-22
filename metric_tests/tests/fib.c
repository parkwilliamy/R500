int fib(int n);

int main() {

    int x = fib(15);
    *(volatile int*)0x5000 = x;

}


int fib(int n) {

    if (n == 0 || n == 1) return n;
    else return fib(n-1) + fib(n-2);

}