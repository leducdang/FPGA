/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'CPU' in SOPC Builder design 'I2C'
 * SOPC Builder design path: ../../I2C.sopcinfo
 *
 * Generated: Wed Oct 16 09:45:08 ICT 2024
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_gen2"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x00080820
#define ALT_CPU_CPU_ARCH_NIOS2_R1
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "tiny"
#define ALT_CPU_DATA_ADDR_WIDTH 0x14
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00040020
#define ALT_CPU_FLASH_ACCELERATOR_LINES 0
#define ALT_CPU_FLASH_ACCELERATOR_LINE_SIZE 0
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 0
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x14
#define ALT_CPU_NAME "CPU"
#define ALT_CPU_OCI_VERSION 1
#define ALT_CPU_RESET_ADDR 0x00040000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x00080820
#define NIOS2_CPU_ARCH_NIOS2_R1
#define NIOS2_CPU_FREQ 50000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "tiny"
#define NIOS2_DATA_ADDR_WIDTH 0x14
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00040020
#define NIOS2_FLASH_ACCELERATOR_LINES 0
#define NIOS2_FLASH_ACCELERATOR_LINE_SIZE 0
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 0
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 0
#define NIOS2_ICACHE_LINE_SIZE_LOG2 0
#define NIOS2_ICACHE_SIZE 0
#define NIOS2_INST_ADDR_WIDTH 0x14
#define NIOS2_OCI_VERSION 1
#define NIOS2_RESET_ADDR 0x00040000


/*
 * DEBUG configuration
 *
 */

#define ALT_MODULE_CLASS_DEBUG altera_avalon_jtag_uart
#define DEBUG_BASE 0x81110
#define DEBUG_IRQ 0
#define DEBUG_IRQ_INTERRUPT_CONTROLLER_ID 0
#define DEBUG_NAME "/dev/DEBUG"
#define DEBUG_READ_DEPTH 64
#define DEBUG_READ_THRESHOLD 8
#define DEBUG_SPAN 8
#define DEBUG_TYPE "altera_avalon_jtag_uart"
#define DEBUG_WRITE_DEPTH 64
#define DEBUG_WRITE_THRESHOLD 8


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_I2C
#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __ALTERA_AVALON_SYSID_QSYS
#define __ALTERA_AVALON_TIMER
#define __ALTERA_NIOS2_GEN2


/*
 * I2C configuration
 *
 */

#define ALT_MODULE_CLASS_I2C altera_avalon_i2c
#define I2C_BASE 0x81040
#define I2C_FIFO_DEPTH 4
#define I2C_FREQ 50000000
#define I2C_IRQ 1
#define I2C_IRQ_INTERRUPT_CONTROLLER_ID 0
#define I2C_NAME "/dev/I2C"
#define I2C_SPAN 64
#define I2C_TYPE "altera_avalon_i2c"
#define I2C_USE_AV_ST 0


/*
 * LED1 configuration
 *
 */

#define ALT_MODULE_CLASS_LED1 altera_avalon_pio
#define LED1_BASE 0x810e0
#define LED1_BIT_CLEARING_EDGE_REGISTER 0
#define LED1_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED1_CAPTURE 0
#define LED1_DATA_WIDTH 7
#define LED1_DO_TEST_BENCH_WIRING 0
#define LED1_DRIVEN_SIM_VALUE 0
#define LED1_EDGE_TYPE "NONE"
#define LED1_FREQ 50000000
#define LED1_HAS_IN 0
#define LED1_HAS_OUT 1
#define LED1_HAS_TRI 0
#define LED1_IRQ -1
#define LED1_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED1_IRQ_TYPE "NONE"
#define LED1_NAME "/dev/LED1"
#define LED1_RESET_VALUE 0
#define LED1_SPAN 16
#define LED1_TYPE "altera_avalon_pio"


/*
 * LED2 configuration
 *
 */

#define ALT_MODULE_CLASS_LED2 altera_avalon_pio
#define LED2_BASE 0x810f0
#define LED2_BIT_CLEARING_EDGE_REGISTER 0
#define LED2_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED2_CAPTURE 0
#define LED2_DATA_WIDTH 7
#define LED2_DO_TEST_BENCH_WIRING 0
#define LED2_DRIVEN_SIM_VALUE 0
#define LED2_EDGE_TYPE "NONE"
#define LED2_FREQ 50000000
#define LED2_HAS_IN 0
#define LED2_HAS_OUT 1
#define LED2_HAS_TRI 0
#define LED2_IRQ -1
#define LED2_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED2_IRQ_TYPE "NONE"
#define LED2_NAME "/dev/LED2"
#define LED2_RESET_VALUE 0
#define LED2_SPAN 16
#define LED2_TYPE "altera_avalon_pio"


/*
 * LED3 configuration
 *
 */

#define ALT_MODULE_CLASS_LED3 altera_avalon_pio
#define LED3_BASE 0x810d0
#define LED3_BIT_CLEARING_EDGE_REGISTER 0
#define LED3_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED3_CAPTURE 0
#define LED3_DATA_WIDTH 7
#define LED3_DO_TEST_BENCH_WIRING 0
#define LED3_DRIVEN_SIM_VALUE 0
#define LED3_EDGE_TYPE "NONE"
#define LED3_FREQ 50000000
#define LED3_HAS_IN 0
#define LED3_HAS_OUT 1
#define LED3_HAS_TRI 0
#define LED3_IRQ -1
#define LED3_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED3_IRQ_TYPE "NONE"
#define LED3_NAME "/dev/LED3"
#define LED3_RESET_VALUE 0
#define LED3_SPAN 16
#define LED3_TYPE "altera_avalon_pio"


/*
 * LED4 configuration
 *
 */

#define ALT_MODULE_CLASS_LED4 altera_avalon_pio
#define LED4_BASE 0x810c0
#define LED4_BIT_CLEARING_EDGE_REGISTER 0
#define LED4_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED4_CAPTURE 0
#define LED4_DATA_WIDTH 7
#define LED4_DO_TEST_BENCH_WIRING 0
#define LED4_DRIVEN_SIM_VALUE 0
#define LED4_EDGE_TYPE "NONE"
#define LED4_FREQ 50000000
#define LED4_HAS_IN 0
#define LED4_HAS_OUT 1
#define LED4_HAS_TRI 0
#define LED4_IRQ -1
#define LED4_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED4_IRQ_TYPE "NONE"
#define LED4_NAME "/dev/LED4"
#define LED4_RESET_VALUE 0
#define LED4_SPAN 16
#define LED4_TYPE "altera_avalon_pio"


/*
 * LED5 configuration
 *
 */

#define ALT_MODULE_CLASS_LED5 altera_avalon_pio
#define LED5_BASE 0x810b0
#define LED5_BIT_CLEARING_EDGE_REGISTER 0
#define LED5_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED5_CAPTURE 0
#define LED5_DATA_WIDTH 7
#define LED5_DO_TEST_BENCH_WIRING 0
#define LED5_DRIVEN_SIM_VALUE 0
#define LED5_EDGE_TYPE "NONE"
#define LED5_FREQ 50000000
#define LED5_HAS_IN 0
#define LED5_HAS_OUT 1
#define LED5_HAS_TRI 0
#define LED5_IRQ -1
#define LED5_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED5_IRQ_TYPE "NONE"
#define LED5_NAME "/dev/LED5"
#define LED5_RESET_VALUE 0
#define LED5_SPAN 16
#define LED5_TYPE "altera_avalon_pio"


/*
 * LED6 configuration
 *
 */

#define ALT_MODULE_CLASS_LED6 altera_avalon_pio
#define LED6_BASE 0x810a0
#define LED6_BIT_CLEARING_EDGE_REGISTER 0
#define LED6_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED6_CAPTURE 0
#define LED6_DATA_WIDTH 7
#define LED6_DO_TEST_BENCH_WIRING 0
#define LED6_DRIVEN_SIM_VALUE 0
#define LED6_EDGE_TYPE "NONE"
#define LED6_FREQ 50000000
#define LED6_HAS_IN 0
#define LED6_HAS_OUT 1
#define LED6_HAS_TRI 0
#define LED6_IRQ -1
#define LED6_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED6_IRQ_TYPE "NONE"
#define LED6_NAME "/dev/LED6"
#define LED6_RESET_VALUE 0
#define LED6_SPAN 16
#define LED6_TYPE "altera_avalon_pio"


/*
 * RAM configuration
 *
 */

#define ALT_MODULE_CLASS_RAM altera_avalon_onchip_memory2
#define RAM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define RAM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define RAM_BASE 0x40000
#define RAM_CONTENTS_INFO ""
#define RAM_DUAL_PORT 0
#define RAM_GUI_RAM_BLOCK_TYPE "AUTO"
#define RAM_INIT_CONTENTS_FILE "I2C_RAM"
#define RAM_INIT_MEM_CONTENT 1
#define RAM_INSTANCE_ID "NONE"
#define RAM_IRQ -1
#define RAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RAM_NAME "/dev/RAM"
#define RAM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define RAM_RAM_BLOCK_TYPE "AUTO"
#define RAM_READ_DURING_WRITE_MODE "DONT_CARE"
#define RAM_SINGLE_CLOCK_OP 0
#define RAM_SIZE_MULTIPLE 1
#define RAM_SIZE_VALUE 204800
#define RAM_SPAN 204800
#define RAM_TYPE "altera_avalon_onchip_memory2"
#define RAM_WRITABLE 1


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone IV E"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/DEBUG"
#define ALT_STDERR_BASE 0x81110
#define ALT_STDERR_DEV DEBUG
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/DEBUG"
#define ALT_STDIN_BASE 0x81110
#define ALT_STDIN_DEV DEBUG
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/DEBUG"
#define ALT_STDOUT_BASE 0x81110
#define ALT_STDOUT_DEV DEBUG
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "I2C"


/*
 * hal configuration
 *
 */

#define ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
#define ALT_MAX_FD 32
#define ALT_SYS_CLK TIMER_0
#define ALT_TIMESTAMP_CLK none


/*
 * sysid_qsys_0 configuration
 *
 */

#define ALT_MODULE_CLASS_sysid_qsys_0 altera_avalon_sysid_qsys
#define SYSID_QSYS_0_BASE 0x81108
#define SYSID_QSYS_0_ID 0
#define SYSID_QSYS_0_IRQ -1
#define SYSID_QSYS_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SYSID_QSYS_0_NAME "/dev/sysid_qsys_0"
#define SYSID_QSYS_0_SPAN 8
#define SYSID_QSYS_0_TIMESTAMP 1729045351
#define SYSID_QSYS_0_TYPE "altera_avalon_sysid_qsys"


/*
 * timer_0 configuration
 *
 */

#define ALT_MODULE_CLASS_timer_0 altera_avalon_timer
#define TIMER_0_ALWAYS_RUN 0
#define TIMER_0_BASE 0x81080
#define TIMER_0_COUNTER_SIZE 32
#define TIMER_0_FIXED_PERIOD 0
#define TIMER_0_FREQ 50000000
#define TIMER_0_IRQ 2
#define TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID 0
#define TIMER_0_LOAD_VALUE 49999
#define TIMER_0_MULT 0.001
#define TIMER_0_NAME "/dev/timer_0"
#define TIMER_0_PERIOD 1
#define TIMER_0_PERIOD_UNITS "ms"
#define TIMER_0_RESET_OUTPUT 0
#define TIMER_0_SNAPSHOT 1
#define TIMER_0_SPAN 32
#define TIMER_0_TICKS_PER_SEC 1000
#define TIMER_0_TIMEOUT_PULSE_OUTPUT 0
#define TIMER_0_TYPE "altera_avalon_timer"

#endif /* __SYSTEM_H_ */
