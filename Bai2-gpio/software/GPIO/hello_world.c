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
#include "altera_avalon_pio_regs.h"

void delay_ms(unsigned long ms)
{
	unsigned long x, y;
	for(x = 0; x< ms; x++)
		for(y = 0; y<1000; y++);
}

int main()
{
  printf("Hello from Nios II!\n");
  while(1)
  {
//	  IOWR_ALTERA_AVALON_PIO_DATA(0x81010,1);
//	  delay_ms(500);
	  IOWR_ALTERA_AVALON_PIO_DATA(0x81010,0);
	  delay_ms(500);
	  IOWR_ALTERA_AVALON_PIO_DATA(LED_DON_BASE,1);
	  delay_ms(500);
  }
  return 0;

}
