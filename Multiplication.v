module Multiplication
#(parameter Mantissa_Size = 23, parameter Exponent_Size = 8, parameter N = Mantissa_Size + Exponent_Size)
            (   output [N:0] result,output overflow,output zero,
                input clk, enable, load, 
                input [N:0] A, B            );   
					
    // for storing each individual part of the encoded floating point number
    // EA -> exponent of A, MR -> mantissa of Result... and so on
    reg [Exponent_Size:0] EA, EB,ES;     // exponents 
	 reg [Exponent_Size-1:0] ER;
    reg [Mantissa_Size:0] MA, MB, MR;       // mantissas
    reg SA, SB, SR;                         // signs
	 reg[Mantissa_Size*2+1:0] product,product_normalised;
	 reg round,normalised;
	 reg[N:0] op_a,op_b;
	 reg over_flow,zero1;
	 always @ (posedge clk or posedge load or posedge enable) begin
	 if(enable)begin
	     if(load)begin
		  //load data to reg;
		          SA = A[N];
                SB = B[N];
					 op_a = A;
					 op_b = B;
					 EA = A[N-1:N-Exponent_Size];
                EB = B[N-1:N-Exponent_Size];
                MA =(|A[N-1:N-Exponent_Size]) ? {1'b1,A[Mantissa_Size-1:0]}:{1'b0,A[Mantissa_Size-1:0]};
                MB =(|B[N-1:N-Exponent_Size]) ? {1'b1,B[Mantissa_Size-1:0]}:{1'b0,B[Mantissa_Size-1:0]};
					 round = |product_normalised[22:0];  // Last 22 bits are Ored for rounding.
					 //corner cases ketteeera:
					 if(op_a==0||op_b==0)begin //zeros operands;
					 ER[Exponent_Size-1:0] <= 0;
					 MR[Mantissa_Size-1:0] <= 0;
					 SR <= 0;
					 zero1<=1;
					 end
					 if(op_a>=128||op_b>=128)begin
					 over_flow <=1;
					 if(op_a==0||op_b==0)
					 zero1<=1;
					 ER[Exponent_Size-1:0] <= 0;
					 MR[Mantissa_Size-1:0] <= 0;
					 SR <= 0;

					 end
					///////////////////////////////////////////////////////////////////
					 else begin
					 zero1<=0;
					 SR <= SA^SB;
					 ES <= EA+EB;
					 product = MA*MB;
					 if(product[47]==0)begin
					 normalised = 0;
					 product_normalised = product<<1;
					 ER <= ES - 8'd127 + normalised;
					 if(!(1<=ER<=254))begin
					 over_flow<=1'b1;
					 end
					 else begin
					 over_flow<=1'b0;
					 end
					 MR <= product_normalised[Mantissa_Size*2:Mantissa_Size+1] + (product_normalised[Mantissa_Size] & round);
					 end
					 else if(product[47]==1)begin
					 normalised = 1;
					 product_normalised = product;
					 ER <= ES - 8'd127 + normalised;
					 if(!(1<=ER<=254))begin
					 over_flow<=1'b1;
					 end
					 else begin
					 over_flow<=1'b0;
					 end
					 MR <= product_normalised[Mantissa_Size*2:Mantissa_Size+1] + (product_normalised[Mantissa_Size] & round);
					 end
					 end					 
					 end
					 end
					 end
					 assign result = {SR,ER[Exponent_Size-1:0],MR[Mantissa_Size-1:0]};
					 assign overflow = over_flow;
					 assign zero = zero1;
endmodule

















