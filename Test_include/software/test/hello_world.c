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
#include "delay.h"
#include "system.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_spi.h"
#include "mfrc522.h"
//#include "altera_avalon_pio_regs.h"

int main()
{
  printf("Hello from Nios II!\n");
  delay_ms(2000);
  char CardID[5];
  char szBuff[100];
  return 0;
  TM_MFRC522_Init();
  while(1)
  {
	if (TM_MFRC522_Check(CardID) == MI_OK) {
		sprintf(szBuff, "ID: 0x%02X%02X%02X%02X%02X", CardID[0], CardID[1], CardID[2], CardID[3], CardID[4]);
		printf(szBuff);
	}
  }
}