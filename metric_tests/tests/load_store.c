int main() {

    *(volatile int*)0x5000 = 32;
    *(volatile int*)0x5004 = 64;
    *(volatile int*)0x5008 = 128;

    volatile int a = *(volatile int*)0x5000;
    *(volatile int*)0x5020 = a;

    volatile int b = *(volatile int*)0x5004;
    *(volatile int*)0x5024 = b;

    volatile int c = *(volatile int*)0x5008;
    *(volatile int*)0x5028 = c;
    
    while(1);

}