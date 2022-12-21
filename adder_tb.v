module adder_tb();

    parameter Mantissa_Size = 23;
	parameter Exponent_Size = 8;
    parameter N = Mantissa_Size + Exponent_Size;
	parameter T = 10;
	
	reg clk, enable, load;

	reg [N:0] A;
	reg [N:0] B;

    reg [Exponent_Size-1:0] ER;
    reg [Mantissa_Size-1:0] MR;
    reg SR;

    wire [Mantissa_Size + Exponent_Size:0] result;
	
	wire done;
    wire overflow;
	
	adder #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size)) adder_UUT(
                                                                            .result(result),
                                                                            .done(done),
                                                                            .overflow(overflow),
                                                                            .clk(clk),
                                                                            .enable(enable),
                                                                            .load(load),
                                                                            .A(A),
                                                                            .B(B)       );
			
	always 
		#(T/2) clk = ~clk;
	

	
	initial begin
		
		// $monitor("%d", done);
		clk = 1'b0;
		enable = 1'b1;

        A = 32'b0_____0111_1100_____11111100011101101110110;
        B = 32'b0_____0111_1100_____11111100011101101111000;

		load = 1'b1;
	
		#(T)  load = 1'b0;
				
				
		// #(10*T)
		//       $display("%b \n %b", result, 32'b1_01111100_00000000000000000000010);
		
		#(10*T)
            if (result == 32'b0_01111101__1111_1100_0111_0110_1110_111)
		      $display("Test 1 Passed!!");
            else begin
		      SR = result[N];
              ER = result[N-1:N-Exponent_Size];
              MR = result[Mantissa_Size-1:0];
              $display("Test 1 Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b", 
              SR, ER, MR, 1'b0, 8'b01111101, 23'b1111_1100_0111_0110_1110_111);
            end

        #(T)
            A = 32'b0_____1111_1111_____11111111111111111111111;
            B = 32'b0_____1111_1111_____00000000000000000000001;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            if (overflow) begin
                SR = result[N];
                ER = result[N-1:N-Exponent_Size];
                MR = result[Mantissa_Size-1:0];
                $display("Test 2 passed!!");
            end
            else
                $display("Test 2 Failed!\noverflow: %b   sign:   %b  exp:    %b  m:  %b", 
                overflow, SR, ER, MR);
            
            
        #(T)
            A = 32'b0_____1111_1110_____00000000000000000000000;
            B = 32'b0_____1111_1101_____00000000000000000000010;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            if (overflow) begin
                SR = result[N];
                ER = result[N-1:N-Exponent_Size];
                MR = result[Mantissa_Size-1:0];

                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);
            
            end
            else if (result == 32'b0____1111_1110____1000_0000_0000_0000_0000_001)
		      $display("Test 3 Passed!!");
            else begin
		      SR = result[N];
              ER = result[N-1:N-Exponent_Size];
              MR = result[Mantissa_Size-1:0];
              $display("Test 3 Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b", 
                        SR, ER, MR, 1'b0, 8'b1111_1110, 23'b1000_0000_0000_0000_0000_001);
            end
		
		
		
		
	
	end
			

endmodule 