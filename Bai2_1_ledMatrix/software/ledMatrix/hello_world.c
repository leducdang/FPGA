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
#include "unistd.h"
#include "altera_avalon_timer.h"


int main()
{
  printf("Hello from Nios II!\n");
  while(1)
  {
	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 1);
	IOWR_ALTERA_AVALON_PIO_DATA(R2_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R3_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R4_BASE, 0);
	usleep(1500);
	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R2_BASE, 1);
	IOWR_ALTERA_AVALON_PIO_DATA(R3_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R4_BASE, 0);
	usleep(1500);
	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R2_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R3_BASE, 1);
	IOWR_ALTERA_AVALON_PIO_DATA(R4_BASE, 0);
	usleep(1500);
	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R2_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R3_BASE, 0);
	IOWR_ALTERA_AVALON_PIO_DATA(R4_BASE, 1);
	usleep(1500);

//
//	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 1);
//	usleep(1000);
//	if(IORD_ALTERA_AVALON_PIO_DATA(C1_BASE))printf("1");
//	if(IORD_ALTERA_AVALON_PIO_DATA(C2_BASE))printf("2");
//	if(IORD_ALTERA_AVALON_PIO_DATA(C3_BASE))printf("3");
//	if(IORD_ALTERA_AVALON_PIO_DATA(C4_BASE))printf("A");
//	IOWR_ALTERA_AVALON_PIO_DATA(R1_BASE, 0);


  }

  return 0;
}

