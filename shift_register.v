module shift_register
				#(	parameter Mantissa_Size, parameter Exponent_Size	)

				 (	output [Mantissa_Size:0] shifted, output done, 
				 	input clk, input enable, input load, 
				 	input [Mantissa_Size:0] unshifted, input direction, input [Exponent_Size-1:0] no_of_shifts	);

	// to hold the data being shifted
	reg [Mantissa_Size:0] register;
	
	// the count of shifts that will be executed, when remaining_shifts=0 the done flag is turned on
	reg [Exponent_Size-1:0]remaining_shifts;		

	// the flag that determines whether the shifting has finished 
	// this flag will be used in other modules (adder/subtractor, multiplier...etc.) to determine when the actual operation starts
	// done_flag = 0  -> nothing happens
	// done_flag = 1 -> start addition, subtraction...etc.
	reg done_flag;
	
	
	always @ (posedge clk or posedge load or posedge enable) begin
	
		if (enable) begin
			
			// loading the mantissa to be shifted and the number of shifts as well as setting the done flag to 0
			if (load) begin
				register <= unshifted;
				remaining_shifts <= no_of_shifts;
				done_flag <= 1'b0;
			end
			// continue shifting as long as done == 0
			else if (!done) begin
				// if shifting will ultimately result in 0, return immediately
				if (remaining_shifts >= Exponent_Size) begin
					register <= 0;
					done_flag <= 1'b1;
				end
				
				// if direction = 1, shift right a certain no. of shifts
				else if (direction) begin
					if (remaining_shifts == 0)
						done_flag <= 1'b1;
					else begin
						register <= {1'b0, register[Mantissa_Size:1]};
						remaining_shifts <= remaining_shifts - 1;
					end	
				end

				// shifting left is for the purpose of normalizing, therefore we keep shifting until a 1 is found
				else begin

					if (register[Mantissa_Size])
						done_flag <= register[Mantissa_Size];
					else
						register <= {register[Mantissa_Size-1:0], 1'b0};

				end	
			end
		end	
		
	end
	
	
	assign shifted = register;
	assign done = done_flag;
	
	
endmodule

