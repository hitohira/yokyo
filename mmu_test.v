module mmu_test(
	input wire clk,
	input wire rstn,
		// mmu
	output reg [31:0] c_axi_araddr,
	input wire c_axi_arready,
	output reg c_axi_arvalid,
				
	output reg [31:0] c_axi_awaddr,
	input wire c_axi_awready,
	output reg c_axi_awvalid,
									
	output reg c_axi_bready,
	input wire [1:0] c_axi_bresp,
	input wire c_axi_bvalid,
	
	input wire [31:0] c_axi_rdata,
	output reg c_axi_rready,
	input wire [1:0] c_axi_rresp,
	input wire c_axi_rvalid,
	
	output reg [31:0] c_axi_wdata,
	input wire c_axi_wready,
	output reg [3:0] c_axi_wstrb,
	output reg c_axi_wvalid,
																	
	output reg [1:0] cpu_mode,
	output reg [31:0] satp,
	output reg is_instr,
		
	input wire throw_exception,
	input wire [2:0] exception_vec
	);


	reg [5:0] state;
	reg is_write;

	always @(posedge clk) begin
		if(~rstn) begin
			c_axi_araddr <= 0;
			c_axi_arvalid <= 0;
			c_axi_awaddr <= 0;
			c_axi_awvalid <= 0;
			c_axi_bready <= 0;
			c_axi_rready <= 0;
			c_axi_wdata <= 0;
			c_axi_wstrb <= 0;
			c_axi_wvalid <= 0;
			cpu_mode <= 3;
			satp <= {1'b1,31'b0};
			is_instr <= 1;

			state <= 0;
		end else if(state == 0) begin // set
				c_axi_araddr <= 32'h00006020; 
				c_axi_awaddr <= 32'h00006020;
				is_write <= 1;


				c_axi_wdata <= 32'h11111111;
				c_axi_wstrb <= 4'b0011;
				state <= 1;
		end else if (state == 1) begin
			if(is_write) begin
				c_axi_awvalid <= 1;
				c_axi_wvalid <= 1;
				state <= 2;
			end else begin 
				c_axi_arvalid <= 1;
				state <= 4;
			end
		end else if (state == 2) begin // write
			if(c_axi_awready) begin
				c_axi_awvalid <= 0;
			end
			if(c_axi_wready) begin
				c_axi_wvalid <= 0;
			end
			if(!c_axi_wvalid && !c_axi_awvalid) begin
				c_axi_bready <= 1;
				state <= 3;
			end
		end else if (state == 3) begin
			if(c_axi_bvalid) begin
				c_axi_bready <= 0;
				// loop //////////
				is_write = 0;
				state <= 1;
			end
		end else if (state == 4) begin // read
			if(c_axi_arready) begin
				c_axi_arvalid <= 0;
				c_axi_rready <= 1;
				state <= 5;
			end
		end if (state == 5) begin
			if(c_axi_rvalid) begin
				// loop ////////////
			end
		end
	end // always
endmodule
