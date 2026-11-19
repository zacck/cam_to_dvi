`timescale 1ns / 1ps
`default_nettype none

module top_level(
	input wire clk_100mhz, 
	input wire [15:0] sw, 
	input wire [3:0] btn, 
	output logic [15:0] led, 
	output logic [2:0] hdmi_tx_p, 
	output logic [2:0] hdmi_tx_n, 
	output logic hdmi_clk_n, hdmi_clk_p

	//output logic [6:0] ss0_c,
	//output logic [6:0] ss1_c,
	//output logic [3:0] ss0_an,
	//output logic [3:0] ss1_an
);
	// switch indicator
	assign led = sw; 
	
	// system reset
	logic sys_rst; 
	assign sys_rst = btn[0];

	//Clocking 
	logic clk_pixel, clk_5x;
	logic locked; 

	// generate hdmi clock
	hdmi_clk_wiz_720p hdmicw (
		.clk_pixel(clk_pixel), 
		.clk_tmds(clk_5x),
		.reset(0), 
		.locked(locked), 
		.clk_ref(clk_100mhz)
	);

	// video signals 
	logic [10:0] h_count; 
	logic [9:0] v_count; 
	logic v_sync; 
	logic h_sync; 
	logic active_draw; 
	logic new_frame; 
	logic [5:0] frame_count; 


	// video signal generator
	video_sig_gen vsg(
		.pixel_clk(clk_pixel),
		.rst(sys_rst), 
		.h_count(h_count), 
		.v_count(v_count), 
		.h_sync(h_sync), 
		.v_sync(v_sync), 
		.active_draw(active_draw),
		.frame_count(frame_count)
	); 

	logic [7:0] img_red, img_blue, img_green;

	// image sprite locations 
	logic [10:0] x_com;
	logic [9:0] y_com; 
	logic pop;

	// update center of mass  
	always_ff @(posedge clk_pixel) begin
		if(sys_rst) begin
			x_com <= 0; 
			y_com <= 0; 
		end if(btn[1]) begin 
			// random popcat showing
		end 
	end


	// popcat
	logic [10:0] sprite_x; 
	logic [9:0] sprite_y; 

	// check bounds 
	assign sprite_x = x_com > 128 ? x_com-128 : 0;
	assign sprite_y = y_com > 128 ? y_com-128 : 0;

	image_sprite #(
		.WIDTH(256), 
		.HEIGHT(256)
	)
	com_sprite_m (
		.pixel_clk(clk_pixel),
		.rst(sys_rst),
		.h_count(h_count), 
		.v_count(v_count),
		.x(sprite_x), 
		.y(sprite_y), 
		.pixel_red(img_red), 
		.pixel_green(img_green), 
		.pixel_blue(img_blue)
	);


	logic [7:0] red, green, blue; 
	
	assign red = img_red; 
	assign green = img_green; 
	assign blue = img_blue;

	logic [9:0] tmds_10b [0:2]; 
	logic tmds_signal [2:0]; 

	// assign tmds_encoders 
    	tmds_encoder tmds_red(
        	.clk(clk_pixel),
        	.rst(sys_rst),
        	.video_data(red),
        	.control(2'b0),
        	.video_enable(active_draw),
        	.tmds(tmds_10b[2]));

    	tmds_serializer red_ser(
        	.clk_pixel(clk_pixel),
        	.clk_5x(clk_5x),
        	.rst(sys_rst),
       		.tmds_in(tmds_10b[2]),
        	.tmds_out(tmds_signal[2]));

    	tmds_encoder tmds_green(
 		.clk(clk_pixel),
        	.rst(sys_rst),
        	.video_data(green),
        	.control(2'b0),
        	.video_enable(active_draw),
        	.tmds(tmds_10b[1]));

    	tmds_serializer green_ser(
		.clk_pixel(clk_pixel),
		.clk_5x(clk_5x),
		.rst(sys_rst),
		.tmds_in(tmds_10b[1]),
		.tmds_out(tmds_signal[1]));

    
	tmds_encoder tmds_blue(
		.clk(clk_pixel),
		.rst(sys_rst),
		.video_data(blue),
		.control({v_sync, h_sync}),
		.video_enable(active_draw),
		.tmds(tmds_10b[0]));

    	tmds_serializer blue_ser(
		.clk_pixel(clk_pixel),
		.clk_5x(clk_5x),
		.rst(sys_rst),
		.tmds_in(tmds_10b[0]),
		.tmds_out(tmds_signal[0]));

    	//output buffers generating differential signal:
    	OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    	OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    	OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    	OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

	//assign ss0_c = 0;
	//assign ss1_c = 0;

endmodule 
`default_nettype wire
