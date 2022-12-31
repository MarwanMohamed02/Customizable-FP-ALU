module mult
        #(  parameter Mantissa_Size = 23, parameter Exponent_Size = 8, 
            parameter Bias = 127, parameter Product_Size = (Mantissa_Size+1)*2,
            parameter N = Mantissa_Size + Exponent_Size)

        (   output done, zero, overflow, underflow, NAN,
            output [N:0] result, 
            input clk, enable, load, 
            input [N:0] A, B            );
					 

    // for storing each individual part of the encoded floating point number
    // EA -> exponent of A, MR -> mantissa of Result... and so on
    reg [Exponent_Size-1:0] EA, EB, ER;     // exponents 
    reg [Mantissa_Size:0] MA, MB, MR;       // mantissas
    reg SA, SB, SR;                         // signs

    // intermediate registers with bigger size 
    reg [Product_Size-1:0] MP; 
    reg [Exponent_Size:0]  EP;
 

    // flags for the adder itself
    reg done_mult;
    reg zero_flag;
    reg overflow_flag;
    reg underflow_flag;
    reg NAN_flag;
 


    
    always @ (posedge clk or posedge load or posedge enable) begin
        
        if (enable) begin
            if (load) begin
                // loading each component of the encoded fp numbers
                SA = A[N];
                SB = B[N];

                // the sign bit is computed in this manner regardless of other inputs so will be done here
                SR = SA ^ SB;
                
                EA = A[N-1:N-Exponent_Size];
                EB = B[N-1:N-Exponent_Size];

                MA = {1'b1,A[Mantissa_Size-1:0]};
                MB = {1'b1,B[Mantissa_Size-1:0]};

                // intital flags state
                done_mult = 0;
                NAN_flag <= 0;
                zero_flag = 0;
                overflow_flag = 0;
                underflow_flag <= 0;



                // checking for NAN && infinities 
                if ((EA == {(Exponent_Size){1'b1}}) || (EB == {(Exponent_Size){1'b1}})) begin

                    if (MA[0] === 1'bX || MB[0] === 1'bX || EA == 0 || EB == 0)  begin
                        NAN_flag <= 1;    
                        MR = {2'b11, { (Mantissa_Size-1){1'bx} }};

                    end
                    else  begin
                        overflow_flag = 1;
                        MR = 0;
                    end
                    
                    ER = {(Exponent_Size){1'b1}};
                    done_mult = 1;

                end                  

                //checking for zeros
                else if (EA == 0 || EB == 0) begin
                    zero_flag = 1;
                    done_mult = 1;
                    MR = 0;
                    ER = 0;
                end

            end

            else if (!done_mult) begin

                EP = EA + EB;

                if (EP <= Bias) begin
                    underflow_flag <= 1;
                    ER = 0;
                    MR = 0;
                end

                else if (EP - Bias >= {(Exponent_Size){1'b1}}) 
                    overflow_flag = 1;
                 
                else begin

                    ER = EP - Bias;
                    MP = MA*MB;

                    {MR, ER} = MP[Product_Size-1] ? {MP[Product_Size-1:Product_Size-1-Mantissa_Size], ER+1} : {MP[Product_Size-2:Product_Size-2-Mantissa_Size], ER};

                    if (ER == {(Exponent_Size){1'b1}})
                        overflow_flag = 1;

                end

                done_mult = 1;
            end

            overflow_flag = zero_flag ? 0 : overflow_flag;
        end
    end


    // assigning the module variables to the outputs
    assign done = done_mult;
    assign result = overflow? {1'b0, {(Exponent_Size){1'b1}}, {(Mantissa_Size){1'b0}}} : {SR, ER, MR[Mantissa_Size-1:0]};
    assign overflow = overflow_flag;
    assign underflow = underflow_flag;
    assign zero = underflow_flag? 1 : zero_flag;
    assign NAN = NAN_flag;



endmodule 