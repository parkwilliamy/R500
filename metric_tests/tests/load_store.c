int main() {

    *(volatile int*)0x5000 = 0xdeadbeef;
    *(volatile int*)0x5004 = 0xcafef00d;
    *(volatile int*)0x5008 = 0xfee1dead;

    volatile int a = *(volatile int*)0x5000;
    *(volatile int*)0x5020 = a;

    volatile int b = *(volatile int*)0x5004;
    *(volatile int*)0x5024 = b;

    volatile int c = *(volatile int*)0x5008;
    *(volatile int*)0x5028 = c;
    
    while(1);

}