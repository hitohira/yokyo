module distram(
	input wire clk,
	input wire [13:0] addr,
	input wire [13:0] din,
	output wire [13:0] dout,
	input wire we
	);
	
	localparam WORDS = 2**14;

	reg [13:0] mem [WORDS-1:0];

	assign dout = mem[addr];

	always @(posedge clk) begin
		if(we) begin
			mem[addr] <= din;
		end
	end

	integer i;
	initial begin
		for(i=0;i<WORDS;i=i+1) begin
			mem[i] = {2'b11,12'b0};
		end
	end
endmodule

module distram2(
	input wire clk,
	input wire [12:0] addr,
	input wire [30:0] din,
	output wire [30:0] dout,
	input wire we
	);
	
	localparam WORDS = 2**13;

	reg [30:0] mem [WORDS-1:0];

	assign dout = mem[addr];

	always @(posedge clk) begin
		if(we) begin
			mem[addr] <= din;
		end
	end

	integer i;
	initial begin
		for(i=0;i<WORDS;i=i+1) begin
			mem[i] = {2'b11,12'b0};
		end
	end
endmodule
