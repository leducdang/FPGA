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
#include "altera_avalon_uart_regs.h"
#include "altera_avalon_pio_regs.h"
#include <unistd.h>
#include "altera_avalon_uart.h"
#include "altera_up_avalon_rs232.h

void delay_ms(int ms)
{
	unsigned int x,y;
	for(x =0; x<ms; x++)
	{	for(y =0; y<1000; y++);}
}

int main()
{
//  char a = '0';
  int rx_cnt,rx_buf[16];
  char ch;
  printf("Hello from Nios II!\n");

  while(1)
  {
//	a = IORD_ALTERA_AVALON_UART_RXDATA(UART_0_BASE);
//	if(a == '1') IOWR_ALTERA_AVALON_PIO_DATA(0x81020, 1);
//	if(a == '0') IOWR_ALTERA_AVALON_PIO_DATA(0x81020, 0);
//	printf(a);

	  rx_cnt=0;

	  ch = IORD_ALTERA_AVALON_UART_STATUS(UART_0_BASE);
	  // if received some byte, read it
	  if ((ch&0x80)==0x80){
		  for(char n=0;n<10;n++)
	  {
			  usleep(10);
			 ch = IORD_ALTERA_AVALON_UART_RXDATA(UART_0_BASE);
			 rx_buf[rx_cnt]= ch;
			 alt_printf("%x ",ch);
			 if(ch == '1') IOWR_ALTERA_AVALON_PIO_DATA(0x81020, 1);
			 if(ch == '0') IOWR_ALTERA_AVALON_PIO_DATA(0x81020, 0);
			 rx_cnt++;
	  }
	  }


	  // print the bytes to terminal
//	  if (rx_cnt>0)
//	  { alt_printf("rx_data:");
//	  for(int n=0;n<rx_cnt;n++)
//	  { alt_printf("%x ",rx_buf[n]);
//	  }
//	  alt_printf("\n");
//	  }

  }

  return 0;
}