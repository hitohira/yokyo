module BramController (
	input wire clk,
	input wire rstn,

	//axi
	input wire [31:0] s_axi_araddr,
	output reg s_axi_arready,
	input wire s_axi_arvalid,

	input wire [31:0] s_axi_awaddr,
	output reg s_axi_awready,
	input wire s_axi_awvalid,

	input wire s_axi_bready,
	output reg [1:0] s_axi_bresp,
	output reg s_axi_bvalid,

	output reg [31:0] s_axi_rdata,
	input wire s_axi_rready,
	output reg [1:0] s_axi_rresp,
	output reg s_axi_rvalid,

	input wire [31:0] s_axi_wdata,
	output reg s_axi_wready,
	input wire [3:0] s_axi_wstrb,
	input wire s_axi_wvalid,
	
	//bram
	output reg [31:0] bram_addr,
	output reg [31:0] bram_din,
	input wire  [31:0] bram_dout,
	output reg bram_en,
	output reg [3:0] bram_we
	);

	//assume addr 4byte aligned
	// memory optional output reg used !!!

	reg [3:0] state;

	always @(posedge clk) begin
		if(~rstn) begin
			s_axi_arready <= 0;
			s_axi_awready <= 0;
			s_axi_bresp <= 0;
			s_axi_bvalid <= 0;
			s_axi_rdata <= 0;
			s_axi_rresp <= 0;
			s_axi_rvalid <= 0;
			s_axi_wready <= 0;
			
			bram_addr <= 0;
			bram_din <= 0;
			bram_en <= 1;
			bram_we <= 0;

			state <= 0;
		end else if (state == 0) begin
			s_axi_arready <= 1;
			state <= 1;
		end else if (state == 1) begin
			s_axi_arready <= 0;
			if (s_axi_arvalid) begin
				bram_addr <= s_axi_araddr;
				bram_we <= 0;
				state <= 3;
			end else begin
				s_axi_awready <= 1;
				state <= 2;
			end
		end else if (state == 2) begin
			s_axi_awready <= 0;
			if(s_axi_awvalid) begin
				bram_addr <= s_axi_awaddr;
				s_axi_wready <= 1;
				state <= 7;
			end else begin
				s_axi_arready <= 1;
				state <= 1;
			end
		end else if (state == 3) begin // read
			state <= 4;
		end else if (state == 4) begin
			state <= 5;
		end else if (state == 5) begin
			s_axi_rdata <= bram_dout;	
			s_axi_rresp <= 2'b00; // not used
			s_axi_rvalid <= 1;
			state <= 6;
		end else if (state == 6) begin
			if(s_axi_rready) begin
				s_axi_rvalid <= 0;
				state <= 0;
			end
		end else if(state == 7) begin // write
			if(s_axi_wvalid) begin
				s_axi_wready <= 0;
				bram_din <= s_axi_wdata;
				bram_we <= s_axi_wstrb;
				state <= 8;
			end
		end else if(state == 8) begin
			bram_we <= 0;
			s_axi_bresp <= 2'b00; // not used
			s_axi_bvalid <= 1;
			state <= 9;
		end else if(state == 9) begin
			if(s_axi_bready) begin
				s_axi_bvalid <= 0;
				state <= 0;
			end
		end
	end
endmodule
