`timescale 1ns / 1ps
`default_nettype none

// Testing 
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif /* ! SYNTHESIS */


module image_sprite #(
	parameter WIDTH=256, HEIGHT=256)
	(
		input wire pixel_clk,
		input wire rst, 
		input wire [10:0] x, h_count,
		input wire [9:0] y, v_count, 
		output logic [7:0] pixel_red, 
		output logic [7:0] pixel_green, 
		output logic [7:0] pixel_blue
	);	


	// get ROM location
	logic [$clog2(WIDTH*HEIGHT)-1: 0] image_addr;
	assign image_addr = (h_count - x) + ((v_count - y) * WIDTH); 
	logic [7:0] pallet_addr;
	logic [23:0] color_out;


	logic in_sprite; 
	assign in_sprite = ((h_count >= x && h_count < (x + WIDTH)) &&
		(v_count >= y && v_count< (y + HEIGHT)));


	// Add image data
	xilinx_single_port_ram_read_first #(
		.RAM_WIDTH(24),
		.RAM_DEPTH(256), 
		.RAM_PERFORMANCE("HIGH_PERFORMANCE"), 
		.INIT_FILE(`FPATH(palette.mem))
	) pallette_rom (
		.addra(pallet_addr),
		.dina(1'b0), 
		.clka(pixel_clk), 
		.wea(1'b0),
		.ena(1'b1),
		.rsta(rst), 
		.regcea(1'b1),
		.douta(color_out) 
	);

	xilinx_single_port_ram_read_first #(
		.RAM_WIDTH(8),
		.RAM_DEPTH(525_288), 
		.RAM_PERFORMANCE("HIGH_PERFORMANCE"), 
		.INIT_FILE(`FPATH(image.mem))
	) image_rom (
		.addra(image_addr),
		.dina(1'b0), 
		.clka(pixel_clk), 
		.wea(1'b0),
		.ena(1'b1),
		.rsta(rst), 
		.regcea(1'b1),
		.douta(pallet_addr)
	); 

	
	// Load pixels from ROM 
	assign pixel_red = in_sprite ? color_out[23:16] : 0;
	assign pixel_green = in_sprite ? color_out[15:8] : 0; 
	assign pixel_blue = in_sprite ? color_out[7:0] : 0; 
endmodule
`default_nettype none


