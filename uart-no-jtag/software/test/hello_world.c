/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include "system.h"
#include "string.h"
//#include "altera_up_avalon_rs232.h"
#include "altera_avalon_uart_regs.h"
#include "altera_avalon_pio_regs.h"

char buffer[5];


void delay_ms(int ms)
{
	unsigned int x,y;
	for(x =0; x<ms; x++)
	{	for(y =0; y<1000; y++);}
}


int main()
{
	char a='0';


	printf("hello World\n");

	while(1)
	{
		a= IORD_ALTERA_AVALON_UART_RXDATA(UART_BASE);

		if(a == '1')
			IOWR_ALTERA_AVALON_PIO_DATA(LED1_BASE,1);
		if(a == '0')
			IOWR_ALTERA_AVALON_PIO_DATA(LED1_BASE,0);
	}
	return 0;
}