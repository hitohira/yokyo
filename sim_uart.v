module sim_uart(
	input clk,
	input rstn,

	//axi
  input wire [31:0] s_axi_araddr,
  output wire s_axi_arready,
	input wire s_axi_arvalid,

	input wire [31:0] s_axi_awaddr,
	output wire s_axi_awready,
	input wire s_axi_awvalid,

	input wire s_axi_bready,
	output wire [1:0] s_axi_bresp,
	output wire s_axi_bvalid,

	output wire [31:0] s_axi_rdata,
	input wire s_axi_rready,
	output wire [1:0] s_axi_rresp,
	output wire s_axi_rvalid,

	input wire [31:0] s_axi_wdata,
	output wire s_axi_wready,
	input wire [3:0] s_axi_wstrb,
	input wire s_axi_wvalid

	);

	wire [31:0] addr;
	wire [31:0] din;
	wire [31:0] dout;
	wire en;
	wire [3:0] we;
	wire err;

	BramController u1(
		clk,
		rstn,
		s_axi_araddr,
		s_axi_arready,
		s_axi_arvalid,
		s_axi_awaddr,
		s_axi_awready,
		s_axi_awvalid,
		s_axi_bready,
		s_axi_bresp,
		s_axi_bvalid,
		s_axi_rdata,
		s_axi_rready,
		s_axi_rresp,
		s_axi_rvalid,
		s_axi_wdata,
		s_axi_wready,
		s_axi_wstrb,
		s_axi_wvalid,
		addr,
		din,
		dout,
		en,
		we

	);
	sim_uart_sub u2(clk,rstn,addr,din,dout,en,we,err);




endmodule
