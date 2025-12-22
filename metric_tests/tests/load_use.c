int main() {

    *(volatile int*)0x5000 = 32;
    *(volatile int*)0x5004 = 64;
    *(volatile int*)0x5008 = 128;

    volatile int a = *(volatile int*)0x5000;
    int b = a+24;
    *(volatile int*)0x5020 = b;

    volatile int c = *(volatile int*)0x5004;
    int d = c-12;
    *(volatile int*)0x5024 = d;

    volatile int e = *(volatile int*)0x5008;
    int f = e+128;
    *(volatile int*)0x5028 = f;
    
    while(1);

}