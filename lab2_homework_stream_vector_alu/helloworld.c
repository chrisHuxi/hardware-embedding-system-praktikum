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
#include "xaxidma.h"
#include "xil_types.h"

#define DMA_FROM_MASTER_DEVICE_ID XPAR_AXI_DMA_FROM_MASTER_DEVICE_ID
#define DMA_FROM_MASTER_BASE_ADDR XPAR_AXI_DMA_FROM_MASTER_BASEADDR

#define DMA_TO_SLAVE1_DEVICE_ID XPAR_AXI_DMA_TO_SLAVE1_DEVICE_ID
#define DMA_TO_SLAVE2_DEVICE_ID XPAR_AXI_DMA_TO_SLAVE2_DEVICE_ID

#define DMA_TO_SLAVE1_BASE_ADDR XPAR_AXI_DMA_TO_SLAVE1_BASEADDR
#define DMA_TO_SLAVE2_BASE_ADDR XPAR_AXI_DMA_TO_SLAVE2_BASEADDR

#define ADDER_REG_A XPAR_VECTOR_STREAM_ALU_0_S00_AXI_BASEADDR
#define ADDER_REG_B XPAR_VECTOR_STREAM_ALU_0_S00_AXI_BASEADDR + 4

#define SIMPLE_AXIS_NUM_WORDS 1024

XAxiDma axi_dma[3];

int init_dma(int device_id);
int test_simple_axis();

int main()
{
  int status;
  init_platform();

  print("Test Simple AXIS Hardware\n\r");
  status = init_dma(DMA_FROM_MASTER_DEVICE_ID);
  if (status != XST_SUCCESS){
    xil_printf("there is error dma from master, quit now\n\r");
    return 1;
  }
  status = init_dma(DMA_TO_SLAVE1_DEVICE_ID);
  if (status != XST_SUCCESS){
    xil_printf("there is error dma to slave1, quit now\n\r");
    return 1;
  }
  status = init_dma(DMA_TO_SLAVE2_DEVICE_ID);
  if (status != XST_SUCCESS){
    xil_printf("there is error dma to slave2, quit now\n\r");
    return 1;
  }

  int *a = (UINTPTR) ADDER_REG_A; // cmd
  int *b = (UINTPTR) ADDER_REG_B; // len
  *a = 2;
  *b = SIMPLE_AXIS_NUM_WORDS;

  status = test_simple_axis();
  if (status != XST_SUCCESS){
    xil_printf("there is error, quit now\n\r");
    return 1;
  }

  xil_printf("TEST SUCCESS\n\r");
  return 0;
}

int init_dma(int device_id)
{
  int status;
  XAxiDma_Config *CfgPtr;
  /* Initialize the XAxiDma device. */
  CfgPtr = XAxiDma_LookupConfig(device_id);
  if (!CfgPtr) {
    xil_printf("No config found for %d\r\n", device_id);
    return XST_FAILURE;
  }
  xil_printf("Found config for AXI DMA %d\n\r", device_id);


  status = XAxiDma_CfgInitialize(&axi_dma[device_id], CfgPtr);
  if (status != XST_SUCCESS) {
    xil_printf("Initialization failed %d\r\n", status);
    return XST_FAILURE;
  }
  xil_printf("Finish initializing configurations for AXI DMA %d\n\r", device_id);

  if(XAxiDma_HasSg(&axi_dma[device_id])){
    xil_printf("Device configured as SG mode \r\n");
    return XST_FAILURE;
  }
  xil_printf("AXI DMA is configured as Simple Transfer mode\n\r");

  XAxiDma_IntrDisable(&axi_dma[device_id], XAXIDMA_IRQ_ALL_MASK,
      XAXIDMA_DEVICE_TO_DMA);
  XAxiDma_IntrDisable(&axi_dma[device_id], XAXIDMA_IRQ_ALL_MASK,
      XAXIDMA_DMA_TO_DEVICE);
  return XST_SUCCESS;
}//init_dma

int test_simple_axis()
{
  int in_test_data_1[SIMPLE_AXIS_NUM_WORDS];
  int in_test_data_2[SIMPLE_AXIS_NUM_WORDS];
  int out_test_data[SIMPLE_AXIS_NUM_WORDS];
  int i;
  int status;

  //init input test data
  for (i = 0; i < SIMPLE_AXIS_NUM_WORDS; i++){
    in_test_data_1[i] = i;
  }
  for (i = 0; i < SIMPLE_AXIS_NUM_WORDS; i++){
    in_test_data_2[i] = 2+i;
  }

  //we need to flush the cache to DDR
  Xil_DCacheFlushRange((UINTPTR) in_test_data_1, SIMPLE_AXIS_NUM_WORDS * sizeof(int));
  Xil_DCacheFlushRange((UINTPTR) in_test_data_2, SIMPLE_AXIS_NUM_WORDS * sizeof(int));

  //initiate the transfer to device1
  status = XAxiDma_SimpleTransfer(&axi_dma[DMA_TO_SLAVE1_DEVICE_ID],
                                  (UINTPTR) in_test_data_1,
                                  SIMPLE_AXIS_NUM_WORDS * sizeof(int),
                                  XAXIDMA_DMA_TO_DEVICE);
  if (status != XST_SUCCESS){ return XST_FAILURE;}

  //initiate the transfer to device2
  status = XAxiDma_SimpleTransfer(&axi_dma[DMA_TO_SLAVE2_DEVICE_ID],
                                  (UINTPTR) in_test_data_2,
                                  SIMPLE_AXIS_NUM_WORDS * sizeof(int),
                                  XAXIDMA_DMA_TO_DEVICE);
  if (status != XST_SUCCESS){ return XST_FAILURE;}


  //instruct the DMA_FROM_MASTER to receive the data
  status = XAxiDma_SimpleTransfer(&axi_dma[DMA_FROM_MASTER_DEVICE_ID],
                                  (UINTPTR) out_test_data,
                                  SIMPLE_AXIS_NUM_WORDS * sizeof(int),
                                  XAXIDMA_DEVICE_TO_DMA);
  if (status != XST_SUCCESS){ return XST_FAILURE;}

  //wait for the DMA_TO_SLAVE to finish
  while (XAxiDma_Busy(&axi_dma[DMA_TO_SLAVE1_DEVICE_ID],XAXIDMA_DMA_TO_DEVICE)){}
  xil_printf("finish dma to slave1\n\r");

  //wait for the DMA_TO_SLAVE to finish
  while (XAxiDma_Busy(&axi_dma[DMA_TO_SLAVE2_DEVICE_ID],XAXIDMA_DMA_TO_DEVICE)){}
  xil_printf("finish dma to slave2\n\r");

  //wait for the DMA_FROM_MASTER to finish
  while (XAxiDma_Busy(&axi_dma[DMA_FROM_MASTER_DEVICE_ID],XAXIDMA_DEVICE_TO_DMA)){}
  xil_printf("finish dma from master\n\r");

  //everything is done, now invalidate the output result to read from DDR
  Xil_DCacheInvalidateRange((UINTPTR) out_test_data, SIMPLE_AXIS_NUM_WORDS * sizeof(int));

  status = XST_SUCCESS;
  for (i = 0; i < SIMPLE_AXIS_NUM_WORDS; i++){
    if (out_test_data[i] != in_test_data_1[i] * in_test_data_2[i]) {
      xil_printf("error: out_test_data[%d] = %d, in_test_data_1[%d] = %d\n\r", i, out_test_data[i], i, in_test_data_1[i]);
      status = XST_FAILURE;
    }
  }

  return status;
}//test_simple_axis
