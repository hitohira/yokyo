module mmu(
	input wire clk,
	input wire rstn,

	// to mem
	output reg [31:0] m_axi_araddr,
	input wire m_axi_arready,
	output reg m_axi_arvalid,
	
	output reg [31:0] m_axi_awaddr,
	input wire m_axi_awready,
	output reg m_axi_awvalid,
	
	output reg m_axi_bready,
	input wire [1:0] m_axi_bresp,
	input wire m_axi_bvalid,

	input wire [31:0] m_axi_rdata,
	output reg m_axi_rready,
	input wire [1:0] m_axi_rresp,
	input wire m_axi_rvalid,

	output reg [31:0] m_axi_wdata,
	input wire m_axi_wready,
	output reg [3:0] m_axi_wstrb,
	output reg m_axi_wvalid,

	// IO
	(* mark_debug = "true" *) input wire [7:0] io_in_data,
	(* mark_debug = "true" *) output reg io_in_rdy,
	(* mark_debug = "true" *) input wire io_in_vld,
	(* mark_debug = "true" *) output reg [7:0] io_out_data,
	(* mark_debug = "true" *) input wire io_out_rdy,
	(* mark_debug = "true" *) output reg io_out_vld,
	input wire [4:0] io_err, // {resp[1],parity,frame,overrun,lost }

	// from core
	input wire [31:0] c_axi_araddr,
	output reg c_axi_arready,
	input wire c_axi_arvalid,
	
	input wire [31:0] c_axi_awaddr,
	output reg c_axi_awready,
	input wire c_axi_awvalid,
	
	input wire c_axi_bready,
	output reg [1:0] c_axi_bresp,
	output reg c_axi_bvalid,

	output reg [31:0] c_axi_rdata,
	input wire c_axi_rready,
	output reg [1:0] c_axi_rresp,
	output reg c_axi_rvalid,

	input wire [31:0] c_axi_wdata,
	output reg c_axi_wready,
	input wire [3:0] c_axi_wstrb,
	input wire c_axi_wvalid,

	
	// optional signal
	input wire [1:0] cpu_mode,
	input wire [31:0] satp,
	input wire is_instr,

	(* mark_debug = "true" *) output reg throw_exception,
	output reg [2:0] exception_vec
	);

	// little endian!!!!!!!!!!!
	// c_axi bresp and rresp
	
	localparam EXCEPTION_INSTR_PG_FAULT = 3'b001;
	localparam EXCEPTION_LOAD_PG_FAULT = 3'b010;
	localparam EXCEPTION_STORE_PG_FAULT = 3'b011;
	localparam EXCEPTION_UNDEFINED = 3'b111;
	

	function [31:0] ch_endian(input [31:0] e_data);
		ch_endian = { e_data[7:0],e_data[15:8],e_data[23:16],e_data[31:24]};
	endfunction

	function [2:0] fault(input instr,input write);
		fault = instr ? EXCEPTION_INSTR_PG_FAULT :
		        write ? EXCEPTION_STORE_PG_FAULT : EXCEPTION_STORE_PG_FAULT;
	endfunction

	(* mark_debug = "true" *) reg [5:0] state;
	reg [31:0] v_addr;
	(* mark_debug = "true" *) reg [33:0] p_addr;
	reg [31:0] data;
	reg [3:0] strb;
	reg is_write;
	reg [1:0] level;

	wire satp_mode;
	wire [21:0] satp_ppn;
	wire [9:0] vpn_1;
	wire [9:0] vpn_0;
	wire [11:0] offset;
	wire [11:0] data_ppn_1;
	wire [9:0] data_ppn_0;
	wire data_d,data_a,data_g,data_u,data_x,data_w,data_r,data_v;

	assign satp_mode = satp[31];
	assign satp_ppn = satp[21:0];
	assign vpn_1 = v_addr[31:22];
	assign vpn_0 = v_addr[21:12];
	assign offset = v_addr[11:0];
	assign data_ppn_1 = data[31:20];
	assign data_ppn_0 = data[19:10];
	assign {data_d,data_a,data_g,data_u,data_x,data_w,data_r,data_v} = data[7:0];

	always @(posedge clk) begin
		if(~rstn) begin
			m_axi_araddr <= 0;
			m_axi_arvalid <= 0;
			m_axi_awaddr <= 0;
			m_axi_awvalid <= 0;
			m_axi_bready <= 0;
			m_axi_rready <= 0;
			m_axi_wdata <= 0;
			m_axi_wstrb <= 0;
			m_axi_wvalid <= 0;

			io_in_rdy <= 0;
			io_out_data <= 0;
			io_out_vld <= 0;

			c_axi_arready <= 0;
			c_axi_awready <= 0;
			c_axi_bresp <= 0;
			c_axi_bvalid <= 0;
			c_axi_rdata <= 0;
			c_axi_rresp <= 0;
			c_axi_rvalid <= 0;
			c_axi_wready <= 0;

			throw_exception <= 0;
			exception_vec <= 0;
			state <= 0;
			v_addr <= 0;
			p_addr <= 0;
			data <= 0;
			is_write <= 0;
			level <= 0;
			//wait for core
		end else if (state == 0) begin
			c_axi_arready <= 1;
			state <= 1;
		end else if (state == 1) begin
			c_axi_arready <= 0;
			throw_exception <= 0;
			if(c_axi_arvalid) begin
				v_addr <= c_axi_araddr;
				is_write <= 0;
				state <= 4;
			end else begin
				c_axi_awready <= 1;
				state <= 2;
			end
		end else if (state == 2) begin
			c_axi_awready <= 0;
			throw_exception <= 0;
			if(c_axi_awvalid) begin
				v_addr <= c_axi_awaddr;
				is_write <= 1;
				state <= 4;
			end else begin
				c_axi_arready <= 1;
				state <= 1;
			end
			// addr translation
		end else if (state == 4) begin //1,2
			throw_exception <= 0;
			exception_vec <= 0;
			if (satp_mode == 1) begin
				level <= 1;
				m_axi_araddr <= {satp_ppn,12'b0} + {vpn_1,2'b0};
				m_axi_arvalid <= 1;
				state <= 5;
			end else begin
				p_addr <= v_addr;
				if(is_write) begin
					state <= 12; 
				end else begin
					state <= 19;
				end
			end
		end else if (state == 5) begin 
			if (m_axi_arready) begin
				m_axi_arvalid <= 0;
				m_axi_rready <= 1;
				state <= 6;
			end
		end else if (state == 6) begin
			if (m_axi_rvalid) begin
				m_axi_rready <= 0;
				if(m_axi_rresp[1]) begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
					state <= 12; //ret
				end else begin
					data <= ch_endian(m_axi_rdata);
					state <= 7;
				end
			end
		end else if (state == 7) begin
			if(data_v == 0 || (data_r == 0 && data_w == 1)) begin // 3
				throw_exception <= 1;
				exception_vec <= fault(is_instr,is_write);
				state <= 12; //ret
			end	else if (data_r == 1 || data_x == 1) begin // 4 ...step 5. ,5
				if (level == 1) begin
					p_addr <= {data_ppn_1,vpn_0,offset};
				end else if(level == 0) begin
					p_addr[21:0] <= {data_ppn_0,offset};
				end
				if(cpu_mode == 2'b11 && !data_u) begin // user?
					throw_exception <= 1;
					exception_vec <= fault(is_instr,is_write);
					state <= 12; //ret
				end else if(is_write && !data_w) begin //write ok?
					throw_exception <= 1;
					exception_vec <= fault(is_instr,is_write);
					state <= 12; //ret
				end else if(is_instr && !data_x) begin //exec ok?
					throw_exception <= 1;
					exception_vec <= fault(is_instr,is_write);
					state <= 12; //ret
				end else if(!data_r) begin // read ok?
					throw_exception <= 1;
					exception_vec <= fault(is_instr,is_write);
					state <= 12; //ret
				end else if(level == 1 && data_ppn_0 != 0) begin //6 superpage ok? 
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
					state <= 12; //ret
				end else if(data_a == 0 || (is_write && data_d == 0)) begin //7
					if(is_write) begin
						m_axi_wdata <= ch_endian({data_ppn_1,data_ppn_0,4'b0011,
						         data_g,data_u,data_x,data_w,data_r,data_v});
					end else begin
						m_axi_wdata <= ch_endian({data_ppn_1,data_ppn_0,2'b00,data_d,1'b1,
						         data_g,data_u,data_x,data_w,data_r,data_v});
					end
					m_axi_wvalid <= 1;
					m_axi_wstrb <= 4'b1111;
					m_axi_awaddr <= m_axi_araddr;
					m_axi_awvalid <= 1;
					state <= 8;
				end else begin
					state <= 12; //ret
				end
			end else begin //4. otherwise, this PTE is...
				if(level == 1) begin
					level <= 0;
					m_axi_araddr <= {data_ppn_1,data_ppn_0,12'b0} + {vpn_0,2'b0};
					m_axi_arvalid <= 1;
					state <= 5;
				end else begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
					state <= 12; //ret
				end
			end
		end else if (state == 8) begin
			if(m_axi_awready) begin
				m_axi_awvalid <= 0;
			end
			if (m_axi_wready) begin
				m_axi_wvalid <= 0;
			end
			if (m_axi_awvalid == 0 && m_axi_wvalid == 0) begin
				m_axi_bready <= 1;
				state <= 10;
			end
		end else if(state == 10) begin
			if(m_axi_bvalid) begin
				m_axi_bready <= 0;
				if(m_axi_bresp[1]) begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
					state <= 12; //ret
				end else begin // addr translate success
					state <= 12;
				end
			end
		end else if (state == 12) begin // return result of addr translate
			if(is_write) begin // write
				c_axi_wready <= 1;
				state <= 14;
			end else begin // read
				if(throw_exception) begin
					c_axi_rdata <= 0;
					c_axi_rresp <= 0;
					c_axi_rvalid <= 1;
					state <= 13;
				end else begin
					state <= 19;//read ok => read acccess mem
				end
			end
		end else if (state == 13) begin // read end
			if(c_axi_rready) begin
				c_axi_rvalid <= 0;
				throw_exception <= 0;
				exception_vec <= 0;
				state <= 0;
			end
		end else if (state == 14) begin
			if(c_axi_wvalid) begin
				c_axi_wready <= 0;
				data <= c_axi_wdata;
				strb <= c_axi_wstrb;
				if(p_addr == 34'h80000004) begin // uart
					state <= 24;
				end else if (p_addr[33:31] == 3'b0) begin
					state <= 15;
				end else begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
					c_axi_bresp <= 0;
					c_axi_bvalid <= 1;
					state <= 18; // write end
				end
			end
		end else if (state == 15) begin // write acccess memory
			m_axi_awaddr <= p_addr[31:0];
			m_axi_awvalid <= 1;
			m_axi_wdata <= ch_endian(data);
			m_axi_wstrb <= {strb[0],strb[1],strb[2],strb[3]};
			m_axi_wvalid <= 1;
			state <= 16;
		end else if (state == 16) begin
			if (m_axi_awready) begin
				m_axi_awvalid <= 0;
			end
			if (m_axi_wready) begin
				m_axi_wvalid <= 0;
			end
			if(m_axi_awvalid == 0 && m_axi_wvalid == 0) begin
				m_axi_bready <= 1;
				state <= 17;
			end
		end else if (state == 17) begin 
			if(m_axi_bvalid) begin
				m_axi_bready <= 0;
				if(m_axi_bresp[1]) begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
				end
				c_axi_bresp <= m_axi_bresp;
				c_axi_bvalid <= 1;
				state <= 18;
			end
		end else if (state == 18) begin // write end
			if(c_axi_bready) begin
				c_axi_bvalid <= 0;
				throw_exception <= 0;
				exception_vec <= 0;
				state <= 0;
			end
		end else if (state == 19) begin // read access memory
			if(p_addr == 34'h80000000) begin
				io_in_rdy <= 1;
				state <= 28;
			end else if (p_addr[33:31] == 3'b0) begin
				m_axi_araddr <= p_addr[31:0];
				m_axi_arvalid <= 1;
				state <= 20;
			end else begin
				throw_exception <= 1;
				exception_vec <= EXCEPTION_UNDEFINED;
				c_axi_rdata <= 0;
				c_axi_rresp <= 0;
				c_axi_rvalid <= 1;
				state <= 13; // read end
			end
		end else if (state == 20) begin
			if(m_axi_arready) begin
				m_axi_arvalid <= 0;
				m_axi_rready <= 1;
				state <= 21;
			end
		end else if(state == 21) begin
			if(m_axi_rvalid) begin
				m_axi_rready <= 0;
				if(m_axi_rresp[1])begin
					throw_exception <= 1;
					exception_vec <= EXCEPTION_UNDEFINED;
				end
				c_axi_rdata <= ch_endian(m_axi_rdata);
				c_axi_rresp <= m_axi_rresp;
				c_axi_rvalid <= 1;
				state <= 13;  // read end
			end
		end else if (state == 24) begin // uart write
			io_out_data <= data[31:24];
			io_out_vld <= 1;
			state <= 25;
		end else if (state == 25) begin
			if(io_out_rdy) begin
				io_out_vld <= 0;
				c_axi_bresp <= 0;
				c_axi_bvalid <= 1;
				state <= 18;
			end
		end else if (state == 28) begin
			if(io_in_vld) begin
				io_in_rdy <= 0;
				c_axi_rdata <= {io_in_data[7:0],24'b0};
				c_axi_rresp <= 0;
				c_axi_rvalid <= 1;
				state <= 13; //read end
			end
		end
	end // always

endmodule
