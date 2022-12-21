

module adder
           #(parameter Mantissa_Size = 23, parameter Exponent_Size = 8, parameter N = Mantissa_Size + Exponent_Size)

            (   output [N:0] result, output done, output overflow,
                input clk, enable, load, 
                input [N:0] A, B            );

    // for storing each individual part of the encoded floating point number
    // EA -> exponent of A, MR -> mantissa of Result... and so on
    reg [Exponent_Size-1:0] EA, EB, ER;     // exponents 
    reg [Mantissa_Size:0] MA, MB, MR;       // mantissas
    reg SA, SB, SR;                         // signs

    // for faster and easier computations the following registers will be used
    
    // larger -> stores the number with the greatest magnitude 
    // smaller -> stores the number with the smallest magnitude
    reg [Mantissa_Size:0] smaller, larger;

    // stores the diff. bet. the exponents (if they're not equal)
    reg [Exponent_Size-1:0] exponent_diff;

    // used to tell the shifter to start loading its parameters
    reg shift_load;

    // direction of shifting (0 -> shift right #exponent_diff times, 1 -> normalize input)
    reg direction;
    
    // output of the shifter
    wire [Mantissa_Size:0] shifted_data;
	wire done_shifting;

    // flags for the adder itself
    reg done_adding;
    reg Cout;
    reg overflow_flag;



    shift_register #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size)) shift(
                    .shifted(shifted_data),
                    .done(done_shifting),
                    .clk(clk),
                    .enable(enable),
                    .load(shift_load),
                    .unshifted(smaller),
                    .direction(direction),
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

                // if numbers have different exponents put the diff in exponent_diff for shifting
                // also put the greater exponent  in ER (ER maybe changed later but we initialize it like this then check later if shifting will be needed)
                if (EA != EB) 
                    {SR, ER, larger, smaller, exponent_diff} <= EA > EB ? {SA, EA, MA, MB, EA-EB} : {SB, EB, MB, MA, EB-EA}; 
    
                // otherwise perform addition right away
                else begin
                    { SR, larger, smaller } <= MA >= MB ? {SA, MA, MB} : {SB, MB, MA}; 
                    ER <= EA;
                    exponent_diff <= 0;
                end
                
                // tell shifter to start loading 
                direction <= 1'b1;
                shift_load <= 1'b1;

                // initialize adder flags
                done_adding <= 1'b0;
                overflow_flag <= 0;
            end
            // to prevent the result from changing overtime, we check if we've already finished addition before entering the addition block
            else if (!done_adding) begin
                // tell the shifter to stop loading & start executing
                shift_load <= 1'b0;

                // start addition when shifting is complete
                if (done_shifting) begin

                    // adding/subtracting and checking if there is a carry  
                    {Cout, MR} = SA != SB ? larger - shifted_data : larger + shifted_data;

                    // if there is carry shift the mantissa to the right and increment the exponent
                    if (Cout == 1) begin
                        MR <= {Cout, MR[Mantissa_Size:1]};
                        {overflow_flag, ER} <= ER + 1;      // checking if overflow ocurred 
                    end
                      
                    // finally, we turn on the done flag to indicate to any module that will use the adder that it has finished its calculations
                    done_adding <= 1'b1;
                end
            end
        end

    end

    // assigning the module variables to the outputs
    assign result = {SR, ER, MR[Mantissa_Size-1:0]};
    assign done = done_adding;
    assign overflow = overflow_flag;

endmodule 