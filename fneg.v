module fsgnj(
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y
    );
    assign y = {x2[31], x1[30:0]};
endmodule

module fsgnjn(
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y
    );
    assign y = {~x2[31], x1[30:0]};
endmodule
