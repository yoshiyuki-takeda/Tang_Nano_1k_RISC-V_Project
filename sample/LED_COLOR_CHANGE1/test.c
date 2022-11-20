// 

#define LED_ADDR (0x00010018)
#define LOOPMAX (2700000/5)
//#define LOOPMAX (5)

int main()
{
    unsigned long i;
    volatile unsigned long *led;

    led = (unsigned long*)LED_ADDR;
    *led = 0x0;

    i = 0;
    while(1){
        i++;
        if(i>=LOOPMAX){
            *led = ( (*led)&0x7 )+1;
            i = 0;
        }
    }
}
