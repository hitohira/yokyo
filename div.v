
module div1 (
	input [32:0] x,
	input [31:0] d,
	output q,
	output [31:0] r
	);
	wire [33:0] sub;

	assign sub = { 1'b1,x } - { 2'b00,d };
	assign q = sub[33];
	assign r = q ? sub[31:0] : x[31:0];
endmodule

module div2 (
	input clk,
	input [31:0] ux,
	input [1:0] lx,
	input [31:0] d,
	output reg [1:0] q_,
	output reg [31:0] r_
	);
	wire tq;
	wire tq2;
	wire [31:0] tr;

	wire [1:0] q;
	wire [31:0] r;

	div1 u1 ({ux,lx[1]},d,tq,tr);
	div1 u2 ({tr,lx[0]},d,tq2,r);
	assign q = {tq,tq2};

	always @(posedge clk) begin
		q_ <= q;
		r_ <= r;
	end
endmodule

module div4 (
	input clk,
	input [31:0] ux,
	input [3:0] lx,
	input [31:0] d,
	output [3:0] q,
	output [31:0] r
	);
	wire [1:0] tq;
	wire [1:0] tq2;
	wire [31:0] tr;

	div2 u1 (clk,ux,lx[3:2],d,tq,tr);
	div2 u2 (clk,tr,lx[1:0],d,tq2,r);
	assign q = {tq,tq2};
endmodule

module div8 (
	input clk,
	input [31:0] ux,
	input [7:0] lx,
	input [31:0] d,
	output [7:0] q,
	output [31:0] r
	);
	wire [3:0] tq;
	wire [3:0] tq2;
	wire [31:0] tr;

	div4 u1 (clk,ux,lx[7:4],d,tq,tr);
	div4 u2 (clk,tr,lx[3:0],d,tq2,r);
	assign q = {tq,tq2};
endmodule

module div16 (
	input clk,
	input [31:0] ux,
	input [15:0] lx,
	input [31:0] d,
	output [15:0] q,
	output [31:0] r
	);
	wire [7:0] tq;
	wire [7:0] tq2;
	wire [31:0] tr;

	div8 u1 (clk,ux,lx[15:8],d,tq,tr);
	div8 u2 (clk,tr,lx[7:0],d,tq2,r);
	assign q = {tq,tq2};
endmodule

module div32 (
	input clk,
	input   [63:0] x,
	input   [31:0] d,
	output  [31:0] q,
	output  [31:0] r
	);
	wire [15:0] tq;
	wire [15:0] tq2;
	wire [31:0] tr;

	div16 u1(clk,x[63:32],x[31:16],d,tq,tr);
	div16 u2(clk,tr,x[15:0],d,tq2,r);
	assign q = {tq,tq2};
endmodule

