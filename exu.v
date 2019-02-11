module exu(
	input wire clk,
	input wire rstn,

	input wire [19:0] ex_sig,
	input wire [31:0] ex_src1,
	input wire [31:0] ex_src2,
	input wire ex_out_valid,
	output reg [31:0] ex_result,
	output reg [2:0] ex_exception,
	output reg ex_in_valid
	);

	// 1clkだけex_out_validがアサートされるのでそのタイミングで取り込み
	// 各計算させる
	// 適切なclk後に計算結果を取り出しex_in_validを1clkだけアサートして返す
	// 上に戻る

	wire imul;
	assign imul = ex_sig[0];
	wire imulh;
	assign imulh = ex_sig[1];
	wire imulhsu;
	assign imulhsu = ex_sig[2];
	wire imulhu;
	assign imulhu = ex_sig[3];
	wire idiv;
	assign idiv = ex_sig[4];
	wire idivu;
	assign idivu = ex_sig[5];
	wire irem;
	assign irem = ex_sig[6];
	wire iremu;
	assign iremu = ex_sig[7];
	wire ifadd;
	assign ifadd = ex_sig[8];
	wire ifsub;
	assign ifsub = ex_sig[9];
	wire ifmul;
	assign ifmul = ex_sig[10];
	wire ifdiv;
	assign ifdiv = ex_sig[11];
	wire ifeq;
	assign ifeq = ex_sig[12];
	wire iflt;
	assign iflt = ex_sig[13];
	wire ifle;
	assign ifle = ex_sig[14];
	wire ifsgnj;
	assign ifsgnj = ex_sig[15];
	wire ifsgjn;
	assign ifsgjn = ex_sig[16];
	
	reg [6:0] counter;
	always @(posedge clk) begin
		if(~rstn) begin
			counter <= 0;
		end else if(ex_out_valid) begin
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
	end

	always @(posedge clk) begin
		if(~rstn) begin
			ex_result <= 0;
			ex_exception <= 0;
			ex_in_valid <= 0;
		end else begin

		end
	end

endmodule
