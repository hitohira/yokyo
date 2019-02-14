module IOcontroller (
	input wire clk,
	input wire rstn,

	// cpu
	output wire [7:0] io_in_data,
	(* mark_debug = "true" *) input wire io_in_rdy,
	(* mark_debug = "true" *) output reg io_in_vld,

	(* mark_debug = "true" *) input wire [7:0] io_out_data,
	(* mark_debug = "true" *) output reg io_out_rdy,
	(* mark_debug = "true" *) input wire io_out_vld,

	output reg [4:0] io_err, // { resp[1],parity,frame,overrun,lost }

	// axi4 lite
	output wire [3:0] s_axi_araddr, // out :read addr
	input wire s_axi_arready,
	output reg s_axi_arvalid,
	output wire [3:0] s_axi_awaddr, // out :write addr
	input wire s_axi_awready,
	output reg s_axi_awvalid,
	output reg s_axi_bready,				// in :is written properly ?
	input wire [1:0] s_axi_bresp,
	input wire s_axi_bvalid,
	input wire [31:0] s_axi_rdata,	// in :read data
	output reg s_axi_rready,
	input wire [1:0] s_axi_rresp,
	input wire s_axi_rvalid,
	output wire [31:0] s_axi_wdata,	// out :write data
	input wire s_axi_wready,
	output wire [3:0] s_axi_wstrb,
	output reg s_axi_wvalid
	);
	
	localparam st_check = 3'b001;
	localparam st_read  = 3'b010;
	localparam st_write = 3'b011;
	
	localparam err_lost = 5'b00001;

	// if you want to use large buffer, you should rewrite buffer using dual port memory
	localparam buf_size = 32;
	localparam buf_bit  = 5;

	(* mark_debug = "true" *)	reg [2:0] state;
	(* mark_debug = "true" *) reg [2:0] sub_state;
	reg [2:0] in_state;
	reg [2:0] out_state;
	reg [7:0] stat_reg;

	// when push to buf, hd++;; when pop from buf, tl++  tl <= x < hd is valid data
	reg [7:0] rbuf_data [buf_size-1:0];
	(* mark_debug = "true" *) reg [buf_bit-1:0] rbuf_hd;
	(* mark_debug = "true" *) reg [buf_bit-1:0] rbuf_tl;
	reg [7:0] wbuf_data [buf_size-1:0];
	(* mark_debug = "true" *) reg [buf_bit-1:0] wbuf_hd;
	(* mark_debug = "true" *) reg [buf_bit-1:0] wbuf_tl;
	wire r_uart_rdy;
	wire w_uart_rdy;
	wire r_in_rdy;
	wire w_out_rdy;

	//const
	assign s_axi_wstrb = 4'b0001;

	assign io_in_data = rbuf_data[rbuf_tl];

	assign s_axi_araddr = state == st_read  ? 4'h0 :
												state == st_write ? 4'h4 :
												state == st_check ? 4'h8 : 4'h0;
	assign s_axi_awaddr = s_axi_araddr;
	assign s_axi_wdata = { 24'b0 , wbuf_data[wbuf_tl] };

	assign r_uart_rdy = (rbuf_hd + 5'b00001) != rbuf_tl;
	assign w_uart_rdy = wbuf_hd != wbuf_tl;
	assign r_in_rdy = rbuf_hd != rbuf_tl;
	assign w_out_rdy = (wbuf_hd + 5'b00001) != wbuf_tl;

	always @(posedge clk) begin
		if(~rstn) begin
			io_in_vld <= 0;
			io_out_rdy <= 0;
			io_err <= 0;
			s_axi_arvalid <= 0;
			s_axi_awvalid <= 0;
			s_axi_bready <= 0;
			s_axi_rready <= 0;
			s_axi_wvalid <= 0;
			state <= st_check;
			sub_state <= 0;
			in_state <= 0;
			out_state <= 0;
	//		rbuf_hd <= 0;
			rbuf_data[0] <= 8'h37;
			rbuf_data[1] <= 8'h0a;
			rbuf_data[2] <= 8'h33;
			rbuf_data[3] <= 8'h0a;
			rbuf_hd <= 4;
			rbuf_tl <= 0;
			wbuf_hd <= 0;
			wbuf_tl <= 0;
		end else begin
			//axi
			if (state == st_check) begin		// check status register
				if (sub_state == 0) begin
					s_axi_arvalid <= 1;
					sub_state <= 1;
				end else if (sub_state == 1 && s_axi_arready && s_axi_arvalid) begin
					s_axi_arvalid <= 0;
					s_axi_rready <= 1;
					sub_state <= 2;
				end else if (sub_state == 2 && s_axi_rready && s_axi_rvalid) begin
					s_axi_rready <= 0;
					io_err <= io_err | { s_axi_rresp[1] , s_axi_rdata[7:5], 1'b0 };
					if (w_uart_rdy && ~s_axi_rdata[3]) begin				// write > read, so read can be starve
						state <= st_write;
						sub_state <= 0;
					end else if(r_uart_rdy && s_axi_rdata[0]) begin
						state <= st_read;
						sub_state <= 0;
					end else begin
						state <= st_check;
						sub_state <= 0;
					end
				end
			end else if (state == st_read) begin		// read
				if (sub_state == 0) begin
					s_axi_arvalid <= 1;
					sub_state <= 1;
				end else if (sub_state == 1 && s_axi_arready && s_axi_arvalid) begin
					s_axi_arvalid <= 0;
					s_axi_rready <= 1;
					sub_state <= 2;
				end else if (sub_state == 2 && s_axi_rready && s_axi_rvalid) begin
					s_axi_rready <= 0;
					io_err <= io_err | { s_axi_rresp[1] ,4'b0000 };
					rbuf_data[rbuf_hd] <= s_axi_rdata;
					rbuf_hd <= rbuf_hd + 1;
					state <= st_check;
					sub_state <= 0;
				end
			end else if (state == st_write) begin		//write
				if (sub_state == 0) begin
					s_axi_awvalid <= 1;
					s_axi_wvalid <= 1;
					sub_state <= 1;
				end else if (sub_state == 1) begin
					if (s_axi_awready && s_axi_awvalid) begin
						s_axi_awvalid <= 0;
					end
					if (s_axi_wready && s_axi_wvalid) begin
						s_axi_wvalid <= 0;
					end
					if (~s_axi_awvalid && ~s_axi_wvalid) begin
						s_axi_bready <= 1;
						sub_state <= 2;
					end
				end else if (sub_state == 2 && s_axi_bready && s_axi_bvalid) begin
					s_axi_bready <= 0;
					io_err <= io_err | { s_axi_bresp[1] , 4'b0000 };
					wbuf_tl <= wbuf_tl + 1;
					state <= st_check;
					sub_state <= 0;
				end		
			end else begin
				io_err <= io_err | err_lost;
			end
			
			//cpu
			//in
			if (in_state == 0 && r_in_rdy) begin
				io_in_vld <= 1;
				in_state <= 1;
			end else if (in_state == 1 && io_in_rdy && io_in_vld) begin
				io_in_vld <= 0;
				rbuf_tl <= rbuf_tl + 1;
				in_state <= 0;
			end
			//out
			if(out_state == 0 && w_out_rdy) begin
				io_out_rdy <= 1;
				out_state <= 1;
			end else if (out_state == 1 && io_out_rdy && io_out_vld) begin
				io_out_rdy <= 0;
				wbuf_data[wbuf_hd] <= io_out_data;
				wbuf_hd <= wbuf_hd + 1;
				out_state <= 0;
			end
		end
	end

endmodule
