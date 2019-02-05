module cache(
	input wire clk,

	// mmu
  input wire [31:0] m_axi_araddr,
  output reg m_axi_arready,
  input wire m_axi_arvalid,

  input wire [31:0] m_axi_awaddr,
  output reg m_axi_awready,
	input wire m_axi_awvalid,

	input wire m_axi_bready,
	output reg [1:0] m_axi_bresp,
	output reg m_axi_bvalid,

	output reg [31:0] m_axi_rdata,
	input wire m_axi_rready,
	output reg [1:0] m_axi_rresp,
	output reg m_axi_rvalid,

	input wire [31:0] m_axi_wdata,
	output reg m_axi_wready,
	input wire [3:0] m_axi_wstrb,
	input wire m_axi_wvalid,

	// sdram
  output reg [30:0] s_axi_araddr,
  output wire [1:0] s_axi_arburst,
	output wire [3:0] s_axi_arcache,
	output wire [3:0] s_axi_arid,
	output wire [7:0] s_axi_arlen,
	output wire [0:0] s_axi_arlock,
	output wire  [2:0] s_axi_arprot,
	output wire [3:0] s_axi_arqos,
	input wire s_axi_arready,
	output wire [2:0] s_axi_arsize,
	output reg s_axi_arvalid,

	output reg [30:0] s_axi_awaddr,
	output wire [1:0] s_axi_awburst,
	output wire [3:0] s_axi_awcache,
	output wire [3:0] s_axi_awid,
	output wire [7:0] s_axi_awlen,
	output wire [0:0] s_axi_awlock,
	output wire  [2:0] s_axi_awprot,
	output wire [3:0] s_axi_awqos,
	input wire s_axi_awready,
	output wire [2:0] s_axi_awsize,
	output reg s_axi_awvalid,

	input wire [3:0] s_axi_bid,
	output reg s_axi_bready,
	input wire [1:0] s_axi_bresp,
	input wire s_axi_bvalid,

  input wire [511:0] s_axi_rdata,
  input wire [3:0] s_axi_rid,
  input wire s_axi_rlast,
  output reg s_axi_rready,
  input wire [1:0] s_axi_rresp,
  input wire s_axi_rvalid,

  output reg [511:0] s_axi_wdata,
  output wire s_axi_wlast,
  input wire s_axi_wready,
  output wire [63:0] s_axi_wstrb,
  output reg s_axi_wvalid,

	output reg err
	);
	
	// cache size 1MB(2**20)
	// num of block 2**14
	// block size 512bit=64B(2**6) = 16word
	// word size 4B
	// global_tag 12bit, block_tag 14bit, offset 4 bit = 30bit 下位2bitは2'b00

	// bram size 
		// width = 32
		// depth = 2**18 = 262144

	// cache controller
		// table size
			// { valid 1bit,tag 12bit } * num_of_block 2**14

	reg [31:0] bram_addr;
	reg [31:0] bram_din;
	wire [31:0] bram_dout;
	reg bram_we;

	bram u1(clk,ram_addr,bram_din,bram_dout,bram_we);

	reg [13:0] table_addr;
	reg [12:0] table_din;
	wire [12:0] table_dout;
	reg table_we;

	distram u2(clk,table_addr,table_din,table_dout,table_we);
	
	wire table_valid;
	wire [11:0] table_tag;

	assign table_valid = table_dout[12];
	assign table_tag = table_dout[11:0];

	reg [5:0] state;
	reg [3:0] counter;
	reg [511:0] line_data;

	reg [31:0] req_addr;
	reg [31:0] req_data;
	reg [3:0] req_strb;
	reg is_write;
	
	wire [11:0] g_tag;
	wire [13:0] b_tag;
	wire [5:0] offset;

	assign g_tag = req_addr[31:20];
	assign b_tag = req_addr[19:6];
	assign offset = {req_addr[5:2],2'b00};

	always @(posedge clk) begin
		if (state == 0) begin // wait for mmu request 1
			m_axi_arready <= 1;
			state <= 1;
		end else if (state == 1) begin // wait for mmu request 2
			m_axi_arready <= 0;
			if(m_axi_arvalid) begin
				req_addr <= m_axi_araddr;
				is_write <= 0;
				table_addr <= m_axi_araddr[19:6];
				state <= 4; // tag check
			end else begin
				m_axi_awready <= 1;
				stete <= 2;
			end
		end else if (state == 2) begin // wait for mmu request 3
			m_axi_awready <= 0;
			if(m_axi_awvalid) begin
				m_axi_wready <= 1;
				req_addr <= m_axi_awaddr;
				is_write <= 1;
				table_addr <= m_axi_awaddr[19:6];
				state <= 3;
			end else begin
				m_axi_arready <= 1;
				state <= 1;
			end
		end else if (state == 3) begin // get wdata
			if(m_axi_wvalid) begin
				m_axi_wready <= 0;
				req_data <= m_axi_wdata;
				req_strb <= m_axi_wstrb;
				state <= 4; // tag check
			end
		end else if (state == 4) begin // tag is exist?
			if(table_tag == g_tag && table_valid) begin // cache block exist
				if(is_write) begin
					/////////////////////////////////////////////////////////
				end else begin
					////////////////////////////////////////////////////////
				end
			end else begin // cache miss -> sdram access
				s_axi_araddr <= {g_tag,b_tag,6'b00};
				s_axi_arvalid <= 1;
				state <= 5;
			end
		end else if (state == 5) begin // read sdram 
			if(s_axi_arready) begin
				s_axi_arvalid <= 0;
				s_axi_rready <= 1;
				state <= 6;
			end
		end else if(state == 6) begin // read sdram2
			if(s_axi_rvalid) begin
				s_axi_rready <= 0;
				line_data <= s_axi_rdata;
				counter <= 0;
				if(s_axi_rresp[1]) begin
					err <= 1;
				end else begin
					state <= 7;
				end
			end
		end else if (state == 7) begin // write cache line(16clk)
			bram_addr <= {b_tag,counter,2'b00};
			bram_din <= line_data[31:0];
			bram_we <= 1;
			line_data <= line_data >> 32;
			counter <= counter + 1'b1;
			if(counter == 4'b1111) begin
				table_din <= {1'b1,g_tag}; // update table
				table_we <= 1;
				state <= 9;
			end
		end else if (state == 9) begin // start mem ope
			bram_we <= 0;
			table_we <= 0;
			if(is_write) begin
				/////////////////////////////////////////////////
			end else begin
				////////////////////////////////////////////////
			end
		end
	end // always


	assign	s_axi_arburst = 2'b01; // INCR
	assign	s_axi_arcache = 4'b0011; // magic num
	assign	s_axi_arid = 0; 
	assign	s_axi_arlen = 0; // burst len = 1
	assign	s_axi_arlock = 0;
	assign	s_axi_arprot = 0;
	assign	s_axi_arqos = 0;
	assign	s_axi_arsize = 3'b011; //64bit

	assign	s_axi_awburst = 2'b01; // INCR
	assign	s_axi_awcache = 4'b0011; //magic num
	assign	s_axi_awid = 0;
	assign	s_axi_awlen = 0; // burst len = 1
	assign	s_axi_awlock = 0;
	assign	s_axi_awprot = 0;
	assign	s_axi_awqos = 0;
	assign	s_axi_awsize = 3'b001; // 64bit
	assign	s_axi_wlast = 1; // because burst len = 0, it is always 1
	assign	s_axi_wstrb = {64{1'b1}};

	initial begin
		state = 0;
		bram_addr = 0;
		bram_din = 0;
		bram_we = 0;
		table_addr = 0;
		table_din = 0;
		table_we = 0;
		err = 0;

		m_axi_arready = 0;
		m_axi_awready = 0;
		m_axi_bresp = 0;
		m_axi_bvalid = 0;
		m_axi_rdata = 0;
		m_axi_rresp = 0;
		m_axi_rvalid = 0;
		m_axi_wready = 0;

		s_axi_araddr = 0;
		s_axi_arvalid = 0;
		s_axi_awaddr = 0;
		s_axi_awvalid = 0;
		s_axi_bready = 0;
		s_axi_rready = 0;
		s_axi_wdata = 0;
		s_axi_wvalid = 0;

	end
endmodule
