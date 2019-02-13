module mul_pre (
    input wire [31:0] r1,
    input wire [31:0] r2,
    output reg [35:0] ll,
    output reg [31:0] lh,
    output reg [31:0] hl,
    output reg [27:0] hh,
    input wire CLK);

    reg [13:0] ha1, ha2; // 31:18
    reg [17:0] lo1, lo2;

    reg [35:0] lolo [0:0]; // 35:0
    reg [31:0] loha [0:0]; // 49:18
    reg [31:0] halo [0:0]; // 49:18
    reg [27:0] haha [0:0]; // 63:36

    always @(posedge CLK) begin
        {ha1, lo1} <= r1;
        {ha2, lo2} <= r2;
        
        lolo[0] <= lo1 * lo2;
        loha[0] <= lo1 * ha2;
        halo[0] <= ha1 * lo2;
        haha[0] <= ha1 * ha2;

        ll <= lolo[0];
        lh <= loha[0];
        hl <= halo[0];
        hh <= haha[0];
    end
endmodule

module mul (
    input wire [31:0] r1,
    input wire [31:0] r2,
    output reg [31:0] rd,
    input CLK);

    wire [35:0] ll; // 35:0
    wire [31:0] lh; // 49:18
    wire [31:0] hl; // 49:18
    wire [27:0] hh; // 63:36
    mul_pre mp (r1, r2, ll, lh, hl, hh, CLK);

    always @(posedge CLK) begin
        rd[17:0] <= ll[17:0];
        rd[31:18] <= ll[31:18] + lh[13:0] + hl[13:0];
    end
endmodule
