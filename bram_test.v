module BramTest(
	input wire clk,
	input wire rstn,

	output reg [31:0] s_axi_araddr,
	input wire s_axi_arready,
	output reg s_axi_arvalid,

	output reg [31:0] s_axi_awaddr,
	input wire s_axi_awready,
	output reg s_axi_awvalid,
	
	output reg s_axi_bready,
	input wire [1:0] s_axi_bresp,
	input wire s_axi_bvalid,
								
	input wire [31:0] s_axi_rdata,
	output reg s_axi_rready,
	input wire [1:0] s_axi_rresp,
	input wire s_axi_rvalid,
									
	output reg [31:0] s_axi_wdata,
	input wire s_axi_wready,
	output reg [3:0] s_axi_wstrb,
	output reg s_axi_wvalid
	);

	reg [4:0] state;
	
	reg [31:0] addr;
	reg [31:0] data;
	reg [31:0] wd;

	always @(posedge clk) begin
		if(~rstn) begin
			state <= 0;
			data <= 0;
			addr <= 0;
			wd <= 0;
			
			s_axi_araddr <= 0;
			s_axi_arvalid <= 0;
			s_axi_awaddr <= 0;
			s_axi_awvalid <= 0;
			s_axi_bready <= 0;
			s_axi_rready <= 0;
			s_axi_wdata <= 0;
			s_axi_wstrb <= 0;
			s_axi_wvalid <= 0;
		end else if(state == 0) begin
			s_axi_awaddr <= 4;
			s_axi_awvalid <= 1;
			state <= 1;
		end else if(state == 1) begin
			if(s_axi_awready) begin
				s_axi_awvalid <= 0;
				s_axi_wvalid <= 1;
				s_axi_wdata <= 15;
				s_axi_wstrb <= 4'b1111;
				state <= 2;
			end	
		end else if(state == 2) begin
			if(s_axi_wready) begin
				s_axi_wvalid <= 0;
				s_axi_bready <= 1;
				state <= 3;
			end
		end else if(state == 3) begin
			if(s_axi_bvalid) begin
				s_axi_bready <= 0;
				state <= 4;
			end
		end else if(state == 4) begin
			s_axi_araddr <= 0;
			s_axi_arvalid <= 1;
			state <= 5;
		end else if(state == 5) begin
			if(s_axi_arready) begin
				s_axi_arvalid <= 0;
				s_axi_rready <= 1;
				state <= 6;
			end
		end else if(state == 6) begin
			if(s_axi_rvalid) begin
				data <= s_axi_rdata;
				addr <= addr + 4;
				state <= 0;
			end
		end
	end

endmodule	
