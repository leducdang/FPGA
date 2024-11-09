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
#include "system.h"
#include "unistd.h"

int rs232_read_str (alt_fd* fd, char* ptr, int len);
void rs232_write_str(alt_fd* fd, char *ptr, int len);

int status;
char cnt = 0;
char chuoi[5]; // = "HELLO";
char reciver[100];

alt_up_rs232_dev* rs232_dev;

int main()
{
  printf("Hello from Nios II!\n");
  rs232_dev = alt_up_rs232_open_dev("/dev/RS232");

  while(1)
  	{
  	if(rs232_read_str(rs232_dev, chuoi, 1)>0)
  		{
  		if(chuoi[0] != '*')
  			{
  				reciver[cnt] = chuoi[0];
  				cnt++;
  			}
  		else
  			{
  				rs232_write_str(rs232_dev, "ok", 2);
  				reciver[cnt] = 0 ;
  				printf("%s\n",reciver,cnt);
  				cnt = 0;
  			}
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


