`timescale 1ns / 1ps
module sprite1(
	input  clk, en,
	input [14-1:0] addr,
	output reg [12-1:0] dataout);

	parameter RAM_WIDTH = 12; //12bit rgb
	parameter RAM_ADDR_BITS = 14; //2^14 = 16384

	reg [RAM_WIDTH-1:0] image [(2**RAM_ADDR_BITS)-1:0];

	initial begin
		$readmemb("sprite1.bin", image, 0, (2**RAM_ADDR_BITS)-1);
	end

	always @(posedge clk) begin
		if (en) begin
			dataout <= image[addr];
		end
	end
	
endmodule