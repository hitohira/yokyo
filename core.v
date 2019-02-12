module core_wrapper (
  input wire clk,
  input wire rstn,

	//mmu (big endian)
	output wire [31:0] m_axi_araddr,
	input wire m_axi_arready,
	output wire m_axi_arvalid,
			   
	output wire [31:0] m_axi_awaddr,
	input wire m_axi_awready,
	output wire m_axi_awvalid,
				   
	output wire m_axi_bready,
	input wire [1:0] m_axi_bresp,
	input wire m_axi_bvalid,

	input wire [31:0] m_axi_rdata,
	output wire m_axi_rready,
	input wire [1:0] m_axi_rresp,
	input wire m_axi_rvalid,

	output wire [31:0] m_axi_wdata,
	input wire m_axi_wready,
	output wire [3:0] m_axi_wstrb,
	output wire m_axi_wvalid,

  output wire [1:0] m_cpu_mode,
	output wire [31:0] m_satp,
	output wire m_is_instr,

	input wire m_throw_exception,
	input wire [2:0] m_exception_vec,

	input wire is_timer_intr,
	input wire is_ext_intr,

	output wire [19:0] ex_sig,
	output wire [31:0] ex_src1,
	output wire [31:0] ex_src2,
	output wire ex_out_valid,
	input wire [31:0] ex_result,
	input wire [2:0] ex_exception,
	input wire ex_in_valid
  );
  
core u1(
  clk,
  rstn,

 m_axi_araddr,
 m_axi_arready,
 m_axi_arvalid,
	   
 m_axi_awaddr,
 m_axi_awready,
 m_axi_awvalid,
				   
 m_axi_bready,
 m_axi_bresp,
 m_axi_bvalid,

 m_axi_rdata,
 m_axi_rready,
 m_axi_rresp,
 m_axi_rvalid,

 m_axi_wdata,
 m_axi_wready,
 m_axi_wstrb,
 m_axi_wvalid,

 m_cpu_mode,
 m_satp,
 m_is_instr,
 m_throw_exception,
 m_exception_vec,

 is_timer_intr,
 is_ext_intr,

 ex_sig,
 ex_src1,
 ex_src2,
 ex_out_valid,
 ex_result,
 ex_exception,
 ex_in_valid

);
  
endmodule
