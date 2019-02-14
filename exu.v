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

	reg [31:0] src1;
	reg [31:0] src2;
	reg [19:0] sig;
	always @(posedge clk) begin
		if(~rstn) begin
			src1 <= 0;
			src2 <= 0;
			sig <= 0;
		end if(ex_out_valid) begin
			src1 <= ex_src1;
			src2 <= ex_src2;
			sig <= ex_sig;
		end
	end

	wire imul;
	assign imul = sig[0];
	wire imulh;
	assign imulh = sig[1];
	wire imulhsu;
	assign imulhsu = sig[2];
	wire imulhu;
	assign imulhu = sig[3];
	wire idiv;
	assign idiv = sig[4];
	wire idivu;
	assign idivu = sig[5];
	wire irem;
	assign irem = sig[6];
	wire iremu;
	assign iremu = sig[7];
	wire ifadd;
	assign ifadd = sig[8];
	wire ifsub;
	assign ifsub = sig[9];
	wire ifmul;
	assign ifmul = sig[10];
	wire ifdiv;
	assign ifdiv = sig[11];
	wire ifeq;
	assign ifeq = sig[12];
	wire iflt;
	assign iflt = sig[13];
	wire ifle;
	assign ifle = sig[14];
	wire ifsgnj;
	assign ifsgnj = sig[15];
	wire ifsgjn;
	assign ifsgjn = sig[16];
	
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

	reg is_calc;
	always @(posedge clk) begin
		if (~rstn) begin
			is_calc <= 0;
		end else if (ex_out_valid) begin
			is_calc <= 1;
		end else if (ex_in_valid) begin
			is_calc <= 0;
		end
	end


	wire [31:0] mul_result,mulh_result,mulhu_result,mulhsu_result;
	wire [31:0] fadd_result,fmul_result,fdiv_result;
	wire feq_result,flt_result,fle_result;
	wire [31:0] fsgnj_result,fsgnjn_result;
	wire [31:0] divq,divr;

	mul mul_u (src1,src2,mul_result,clk);
	mulh mulh_u (src1,src2,mulh_result,clk);
	mulhsu mulhsu_u (src1,src2,mulhsu_result,clk);
	mulhu mulhu_u (src1,src2,mulhu_result,clk);

	reg [63:0] divx;
	reg  [31:0] divd;
	reg sigx,sigd;
	wire [31:0] src1neg,src2neg;
	assign src1neg = (~src1) + 1'b1;
	assign src2neg = (~src2) + 1'b1;
	always @(posedge clk) begin
		divx <= (idiv | irem) && src1[31] ? {32'b0,src1neg} : {32'b0,src1};
		divd <= (idiv | irem) && src2[31] ? src2neg : src2;
		sigx <= src1[31];
		sigd <= src2[31];
	end
	div32 div_u(clk,divx,divd,divq,divr);

	wire [31:0] fadd_src2;
	assign fadd_src2 = ifsub ? {~src2[31],src2[30:0]} : src2;
	fadd fadd_u (clk,src1,fadd_src2,fadd_result);
	fmul fmul_u (clk,src1,src2,fmul_result);
	fdiv fdiv_u (clk,src1,src2,fdiv_result);

	feq feq_u (src1,src2,feq_result);
	flt flt_u (src1,src2,flt_result);
	fle fle_u (src1,src2,fle_result);
	fsgnj fsgnj_u (src1,src2,fsgnj_result);
	fsgnjn fsgnjn_u (src1,src2,fsgnjn_result);

	always @(posedge clk) begin
		if(~rstn) begin
			ex_result <= 0;
			ex_exception <= 0;
			ex_in_valid <= 0;
		end else if (!is_calc | ex_in_valid) begin
			ex_in_valid <= 0;
		end else if(imul && counter == 4) begin
			ex_in_valid <= 1;
			ex_result <= mul_result;
		end else if (imulh && counter == 5) begin
			ex_in_valid <= 1;
			ex_result <= mulh_result;
		end else if (imulhsu && counter == 5) begin
			ex_in_valid <= 1;
			ex_result <= mulhsu_result;
		end else if (imulhu && counter == 5) begin
			ex_in_valid <= 1;
			ex_result <= mulhu_result;
		end else if (idiv && counter == 17) begin
			ex_in_valid <= 1;
			if(sigx && sigd) begin // - / -
				ex_result <= divq;
			end else if (sigx && !sigd) begin // - / +
				ex_result <= (~divq) + 1'b1;
			end else if (!sigx && sigd) begin // + / -
				ex_result <= (~divq) + 1'b1;
			end else begin // + / +
				ex_result <= divq;
			end
		end else if (idivu && counter == 17) begin
			ex_in_valid <= 1;
			ex_result <= divq;
		end else if (irem && counter == 17) begin
			ex_in_valid <= 1;
			if(sigx && sigd) begin // - / -
				ex_result <= (~divr) + 1'b1;
			end else if (sigx && !sigd) begin // - / +
				ex_result <= (~divr) + 1'b1;
			end else if (!sigx && sigd) begin // + / -
				ex_result <= divr;
			end else begin // + / +
				ex_result <= divr;
			end
		end else if (iremu && counter == 17) begin
			ex_in_valid <= 1;
			ex_result <= divr;
		end else if ((ifadd || ifsub) && counter == 2) begin
			ex_in_valid <= 1;
			ex_result <= fadd_result;
		end else if (ifmul && counter == 3) begin
			ex_in_valid <= 1;
			ex_result <= fmul_result;
		end else if (ifdiv && counter == 8) begin
			ex_in_valid <= 1;
			ex_result <= fdiv_result;
		end else if (ifeq) begin
			ex_in_valid <= 1;
			ex_result <= feq_result;
		end else if (iflt) begin
			ex_in_valid <= 1;
			ex_result <= flt_result;
		end else if (ifle) begin
			ex_in_valid <= 1;
			ex_result <= fle_result;
		end else if (ifsgnj) begin
			ex_in_valid <= 1;
			ex_result <= fsgnj_result;
		end else if (ifsgjn) begin
			ex_in_valid <= 1;
			ex_result <= fsgnjn_result;
		end
	end // always

endmodule
