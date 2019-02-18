module button_ctrl(
	input wire clk,
	input wire rstn,

	input wire button,

	output reg is_soft_intr
	);

	reg [63:0] shifter;
	reg is_pushed;
	reg was_pushed;

	always @(posedge clk) begin
		if(~rstn) begin
			is_soft_intr <= 0;
			is_pushed <= 0;
			was_pushed <= 0;
			shifter <= 0;
		end else begin
			shifter[62:0] <= shifter >> 1;
			shifter[63] <= button;

			is_pushed <= (&(shifter[31:0]));
			was_pushed <= is_pushed;

			is_soft_intr <= is_pushed & ~was_pushed;

		end
	end


endmodule
