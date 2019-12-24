/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_types.h"
#include "xil_io.h"


#define ADDER_REG_A XPAR_VECTOR_ADDER_V2_0_S00_AXI_BASEADDR
#define ADDER_REG_B XPAR_VECTOR_ADDER_V2_0_S00_AXI_BASEADDR + 4
#define ADDER_REG_C XPAR_VECTOR_ADDER_V2_0_S00_AXI_BASEADDR + 8
#define ADDER_REG_D XPAR_VECTOR_ADDER_V2_0_S00_AXI_BASEADDR + 12




int main()
{
	int *a = (UINTPTR) ADDER_REG_A;
	int *b = (UINTPTR) ADDER_REG_B;
	int *c = (UINTPTR) ADDER_REG_C;


    init_platform();

    print("Hello World test\n\r");

    *c = 0x00050003;

    *a = 3;
    *a = 4;
    *a = 5;
    *a = 6;
    *a = 7;

    *b = 4;
    *b = 5;
    *b = 6;
    *b = 7;
    *b = 8;

    printf("a = %d, b = %d, c = %d \n\r",*a,*b, *c);

    cleanup_platform();
    return 0;
}
