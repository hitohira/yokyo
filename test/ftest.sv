`timescale 1ns / 100ps
`default_nettype none

module ftest 
    #(parameter NSTAGE = 7)
    ();
    wire [31:0] y,old_y;
		logic [31:0] x1,x2;
    logic clk;
		logic rstn;
		logic [4:0] counter;

    int i,j;


    fadd u_new (clk,x1, x2, y);
		fadd_old u_old (x1,x2,old_y);


    // assertion
    always @(posedge clk) begin
        if (counter == NSTAGE && old_y !== y) begin
            $display("x1, x2 = %b %b", x1,x2);
            $display("expected: %b", old_y);
            $display("actual  : %b", y);
        end
    end


    initial begin
        #1;
				rstn = 0;
        clk = 1;
        x1 = 0;
        x2 = 0;
        #1;
        clk = 0;
        #1;
				rstn = 1;
        clk = 1;
        $display("random case");
        for (i=0; i<10000000; i++) begin
            x1 = $urandom();
            x2 = $urandom();
						counter <= 0;
						for (j=0;j<=NSTAGE;j=j+1) begin
           	 	 #1;
           	 	 clk = 0;
           	 	 #1;
           		 clk = 1;
							 counter <= counter + 1;
						end
           	#1;
           	clk = 0;
           	#1;
           	clk = 1;
        end
        $display("finish");
    end
endmodule
`default_nettype wire
