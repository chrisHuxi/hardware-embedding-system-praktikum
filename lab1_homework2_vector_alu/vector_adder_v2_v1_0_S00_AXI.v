
`timescale 1 ns / 1 ps

	module vector_adder_v2_v1_0_S00_AXI #
	(
		// Users to add parameters here
        parameter MEM_SIZE = 32,
        
        
		// User parameters ends
		// Do not modify the parameters beyond this line
        
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0; // for input vector A
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1; // for input vector B
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2; // for status and command
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3; // for result vector C
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;
	
    // we take slv_reg2 as three reg: 1.return done signal 2. get vector length 3. get the op command (+, -, *, power)
	wire [7:0] status_reg; 
    reg [7:0] vector_length_reg;
	reg [15:0] command_reg;
    //==============================================================================================================//
    
    // every time we read data from ARM, we set read_in_A = read_in_A + 1, so that we can start store data into bram A, the same as bram B
    reg[31:0] read_in_A;
    reg[31:0] read_in_B;
	reg [2:0] state_counter; //3 states£º1.input1£¬2.input2£¬3.commad
    //==============================================================================================================//
    
    // we use 3 bram, A and B for reading 2 input vectors, C for output vector
    // for each bram we need rd and wr address, data, enable
    // here write enable and address we use other signals.
    reg [C_S_AXI_DATA_WIDTH-1 : 0] addr_wr_A; 
    reg [C_S_AXI_DATA_WIDTH-1 : 0] addr_wr_B; 
    wire [C_S_AXI_DATA_WIDTH-1 : 0] addr_wr_C;
    
    reg [C_S_AXI_DATA_WIDTH-1 : 0] addr_rd_A;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] addr_rd_B;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] addr_rd_C;

    wire [C_S_AXI_DATA_WIDTH-1 : 0] data_rd_A;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] data_rd_B;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] data_rd_C;

    reg read_mem_en_A;
    reg read_mem_en_B;
    reg read_mem_en_C;
    //==============================================================================================================//
    
    // signal for alu, when we have read vector A and B, then we set start_cal_reg to 1
    // and every time we finish calculate, we set the result to result_element, and set result_done_element to 1
    reg start_cal_reg;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] result_element;
    wire result_done_element;
    //==============================================================================================================//
    

	
	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	assign slv_reg2 = {status_reg, vector_length_reg, command_reg};
	
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      command_reg <= 0;
	      vector_length_reg <= 0;
	      read_in_A <= 0;
	      read_in_B <= 0;
	      state_counter <= 0;
	      //https://stackoverflow.com/questions/59227521/vhdl-vivado-combinatorial-loop-alert
	      //https://stackoverflow.com/questions/54817633/inferring-latch-in-a-nested-if-else-statement-vhdl
	      //slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	          begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
	            state_counter <= state_counter | 3'b001;
	            read_in_A <= read_in_A + 1;
	          end
	          2'h1:
	          begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) 
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end          
	            state_counter <= state_counter | 3'b010;
	            read_in_B <= read_in_B + 1;
	          end 
	          2'h2:
	          begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)- 1 - 1 - 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                //slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                command_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                vector_length_reg <= S_AXI_WDATA[ ((C_S_AXI_DATA_WIDTH/8)- 1 - 1) * 8 +: 8 ];
	              end 
	                
	              state_counter <= state_counter | 3'b100;
	          end
//	          2'h3:
//	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
//	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      command_reg <= command_reg;
	                      vector_length_reg <= vector_length_reg;
	                      //slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	      
	      
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	
	// every time we set addr_wr_A as read_in_A, 
    // so that we can get data from ARM and write to bram A
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	  begin
	    addr_wr_A <= 0;
	  end
	  else
	  begin
	    if((read_in_A <= vector_length_reg))
	    begin
	      addr_wr_A <= read_in_A;
	    end
	    else
	    begin
	      addr_wr_A <= addr_wr_A;
	    end
	  end	
	end
	
	
	// every time we set addr_wr_B as read_in_B, 
    // so that we can get data from ARM and write to bram B
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	  begin
	    addr_wr_B <= 0;
	  end
	  else
	  begin
	    if((read_in_B <= vector_length_reg) )
	    begin
	      addr_wr_B <= read_in_B;
	    end
	    else
	    begin
	      addr_wr_B <= addr_wr_B;
	    end
	  end	
	end
    
    
	//after writing bram A and bram B, we can do read and calculate
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	  begin
	    read_mem_en_A <= 0;
	    read_mem_en_B <= 0;
	  end
	  else
	  begin
	    if((state_counter == 3'b111) && (addr_wr_A == vector_length_reg) && (addr_wr_B  == vector_length_reg) ) 
	    begin
	      read_mem_en_A <= 1;
	      read_mem_en_B <= 1; 
	    end
	  end
	end
    
    
    //reading and set start_cal_reg=1, every time calculate 1 element, then set start_cal_reg=0,
    // in order to make sure writing the result to bram C 
	always @( posedge S_AXI_ACLK )
	begin	
	  if ( S_AXI_ARESETN == 1'b0 )
	  begin
	    start_cal_reg <= 0;
	  end
	  else
	  begin
	    if((read_mem_en_A == 1) &&(read_mem_en_B == 1))
	    begin
	      if((addr_rd_B < vector_length_reg) && (addr_rd_A < vector_length_reg))
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
      if ( S_AXI_ARESETN == 1'b0 )
	  begin
	    addr_rd_A <= 0;
	    addr_rd_B <= 0;
	  end
	  else
	  begin
	    if((addr_rd_B < vector_length_reg) && (addr_rd_A < vector_length_reg))
	    begin
	      addr_rd_B <= addr_rd_B + 1;
	      addr_rd_A <= addr_rd_A + 1;
	    end
	    else
	    begin
	      addr_rd_B <= addr_rd_B;
	      addr_rd_A <= addr_rd_A;
	    end
	  end
	end    
    
    // when calculation of whole vector finished, we start to read bram C
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      read_mem_en_C <= 0;
	    end
	  else
	    begin
	      if((status_reg == 1) && (addr_rd_C < vector_length_reg))
	        begin
	          read_mem_en_C <= 1;
	        end
	      else
	        begin
	          read_mem_en_C <= 0;
	        end
	    end
	end

	// move reading address accordingly
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	  begin
          addr_rd_C <= 0;
	  end
	  else
	  begin
	    if(read_mem_en_C == 1)
	    begin
	      addr_rd_C <= addr_rd_C + 1;
	    end
	    else
	    begin
	      addr_rd_C <= addr_rd_C;
	    end
	  end
	end



	//bram A instance
	bram bram_inputA_inst(
	.clk(S_AXI_ACLK), 
    .wr_enable((state_counter & 3'b001) == 3'b001), //when we get data , we start to write mem.
    .write_element(slv_reg0),
    .write_addr(addr_wr_A),

    .rd_enable((read_mem_en_A == 1) &&(read_mem_en_B == 1)), // only when input1 and input2 have finished, we start to read (and calculate)
    .read_addr(addr_rd_A),
    .read_element(data_rd_A)
	);
	
	//bram B instance
	bram bram_inputB_inst(
	.clk(S_AXI_ACLK), 
    .wr_enable((state_counter & 3'b010) == 3'b010),
    .write_element(slv_reg1),
    .write_addr(addr_wr_B),

    .rd_enable((read_mem_en_A == 1) &&(read_mem_en_B == 1)), 
    .read_addr(addr_rd_B),
    .read_element(data_rd_B) 
	);
	
	//bram C instance
	bram bram_inputC_inst(
	.clk(S_AXI_ACLK),              
    .wr_enable((result_done_element) && (addr_wr_C < vector_length_reg)),
    .write_element(result_element),
    .write_addr(addr_wr_C),
    
    .rd_enable(read_mem_en_C), 
    .read_addr(addr_rd_C),
    .read_element(data_rd_C)              
	);
	
	
	//alu instance
	alu_vector alu_vector_inst(
	.clk(S_AXI_ACLK),               
    .resetn(S_AXI_ARESETN), 
    .a(data_rd_A),                   //input1
    .b(data_rd_B),                   //input2
    .command(command_reg),      //command
    .vector_length(vector_length_reg), //input vector length
    
    .start_cal(start_cal_reg),  

    .element_output(result_element),
    .result_done_element(result_done_element), // did we finish calculation for one element?
    .result_done_vector(status_reg),       // did we finish calculation for the whole vector?
    .counter(addr_wr_C)
	);
	

    // ila to check result
    ila_axi ila_axi_inst(
    .clk(S_AXI_ACLK),
    .probe0(read_mem_en_A),
    .probe1(read_mem_en_B),
    .probe2(start_cal_reg),
    .probe3(data_rd_A),
    .probe4(data_rd_B),
    .probe5(state_counter),
    .probe6(read_mem_en_C),
    .probe7(addr_rd_C),
    .probe8(data_rd_C)
    );

	// User logic ends

	endmodule
