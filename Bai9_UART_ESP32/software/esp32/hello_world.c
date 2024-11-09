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
#include <altera_up_avalon_rs232.h>
#include <altera_avalon_pio_regs.h>
#include "system.h"
#include "unistd.h"

int rs232_read_str (alt_fd* fd, char* ptr, int len);
void rs232_write_str(alt_fd* fd, char *ptr, int len);

int stt1=1, stt2=1, stt3=1;
char cnt = 0;
char chuoi[10]; // = "HELLO";
char reciver[50];
char reciver1[100];

alt_up_rs232_dev* rs232_dev;

int main()
{
  printf("Hello from Nios II!\n");
  rs232_dev = alt_up_rs232_open_dev("/dev/RS232");

  while(1)
  	{
  	if(rs232_read_str(rs232_dev, chuoi, 1)>0)
  		{
  		if(chuoi[0] != '\n')
  			{
  				reciver[cnt] = chuoi[0];
  				cnt++;
  			}
  		else
  		{		reciver[cnt] = 0;
  				sprintf(reciver1, "FPGA:%s\n",reciver);
  				rs232_write_str(rs232_dev,reciver1,cnt+6);
//  				reciver[cnt] = 0 ;
  				printf(reciver1);
  				cnt = 0;
  			}
  		}
  	if(strstr(reciver,"on1") && !stt1)
  		{	printf("bat led 1");
//  			rs232_write_str(rs232_dev,"on1\n",4);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED1_BASE, 1);
  			stt1 = 1;
  		}
  	if(strstr(reciver,"off1") && stt1)
  		{	printf("tat led 1");
//  			rs232_write_str(rs232_dev,"off1\n",5);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED1_BASE, 0);
  			stt1 = 0;
  		}
  	if(strstr(reciver,"on2") && !stt2)
  		{	printf("bat led 2");
//  			rs232_write_str(rs232_dev,"on2\n",4);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED2_BASE, 1);
  			stt2 = 1;
  		}
  	if(strstr(reciver,"off2") && stt2)
  		{	printf("tat led 2");
//  			rs232_write_str(rs232_dev,"off2\n",5);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED2_BASE, 0);
  			stt2 = 0;
  		}
  	if(strstr(reciver,"on3") && !stt3)
  		{	printf("bat led 3");
//  			rs232_write_str(rs232_dev,"on3\n",4);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED3_BASE, 1);
  			stt3 = 1;
  		}
  	if(strstr(reciver,"off3") && stt3)
  		{	printf("tat led 3");
//  			rs232_write_str(rs232_dev,"off3\n",5);
  			IOWR_ALTERA_AVALON_PIO_DATA(LED3_BASE, 0);
  			stt3  = 0;
  		}

  	}
  return 0;
}

int rs232_read_str (alt_fd* fd, char* ptr, int len)
{
	int count = 0;
	alt_u8 parity_error;
	while(len--)
	{
		if (alt_up_rs232_read_data(fd, (alt_u8 *)ptr++, &parity_error)==0)
			{
				count++;
			}
		else
			break;
	}
	return count;
}

void rs232_write_str(alt_fd* fd, char *ptr, int len)
{
	int count = 0;
	while(len--)
	{
		if (alt_up_rs232_write_data(fd, *ptr)==0)
			{
				count++;
				ptr++;
			}
	}
}


