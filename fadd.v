module fadd(
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y);

    wire [7:0] e1,e2;
    wire [22:0] mx1,mx2;
    assign e1 = x1[30:23];
    assign mx1 = x1[22:0];
    assign e2 = x2[30:23];
    assign mx2 = x2[22:0];

    // path1,2に使う
    wire [8:0] sm1;
    wire [7:0] sm2;
    wire [7:0] sm;
    assign sm1 = e1 - e2;
    assign sm2 = e2 - e1;
    assign sm = (sm1[8]) ? sm2: sm1[7:0];

    wire [7:0] e1a;
    wire [22:0] m1a,m2a;
    assign e1a = (sm1[8]) ? e2: e1;
    assign m1a = (sm1[8]) ? mx2: mx1;
    assign m2a = (sm1[8]) ? mx1: mx2;

    // path1 |e1 - e2| = 0 or 1 かつ 異符号
    wire [23:0] m1_01;
    wire [22:0] m1_02;
    assign m1_01 = mx1 - mx2;
    assign m1_02 = mx2 - mx1;

    wire [22:0] m1_0;
    assign m1_0 = (m1_01[23]) ? m1_02: m1_01[22:0];

    wire [24:0] m1_1;
    assign m1_1 = {1'b1,m1a,1'b0} - {2'b01,m2a};

    wire [24:0] m1;
    assign m1 = (sm1[0]) ? m1_1: {1'b0,m1_0,1'b0};

    function [7:0] SE1 (
	input [24:0] M1
    );
    begin
	casex(M1)
        25'b1xxxxxxxxxxxxxxxxxxxxxxxx: SE1 = 8'd0;
        25'b01xxxxxxxxxxxxxxxxxxxxxxx: SE1 = 8'd1;
	25'b001xxxxxxxxxxxxxxxxxxxxxx: SE1 = 8'd2;
	25'b0001xxxxxxxxxxxxxxxxxxxxx: SE1 = 8'd3;
	25'b00001xxxxxxxxxxxxxxxxxxxx: SE1 = 8'd4;
        25'b000001xxxxxxxxxxxxxxxxxxx: SE1 = 8'd5;
	25'b0000001xxxxxxxxxxxxxxxxxx: SE1 = 8'd6;
	25'b00000001xxxxxxxxxxxxxxxxx: SE1 = 8'd7;
	25'b000000001xxxxxxxxxxxxxxxx: SE1 = 8'd8;
	25'b0000000001xxxxxxxxxxxxxxx: SE1 = 8'd9;
	25'b00000000001xxxxxxxxxxxxxx: SE1 = 8'd10;
	25'b000000000001xxxxxxxxxxxxx: SE1 = 8'd11;
	25'b0000000000001xxxxxxxxxxxx: SE1 = 8'd12;
	25'b00000000000001xxxxxxxxxxx: SE1 = 8'd13;
	25'b000000000000001xxxxxxxxxx: SE1 = 8'd14;
	25'b0000000000000001xxxxxxxxx: SE1 = 8'd15;
	25'b00000000000000001xxxxxxxx: SE1 = 8'd16;
	25'b000000000000000001xxxxxxx: SE1 = 8'd17;
	25'b0000000000000000001xxxxxx: SE1 = 8'd18;
	25'b00000000000000000001xxxxx: SE1 = 8'd19;
	25'b000000000000000000001xxxx: SE1 = 8'd20;
	25'b0000000000000000000001xxx: SE1 = 8'd21;
	25'b00000000000000000000001xx: SE1 = 8'd22;
	25'b000000000000000000000001x: SE1 = 8'd23;
	25'b0000000000000000000000001: SE1 = 8'd24;
        25'b0000000000000000000000000: SE1 = 8'd255;
	endcase
    end
    endfunction

    wire [7:0] se1;
    assign se1 = SE1(m1);

    wire [24:0] mya1;
    assign mya1 = m1 << se1;

    wire [22:0] my1;
    assign my1 = mya1[23:1];
    
    wire [8:0] ey1a;
    assign ey1a = e1a - se1;

    wire [7:0] ey1;
    assign ey1 = (ey1a[8]) ? 8'b0: ey1a[7:0];

    // path2 その他
    wire [24:0] m2b;
    assign m2b = {1'b1,m2a,1'b0} >> sm;

    // pm : 0のとき +, 1のとき -
    wire pm;
    assign pm = x1[31] ^ x2[31];

    wire [25:0] mya2;
    assign mya2 = (pm) ? {2'b01,m1a,1'b0} - {1'b0,m2b}: {2'b01,m1a,1'b0} + {1'b0,m2b};

    wire [22:0] my2;
    assign my2 = (mya2[25]) ? mya2[24:2]:((mya2[24]) ? mya2[23:1]: mya2[22:0]);

    wire [7:0] ey2_p1,ey2_m1;
    assign ey2_p1 = e1a + 8'b1;
    assign ey2_m1 = (|e1a) ? e1a - 8'b1: 8'b0;

    wire [7:0] ey2;
    assign ey2 = (mya2[25]) ? ey2_p1: ((mya2[24]) ? e1a: ey2_m1); 

    // path選択
    wire flag1;
    assign flag1 = (sm[7:1] == 7'b0 & pm);

    wire sy;
    assign sy = (x1[30:0] > x2[30:0]) ? x1[31]: x2[31];

    wire [7:0] ey;
    assign ey = (flag1) ? ey1: ey2;

    wire [22:0] my;
    assign my = (flag1) ? my1: my2;

    assign y = {sy,ey,my};

endmodule
