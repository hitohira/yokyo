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
	assign ex_sig[0];
	wire imulh;
	assign ex_sig[1];
	wire imulhsu;
	assign ex_sig[2];
	wire imulhu;
	assign ex_sig[3];
	wire idiv;
	assign ex_sig[4];
	wire idivu;
	assign ex_sig[5];
	wire irem;
	assign ex_sig[6];
	wire iremu;
	assign ex_sig[7];
	wire ifadd;
	assign ex_sig[8];
	wire ifsub;
	assign ex_sig[9];
	wire ifmul;
	assign ex_sig[10];
	wire ifdiv;
	assign ex_sig[11];
	wire ifeq;
	assign ex_sig[12];
	wire iflt;
	assign ex_sig[13];
	wire ifle;
	assign ex_sig[14];
	wire ifsgnj;
	assign ex_sig[15];
	wire ifsgjn;
	assign ex_sig[16];
	
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
