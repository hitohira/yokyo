module sim_uart_sub(
	input wire clk,
	input wire rstn,
	
	input wire [31:0] addr,
	input wire [31:0] din,
	output reg [31:0] dout,
	input wire en,
	input wire [3:0] we,

	output reg err
	);
	reg tx;
	
	reg [31:0] tmp_dout;

	reg [8:0] counter;
	
	reg [31:0] tx_fifo [15:0]; 
	reg [31:0] rx_fifo [15:0]; 
	reg [31:0] stat_reg;
	reg [31:0] ctrl_reg;
	
	reg [3:0] tx_head;
	reg [3:0] tx_tail;
	reg [3:0] rx_head;
	reg [3:0] rx_tail;
		
	wire tx_full;
	wire tx_empty;
	wire rx_full;
	wire rx_valid;
	
	wire [3:0] tx_head_1;
	wire [3:0] rx_head_1;

	assign tx_head_1 = tx_head + 1'b1;
	assign rx_head_1 = rx_head + 1'b1;

	assign tx_full = tx_head_1 == tx_tail;
	assign tx_empty = tx_head == tx_tail;
	assign rx_full = rx_head_1 == rx_tail;
	assign rx_valid = rx_head != rx_tail;

	always @(posedge clk) begin
		if(~rstn) begin
			dout <= 0;
			counter <= 0;
			rx_head <= 0;
			tx_tail <= 0;
			tx <= 0;
			for(i=0;i<16;i=i+1)begin
				rx_fifo[i] <= 0;
			end
		end else if(en) begin
				if (addr == 32'hc && din[1]) begin
					for(i=0;i<16;i=i+1) begin
						rx_fifo[i] <= 0;
					end
				end
			dout <= tmp_dout;
		end else begin
			dout <= tmp_dout;
			counter <= counter + 1;
			if(counter == 0) begin
				if(!tx_empty) begin
					tx_tail <= tx_tail + 1;
					tx <= tx_fifo[tx_tail];
				end
				if(!rx_full) begin
					// if you want to get data, fill in
					rx_fifo[rx_head] <= 5;
					rx_head <= rx_head + 1;
				end
			end
		end
	end

	integer i;

	always @(posedge clk) begin
		if(~rstn) begin
			for(i=0;i<16;i=i+1)begin
				tx_fifo[i] <= 0;
			end
			stat_reg <= 0;
			ctrl_reg <= {29'b0,1'b1,2'b0};
			
			tx_head <= 0;
			rx_tail <= 0;
			
			tmp_dout <= 0;
			err <= 0;
		end else if (en) begin
			if(addr == 32'h0) begin //rx
				if(!rx_valid) begin
					err <= 1;
				end
				tmp_dout <= rx_fifo[rx_tail];
				rx_tail <= rx_tail + 1;
			end else if(addr == 32'h4) begin //tx
				if(tx_full) begin
					err <= 1;
				end
				tmp_dout <= 0;
				tx_fifo[tx_head] <= din;
				tx_head <= tx_head + 1;

			end else if(addr == 32'h8) begin // stat
				tmp_dout <= {28'b0,tx_full,tx_empty,rx_full,rx_valid};

			end else if(addr == 32'hc) begin // ctrl
				tmp_dout <= 0;
				if (din[0]) begin
					for(i=0;i<16;i=i+1) begin
						tx_fifo[i] <= 0;
					end
				end
			end else begin
				err <= 1;
			end
		end
	end

endmodule
