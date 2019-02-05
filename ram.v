module distram(
	input wire clk,
	input wire [13:0] addr,
	input wire [12:0] din,
	output wire [12:0] dout,
	input wire we
	);
	
	localparam WORDS = 2**14;

	reg [12:0] mem [WORDS-1:0];

	assign dout <= mem[addr];

	always @(posedge clk) begin
		if(we) begin
			mem[addr] <= din;
		end
	end

	integer i;
	initial begin
		for(i=0;i<WORDS;i=i+1) begin
			mem[i] = 0;
		end
	end
endmodule
