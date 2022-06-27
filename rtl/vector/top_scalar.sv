module top_scalar #(parameter int WIDTH=32,
			 		parameter int ADDR_WIDTH=15,
			 		parameter int DATA_FROM_SCALAR=96
		       	  )(input logic clk,
		     	    input logic rst,
			 		input logic we,
			 		input logic [ADDR_WIDTH-1:0] addr_wr,
			 		input logic [WIDTH-1:0] data_in,
			 		input logic out_rsc_rdy,
					output logic [DATA_FROM_SCALAR-1:0] out_rsc_dat,
					output logic out_rsc_vld);
			 

logic [ADDR_WIDTH-1:0] InstructionMemory_rsc_addr_rd;
logic [ADDR_WIDTH-1:0] DataMemory_rsc_addr_rd;
logic [ADDR_WIDTH-1:0] DataMemory_rsc_addr_wr;
logic [WIDTH-1:0] InstructionMemory_rsc_data_out;
logic [WIDTH-1:0] DataMemory_rsc_data_out;
logic [WIDTH-1:0] DataMemory_rsc_data_in;
logic DataMemory_rsc_re;
logic DataMemory_rsc_we; 
logic InstructionMemory_rsc_re;
logic InstructionMemory_rsc_triosy_lz;
logic DataMemory_rsc_triosy_lz;
logic vector_operation_rsc_dat;
logic vector_operation_rsc_triosy_lz;

RISC processor1 (.clk(clk),
				 .rst(rst),
				 .InstructionMemory_rsc_radr(InstructionMemory_rsc_addr_rd),
				 .InstructionMemory_rsc_re(InstructionMemory_rsc_re),
				 .InstructionMemory_rsc_q(InstructionMemory_rsc_data_out),
				 .InstructionMemory_rsc_triosy_lz(InstructionMemory_rsc_triosy_lz),
				 .DataMemory_rsc_radr(DataMemory_rsc_addr_rd),
				 .DataMemory_rsc_re(DataMemory_rsc_re),
				 .DataMemory_rsc_q(DataMemory_rsc_data_out),
				 .DataMemory_rsc_d(DataMemory_rsc_data_in),
				 .DataMemory_rsc_wadr(DataMemory_rsc_addr_wr),
				 .DataMemory_rsc_we(DataMemory_rsc_we),
				 .DataMemory_rsc_triosy_lz(DataMemory_rsc_triosy_lz),
				 .out_rsc_dat(out_rsc_dat),
				 .out_rsc_vld(out_rsc_vld),
				 .out_rsc_rdy(out_rsc_rdy),
				 .vector_operation_rsc_dat(vector_operation_rsc_dat),
				 .vector_operation_rsc_triosy_lz(vector_operation_rsc_triosy_lz));
				
				
ccs_ram_sync_1R1W instructionmemory(.d(data_in),
									.radr(InstructionMemory_rsc_addr_rd),
									.wadr(addr_wr),
									.re(InstructionMemory_rsc_re),
									.we(we),
									.q(InstructionMemory_rsc_data_out),
									.clk(clk));


ccs_ram_sync_1R1W Datamemory(.d(DataMemory_rsc_data_in),
							 .radr(DataMemory_rsc_addr_rd),
							 .wadr(DataMemory_rsc_addr_wr),
						     .re(DataMemory_rsc_re),
							 .we(DataMemory_rsc_we),
							 .q(DataMemory_rsc_data_out),
						     .clk(clk));
										 

endmodule