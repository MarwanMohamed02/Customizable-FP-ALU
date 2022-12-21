module shift_register_tb();

	parameter Mantissa_Size = 23;
	parameter Exponent_Size = 8;
	parameter T = 10;
	
	reg clk, enable, load, direction;

	reg [Mantissa_Size:0] seed;

	reg [Exponent_Size-1: 0] no_of_shifts;

	wire [Mantissa_Size:0] output_data;

	wire done;
	
	
	shift_register #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size)) shift_register_UUT(	
																		.shifted(output_data),
																		.done(done),
																		.clk(clk),
																		.enable(enable),
																		.load(load),
																		.unshifted(seed),
																		.direction(direction),
																		.no_of_shifts(no_of_shifts) 					);
			
	always 
		#(T/2) clk = ~clk;
	

	
	initial begin
		
		// $monitor("%d", done);
		clk = 1'b0;
		enable = 1'b1;
	
		
		// a size 24 is given to the register because there is an extra hard-coded bit (1.m)
		
		
		// testing shift right operation 
		seed = 24'b0110_1110_0010_1010_1110_0110;
		no_of_shifts = 7'b0000101;
		direction = 1'b1;	
		load = 1'b1;
	
		#(T)  	load = 1'b0;

		#(5*T)
				if (output_data == 24'b0000_0011_0111_0001_0101_0111)
					$display("Test 1 Passed!!");
				else
					$display("Test 1 Failed!");

		// testing normalizer
		// the normailzer shifts left until it reaches the first 1
		#(T) 	seed = 24'b0000_0110_0010_1010_1110_0110;
				no_of_shifts = 7'b0000110;
				direction = 1'b0;	
				load = 1'b1;

		#(T)  	load = 1'b0;

		#(6*T) 	
				if (output_data == 24'b1100_0101_0101_1100_1100_0000)
					$display("Test 2 Passed!!");
				else
					$display("Test 2 Failed! \n got: \t %b\n correct:\t %b", output_data,24'b1100_0101_0101_1100_1100_0000);
	
		
	
	end
														
	

	
		
endmodule 