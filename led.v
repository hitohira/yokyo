module led_ctrl(
	input wire clk,
	input wire rstn,
	input wire [4:0] io_err,
	input wire cache_err,
	output reg  [7:0] led
	);
	
	always @(posedge clk) begin
		if(~rstn) begin
			led <= 0;
		end else begin
			led <= led | {2'b10,io_err,cache_err};
		end
	end

endmodule
