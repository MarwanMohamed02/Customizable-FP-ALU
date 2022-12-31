module shift_register
				#(	parameter Mantissa_Size, parameter Exponent_Size	)

				 (	output [Mantissa_Size:0] shiftedMantissa, output [Exponent_Size-1: 0] shiftedExponent,  // shifted outputs
				    output done, output underflow, // done flag that will be used by modules that use the shifter
				 	input clk, input enable, input load, input direction,  // flags
					input [Exponent_Size-1:0] exponent, // shifting left will shift the exponent with the mantissa
				 	input [Mantissa_Size:0] mantissa, input [Exponent_Size-1:0] no_of_shifts  // shifting right shifts the mantissa only
				);

	// to hold the data being shifted
	reg [Mantissa_Size:0]   mantissa_register;
	reg [Exponent_Size-1:0] exponent_register;
	
	// the count of shifts that will be executed, when remaining_shifts=0 the done flag is turned on
	reg [Exponent_Size-1:0] remaining_shifts;		

	// the flag that determines whether the shifting has finished 
	// this flag will be used in other modules (adder/subtractor, multiplier...etc.) to determine when the actual operation starts
	// done_flag = 0  -> nothing happens
	// done_flag = 1  -> start addition, subtraction...etc.
	reg done_flag;
	reg underflow_flag;
	
	
	always @ (posedge clk or posedge load or posedge enable) begin
	
		if (enable) begin
			
			// loading the mantissa to be shifted and the number of shifts as well as setting the done flag to 0
			if (load) begin
				mantissa_register <= mantissa;
				exponent_register <= exponent;
				remaining_shifts <= no_of_shifts;
				done_flag <= 1'b0;
				underflow_flag <= 0;
			end

			// continue shifting as long as done == 0
			else if (!done) begin

				if  (mantissa_register == 0)
					done_flag <= 1;

				else if  (exponent_register == 0) begin
					underflow_flag <= 1;
					mantissa_register <= 0;
					done_flag <= 1;
				end

				// if shifting will ultimately result in 0, return immediately
				else if (remaining_shifts >= Mantissa_Size) begin
					mantissa_register <= 0;
					done_flag <= 1'b1;
				end
				
				// if direction = 1, shift right a certain no. of shifts (exponent difference)
				else if (direction) begin

					if (remaining_shifts == 0)
						done_flag <= 1'b1;
					else begin
						mantissa_register <= {1'b0, mantissa_register[Mantissa_Size:1]};
						remaining_shifts <= remaining_shifts - 1;
					end	

				end

				// if direction = 0
				// shifting left is for the purpose of normalizing, therefore we keep shifting until a 1 is found & decrement the exponent
				else begin

					if (mantissa_register[Mantissa_Size])
						done_flag <= mantissa_register[Mantissa_Size];
					else begin
						mantissa_register <= {mantissa_register[Mantissa_Size-1:0], 1'b0};
						exponent_register <= exponent_register - 1;
					end

				end	

			end

		end	

	end
	
	
	assign shiftedMantissa = mantissa_register; 
	assign shiftedExponent = exponent_register; 
	assign underflow = underflow_flag;
	assign done = done_flag;
	
endmodule

