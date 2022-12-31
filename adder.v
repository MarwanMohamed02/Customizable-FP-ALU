

module adder
           #(parameter Mantissa_Size = 23, parameter Exponent_Size = 8, parameter N = Mantissa_Size + Exponent_Size)

            (   output done, zero_flag, overflow, underflow, NAN,
                output [N:0] result, 
                input clk, enable, load, 
                input [N:0] A, B            );
					 

    // for storing each individual part of the encoded floating point number
    // EA -> exponent of A, MR -> mantissa of Result... and so on
    reg [Exponent_Size-1:0] EA, EB, ER;     // exponents 
    reg [Mantissa_Size:0] MA, MB, MR;       // mantissas
    reg SA, SB, SR;                         // signs

    // for faster and easier computations the following registers will be used
    
    // larger -> stores the number with the greatest magnitude 
    reg [Mantissa_Size:0] larger;

    // stores the diff. bet. the exponents (if they're not equal)
    reg [Exponent_Size-1:0] exponent_diff;

    // used to tell the shifter to start loading its parameters
    reg shift_load;

    // direction of shifting (0 -> shift right #exponent_diff times, 1 -> normalize input)
    reg shifting_direction;
    
    // input of the shifter
    reg  [Mantissa_Size:0]   shifter_input_mantissa;
    // reg  [Exponent_Size-1:0] shifter_input_exponent;

    // output of the shifter
    wire [Mantissa_Size:0]   shifted_mantissa;
    wire [Exponent_Size-1:0] shifted_exponent;
	wire done_shifting;

    // flags for the adder itself
    reg done_adding;
    reg done_normalizing;
    reg zero;
    reg Cout;
    reg overflow_flag;
    reg NAN_flag;
 



    shift_register #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size)) shift(
                    .shiftedMantissa(shifted_mantissa),
                    .shiftedExponent(shifted_exponent),
                    .done(done_shifting),
                    .underflow(underflow),
                    .clk(clk),
                    .enable(enable),
                    .load(shift_load),
                    .mantissa(shifter_input_mantissa),
                    .exponent(ER),
                    .direction(shifting_direction),
                    .no_of_shifts(exponent_diff)
                );

    
    always @ (posedge clk or posedge load or posedge enable) begin
        
        if (enable) begin
            if (load) begin
                // loading each component of the encoded fp numbers
                SA = A[N];
                SB = B[N];
                
                EA = A[N-1:N-Exponent_Size];
                EB = B[N-1:N-Exponent_Size];

                MA = {1'b1,A[Mantissa_Size-1:0]};
                MB = {1'b1,B[Mantissa_Size-1:0]};


                // checking for NAN && infinities 
                if ((EA == {(Exponent_Size){1'b1}}) || (EB == {(Exponent_Size){1'b1}})) begin

                    if (MA[0] === 1'bX || MB[0] === 1'bX) begin
                        NAN_flag <= 1;
                        shifter_input_mantissa <= {2'b11, { (Mantissa_Size-1){1'bx} }};
                    end

                    else  
                        overflow_flag <= 1;
                    

                    exponent_diff <= 0;
                    ER = {(Exponent_Size){1'b1}};
                    done_adding <= 1;
                end
                

                // if numbers have different exponents put the diff in exponent_diff for shifting
                // also put the greater exponent  in ER (ER maybe changed later but we initialize it like this then check later if shifting will be needed)
                else begin
                    if (EA != EB)  begin
                    {   SR, ER, larger, shifter_input_mantissa, exponent_diff} = EA > EB ? {SA, EA, MA, MB, EA-EB} : {SB, EB, MB, MA, EB-EA}; 
                    end
                    // otherwise perform addition right away
                    else begin
                        { SR, larger, shifter_input_mantissa } <= MA >= MB ? {SA, MA, MB} : {SB, MB, MA}; 
                        ER = EA;  // since they are equal we can assign EA or EB to ER
                        exponent_diff <= 0;
                    end

                    // initialize adder flags
                    done_adding <= 0;
                    overflow_flag <= 0;
                    NAN_flag <= 0;
                    done_normalizing <= 0;
                end
                // tell shifter to start loading 
                shifting_direction <= 1;
                shift_load <= 1;

                zero <= 0;
                
            end
            
            // to prevent the result from changing overtime, we check if we've already finished addition before entering the addition block
            else begin
                // tell the shifter to stop loading & start executing
                shift_load <= 0;
                
                // start addition when shifting is complete
                if (!done_adding && done_shifting && !overflow && !NAN) begin

                    // adding/subtracting and checking if there is a carry  
                    {Cout, MR} = SA != SB ? larger - shifted_mantissa : larger + shifted_mantissa;

                    if (MR == 0) begin
                        zero <= 1;
                        SR <= 0;
                        MR = 0;
                        ER = 0;
                    end
        
                    // if there is carry shift the mantissa to the right and increment the exponent
                    else if (Cout == 1) begin
                        MR = {Cout, MR[Mantissa_Size:1]};
                        ER = ER + 1;      // checking if overflow ocurred 
                    end

                    if (ER == {(Exponent_Size){1'b1}}) 
                        overflow_flag = 1;
                        

                    // Now, we've finished adding and should start normalizing
                    
                    // So, we set the shift direction=0 to shift left
                    shifting_direction <= 0;
                    shifter_input_mantissa = MR;
                    shift_load <= 1;    

                    // We then indicate that we're done adding so we don't enter this block again   
                    done_adding <= 1'b1;
                    done_normalizing <= 0;

                end

                // if normalization is done, then the adder has finished its job and done flag will be set
                else if (done_shifting) 
                    done_normalizing <= 1;

            end
        end
    end


    // assigning the module variables to the outputs
    assign result = overflow? {1'b0, {(Exponent_Size){1'b1}}, {(Mantissa_Size){1'b0}}} : {SR, shifted_exponent, shifted_mantissa[Mantissa_Size-1:0]};
    assign done = done_normalizing;
    assign overflow = overflow_flag;
    assign zero_flag = underflow? 1 : zero;
    assign NAN = NAN_flag;

endmodule 