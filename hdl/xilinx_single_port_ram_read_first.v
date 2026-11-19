// Single port read first memory 
// Power can be saved by setting the correct WRITE_MODE 

module xilinx_single_port_ram_read_first #(
	parameter RAM_WIDTH = 18, 
	parameter RAM_DEPTH = 1024, 
	parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE",
	parameter INIT_FILE = "" 			// Initialization data for our ROM
) (
	input [clogb2(RAM_DEPTH-1)-1:0] addra,
	input [RAM_WIDTH-1:0] dina, 
	input clka, 
	input wea,
	input ena,
	input rsta,
	input regcea, 
	output [RAM_WIDTH-1:0] douta
); 
	reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
	reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

	// initialize memory according to file or match hardware
	generate
		if(INIT_FILE != "") begin: use_init_file
			initial 
				$readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
		end else begin: init_bram_to_zero 
			integer ram_index;
			initial 
				for(ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
					BRAM[ram_index] = {RAM_WIDTH{1'b0}};
		end
	endgenerate

	always @(posedge clka)
		if(ena) begin
			if (wea)
				BRAM[addra] <= dina;
			ram_data <= BRAM[addra];
		end

	
	// generate HIGH_PERFORMANCE or LOW_LATENCY
	generate 
		if(RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register
			//1 clock read latency 
			assign douta = ram_data; 

		end else begin: output_register
			// 2 clock cycle read latency
			reg [RAM_WIDTH-1:0] douta_reg = {RAM_WIDTH{1'b0}}; 

			always @(posedge clka)
				if(rsta) 
					douta_reg <= {RAM_WIDTH{1'b0}};
				else if (regcea)
					douta_reg <= ram_data; 
				assign douta = douta_reg;
		end
	endgenerate

	// calculate the address based on the RAM  depth 
	function integer clogb2;
		input integer depth;
		for(clogb2=0; depth>0; clogb2=clogb2+1)
			depth = depth >> 1; 
	endfunction
endmodule 



