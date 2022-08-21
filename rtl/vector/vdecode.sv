/*
* @info Vector Prefetch Unit
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
*/
`ifdef MODEL_TECH
    `include "vstructs.sv"
`endif
module vdecode_mod #(
    parameter int DEPTH            = 4 ,
    parameter int DATA_WIDTH       = 32,
    parameter int VECTOR_REGISTERS = 32,
    parameter int VECTOR_LANES     = 8 ,
    parameter int MICROOP_WIDTH    = 32,
	parameter int DATA_FROM_SCALAR = 96
) (
	input  logic						clk					,
	input  logic						rst_n				,
	input  logic						ready_i				,
	output logic						ready_o				,
	input  logic						valid_i				,
	output logic						valid_o				,
	input  logic [DATA_FROM_SCALAR-1:0] vector_instructions , 
	output to_vector 					instr_out

);
 

logic [$clog2(32*DUMMY_VECTOR_LANES):0] 	maxvl			;
logic [$clog2(32*DUMMY_VECTOR_LANES):0] 	vl   			;
logic [DATA_FROM_SCALAR-1:0] 				output_inst	    ; 
logic [31:0] 							 	avl  			; 
logic [31:0] 							 	last_vset		;
logic [10:0]								bubble_cycles   ;
logic [8:0 ] 							 	choice			;
logic [7:0 ] 		                        lmul            ;
logic [5:0 ]								total_regs      ;
logic [4:0 ] 							 	choice_mem_op	;
logic [4:0 ]								initial_lmul    ;
logic [2:0 ] 								sew				;

logic 										vsetflag		;
logic										no_reconfigure  ;

typedef enum logic [1:0]				   {
											
                                            IDLE   =2'b00,
											BUBBLE =2'b01,
											PASS   =2'b10} fsm_state;
 
fsm_state state;

always_ff @( posedge clk or negedge rst_n ) begin
	
	if( ~rst_n ) begin
		output_inst    	<= 0    ;
		state         	<= IDLE ;
		bubble_cycles 	<= 0    ;
		no_reconfigure  <= 0    ;
		last_vset		<= 0	;
	end
	else begin
		
		case(state) 
		IDLE: begin

			if (valid_i) begin
					output_inst <= vector_instructions ;
					if((vector_instructions[70:64] == 87 ) & ( vector_instructions[78:76] == 7 ) ) begin
						state <=	BUBBLE ;
						if(last_vset!=vector_instructions[95:64])
						begin
							last_vset <= vector_instructions[95:64] ;
							no_reconfigure <= 0;
						end
					end
					else
						state <= 	PASS  ; 			
			end
		end
		BUBBLE: begin
			
			bubble_cycles <= bubble_cycles + 1 ;			
			if( bubble_cycles >= 4 ) begin			
				bubble_cycles <= 0 ;
				if (no_reconfigure)
					state <= IDLE ;
				else 
					state <= PASS ;

			end
		end
		PASS: begin
			if(ready_i) begin
				//pass_cycles = pass_cycles + 1 ;
				if(~no_reconfigure)
					no_reconfigure  <=  1  ;	
				state        <= IDLE	   ;
			end
		end

		endcase
	end	

end

// Ready/Valid Out
always_comb begin
	if (state==IDLE) begin
		ready_o = 1;
	end
	else
		ready_o = 0      ;

	if(state==PASS) begin
		valid_o = 1      ;
	end
	else
		valid_o = 0		 ;

end

// Cases select signals for funct6,funct3 and opcode
assign choice 		  = {output_inst[78:76],output_inst[95:90]};
assign choice_mem_op  = {output_inst[91:90],output_inst[78:76]};

// Pass microop and fu to output
always_comb begin
	
	if( output_inst[70:64]==7'b1010111 & output_inst[78:76]==3'b111 )
		vsetflag = 1;
	else
		vsetflag = 0;

	if(state==IDLE) begin
		instr_out.microop = 7'b1111111;
		instr_out.fu	     = 2'b11	 ;
	end
	else begin
		case(output_inst[70:64])
		7'b1010111:begin
			casez(choice)
			//vsets
			9'b111??????:begin
				if(~no_reconfigure) 
					instr_out.microop     = 7'b0000000 ;	 
				else 
					instr_out.microop     = 7'b1111111 ; 

			end
			//vadd(OPIVV)
			9'b000000000: begin
			
				instr_out.microop = 7'b0000001;
				
			end
			//vadd(OPIVI)
			9'b011000000: begin
				
				instr_out.microop = 7'b0000010;
				
			end            
			//vand(OPIVV)
			9'b000001001: begin
				
					instr_out.microop = 7'b0010110;
				
			end
			//vand(OPIVI)
			9'b011001001: begin
				
					instr_out.microop = 7'b0010111;
				
			end
			//vor(OPIVV)
			9'b000001010: begin
				
					instr_out.microop = 7'b0011000;
				
			end
			//vor(OPIVI)
			9'b011001010: begin
				
					instr_out.microop = 7'b0011001;
				
			end
			//vxor(OPIVV)
			9'b000001011: begin
				
					instr_out.microop = 7'b0011010;
				
			end
			//vxor(OPIVI)
			9'b011001011: begin
				
					instr_out.microop = 7'b0011011;
				
			end
			//vmul(OPMVV)
			9'b010100101: begin
				
					instr_out.microop = 7'b0000111;
				
			end
			//vmulh(OPMVV)
			9'b010100111: begin
				
					instr_out.microop = 7'b0001000;
				
			end
			//vmulhu(OPMVV)
			9'b010100100: begin
				
					instr_out.microop = 7'b0001010;
				
			end
			//vmulhsu(OPMVV)
			9'b010100110: begin
				
					instr_out.microop = 7'b0001001;
				
			end
			//vsll(OPIVV)
			9'b000100101: begin
				
					instr_out.microop = 7'b0010000;
				
			end
			//vsll(OPIVI)
			9'b011100101: begin
				
					instr_out.microop = 7'b0010001;
				
			end
			//vsrl(OPIVV)
			9'b000101000: begin
				
					instr_out.microop = 7'b0010100;
				
			end
			//vsrl(OPIVI)
			9'b011101000: begin
				
					instr_out.microop = 7'b0010101;
				
			end
			//vsra(OPIVV)
			9'b000101001: begin
				
					instr_out.microop = 7'b0010010;
				
			end
			//vsra(OPIVI)
			9'b011101001: begin
				
					instr_out.microop = 7'b0010011;
				
			end
			//vmseq(OPIVV) 
			9'b000011000: begin
				
					instr_out.microop = 7'b0011100;
				
			end
			//vmslt(OPIVV)
			9'b000011011: begin
				
					instr_out.microop = 7'b0011101;
				
			end
			//vmsltu(OPIVV)
			9'b000011010: begin
				
					instr_out.microop = 7'b0011110;
				
			end
			//vsub(OPIVV)
			9'b000000010: begin
				
					instr_out.microop = 7'b0000101;
				
			end
			//vdiv(OPMVV)
			9'b010100001: begin
				
					instr_out.microop = 7'b0001100;
				
			end
			//vdivu(OPVV)
			9'b010100000: begin
				
					instr_out.microop = 7'b0001101;
				
			end
			//vrem(OPMVV)
			9'b010100011: begin
				
					instr_out.microop = 7'b0001110;
				
			end
			//vremu(OPMVV)
			9'b010100010: begin
				
					instr_out.microop = 7'b0001111;
				
			end
			//vredadd(OPMVV)
			9'b010000000: begin
				
					instr_out.microop = 7'b1000000;
				
			end
			//vredand(OPMVV)
			9'b010000001: begin
				
					instr_out.microop = 7'b1000001;
				
			end
			//vredor(OPMVV)
			9'b010000010: begin
				
					instr_out.microop = 7'b1000010;
				
			end
			//vredxor(OPMVV)
			9'b010000011: begin
				
					instr_out.microop = 7'b1000011;
				
			end
			default:begin
					instr_out.microop = 7'b1111111;
			end
			endcase
			
			if(vsetflag) begin
				if(~no_reconfigure)
					instr_out.fu             = 2'b00  ;
				else
					instr_out.fu             = 2'b11  ;
			end
			else 
					instr_out.fu             = 2'b10  ;		

		end
		
		7'b0000111:begin
			case(choice_mem_op)
				// vle8
				5'b00000:begin
					instr_out.microop = 7'b1000100;
				end
				//vle16
				5'b00101:begin
					instr_out.microop = 7'b1001000;
				end
				//vle32
				5'b00110:begin
					instr_out.microop = 7'b1000000;
				end
				//vle64
				5'b00111:begin
					instr_out.microop = 7'b1000000;
				end
				
				// vloxei8
				5'b01000:begin
					instr_out.microop = 7'b1110100;
				end
				// vloxei16
				5'b01101:begin
					instr_out.microop = 7'b1001000;
				end
				// vloxei32
				5'b01110:begin
					instr_out.microop = 7'b1110000;
				end
				// vloxei64
				5'b01111:begin
					instr_out.microop = 7'b1110000;
				end
				
				// vlse8
				5'b10000:begin
					instr_out.microop = 7'b1100100;
				end
				// vlse16
				5'b10101:begin
					//instr_out.microop = 7'b1001000;
				end
				// vlse32
				5'b10110:begin
					instr_out.microop = 7'b1100000;
				end
				// vlse64
				5'b10111:begin
					instr_out.microop = 7'b1100000;
				end
				default:begin
					instr_out.microop = 7'b1111111;
				end
			endcase
			
			instr_out.fu             = 2'b00  ;

			end
			7'b0100111:begin
			case(choice_mem_op)
				// vse8
				5'b00000:begin
					instr_out.microop = 7'b0000100;
				end
				//vse16
				5'b00101:begin
					instr_out.microop = 7'b0001000;
				end
				//vse32
				5'b00110:begin
					instr_out.microop = 7'b0000000;
				end
				//vse64
				5'b00111:begin
					instr_out.microop = 7'b0000000;
				end
				
				// vsoxei8
				5'b01000:begin
					instr_out.microop = 7'b0110100;
				end
				// vsoxei16
				5'b01101:begin
					instr_out.microop = 7'b0111000;
				end
				// vsoxei32
				5'b01110:begin
					instr_out.microop = 7'b0110000;
				end
				// vsoxei64
				5'b01111:begin
					instr_out.microop = 7'b0110000;
				end
				
				// vsse8
				5'b10000:begin
					instr_out.microop = 7'b0100100;
				end
				// vsse16
				5'b10101:begin
					instr_out.microop = 7'b0101000;
				end
				// vsse32
				5'b10110:begin
					instr_out.microop = 7'b0100000;
				end
				// vsse64
				5'b10111:begin
					instr_out.microop = 7'b0100000;
				end
				default:begin
					instr_out.microop = 7'b1111000;
				end
				
			endcase
			
			instr_out.fu             = 2'b00  ;
			
			end
			default:begin
				instr_out.microop = 7'b0000001;
				instr_out.fu      = 2'b10  ;
			end
		endcase

	end
	
end


always_ff @( posedge clk or negedge rst_n ) begin
	
	if( ~rst_n ) begin
		initial_lmul  <= 0 ;
		sew   		  <= 0 ;
	end
	if(vsetflag==1)begin	
		// Select lmul	
		case(output_inst[86:84])
			//m1
			3'b000:begin
				initial_lmul <= 1  ;
			end
			//m2
			3'b001:begin
				initial_lmul <= 2  ;
			end
			//m4
			3'b010:begin
				initial_lmul <= 4  ;
			end
			//m8
			3'b011:begin
				initial_lmul <= 8  ;
			end
			default:begin
				initial_lmul <= 0  ;
			end
		endcase

		// Select sew
		case(output_inst[89:87])
			//e8
			3'b000: begin
				sew = 4 ;
			end
			//e16
			3'b001: begin
				sew = 2 ;
			end
			//e32
			3'b010: begin
				sew = 1 ;
			end
			//e64
			3'b011: begin
				sew = 1 ;
			end
		endcase
	end
end

assign vl    = (avl >= maxvl) ? maxvl : avl[$clog2(32*DUMMY_VECTOR_LANES):0]  ;
assign lmul  = initial_lmul * sew  											  ;
assign maxvl = VECTOR_LANES * lmul 											  ;

// Pass the other decoded fields to output
always_comb begin
	
	if (vsetflag == 1) begin


	//	maxvl 					= VECTOR_LANES * lmul  							         	     ; 
	//	vl    					= (avl >= maxvl) ? maxvl : avl[$clog2(32*DUMMY_VECTOR_LANES):0]  ;

		avl   					= output_inst[31:0] ;
		
		instr_out.dst  		    = 0    ;
		instr_out.src1          = 0    ;
		instr_out.src2          = 0    ;
		instr_out.use_mask      = 1'b0 ;
		instr_out.immediate 	= 0    ;
		instr_out.reconfigure   = 1'b1 ;
		instr_out.valid 		= (state==BUBBLE) ? 1'b0 : ~no_reconfigure ;
		instr_out.data1         = 0    ;
		instr_out.data2         = 0    ;
		instr_out.maxvl			= ( (state==BUBBLE) & no_reconfigure ) ? 0 : maxvl;
		instr_out.vl			= ( (state==BUBBLE) & no_reconfigure ) ? 0 : vl   ;	
	end
	else begin
		if(state==IDLE) begin
			instr_out.reconfigure   = 1'b1 ;
			instr_out.dst  		    = 0    ;
			instr_out.src1          = 0    ;
			instr_out.src2          = 0    ;
			instr_out.use_mask      = 1'b0 ;
			instr_out.immediate 	= 0    ;

			instr_out.valid 		= 0    ;
			instr_out.data1         = 0    ;
			instr_out.data2         = 0    ;				 
			instr_out.maxvl			= 0    ;
			instr_out.vl			= 0    ;
		end
		else begin
			instr_out.reconfigure   = 1'b0      					;
			instr_out.dst  		    = output_inst[75:71]  			;
			
			// Arithmetic and Vset instructions.
			if( output_inst[70:64] == 7'b1010111) begin
				instr_out.src1      = output_inst[83:79]  			;
				instr_out.src2      = output_inst[88:84]  			;
				instr_out.immediate = output_inst[83:79]  			;
			
			// Memory operations need the source operands to be flipped, and immediate to be 0.
			end else begin
				instr_out.src2      = output_inst[83:79]  			;
				instr_out.src1      = output_inst[88:84]  			;
				instr_out.immediate = 5'b0				  			;
			end

			instr_out.use_mask      = output_inst[89] 	  			;	
			instr_out.valid 		= (state==IDLE) ? 1'b0 : 1'b1   ;
			instr_out.data1         = output_inst[31:0]   			;
			instr_out.data2         = output_inst[63:32]  			;				 
			instr_out.maxvl			= maxvl 			  			;
			instr_out.vl			= vl    			  			;
			end

	end
	
end
	


endmodule