int main() {

    volatile int a,b,c,d,e,f,g,h;

    a = 20;
    b = a ^ 1;
    
    c = 1;
    d = c+2;
    
    e = 5;
    f = e-1;
    
    g = 2;
    h = g | 0;
    
    volatile int* RESULT_ADDR = (volatile int*)0x6000;

    RESULT_ADDR[0] = b;
    RESULT_ADDR[1] = d;
    RESULT_ADDR[2] = f;
    RESULT_ADDR[3] = h;
    
    while(1);

}