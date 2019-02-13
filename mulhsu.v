module mulhsu_pre ( // latency 4
    input wire [31:0] rs1,
    input wire [31:0] r2,
    output reg [31:0] ll,
    output reg [33:0] lh,
    output reg [33:0] hl,
    output reg [31:0] hh,
    input wire CLK);

    reg signed [15:0] ha1; // 31:16
    reg [15:0] ha2;
    reg [15:0] lo1, lo2;

    wire signed [16:0] lo1x, lo2x;
    assign lo1x = {1'b0, lo1};
    assign lo2x = {1'b0, lo2};

    wire signed [16:0] ha1x, ha2x;
    assign ha1x = {ha1[15], ha1};
    assign ha2x = {1'd0, ha2};

    reg [31:0] lolo [0:0]; // 31:0
    reg [33:0] loha [0:0]; // 48:16
    reg [33:0] halo [0:0]; // 48:16
    reg [31:0] haha [0:0]; // 63:32

    always @(posedge CLK) begin
        {ha1, lo1} <= rs1;
        {ha2, lo2} <= r2;
        
        lolo[0] <= lo1 * lo2;
        loha[0] <= lo1x * ha2x;
        halo[0] <= ha1x * lo2x;
        haha[0] <= ha1x * ha2x;

        ll <= lolo[0];
        lh <= loha[0];
        hl <= halo[0];
        hh <= haha[0];
    end
endmodule

module mulhsu (
    input wire [31:0] rs1,
    input wire [31:0] r2,
    output reg [31:0] rd,
    input clk);

    wire [31:0] ll;
    wire [33:0] lh;
    wire [33:0] hl;
    wire [31:0] hh;

    mulhsu_pre mp (rs1, r2, ll, lh, hl, hh, clk);

    reg [33:0] lower;
    reg [31:0] higher1, higher2;

    always @(posedge clk) begin
        lower[15:0] <= ll[15:0];
        lower[33:16] <= {2'd0, ll[31:16]} + {2'd0, lh[15:0]} + {2'd0, hl[15:0]};
        higher1 <= {{14{lh[33]}}, lh[33:16]} + {{14{hl[33]}}, hl[33:16]};
        higher2 <= hh;
        rd <= higher1 + higher2 + {30'd0, lower[33:32]};
    end
endmodule
