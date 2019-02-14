`timescale 1ns / 100ps
`default_nettype none

module divtest 
    #(parameter NSTAGE = 16)
    ();
    wire [31:0] y,old_y,z,old_z;
		logic [63:0] x1;
		logic [31:0] x2;
    logic clk;
		logic [4:0] counter;

    int i,j;
	

    div32 u1 (clk,x1, x2, y,z);
		
		assign old_y = x1/x2;
		assign old_z = x1%x2;

    // assertion
    always @(posedge clk) begin
        if (counter == NSTAGE && (old_y !== y || old_z != z)) begin
            $display("\nx1, x2 = %b %b", x1,x2);
            $display("expected: %b %b", old_y,old_z);
            $display("actual  : %b %b", y,z);
        end
    end


    initial begin
        #1;
        clk = 1;
        x1 = 0;
        x2 = 0;
        #1;
        clk = 0;
        #1;
        clk = 1;
        $display("random case");
        for (i=0; i<100000; i++) begin
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
