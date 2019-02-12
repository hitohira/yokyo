
module feq(
    input wire [31:0] x,
    input wire [31:0] y,
    output wire z
);
    assign z = x == y ? 1'b1 : 1'b0;
endmodule

module flt(
    input wire [31:0] x,
    input wire [31:0] y,
    output wire z
);
  	wire s1;
    wire s2;
    wire [7:0] e1;
    wire [7:0] e2;
    wire [22:0] m1;
    wire [22:0] m2;
    assign {s1,e1,m1} = x;
    assign {s2,e2,m2} = y;
    
    assign z = (s1 == 1'b1) && (s2 == 1'b0) ? 1'b1 :
               (s1 == 1'b0) && (s2 == 1'b1) ? 1'b0 :
               (s1 == 1'b0) && (e1 < e2) ? 1'b1 :
               (s1 == 1'b0) && (e1 == e2) && (m1 < m2) ? 1'b1 :
               (s1 == 1'b1) && (e1 > e2) ? 1'b1 :
               (s1 == 1'b1) && (e1 == e2) && (m1 > m2) ? 1'b1 :
               1'b0;
endmodule

module fle(
    input wire [31:0] x,
    input wire [31:0] y,
    output wire z
);
    wire t;
    flt FLT(y, x, t);
    assign z = ~t;
endmodule
