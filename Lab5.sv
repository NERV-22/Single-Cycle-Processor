	
// DReg
module DReg #(parameter N = 8) (input clk, reset, input [N-1:0] D, output logic [N-1:0] Q);
always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		Q <= {N{1'b0}};
	end
	else begin
		Q <= D;
	end
end
endmodule

// Mux 4 to 1
module Mux4to1 #(parameter N = 8) (input [N-1:0] A, B, C, D, input [1:0] S, output logic [N-1:0] Z);
always_comb begin
	Z = {N{1'b0}};
	case (S)
		2'b00: Z = A;
		2'b01: Z = B;
		2'b10: Z = C;
		2'b11: Z = D;
		default: Z = {N{1'b0}};
	endcase
end
endmodule

//16 to 1 Mux from 4 to 1
module Mux16to1 #(parameter N = 8) (input [N-1:0] i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, input [3:0] S, output logic [N-1:0] Z);
logic [N-1:0] M0, M1, M2, M3;
// selecting one of each group cased on S
Mux4to1 #(N) Mux0 (i0, i1, i2, i3, S[1:0], M0);
Mux4to1 #(N) Mux1 (i4, i5, i6, i7, S[1:0], M1);
Mux4to1 #(N) Mux2 (i8, i9, i10, i11, S[1:0], M2);
Mux4to1 #(N) Mux3 (i12, i13, i14, i15, S[1:0], M3);
// select one of 4 results based on S
Mux4to1 #(N) Mux4 (M0, M1, M2, M3, S[3:2], Z);
endmodule

// RegFile
module RegFile (input clk, reset, input [3:0] RA, RB, RD, OPCODE, input [1:0] current_state, input [7:0] RF_data_in, output logic [7:0] RF_data_out0, RF_data_out1);
// from manual took out one and One since it is not used at all
logic [4:0] i;
localparam [7:0] Zero = 8'd0;
localparam zero = 1'b0;
logic [7:0] RF [15:0];
parameter IF = 2'b00;
parameter FD = 2'b01;
parameter EX = 2'b10;
parameter RWB = 2'b11;
always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		RF_data_out0 <= Zero;
		RF_data_out1 <= Zero;
		// hardcoded no loop used
		RF[0] <= Zero; RF[1] <= Zero; RF[2] <= Zero; RF[3] <= Zero;
		RF[4] <= Zero; RF[5] <= Zero; RF[6] <= Zero; RF[7] <= Zero;
		RF[8] <= Zero; RF[9] <= Zero; RF[10] <= Zero; RF[11] <= Zero;
		RF[12] <= Zero; RF[13] <= Zero; RF[14] <= Zero; RF[15] <= Zero;
		end else begin
		RF_data_out0 <= RF[RA];
		RF_data_out1 <= RF[RB];
		// write back only in RWB and not for CMPJ JMP or HLT
		if ((current_state == RWB) && ~((OPCODE == 4'd13) || (OPCODE == 4'd14) || (OPCODE == 4'd15))) begin
			RF[RD] <= RF_data_in;
		end
	end
end
endmodule

// ALU
module ALU (input [7:0] A, B, input [3:0] OPCODE, output logic [7:0] ALU_out, output logic Cout, OF);
logic [8:0] sum, sub;
logic [7:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15;
assign sum = {1'b0, A} + {1'b0, B};
assign sub = {1'b0, A} + {1'b0, (~B)} + 9'd1;
assign a1 = 8'd0; // LDI
assign a2 = sum[7:0]; // ADD
assign a3 = sub[7:0]; // SUB
assign a4 = sum[7:0]; // ADDI
assign a5 = A*B; // MUL
assign a6 = (B != 0) ? A/B : 8'd0; // DIV
assign a7 = B - 1; // DEC
assign a8 = B + 1; // INC
assign a9 = ~(A | B); // NOR
assign a10 = ~(A & B); // NAND
assign a11 = A ^ B; // XOR
assign a12 = ~B; // COMP
assign a13 = 8'd0; // CCMPJ
assign a14 = 8'd0; // JMP
assign a15 = 8'd0; // HLT
Mux16to1 #(8) M (8'd0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, OPCODE, ALU_out);
always_comb begin
	Cout = 1'b0;
	OF = 1'b0;
	if (OPCODE == 4'b0010) begin
		Cout = sum[8];
		OF = (~(A[7]^B[7])) & (A[7]^ALU_out[7]);
	end else if (OPCODE == 4'b0011) begin
		Cout = sub[8];
		OF   = (A[7]^B[7]) & (A[7]^ALU_out[7]);
	end else if (OPCODE == 4'b0100) begin
		Cout = sum[8];
		OF = 1'd0;
	end else if (OPCODE == 4'b0111) begin
		Cout = sub[8];
		OF = 1'd0;
	end
end
endmodule

// Lab 5 code
module Lab5 (input clk, reset, output logic [3:0] OPCODE, output logic [1:0] State, output logic [7:0] PC, ALU_out, W_reg, output logic Cout, OF);
localparam [1:0] IF = 2'b00, FD = 2'b01, EX = 2'b10, RWB = 2'b11;
logic [15:0] IR;
logic [7:0] PC_reg, NextPC, A, B, ALU_A, ALU_B, NextW_reg;
logic [3:0] OPCODE_int, RA, RB, RD;
logic [1:0] NextState;
DReg #(8) P (clk, reset, NextPC, PC_reg);
assign PC = PC_reg;
Rom Inst (PC_reg, IR);
assign OPCODE_int = IR[15:12];
assign RA = IR[11:8];
assign RB = IR[7:4];
assign RD = IR[3:0];
assign OPCODE = OPCODE_int;
DReg #(2) SR (clk, reset, NextState, State);
RegFile RF (clk, reset, RA, RB, RD, OPCODE_int, State, W_reg, A, B);
always_comb begin
	ALU_A = A;
	ALU_B = B;
	// for LDI, JMP, CMPJ, HLT
	if (OPCODE_int == 4'b0001 || OPCODE_int == 4'b1101 || OPCODE_int == 4'b1110 || OPCODE_int == 4'b1111) begin
		ALU_A = 8'd0;
		ALU_B = 8'd0;
	// for ADI
	end else if (OPCODE_int == 4'b0100) begin
		ALU_A = A;
		ALU_B = {4'b0000, RB};
	// for DEC, INC, COMP
	end else if (OPCODE_int == 4'b0111 || OPCODE_int == 4'b1000 || OPCODE_int == 4'b1100) begin
		ALU_A = 8'd0;
		ALU_B = B;
	end
end
ALU A1 (ALU_A, ALU_B, OPCODE_int, ALU_out, Cout, OF);
always_comb begin
	NextW_reg = W_reg;
	if (State == EX) begin
		case(OPCODE_int)
		4'b0001: NextW_reg = {RA, RB};
		4'b1110: NextW_reg = {RA, RB};
		4'b1101: NextW_reg = W_reg;
		4'b1111: NextW_reg = W_reg;
		default: NextW_reg = ALU_out;
		endcase
	end
end
DReg #(8) WR (clk, reset, NextW_reg, W_reg);
always_comb begin
	NextState = IF;
	case (State)
		IF: NextState = FD;
		FD: NextState = EX;
		EX: NextState = RWB;
		RWB: NextState = IF;
	endcase
	NextPC = PC_reg;
	if (State == RWB) begin
		if (OPCODE_int == 4'b1101) begin
			NextPC = (A >= B) ? (PC_reg + {4'b0000, RD}) : (PC_reg + 8'd1);
		end else if (OPCODE_int == 4'b1110) begin
			NextPC = W_reg;
		end else if (OPCODE_int != 4'b1111) begin
			NextPC = PC_reg + 8'd1;
		end
	end
end
endmodule

`timescale 1ns/1ps
module Lab5_TB;
logic clk, reset, Cout, OF;
logic [3:0] OPCODE;
logic [1:0] State;
logic [7:0] PC, ALU_out, W_reg;
Lab5 L (clk, reset, OPCODE, State, PC, ALU_out, W_reg, Cout, OF);
integer logfile;
always #5 clk = ~clk;
initial begin
	clk = 1'b0;
	reset = 1'b1;
	logfile = $fopen("Lab5.csv", "w");
	$fwrite(logfile, "PC, IR, OPCODE, RA, RB, RD, W_Reg, Cout, OF\n");
	#20
	reset = 1'b0;
end
always @(posedge clk) begin
	if (!reset) begin
		if (State == 2'b10)  begin
			$fwrite(logfile,"%h, %h,%h, %h, %h, %h, %h, %b, %b\n", PC, L.IR, OPCODE, L.RA, L.RB, L.RD, W_reg, Cout, OF);
		end
		if (State == 2'b11 && OPCODE == 4'b1111) begin
			$display("HALT: PC=%h", PC);
			$fclose(logfile);
			$stop;
		end
	end
end
endmodule