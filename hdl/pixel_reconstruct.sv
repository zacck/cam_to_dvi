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
	logic hsync_prev; 
	logic vsync_prev;

	// true on posedge of pclk, and h_sycn and v_sycn
	logic camera_sample_valid;
	assign camera_sample_valid = camera_h_sync == 1  && camera_v_sync == 1 && pclk_prev == 0 && camera_pclk == 1;

	//last byte from camera
	logic last_sampled_hs; 
	logic [7:0] last_sampled_data; 

	//has last byte been transmitted 
	logic half_pixel_ready;

	always_ff@(posedge clk) begin 
		if(rst) begin
			pixel_valid <= 0; 
			pixel_h_count <= 0;
			pixel_v_count <= 0;
			pixel_data <= 0;

			// store pclk
			pclk_prev <= pclk; 
			hsync_prev <= camera_h_sync;

			// Increment v count and reset h count
			if(camera_h_sync == 0 && hsync_prev) begin 
				pixel_h_count <= 0; 
				pixel_v_count <= pixel_v_count + 1;
				half_pixel_ready <= 0;
			end

			// Reset v count 
			if(camera_v_sync == 0 && vsync_prev) begin 
				pixel_v_count <= 0;
				half_pixel_ready <= 0;
			end 


			// When we get a valid sample 
			// Store the last sample 
			// if we have a half pixel ready, beam out a pixel and
			// post pixel valid
			if(camera_sample_valid) begin
				last_sampled_data <= camera_data; 
				if(half_pixel_ready == 1) begin 
					half_pixel_ready <= 0; 
					pixel_valid <= 1; 
					pixel_data <= {camera_data, last_sampled_data};
				end else begin  
					pixel_valid <= 0;
				end 
			end 

			if(pixel_valid == 1) begin
				pixel_h_count <= pixel_h_count + 1;
			end
		end
	end
endmodule 
`default_nettype wire
