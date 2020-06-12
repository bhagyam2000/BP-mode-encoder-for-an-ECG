//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : ecg_sign_bits.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for a submodule which generates the sign bits and its exact size to be given as two of the final outputs in Top module.  
//	 DATE : 03/06/2020
//===================================================





module ecg_sign_bits (sample_1,sample_2,sample_3,sample_4,ecgidx,Group_skip_flag,sign_bits,size_sign_bits);


//===================================================
// 	PARAMETER DECLARATION
//===================================================


parameter J=10;										// parameter is used to get width of sample inputs, we need to be pass its value during module instatntiation.

//===================================================
// 	PORTS DECLARATION
//===================================================



input signed [J-1:0] sample_1,sample_2,sample_3,sample_4;

input [1:0] ecgidx;

input Group_skip_flag;


output [3:0] sign_bits;

output[2:0] size_sign_bits;


reg [3:0] sign_bits;

reg [2:0] size_sign_bits;


wire w1,w2,w3,w4;


//===================================================
//	 ARCHITECTURE
//===================================================




assign w1 = (sample_1 == 0)? 0:1; 						// use coditional assignments to indicate the non zero samples through wires w1,w2,w3,w4.

assign w2 = (sample_2 == 0)? 0:1;

assign w3 = (sample_3 == 0)? 0:1;

assign w4 = (sample_4 == 0)? 0:1;



/////// MAIN BLOCK /////////


always @(*)
begin

if((ecgidx==3)||(Group_skip_flag==1))					//for fourth ecg, sign bits are not required and for the case in which Group_skip_flag is active, all samples are zero.
	
	begin
	
	sign_bits=0;
	
	size_sign_bits=0;
	
	end

	
else

	begin
	
	sign_bits=0;					// initially assigned zero.
	
////Case with all sample zero is already covered in Group skip flag condition.////
	
//// Cases with one non zero sample. ////
	

	 case({w4,w3,w2,w1})					// Use case statement for concatenated wires outputs indicating non zero samples.
	 
		 4'b0001:							// indicates sample_1 is non zero rest are zero. 
		 begin
		 sign_bits[0] = sample_1[J-1];		// LSB of zero assigned sign_bits is given the MSB(Sign bit) of sample_1. 
		 size_sign_bits = 1;
		 end
		 
		 4'b0010:
		 begin
		 sign_bits[0] = sample_2[J-1];		// LSB of zero assigned sign_bits is given the MSB of sample_2. 
		 size_sign_bits = 1;
		 end 

		 4'b0100:
		 begin
		 sign_bits[0] = sample_3[J-1];		// LSB of zero assigned sign_bits is given the MSB of sample_3. 
		 size_sign_bits =1;
		 end 

		 4'b1000:
		 begin
		 sign_bits[0] = sample_4[J-1];		// LSB of zero assigned sign_bits is given the MSB of sample_4. 
		 size_sign_bits = 1;
		 end  
		 
//// Cases with two non zero samples. ////
		 
		 4'b0011:
		 begin
		 sign_bits[1] = sample_1[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[0] = sample_2[J-1];		// LSB of sign_bits is given the MSB of sample_2. 
		 size_sign_bits = 2;
		 end
		 
		 4'b0101:
		 begin
		 sign_bits[1] = sample_1[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[0] = sample_3[J-1];		// LSB of sign_bits is given the MSB of sample_3. 
		 size_sign_bits = 2;
		 end
		 
		 4'b1001:
		 begin
		 sign_bits[1] = sample_1[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4. 
		 size_sign_bits = 2;
		 end
		 
		 4'b0110:
		 begin
		 sign_bits[1] = sample_2[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_2. 
		 sign_bits[0] = sample_3[J-1];		// LSB of sign_bits is given the MSB of sample_3. 
		 size_sign_bits = 2;
		 end
		 
		 4'b1010:
		 begin
		 sign_bits[1] = sample_2[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_2. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4. 
		 size_sign_bits = 2;
		 end
		 
		 4'b1100:
		 begin
		 sign_bits[1] = sample_3[J-1];		//2nd LSB of zero assigned sign_bits is given the MSB of sample_3. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4. 
		 size_sign_bits = 2;
		 end

//// Cases with three non zero samples.////
		 
		 4'b0111:
		 begin
		 sign_bits[2] = sample_1[J-1];		//3rd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[1] = sample_2[J-1];		// 2nd LSB of sign_bits is given the MSB of sample_2. 
		 sign_bits[0] = sample_3[J-1];		// LSB of sign_bits is given the MSB of sample_3.
		 size_sign_bits = 3;
		 end
		 
		 4'b1011:
		 begin
		 sign_bits[2] = sample_1[J-1];		//3rd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[1] = sample_2[J-1];		// 2nd LSB of sign_bits is given the MSB of sample_2. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4.
		 size_sign_bits = 3;
		 end
		 
		 4'b1101:
		 begin
		 sign_bits[2] = sample_1[J-1];		//3rd LSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[1] = sample_3[J-1];		// 2nd LSB of sign_bits is given the MSB of sample_3. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4.
		 size_sign_bits = 3;
		 end
		 
		 4'b1110:
		 begin
		 sign_bits[2] = sample_2[J-1];		//3rd LSB of zero assigned sign_bits is given the MSB of sample_2. 
		 sign_bits[1] = sample_3[J-1];		// 2nd LSB of sign_bits is given the MSB of sample_3. 
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4.
		 size_sign_bits = 3;
		 end
		 
//// Case with four non zero samples.////
		 
		 4'b1111:
		 begin
		 sign_bits[3] = sample_1[J-1];		// MSB of zero assigned sign_bits is given the MSB of sample_1. 
		 sign_bits[2] = sample_2[J-1];		// 3rd LSB of sign_bits is given the MSB of sample_2. 
		 sign_bits[1] = sample_3[J-1];		// 2nd LSB of sign_bits is given the MSB of sample_3.
		 sign_bits[0] = sample_4[J-1];		// LSB of sign_bits is given the MSB of sample_4.
		 size_sign_bits = 4;
		 end
		 
		 default: 
		 begin
		 sign_bits = 0;
		 size_sign_bits = 0;
		 end
		 
	 endcase
	 
	 end

	 
end
	 	 
endmodule


//===================================================
// END
//===================================================
 

