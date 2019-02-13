module fmul(
		input wire clk,
    input wire [31:0] x1,
    input wire [31:0] x2,
    output reg [31:0] y // 3
		);

    wire s1,s2,sy; // 0
    wire [7:0] e1,e2; // 0
    wire [22:0] m1,m2; // 0
    assign s1 = x1[31];
    assign e1 = x1[30:23];
    assign m1 = x1[22:0];
    assign s2 = x2[31];
    assign e2 = x2[30:23];
    assign m2 = x2[22:0];

    assign sy = s1 ^ s2;

		wire [23:0] m1ex,m2ex; // 0
		assign m1ex = {1'b1,m1};
		assign m2ex = {1'b1,m2};

		wire [11:0] m1ex_l,m1ex_h,m2ex_l,m2ex_h; // 0
		assign m1ex_l = m1ex[11:0];
		assign m1ex_h = m1ex[23:12];
		assign m2ex_l = m2ex[11:0];
		assign m2ex_h = m2ex[23:12];

		reg [23:0] hh,ll; // 1
		always @(posedge clk) begin
			ll <= m1ex_l * m2ex_l;
			hh <= m1ex_h * m2ex_h;
		end

		wire [47:0] hhll; // 1
		assign hhll = {hh,ll};

		reg [23:0] hl,lh; // 1
		always @(posedge clk) begin
	  	hl <= m1ex_h * m2ex_l;
			lh <= m1ex_l * m2ex_h;
		end

		reg [24:0] hllh; // 2
		always @(posedge clk) begin
			hllh <= hl + lh;
		end
		
    wire [47:0] mya; // 2
		assign mya = {hhll[47:12]+hllh,hhll[11:0]};

		wire [22:0] my;
    assign my = (mya[47:47]) ? mya[46:24]: mya[45:23];

    reg [8:0] eya0; // 1
		always @(posedge clK) begin
    	eya0 <= (x1[30:0] == 31'b0 | x2[30:0] == 31'b0) ? 9'b0: e1 + e2;
		end
    
    wire [9:0] ey0a,ey1a; // 1
    assign ey0a = eya0 - 10'd127;
    assign ey1a = eya0 - 10'd126;

    wire [7:0] ey0,ey1; // 1
    assign ey0 = (ey0a[9]) ? 8'b0: ey0a[7:0];
    assign ey1 = (ey1a[9]) ? 8'b0: ey1a[7:0];
		
		wire [7:0] ey; // 1
    assign ey = (mya[47:47]) ? ey1: ey0;

		always @(posedge clk) begin
  	  y <= {sy,ey,my};
		end

endmodule
