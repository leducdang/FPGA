#include <stdio.h>
#include "system.h" //access Nios II system info
#include "io.h" //access to IORD and IORW
#include "unistd.h" //access to usleep
#include "altera_avalon_pio_regs.h" //access to PIO macros
#include <sys/alt_irq.h> // access to the IRQ routines

/* Declare a global variable to holds the edge capture value
Declaring a variable as volatile tells the compiler that
the value of the variable may change at any time without
any action being taken by the code the compiler finds nearby.
This variable will be connected to the interrupt register which
is controlled from HW and not SW. The compile will therefor not
find any code that controls this variable, and if not declared as
volatile, the compile may decided to optimize and remove this variable. */
volatile int edge_capture;
int count = 0;

/* This is the ISR which will be called when the system signals an interrupt. */
static void handle_interrupts(void* context)
{
    //Cast context to edge_capture's type
    //Volatile to avoid compiler optimization
    //this will point to the edge_capture variable.
    volatile int* edge_capture_ptr = (volatile int*) context;

    //Read the edge capture register on the PIO and store the value
    //The value will be stored in the edge_capture variable and accessible
    //from other parts of the code.
    *edge_capture_ptr = IORD_ALTERA_AVALON_PIO_EDGE_CAP(BUTTON_BASE);

    //Write to edge capture register to reset it
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(BUTTON_BASE,0);
    count++;
    printf("Interrupt detected, Key1 was pressed! %d\n", count);

}

/* This function is used to initializes and registers the interrupt handler. */
static void init_interrupt_pio()
{
    //Recast the edge_capture point to match the
    //alt_irq_register() function prototypo
    void* edge_capture_ptr = (void*)&edge_capture;

    //Enable a single interrupt input by writing a one to the corresponding interruptmask bit locations
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(BUTTON_BASE,0x1);

    //Reset the edge capture register
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(BUTTON_BASE,0);

    //Register the interrupt handler in the system
    //The ID and PIO_IRQ number is available from the system.h file.
    alt_ic_isr_register(BUTTON_IRQ_INTERRUPT_CONTROLLER_ID, BUTTON_IRQ, handle_interrupts, edge_capture_ptr, 0x0);

}


int main(){
    printf("Hello, World!\n");
    init_interrupt_pio();

    while(1){
    	if(count<10)
    	{
        IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE,0);
        usleep(100000);
        IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE,1);
        usleep(100000);
    	}
    }
    return 0;
}
