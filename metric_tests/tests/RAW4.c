int main() {

    volatile int a;

    a = 5;
    a = a+1;
    a = a+2;
    a = a+3;
   
    volatile int* RESULT_ADDR = (volatile int*)0x6000;

    *RESULT_ADDR = a;
    
    while(1);

}