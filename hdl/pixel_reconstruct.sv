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
	input wire 			camera_v_sync,
	input wire [7:0]		camera_data, 
	output logic			pixel_valid,
	output logic [HCOUNT_WIDTH-1:0]	pixel_h_count, 
	output logic [VCOUNT_WIDTH-1:0]	pixel_v_count,
	output logic [15:0]		pixel_data 
);
	
	// pclk previous value
	logic pclk_prev;
	logic pclk_edge;
	logic hsync_prev;
	logic hsync_negedge;
	logic last_valid_hs;

	// true on posedge of pclk, and h_sycn and v_sycn
	logic camera_sample_valid, camera_s_v;
	assign camera_sample_valid = camera_s_v;

	// hold a trigger
	logic trigger; 
	assign trigger = camera_h_sync == 1 && camera_v_sync == 1;

	
	

	//last byte from camera
	logic [7:0] last_sampled_data; 

	//has last byte been transmitted 
	logic half_pixel_ready;
	logic pclk_posedge;
	assign pclk_posedge = pclk_edge;

	// States 
	typedef enum {
		RESET = 0,  
		START_ROW = 1, 
		IN_ROW = 2, 
		END_ROW = 3,
		END_FRAME = 4
	}  b2p_state;

	b2p_state state, next_state; 

	always_comb begin 
		if(rst) next_state = RESET; 
		else begin 
			case(state)
				RESET: next_state = trigger ? START_ROW : state;
				START_ROW: next_state = half_pixel_ready ? IN_ROW : state;
				IN_ROW: next_state = trigger == 0 ? END_ROW : state;
				END_ROW: next_state = camera_h_sync == 1 ? START_ROW : camera_v_sync == 0 ?  END_FRAME :  state; 
				END_FRAME: next_state = trigger ? START_ROW : state; 
				default: next_state = RESET;
			endcase
		end
	end 

	always_ff@(posedge clk) begin 
		if(rst) begin
			state <= RESET;
			pixel_valid <= 0; 
			pixel_h_count <= 0;
			pixel_v_count <= 0;
			pixel_data <= 0;
		end else begin 
			state <= next_state;

			// store pclk
			pclk_prev <= camera_pclk; 

			// Monitor  pclk rising edge
			camera_s_v <= camera_pclk == 1 && pclk_prev == 0 && camera_h_sync == 1 && camera_v_sync == 1;

			pclk_edge <= camera_pclk == 1 && pclk_prev == 0;
			
			// state based pixel work
			if(state == RESET) begin 
			end else if( state == START_ROW) begin 
				pixel_h_count <= 0;
			end else if(state == IN_ROW) begin
				if(camera_sample_valid && half_pixel_ready) begin 
					pixel_valid <= 1;
					pixel_h_count <= pixel_h_count + 1;
				end else begin 
					pixel_valid <= 0;
				end 
			end else if (state == END_ROW) begin
				if(camera_h_sync == 0 && last_valid_hs == 1 && pclk_posedge) 
					pixel_v_count <= pixel_v_count + 1;
			end else if (state == END_FRAME) begin 
				pixel_v_count <= 0; 
			end 


			// When we get a valid sample 
			// Store the last sample 
			// if we have a half pixel ready, beam out a pixel and
			// post pixel valid
			if(camera_sample_valid) begin
				last_sampled_data <= camera_data;
				if(half_pixel_ready == 1) begin 
					half_pixel_ready <= 0; 
					pixel_data <= {last_sampled_data, camera_data};
				end else begin  
					half_pixel_ready <= 1;
				end 
			end 

			// store hs at pclk posedge 
			if(pclk_posedge) begin 
				last_valid_hs <= camera_h_sync; 
			end
		end
	end
endmodule 
`default_nettype wire
