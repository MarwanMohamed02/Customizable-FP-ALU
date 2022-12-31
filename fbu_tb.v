module fbu_tb();

   parameter Mantissa_Size = 23;
	parameter Exponent_Size = 8;
   parameter N = Mantissa_Size + Exponent_Size;
	parameter T = 10;
	
	reg clk, enable, load;
	reg[1:0]op;

	reg [N:0] A;
	reg [N:0] B;

    reg [Exponent_Size-1:0] ER;
    reg [Mantissa_Size-1:0] MR;
    reg SR;

    wire [Mantissa_Size + Exponent_Size:0] result;
	
	 wire done;
    wire overflow;
    wire underflow;
    wire zero_flag;
	 wire NAN_flag;
	


	fpu #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size), .Bias(7'd127))fpu_UUT(
                                                                            .result(result),
                                                                            .done(done),
                                                                            .zero(zero_flag),
                                                                            .overflow(overflow),
                                                                            .underflow(underflow),
																	                         .NAN(NAN_flag),
                                                                            .clk(clk),
																									 .op(op),
                                                                            .enable(enable),
                                                                            .load(load),
                                                                            .A(A),
                                                                            .B(B)); 	
	
	
	always 
		#(T/2) clk = ~clk;
	

	
	initial begin
		
		 clk = 1'b0;
		 enable = 1'b1;
		 op = 2'b00;

        // This testbench will have 7 tests that are mostly edge cases and they are the following:
      
		  

        // 1) Normal Addition

        A = 32'b0_____1111_1110_____00000000000000000000000;
        B = 32'b0_____1111_1100_____11111100011101101111000;

		      load = 1'b1;
	
		#(T)  load = 1'b0;

				
		#(10*T)
            if (result == 32'b0__1111_1110__011_1111_1000_1110_1101_1110)
		      $display("Normal Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
		        SR = result[N];
              ER = result[N-1:N-Exponent_Size];
              MR = result[Mantissa_Size-1:0];
              $display("Normal Test Failed!\noverflow: %b  \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
              overflow,SR, ER, MR, 1'b0, 8'b1111_1110, 23'b011_1111_1000_1110_1101_1110, zero_flag, underflow, done, NAN_flag );
            end


        
        // 2) An operation with overflow   

        #(T)
            A = 32'b0_____1111_1110_____11111111111111111111111;
            B = 32'b0_____1111_1110_____00000000000000000000001;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow && ER == {(Exponent_Size){1'b1}} && MR == 0 && done) begin
                $display("Overflow Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            end
            else
                $display("Overflow Test Failed! \noverflow: %b   sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                overflow, SR, ER, MR, zero_flag, underflow, done, NAN_flag );



        // 3) Addition between two numbers with different exponents

        #(T)
            A = 32'b0_____1111_1110_____00000000000000000000000;
            B = 32'b0_____1111_1101_____00000000000000000000010;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                            SR, ER, MR, zero_flag, underflow, done, NAN_flag ); 
            end
            else if (done && result == 32'b0____1111_1110____1000_0000_0000_0000_0000_001)
		      $display("Diff Exp Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Diff Exp Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                        SR, ER, MR, 1'b0, 8'b1111_1110, 23'b1000_0000_0000_0000_0000_001, zero_flag, underflow, done, NAN_flag );
            end
		
        
        
        // 4) An operation that results in 0

        #(T)
            A = 32'b0_____1111_1110_____00000000000000000000111;
            B = 32'b1_____1111_1110_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);            
            end
            else if (result == 0 && zero_flag)
		      $display("Zero Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Zero Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                        SR, ER, MR, 1'b0, 8'b0000_0000, 23'b0000_0000_0000_0000_0000_000, zero_flag, underflow, done, NAN_flag );
            end
		
		
        
        // 5) Subtraction (A-B) where B > A
        #(T)
            A = 32'b0_____1111_1101_____00000000000000000001111;
            B = 32'b1_____1111_1110_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin

                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);
            
            end
            else if (result == 32'b1___1111_1101___0000_0000_0000_0000_0000_000 && done)
		        $display("Subtraction Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
                $display("Subtraction Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b1, 8'b1111_1101, 23'b0000_0000_0000_000, zero_flag, underflow, done, NAN_flag );
            end


        // 6) An operation with underflow
        #(T)
            A = 32'b0_____0000_0001_____00000000000000000001111;
            B = 32'b1_____0000_0001_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);
            
            end
            else if (result == 32'b0___0000_0000___0000_0000_0000_0000_0000_000 && done && underflow && zero_flag)
		      $display("Underflow Test Passed!!\n zf: %b  uf: %b  df: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Underflow Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b1, 8'b0000_0000, 23'b0000_0000_0000_000, zero_flag, underflow, done, NAN_flag);
            end

        // 7) An operation with infinities
        #(T)
            A = 32'b0_____1111_1111_____1xxxxxxxxxxxxxxxxxxxxxx;
            B = 32'b1_____0000_0001_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            // ER = 8'b1111_1111;
            // MR = 23'b1xxx_xxxx_xxxx_xxxx_xxxx_xxx;				
            // $display("MR: %b\nMT: %b\n %b", MR, {1'b1, { (Mantissa_Size-1){1'bx} }}, MR[0] === 1'bX);
				
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);      
            end
            else if (ER == {(Exponent_Size){1'b1}} && MR === {1'b1, { (Mantissa_Size-1){1'bx} }} && done && NAN_flag)
		      $display("Infinities Test Passed!!\n zf: %b  uf: %b  df: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Infinities Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b0, {(Exponent_Size){1'b1}}, {1'b1, { (Mantissa_Size-1){1'bx} }}, zero_flag, underflow, done, NAN_flag );
            end
				
	

////////////////////////////////////////////////Multiplication///////////////////////////////////////////
	
        // 1) Normal Multiplication

        A = 32'b0_____1100_0000_____00000000000000000000000;
        B = 32'b1_____0000_1100_____00000000000000000000000;
		  op = 2'd2;

		      load = 1'b1;
	
		#(T)  load = 1'b0;
				
				
		#(10*T)
            if (result == 32'b1__0100_1101__000_0000_0000_0000_0000_0000)
		      $display("Normal Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
		      SR = result[N];
              ER = result[N-1:N-Exponent_Size];
              MR = result[Mantissa_Size-1:0];
              $display("Normal Test Failed!\n\ngot:         sign:   %b  exp:    %b  m:  %b        \ncorrect:     sign:   %b  exp:    %b  m:  %b\n of: %b  zf: %b  uf: %b  df: %b NAN: %b", 
              overflow,SR, ER, MR, 1'b1, 8'b0001_1000, 23'b011_1111_1000_1110_1101_1110, overflow, zero_flag, underflow, done, NAN_flag );
            end


        
        // 2) An operation with overflow   

        #(T)
            A = 32'b0_____1111_1110_____00000000000110000000000;
            B = 32'b0_____1000_0010_____01100000000000000000001;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow && ER == {(Exponent_Size){1'b1}} && MR == 0 && done) begin
                $display("Overflow Test Passed!!\n of: %b  zf: %b  uf: %b  df: %b NAN: %b", overflow, zero_flag, underflow, done, NAN_flag );
            end
            else
                $display("Overflow Test Failed! \noverflow: %b   sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                overflow, SR, ER, MR, zero_flag, underflow, done, NAN_flag );

        
        
        // 3) An operation that results in 0

        #(T)
            A = 32'b0_____0000_0000_____00000000000000000000000;
            B = 32'b0_____1111_1110_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(10*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);            
            end
            else if (result == 0 && zero_flag)
		      $display("Zero Test Passed!!\n zf: %b  uf: %b  df: %b NAN: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Zero Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b", 
                        SR, ER, MR, 1'b0, 8'b0000_0000, 23'b0000_0000_0000_0000_0000_000, zero_flag, underflow, done, NAN_flag );
            end
		


        // 4) An operation with underflow
        #(T)
            A = 32'b0_____0000_0101_____00000000000000000001111;
            B = 32'b1_____0010_0001_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);
            
            end
            else if (result == 32'b1___0000_0000___0000_0000_0000_0000_0000_000 && done && underflow && zero_flag)
		      $display("Underflow Test Passed!!\n zf: %b  uf: %b  df: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Underflow Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b1, 8'b0000_0000, 23'b0000_0000_0000_000, zero_flag, underflow, done, NAN_flag);
            end

        // 5) An operation with infinities
        #(T)
            A = 32'b0_____1111_1111_____1xxxxxxxxxxxxxxxxxxxxxx;
            B = 32'b1_____0000_0001_____00000000000000000000111;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            // ER = 8'b1111_1111;
            // MR = 23'b1xxx_xxxx_xxxx_xxxx_xxxx_xxx;				
            // $display("MR: %b\nMT: %b\n %b", MR, {1'b1, { (Mantissa_Size-1){1'bx} }}, MR[0] === 1'bX);
				
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);      
            end
            else if (ER == {(Exponent_Size){1'b1}} && MR === {1'b1, { (Mantissa_Size-1){1'bx} }} && done && NAN_flag)
		      $display("Infinities Test Passed!!\n zf: %b  uf: %b  df: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Infinities Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b0, {(Exponent_Size){1'b1}}, {1'b1, { (Mantissa_Size-1){1'bx} }}, zero_flag, underflow, done, NAN_flag );
            end


        // 6) An operation with infinity & zero
        #(T)
            A = 32'b0_____1111_1111_____1xxxxxxxxxxxxxxxxxxxxxx;
            B = 32'b0_____0000_0000_____00000000000000000000000;

            load = 1'b1;
	
		#(T)    
            load = 1'b0;

        #(20*T)
            // ER = 8'b1111_1111;
            // MR = 23'b1xxx_xxxx_xxxx_xxxx_xxxx_xxx;				
            // $display("MR: %b\nMT: %b\n %b", MR, {1'b1, { (Mantissa_Size-1){1'bx} }}, MR[0] === 1'bX);
				
            SR = result[N];
            ER = result[N-1:N-Exponent_Size];
            MR = result[Mantissa_Size-1:0];
            if (overflow) begin
                $display("Wrong Overflow!!\nsign:   %b  exp:    %b  m:  %b", 
                            SR, ER, MR);      
            end
            else if (ER == {(Exponent_Size){1'b1}} && MR === {1'b1, { (Mantissa_Size-1){1'bx} }} && done && NAN_flag)
		      $display("Infinity*0 Test Passed!!\n zf: %b  uf: %b  df: %b", zero_flag, underflow, done, NAN_flag );
            else begin
              $display("Infinity*0 Test Failed! \ngot:         sign:   %b  exp:    %b  m:  %b         \ncorrect:     sign:   %b  exp:    %b  m:  %b\n zf: %b  uf: %b  df: %b NAN: %b" 
                       ,SR, ER, MR, 1'b0, {(Exponent_Size){1'b1}}, {1'b1, { (Mantissa_Size-1){1'bx} }}, zero_flag, underflow, done, NAN_flag );
            end

            
		
	
	end
	
			

endmodule 