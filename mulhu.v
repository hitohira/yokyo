// using mul_pre from mul32.v
module mulhu ( // latency 4
    input wire [31:0] r1,
    input wire [31:0] r2,
    output reg [31:0] rd,
    input clk);

    wire [35:0] ll; // 35:0
    wire [31:0] lh; // 49:18
    wire [31:0] hl; // 49:18
    wire [27:0] hh; // 63:36
    mul_pre mp (r1, r2, ll, lh, hl, hh, clk);

    reg [33:0] lower;
    reg [31:0] higher1, higher2;

    always @(posedge clk) begin
        lower[17:0] <= ll[17:0];
        lower[33:18] <= {2'b00, ll[31:18]} + {2'b00, lh[13:0]} + {2'b00, hl[13:0]};
        higher1 <= {14'd0, lh[31:14]} + {14'd0, hl[31:14]} + {28'd0, ll[35:32]};
        higher2 <= {hh[27:0], 4'b0000};
        rd <= higher1 + higher2 + {30'd0, lower[33:32]};
    end
endmodule
