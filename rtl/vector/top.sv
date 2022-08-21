`ifdef MODEL_TECH
    `include "structs.sv"
    `include "vstructs.sv"
    `include "params.sv"
`endif

module top #(parameter int WIDTH=32,
			 parameter int ADDR_WIDTH=15,
			 parameter int DATA_FROM_SCALAR=96,
             parameter int INSTRUCTION_BITS=32
           )(input logic clk,
             input logic rst,
             input logic we,
             input logic [ADDR_WIDTH-1:0] addr_wr,
             input logic [WIDTH-1:0] data_in);

// Scalar Top
logic out_rsc_rdy;
logic [DATA_FROM_SCALAR-1:0] out_rsc_dat;
logic out_rsc_vld;
//EB One Slot
logic valid;
logic ready;
to_vector decoded_instruction ;
logic [DATA_FROM_SCALAR-1:0] vector_instructions;
// Vector Top
logic           vector_idle_o   ;
logic           pop             ;
//Cache Request Interface       ;
logic           mem_req_valid_o ;
vector_mem_req  mem_req_o       ;
logic           cache_ready_i   ;
//Cache Response Interface
logic           mem_resp_valid_i;
vector_mem_resp mem_resp_i      ;
// Cache and memory unit
logic                 req_rd_l2_dcache_valid;
logic                 resp_l2_dcache_valid  ;
logic                 write_l2_valid        ;
logic [ADDR_BITS-1:0] req_rd_l2_dcache_addr ;
logic [ADDR_BITS-1:0] resp_l2_dcache_addr   ;
logic [ADDR_BITS-1:0] req_wr_l2_dcache_addr ;
logic [    DC_DW-1:0] req_wr_l2_dcache_data ;
logic [    DC_DW-1:0] resp_l2_dcache_data   ;
logic                 req_wr_l2_dcache_valid;
logic                 valid_instr           ;
to_vector             vector_instr          ;
logic                 vector_pop            ;
logic                 mem_req_valid         ;
vector_mem_req        mem_req               ;
logic                 cache_vector_ready    ;
logic                 mem_resp_valid        ;
vector_mem_resp       mem_resp              ;
logic                 vector_idle           ;
logic                 ready_o_decoder       ;
logic                 ready_i_decoder       ;
logic                 valid_o_decoder       ;
logic                 valid_i_decoder       ;
//logic                 bubble_ready          ;

//assign bubble_ready = valid & ready_o_decoder ;
//////////////////////////////////////////////////
//       Decoding' Module (Scalar-Vector)       //
//////////////////////////////////////////////////
vdecode_mod decoder_b(
                        .clk                (clk                ),
                        .rst_n              (rst_n              ),
                        .ready_i            (pop                ),
                        .ready_o            (ready_o_decoder    ),
                        .valid_i            (valid              ),
                        .valid_o            (valid_o_decoder    ),
                        .instr_out          (decoded_instruction),
				        .vector_instructions(vector_instructions)
);
//////////////////////////////////////////////////
//                Scalar' Processor             //
//////////////////////////////////////////////////
top_scalar scalar_proc(.clk         (clk        ),
                       .rst         (rst        ),
                       .we          (we         ),
                       .addr_wr     (addr_wr    ),
                       .data_in     (data_in    ),
                       .out_rsc_rdy (out_rsc_rdy),
                       .out_rsc_dat (out_rsc_dat),
                       .out_rsc_vld (out_rsc_vld));
//////////////////////////////////////////////////
//                Scalar to Decoding            //
//////////////////////////////////////////////////
eb_one_slot one_slot(.clk           (clk                ),
                     .rst           (rst                ),
                     .valid_in      (out_rsc_vld        ),
                     .ready_out     (out_rsc_rdy        ),
                     .data_in       (out_rsc_dat        ),
                     .valid_out     (valid              ),
                     .ready_in      (ready_o_decoder    ),
                     .data_out      (vector_instructions));
					 
assign rst_n = ~rst;
//////////////////////////////////////////////////
//                Vector' Processor             //
//////////////////////////////////////////////////
vector_top #(
        .VECTOR_REGISTERS  (VECTOR_REGISTERS        ),
        .VECTOR_LANES      (VECTOR_LANES            ),
      //  .VECTOR_ACTIVE_LN  (VECTOR_ACTIVE_EL        ), //Just a placeholder, should be a dynamic parameter configured at runtime
        .DATA_WIDTH        (DATA_WIDTH              ),
        .MEM_MICROOP_WIDTH (VECTOR_MEM_MICROOP_WIDTH),
        .MICROOP_WIDTH     (VECTOR_MICROOP_WIDTH    ),
        .VECTOR_TICKET_BITS(VECTOR_TICKET_BITS      ),
        .VECTOR_REQ_WIDTH  (VECTOR_MAX_REQ_WIDTH    ),
        .FWD_POINT_A       (VECTOR_FWD_POINT_A      ),
        .FWD_POINT_B       (VECTOR_FWD_POINT_B      ),
        .USE_HW_UNROLL     (USE_HW_UNROLL           )
) vector_proc (          
        .clk                (clk),
        .rst_n              (rst_n),
        .valid_in           (valid_o_decoder),
        .vector_idle_o      (vector_idle_o),
        .instr_in           (decoded_instruction),
       
        .pop                (pop),
        //Cache Request Interface
        .mem_req_valid_o    (mem_req_valid),
        .mem_req_o          (mem_req),
        .cache_ready_i      (cache_vector_ready),
        //Cache Response Interface
        .mem_resp_valid_i   (mem_resp_valid),
        .mem_resp_i         (mem_resp)
);
//////////////////////////////////////////////////
//                Caches' Subsection            //
//////////////////////////////////////////////////

data_cache #(
    .DATA_WIDTH          (DATA_WIDTH              ),
    .ADDR_BITS           (ADDR_BITS               ),
    .R_WIDTH             (R_WIDTH                 ),
    .MICROOP             (MICROOP_W               ),
    .ROB_TICKET          (ROB_TICKET_W            ),
    .ENTRIES             (DC_ENTRIES              ),
    .BLOCK_WIDTH         (DC_DW                   ),
    .BUFFER_SIZES        (4                       ),
    .ASSOCIATIVITY       (DC_ASC                  ),
    .VECTOR_ENABLED      (VECTOR_ENABLED          ),
    .VECTOR_MICROOP_WIDTH(VECTOR_MEM_MICROOP_WIDTH),
    .VECTOR_REQ_WIDTH    (VECTOR_MAX_REQ_WIDTH    ),
    .VECTOR_LANES        (VECTOR_LANES            )
) data_cache (
    .clk                 (clk                   ),
    .rst_n               (rst_n                 ),
    .output_used         (                      ),
    //Load Input Port
    .load_valid          (1'b0                  ),
    .load_address        (                      ),
    .load_dest           (                      ),
    .load_microop        (                      ),
    .load_ticket         (                      ),
    //Store Input Port
    .store_valid         (1'b0                  ),
    .store_address       (                      ),
    .store_data          (                      ),
    .store_microop       (                      ),
    //Vector Req Input Port
    .mem_req_valid_i     (mem_req_valid         ),
    .mem_req_i           (mem_req               ),
    .cache_vector_ready_o(cache_vector_ready    ),
    //Request Write Port to L2
    .write_l2_valid      (req_wr_l2_dcache_valid),
    .write_l2_addr       (req_wr_l2_dcache_addr ),
    .write_l2_data       (req_wr_l2_dcache_data ),
    //Request Read Port to L2
    .request_l2_valid    (req_rd_l2_dcache_valid),
    .request_l2_addr     (req_rd_l2_dcache_addr ),
    // Update Port from L2
    .update_l2_valid     (resp_l2_dcache_valid  ),
    .update_l2_addr      (resp_l2_dcache_addr   ),
    .update_l2_data      (resp_l2_dcache_data   ),
    //Output Port
    .cache_will_block    (                      ),
    .cache_blocked       (                      ),
    .served_output       (                      ),
    //Vector Output Port
    .vector_resp_valid_o (mem_resp_valid        ),
    .vector_resp         (mem_resp              )
);
//////////////////////////////////////////////////
//               Main Memory Module             //
//////////////////////////////////////////////////
main_memory #(
    .L2_BLOCK_DW    (L2_DW       ),
    .L2_ENTRIES     (L2_ENTRIES  ),
    .ADDRESS_BITS   (ADDR_BITS   ),
    .ICACHE_BLOCK_DW(IC_DW       ),
    .DCACHE_BLOCK_DW(DC_DW       ),
    .REALISTIC      (REALISTIC   ),
    .DELAY_CYCLES   (DELAY_CYCLES),
    .FILE_NAME      ("../vector_simulator/decoder_results/init_main_memory.txt")
) main_memory (
    .clk              (clk                   ),
    .rst_n            (rst_n                 ),
    //Read Request Input from ICache
    .icache_valid_i   (1'b0                  ),
    .icache_address_i (                      ),
    //Output to ICache
    .icache_valid_o   (                      ),
    .icache_data_o    (                      ),
    //Read Request Input from DCache
    .dcache_valid_i   (req_rd_l2_dcache_valid),
    .dcache_address_i (req_rd_l2_dcache_addr ),
    //Output to DCache
    .dcache_valid_o   (resp_l2_dcache_valid  ),
    .dcache_address_o (resp_l2_dcache_addr   ),
    .dcache_data_o    (resp_l2_dcache_data   ),
    //Write Request Input from DCache
    .dcache_valid_wr  (req_wr_l2_dcache_valid),
    .dcache_address_wr(req_wr_l2_dcache_addr ),
    .dcache_data_wr   (req_wr_l2_dcache_data )
);


endmodule