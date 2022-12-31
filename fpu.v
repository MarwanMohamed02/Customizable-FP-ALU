module fpu 
        #(  parameter Mantissa_Size = 23, parameter Exponent_Size = 8, 
            parameter Bias = 127, parameter Product_Size = (Mantissa_Size+1)*2,
            parameter N = Mantissa_Size + Exponent_Size )

        (   output done, zero, overflow, underflow, NAN,
            output [N:0] result, 
            input clk, enable, load,
            input [1:0] op, 
            input [N:0] A, B            );

        // fpu registers
        reg [N:0] res;
        reg done_fpu;
        reg zero_fpu;
        reg overflow_fpu;
        reg underflow_fpu;
        reg NAN_fpu;

        // adder/subtractor flags
        wire [N:0] result_add_sub;
        wire done_add_sub;
        wire zero_add_sub;
        wire overflow_add_sub;
        wire underflow_add_sub;
        wire NAN_add_sub;




        // multiplier flags
        wire [N:0] result_mult;
        wire done_mult;
        wire zero_mult;
        wire overflow_mult;
        wire underflow_mult;
        wire NAN_mult;




        mult #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size), .Bias(7'd127)) multiplier(
                                                                                                    .result(result_mult),
                                                                                                    .done(done_mult),
                                                                                                    .zero(zero_mult),
                                                                                                    .overflow(overflow_mult),
                                                                                                    .underflow(underflow_mult),
                                                                                                    .NAN(NAN_mult),
                                                                                                    .clk(clk),
                                                                                                    .enable(enable),
                                                                                                    .load(load),
                                                                                                    .A(A),
                                                                                                    .B(B)       );


        adder #(.Mantissa_Size(Mantissa_Size), .Exponent_Size(Exponent_Size)) Adder(
                                                                                    .result(result_add_sub),
                                                                                    .done(done_add_sub),
                                                                                    .zero_flag(zero_add_sub),
                                                                                    .overflow(overflow_add_sub),
                                                                                    .underflow(underflow_add_sub),
                                                                                    .NAN(NAN_add_sub),
                                                                                    .clk(clk),
                                                                                    .enable(enable),
                                                                                    .load(load),
                                                                                    .A(A),
                                                                                    .B(B)       );                                                                                            



        localparam addition       = 2'b00;
        localparam subtraction    = 2'b01;
        localparam multiplication = 2'b10;
        localparam division       = 2'b11;



        always @(posedge clk or posedge load) begin

                case (op) 

                     (addition || subtraction):
                        if (done_add_sub) begin

                            done_fpu  = done_add_sub;
                            zero_fpu = zero_add_sub;
                            overflow_fpu = overflow_add_sub;
                            underflow_fpu = underflow_add_sub;
                            NAN_fpu = NAN_add_sub;

                            res = result_add_sub;
                        end

                    (multiplication):
                        if (done_add_sub) begin

                            done_fpu  = done_add_sub;
                            zero_fpu = zero_add_sub;
                            overflow_fpu = overflow_add_sub;
                            underflow_fpu = underflow_add_sub;
                            NAN_fpu = NAN_add_sub;

                            res = result_mult;
                        end

                    
                endcase
            
        end


        

        assign result = res;
        assign done = done_fpu;
        assign zero = zero_fpu;
        assign overflow = overflow_fpu;
        assign underflow = underflow_fpu;
        assign NAN = NAN_fpu;




endmodule 