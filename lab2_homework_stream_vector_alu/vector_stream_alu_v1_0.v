
`timescale 1 ns / 1 ps

	module vector_stream_alu_v1_0 #
	(
		// Users to add parameters here
        parameter integer C_AXIS_MAX_INPUT_WORDS  = 1024,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Slave Bus Interface S01_AXIS
		parameter integer C_S01_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Slave Bus Interface S01_AXIS
		input wire  s01_axis_aclk,
		input wire  s01_axis_aresetn,
		output wire  s01_axis_tready,
		input wire [C_S01_AXIS_TDATA_WIDTH-1 : 0] s01_axis_tdata,
		input wire  s01_axis_tlast,
		input wire  s01_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	  // function called clogb2 that returns an integer which has the 
      // value of the ceiling of the log base 2.
      function integer clogb2 (input integer bit_depth);
        begin
          for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
            bit_depth = bit_depth >> 1;
        end
      endfunction
    
      // gives the minimum number of bits needed to address 'C_AXIS_MAX_INPUT_WORDS' size of memory.
      localparam MEM_ADDR_W = clogb2(C_AXIS_MAX_INPUT_WORDS - 1);
      // ======================================================================================= //
      //signals for the shared BRAM between AXIS Slave and AXIS Master
      //the AXIS Slave uses the write port, while the AXIS Master uses the read port
      reg                                  w_A_rd_en;
      reg [MEM_ADDR_W - 1:0]               w_A_rd_addr;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_A_rd_data;

      reg                                  w_B_rd_en;
      reg [MEM_ADDR_W - 1:0]               w_B_rd_addr;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_B_rd_data;
      
      wire                                  w_C_rd_en;
      wire [MEM_ADDR_W - 1:0]               w_C_rd_addr;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_C_rd_data;
      
      wire                                  w_A_wr_en;
      wire [MEM_ADDR_W - 1:0]               w_A_wr_addr;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_A_wr_data;
      wire                                  w_A_calculate_data_ready;
      
      wire                                  w_B_wr_en;
      wire [MEM_ADDR_W - 1:0]               w_B_wr_addr;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_B_wr_data;
      wire                                  w_B_calculate_data_ready;

      //wire                                  w_C_wr_en;
      wire [MEM_ADDR_W - 1:0]               w_C_wr_addr;
      //wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   w_C_wr_data;
      reg                                  w_C_data_ready;
      
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   control;
      wire [C_S00_AXIS_TDATA_WIDTH - 1:0]   vector_length;
      
      //====================== for alu ======================
        // Here I use C_S00_AXIS_TDATA_WIDTH instead of C_S00_AXIS_TADDR_WIDTH, is there a problem?
        /*
        reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_wr_A; 
        reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_wr_B; 
        wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_wr_C;
        
        reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_rd_A;
        reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_rd_B;
        reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] addr_rd_C;
    
        wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] data_rd_A;
        wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] data_rd_B;
        wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] data_rd_C;
        */
        //reg read_mem_en_A;
        //reg read_mem_en_B;
        //reg read_mem_en_C;
        reg start_cal_reg;
        wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] result_element;
        wire result_done_element;
        wire result_done_vector;
        reg reset_flag_ready_C;
      // =================================== »¹Ã»ÐÞ¸Ä ==================================== //    

// Instantiation of Axi Bus Interface S00_AXIS
	vector_stream_alu_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
		.C_S_AXIS_MAX_INPUT_WORDS(C_AXIS_MAX_INPUT_WORDS)
	) vector_stream_alu_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axi_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),
		
        .o_wr_en(w_A_wr_en),
        .o_wr_addr(w_A_wr_addr),
        .o_wr_data(w_A_wr_data),
        .o_data_ready(w_A_calculate_data_ready)
	);

// Instantiation of Axi Bus Interface S01_AXIS
	vector_stream_alu_v1_0_S01_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S01_AXIS_TDATA_WIDTH),
		.C_S_AXIS_MAX_INPUT_WORDS(C_AXIS_MAX_INPUT_WORDS)
	) vector_stream_alu_v1_0_S01_AXIS_inst (
		.S_AXIS_ACLK(s00_axi_aclk),
		.S_AXIS_ARESETN(s01_axis_aresetn),
		.S_AXIS_TREADY(s01_axis_tready),
		.S_AXIS_TDATA(s01_axis_tdata),
		.S_AXIS_TLAST(s01_axis_tlast),
		.S_AXIS_TVALID(s01_axis_tvalid),
		
        .o_wr_en(w_B_wr_en),
        .o_wr_addr(w_B_wr_addr),
        .o_wr_data(w_B_wr_data),
        .o_data_ready(w_B_calculate_data_ready)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	vector_stream_alu_v1_0_M00_AXIS # ( 
        .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
        .C_M_AXIS_MAX_INPUT_WORDS(C_AXIS_MAX_INPUT_WORDS)
	) vector_stream_alu_v1_0_M00_AXIS_inst (
		.M_AXIS_ACLK(s00_axi_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready),
		
		.i_data_ready(w_C_data_ready),
        .o_rd_en(w_C_rd_en),
        .o_rd_addr(w_C_rd_addr),
        .i_rd_data(w_C_rd_data)
	);

// Instantiation of Axi Bus Interface S00_AXI
	vector_stream_alu_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) vector_stream_alu_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

        .o_control(control),
        .o_vector_length(vector_length)
	);

	// Add user logic here
	//  ============================ alu ==============================: 

	//after writing bram A and bram B, we can do read and calculate

	always @( posedge s00_axi_aclk )
	begin
	  if ( s00_axi_aresetn == 1'b0 )
	  begin
	    w_A_rd_en <= 0;
	  end
	  else
	  begin
	    if((w_A_calculate_data_ready == 1) ) 
	    begin
	      w_A_rd_en <= 1;
	    end
	  end
	end
    	
	always @( posedge s00_axi_aclk )
	begin
	  if ( s00_axi_aresetn == 1'b0 )
	  begin
	    w_B_rd_en <= 0;
	  end
	  else
	  begin
	    if((w_B_calculate_data_ready == 1) ) 
	    begin
	      w_B_rd_en <= 1; 
	    end
	  end
	end

	always @( posedge s00_axi_aclk )
	begin
	  if ( s00_axi_aresetn == 1'b0 )
	  begin
	    reset_flag_ready_C <= 0;
	  end
	  else
	    if(result_done_vector == 1)
	    begin
	       reset_flag_ready_C <= 1;
	    end	
	    else
	    begin
	      reset_flag_ready_C <= reset_flag_ready_C;
	    end
	end

	always @( posedge s00_axi_aclk )
	begin
	  if ( s00_axi_aresetn == 1'b0 )
	  begin
	    w_C_data_ready <= 0;
	  end
	  else
	  begin
	    if((result_done_vector == 1) && (reset_flag_ready_C == 0))
	    begin
	      w_C_data_ready <= 1;
	    end
	    else
	    begin
	      w_C_data_ready <= 0;
	    end	    

	  end
	end
        
    
    //reading and set start_cal_reg=1, every time calculate 1 element, then set start_cal_reg=0,
    // in order to make sure writing the result to bram C 
	always @( posedge s00_axi_aclk )
	begin	
	  if ( s00_axi_aresetn == 1'b0 )
	  begin
	    start_cal_reg <= 0;
	  end
	  else
	  begin
	    if((w_A_rd_en == 1) &&(w_B_rd_en == 1))
	    begin
	      if((w_B_rd_addr < vector_length) && (w_A_rd_addr < vector_length))
	        begin
	          if(result_done_element == 0)
	            begin
	              start_cal_reg <= 1;
	            end 
	          else
	            begin
	              start_cal_reg <= 0;
	            end
	          end
	      else
	        begin
	          start_cal_reg <= 0;
	        end  
	    end
	  end
	end
    
    //everytime after calculation, read the next data from bram A and bram B
    always @( negedge start_cal_reg )
	begin	
      if ( s00_axi_aresetn == 1'b0 )
	  begin
	    w_A_rd_addr <= 0;
	    w_B_rd_addr <= 0;
	  end
	  else
	  begin
	    if((w_B_rd_addr < vector_length) && (w_A_rd_addr < vector_length))
	    begin
	      w_B_rd_addr <= w_B_rd_addr + 1;
	      w_A_rd_addr <= w_A_rd_addr + 1;
	    end
	    else
	    begin
	      w_B_rd_addr <= w_B_rd_addr;
	      w_A_rd_addr <= w_A_rd_addr;
	    end
	  end
	end 
	
	vector_stream_alu alu_inst(
	.clk(s00_axi_aclk),               
    .resetn(s00_axi_aresetn), 
    .a(w_A_rd_data),                   //input1
    .b(w_B_rd_data),                   //input2
    .command(control),      //command
    .vector_length(vector_length), //input vector length
    
    .start_cal(start_cal_reg),  

    .element_output(result_element),
    .result_done_element(result_done_element), // did we finish calculation for one element?
    .result_done_vector(result_done_vector),       // did we finish calculation for the whole vector?
    .counter(w_C_wr_addr)	
	);
	//  ============================ alu end ==============================
	//
	
      //instantiation of the mem A
      mem #(
        .DATA_W(C_S00_AXIS_TDATA_WIDTH),
        .DEPTH(C_AXIS_MAX_INPUT_WORDS)
      ) mem_A (
        .rd_clk(s00_axi_aclk), // dosen't matter, because all clocks are the same
        .rd_en(w_A_rd_en),
        .rd_addr(w_A_rd_addr),
        .rd_data(w_A_rd_data),
    
        .wr_clk(s00_axi_aclk),
        .wr_en(w_A_wr_en),
        .wr_addr(w_A_wr_addr),
        .wr_data(w_A_wr_data)
      );
      
      mem #(
        .DATA_W(C_S00_AXIS_TDATA_WIDTH),
        .DEPTH(C_AXIS_MAX_INPUT_WORDS)
      ) mem_B (
        .rd_clk(s00_axi_aclk), // dosen't matter, because all clocks are the same
        .rd_en(w_B_rd_en),
        .rd_addr(w_B_rd_addr),
        .rd_data(w_B_rd_data),
    
        .wr_clk(s00_axi_aclk),
        .wr_en(w_B_wr_en),
        .wr_addr(w_B_wr_addr),
        .wr_data(w_B_wr_data)
      );
      
      mem #(
        .DATA_W(C_S00_AXIS_TDATA_WIDTH),
        .DEPTH(C_AXIS_MAX_INPUT_WORDS)
      ) mem_C (
        .rd_clk(s00_axi_aclk), // dosen't matter, because all clocks are the same
        .rd_en(w_C_rd_en),
        .rd_addr(w_C_rd_addr),
        .rd_data(w_C_rd_data),
    
        .wr_clk(s00_axi_aclk),
        .wr_en(result_done_element),
        .wr_addr(w_C_wr_addr),
        .wr_data(result_element)
      );
         // ila to check result
    ila_0 ila_axis_inst(
    .clk(s00_axi_aclk),
    .probe0(start_cal_reg),
    .probe1(result_done_element),
    .probe2(w_A_calculate_data_ready),
    .probe3(w_B_calculate_data_ready),
    
    .probe4(w_A_rd_addr),
    .probe5(w_A_rd_data),
    .probe6(w_B_rd_addr),
    .probe7(w_B_rd_data),
    .probe8(control),
    .probe9(vector_length)
    
    
    /*
    .probe0(w_A_rd_en),
    .probe1(result_done_element),
    .probe2(start_cal_reg),
    .probe3(w_A_rd_data),
    .probe4(w_A_rd_addr),
    .probe5(control),
    .probe6(w_B_wr_addr),
    .probe7(w_C_wr_addr),
    .probe8(w_C_rd_data),
    .probe9(w_A_wr_addr),
    .probe10(w_A_calculate_data_ready)  */    
    );
	// User logic ends

	endmodule
