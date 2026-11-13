`timescale 1ns /1 ps
`default_nettype none
module pixel_reconstruct
#(
	parameter HCOUNT_WIDTH = 11, 
	parameter VCOUNT_WIDTH = 10
)
(
	input wire 			clk, 
	input wire 			rst,
	input wire			camera_pclk, 
	input wire 			camera_h_sync, 
	input wire [7:0]		camera_data, 
	output logic			pixel_valid,
	output logic [HCOUNT_WIDTH-1:0]	pixel_h_count, 
	output logic [VCOUNT_WIDTH-1:0]	pixel_v_count,
	output logic [15:0]		pixel_data, 
);
	
	// pclk previous value
	logic pclk_prev; 
	// true on posedge of pclk
	logic camera_sample_valid;
	assign camera_sample_valid = 0;

	//last byte from camera
	logic last_sampled_hs; 
	logic [7:0] last_sampled_data; 

	//has last byte been transmitted 
	logic half_pixel_ready;

	always_ff@(posedge clk) begin 
		if(rst) begin
		end else begin 
			if(camer_sample_valid) begin
			end 
		end
	end
endmodule 
`default_nettype wire
