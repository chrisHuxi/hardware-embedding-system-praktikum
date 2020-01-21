
`timescale 1 ns / 1 ps

module vector_stream_alu_v1_0_S00_AXIS #
(
  // Users to add parameters here

  // User parameters ends
  // Do not modify the parameters beyond this line

  // AXI4Stream sink: Data Width
  parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
  parameter integer C_S_AXIS_MAX_INPUT_WORDS = 1024,
  parameter integer MEM_ADDR_W               = clogb2(C_S_AXIS_MAX_INPUT_WORDS)
  )
  (
    // Users to add ports here
    output wire                                 o_wr_en,
    output wire [MEM_ADDR_W - 1:0]              o_wr_addr,
    output wire [C_S_AXIS_TDATA_WIDTH - 1:0]    o_wr_data,
    output wire                                 o_data_ready,

    // User ports ends
    // Do not modify the ports beyond this line

    // AXI4Stream sink: Clock
    input wire  S_AXIS_ACLK,
    // AXI4Stream sink: Reset
    input wire  S_AXIS_ARESETN,
    // Ready to accept data in
    output wire  S_AXIS_TREADY,
    // Data in
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
    // Indicates boundary of last packet
    input wire  S_AXIS_TLAST,
    // Data is in valid
    input wire  S_AXIS_TVALID
  );
  // function called clogb2 that returns an integer which has the 
  // value of the ceiling of the log base 2.
  function integer clogb2 (input integer bit_depth);
    begin
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
  endfunction

  //limit the number of input words
  localparam NUMBER_OF_INPUT_WORDS = C_S_AXIS_MAX_INPUT_WORDS;
  // Define the states of state machine
  // The control state machine oversees the writing of input streaming data to the mem,
  localparam [0:0] IDLE         = 1'b0;        // This is the initial/idle state 
  localparam [0:0] WRITE_MEM    = 1'b1; // In this state mem is written with the

  // input stream data S_AXIS_TDATA 
  wire  	axis_tready;
  // State variable
  reg mst_exec_state;  
  // mem write pointer
  reg [MEM_ADDR_W - 1:0] write_pointer;
  // sink has accepted all the streaming data and stored in mem
  reg writes_done;
  // I/O Connections assignments

  assign S_AXIS_TREADY	= axis_tready;
  // Control state machine implementation
  always @(posedge S_AXIS_ACLK) 
  begin  
    if (!S_AXIS_ARESETN) 
      // Synchronous reset (active low)
    begin
      mst_exec_state <= IDLE;
    end  
    else
      case (mst_exec_state)
        IDLE: 
          // The sink starts accepting tdata when 
          // there tvalid is asserted to mark the
          // presence of valid streaming data 
          if (S_AXIS_TVALID)
          begin
            mst_exec_state <= WRITE_MEM;
          end
          else
          begin
            mst_exec_state <= IDLE;
          end
          WRITE_MEM: 
            // When the sink has accepted all the streaming input data,
            // the interface swiches functionality to a streaming master
            if (writes_done)
            begin
              mst_exec_state <= IDLE;
            end
            else
            begin
              // The sink accepts and stores tdata 
              // into mem
              mst_exec_state <= WRITE_MEM;
            end

      endcase
  end
  // AXI Streaming Sink 
  // 
  // The example design sink is always ready to accept the S_AXIS_TDATA  until
  // the mem is not filled with NUMBER_OF_INPUT_WORDS number of input words.
  assign axis_tready = ((mst_exec_state == WRITE_MEM) && (write_pointer <= NUMBER_OF_INPUT_WORDS-1));

  // mem write enable generation
  assign o_wr_en        = S_AXIS_TVALID && axis_tready;
  assign o_wr_addr      = write_pointer;
  assign o_wr_data      = S_AXIS_TDATA;
  assign o_data_ready   = writes_done;
  always@(posedge S_AXIS_ACLK)
  begin
    if(!S_AXIS_ARESETN)
    begin
      write_pointer <= 0;
      writes_done <= 1'b0;
    end  
    else
    begin
      if (writes_done == 1'b1)
      begin
        writes_done     <= 1'b0;
        write_pointer   <= 0;
      end 
      else
      begin
        if (write_pointer <= NUMBER_OF_INPUT_WORDS-1)
        begin
          if (o_wr_en)
          begin
            // write pointer is incremented after every write to the mem
            // when mem write signal is enabled.
            write_pointer <= write_pointer + 1;
            writes_done <= 1'b0;
          end
          if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
          begin
            // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
            // has been written to the mem which is also marked by S_AXIS_TLAST(kept for optional usage).
            writes_done <= 1'b1;
          end
        end
      end  
    end
  end


endmodule
