//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : CPEC_encoder.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for a submodule which generates the entropy coded data part using CPEC and the exact size of it.  
//	 DATE : 02/06/2020
//===================================================





module CPEC_encoder(sample_1,sample_2,sample_3,sample_4,ecgidx,Bits_req,Group_skip_flag,CPEC_encoded,size_CPEC_encoded);

//===================================================
// 	PARAMETER DECLARATION
//===================================================


parameter J=10;						// parameter is used to get width of sample inputs, we need to be pass its value during module instatntiation.


//===================================================
// 	PORTS DECLARATION
//===================================================



input signed [J-1:0] sample_1,sample_2,sample_3,sample_4;

input [1:0] ecgidx;

input [3:0] Bits_req;

input Group_skip_flag;


output [39:0] CPEC_encoded;

output [5:0] size_CPEC_encoded;


reg [39:0] CPEC_encoded;

reg [5:0] size_CPEC_encoded,temp;


wire [J-1:0] magnitude1,magnitude2,magnitude3,magnitude4;


//===================================================
//	 ARCHITECTURE
//===================================================


/// GET ABSOLUTE VALUES FOR EACH INPUT SAMPLE BY INSTANTIATING SUB-MODULE "magnitude_calculator" ///


magnitude_calculator_2 #(J) m1(sample_1,magnitude1);  				//find absolute of each sample.

magnitude_calculator_2 #(J) m2(sample_2,magnitude2);

magnitude_calculator_2 #(J) m3(sample_3,magnitude3);

magnitude_calculator_2 #(J) m4(sample_4,magnitude4);



/////////   MAIN BLOCK  ///////



always @(*)
begin

if(Group_skip_flag)										// check if group skip flag is active, if it is make both outputs zero.
	
	begin
	
	CPEC_encoded=0;
	size_CPEC_encoded=0;
	
	end

else

	begin
	 
	 temp[3:0] = Bits_req;
	 size_CPEC_encoded = temp << 2;  						// multiplies the bits_req by 4 and gives to size_CPEC_encoded
	 CPEC_encoded = 0;  									//initially assigned 0
	 
	 
// For 2's complement form //
	 
	if(ecgidx == 3)										
	begin
		
		case(Bits_req)
		 
		 // Not taken the cases in which bits_required is less than or equal to 2 for which VEC encoder will be used.
		
		 4'b0011:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[2:0];   				// Directly take 3 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 3;								//left shift by 3 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[2:0]; 					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 3;
		 CPEC_encoded = CPEC_encoded | sample_3[2:0];
		 CPEC_encoded = CPEC_encoded << 3;
		 CPEC_encoded = CPEC_encoded | sample_4[2:0];
		 end
		 
		 
		 4'b0100:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[3:0];   				// Directly take 4 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 4;								//left shift by 4 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[3:0];  					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 4;
		 CPEC_encoded = CPEC_encoded | sample_3[3:0];
		 CPEC_encoded = CPEC_encoded << 4;
		 CPEC_encoded = CPEC_encoded | sample_4[3:0];
		 end
		 
		 
		 4'b0101:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[4:0];   				// Directly take 5 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 5;								//left shift by 5 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[4:0];  					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 5;
		 CPEC_encoded = CPEC_encoded | sample_3[4:0];
		 CPEC_encoded = CPEC_encoded << 5;
		 CPEC_encoded = CPEC_encoded | sample_4[4:0];
		 end
		 
		 
		 4'b0110:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[5:0];   				// Directly take 6 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 6;								//left shift by 6 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[5:0]; 					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 6;
		 CPEC_encoded = CPEC_encoded | sample_3[5:0];
		 CPEC_encoded = CPEC_encoded << 6;
		 CPEC_encoded = CPEC_encoded | sample_4[5:0];
		 end
		 
		 
		 4'b0111:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[6:0];   				// Directly take 7 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 7;								//left shift by 7 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[6:0];  					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 7;
		 CPEC_encoded = CPEC_encoded | sample_3[6:0];
		 CPEC_encoded = CPEC_encoded << 7;
		 CPEC_encoded = CPEC_encoded | sample_4[6:0];
		 end
		 
		 
		 4'b1000:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[7:0];   				// Directly take 8 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 8;								//left shift by 8 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[7:0]; 					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 8;
		 CPEC_encoded = CPEC_encoded | sample_3[7:0];
		 CPEC_encoded = CPEC_encoded << 8;
		 CPEC_encoded = CPEC_encoded | sample_4[7:0];
		 end
		 
		 
		 4'b1001:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[8:0];   				// Directly take 9 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 9;								//left shift by 9 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[8:0];  					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 9;
		 CPEC_encoded = CPEC_encoded | sample_3[8:0];
		 CPEC_encoded = CPEC_encoded << 9;
		 CPEC_encoded = CPEC_encoded | sample_4[8:0];
		 end
		 
		 
		 4'b1010:
		  begin 
		 CPEC_encoded = CPEC_encoded | sample_1[9:0];   				// Directly take 10 bits from LSB of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 10;								//left shift by 10 bits 
		 CPEC_encoded = CPEC_encoded | sample_2[9:0];  					// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 10;
		 CPEC_encoded = CPEC_encoded | sample_3[9:0];
		 CPEC_encoded = CPEC_encoded << 10;
		 CPEC_encoded = CPEC_encoded | sample_4[9:0];
		 end
		 
		 
		 default:
		 begin
		 CPEC_encoded = 0;
		 size_CPEC_encoded = 0;
		 end
		 
		 
		 endcase
		 end
 
 
 
 // For SM form// 
 
 
	 else							
	 begin
	 
		 case(Bits_req)
		 
		 
		// Not taken the cases in which bits_required is less than or equal to 2 for which VEC encoder will be used
		
		
		 4'b0011: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[2:0];  				// Directly take 3 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 3;							 	//left shift by 3 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[2:0];   			 	// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 3;
		 CPEC_encoded = CPEC_encoded | magnitude3[2:0];
		 CPEC_encoded = CPEC_encoded << 3;
		 CPEC_encoded = CPEC_encoded | magnitude4[2:0];
		 end
		 

		 4'b0100: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[3:0];  			 	// Directly take 4 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 4;							 	//left shift by 4 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[3:0];  			 	// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 4;
		 CPEC_encoded = CPEC_encoded | magnitude3[3:0];
		 CPEC_encoded = CPEC_encoded << 4;
		 CPEC_encoded = CPEC_encoded | magnitude4[3:0];
		 end
		 
		 
		 4'b0101: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[4:0];   				// Directly take 5 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 5;								//left shift by 5 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[4:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 5;
		 CPEC_encoded = CPEC_encoded | magnitude3[4:0];
		 CPEC_encoded = CPEC_encoded << 5;
		 CPEC_encoded = CPEC_encoded | magnitude4[4:0];
		 end
		 
		 
		 4'b0110: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[5:0];   				// Directly take 6 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 6;								//left shift by 6 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[5:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 6;
		 CPEC_encoded = CPEC_encoded | magnitude3[5:0];
		 CPEC_encoded = CPEC_encoded << 6;
		 CPEC_encoded = CPEC_encoded | magnitude4[5:0];
		 end
		 
		 
		 4'b0111: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[6:0];   				// Directly take 7 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 7;								//left shift by 7 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[6:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 7;
		 CPEC_encoded = CPEC_encoded | magnitude3[6:0];
		 CPEC_encoded = CPEC_encoded << 7;
		 CPEC_encoded = CPEC_encoded | magnitude4[6:0];
		 end
		 
		 
		 4'b1000: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[7:0];   				// Directly take 8 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 8;								//left shift by 8 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[7:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 8;
		 CPEC_encoded = CPEC_encoded | magnitude3[7:0];
		 CPEC_encoded = CPEC_encoded << 8;
		 CPEC_encoded = CPEC_encoded | magnitude4[7:0];
		 end
		 
		 
		 4'b1001: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[8:0];   				// Directly take 9 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 9;								//left shift by 9 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[8:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 9;
		 CPEC_encoded = CPEC_encoded | magnitude3[8:0];
		 CPEC_encoded = CPEC_encoded << 9;
		 CPEC_encoded = CPEC_encoded | magnitude4[8:0];
		 end
		 
		 
		 4'b1010: 
		 begin 
		 CPEC_encoded = CPEC_encoded | magnitude1[9:0];  				// Directly take 10 bits from LSB from magnitude of sample_1 and OR with initially zero assigned CPEC_encoded
		 CPEC_encoded = CPEC_encoded << 10;								//left shift by 10 bits 
		 CPEC_encoded = CPEC_encoded | magnitude2[9:0];  				// Repeat for all samples
		 CPEC_encoded = CPEC_encoded << 10;
		 CPEC_encoded = CPEC_encoded | magnitude3[9:0];
		 CPEC_encoded = CPEC_encoded << 10;
		 CPEC_encoded = CPEC_encoded | magnitude4[9:0];
		 end
		 
		 
		 default:
		 begin 
		 CPEC_encoded = 0;
		 size_CPEC_encoded = 0;
		 end
		

		endcase
	 
	 end
	 
	 
 end
 
 end
 
 endmodule
 
 
 
 
//===================================================
// 	MAGNITUDE CALCULATOR SUB-MODULE
//===================================================
 
 
 

module magnitude_calculator_2 (sample,magnitude); 				// This module gives magnitude of a signed number 


parameter K = 10 ;


input signed [K-1:0] sample;

output [K-1:0] magnitude;

reg  [K-1:0] magnitude;




always@(*)
begin

		if(sample[K-1] == 1)             							//check the msb of sample
		
		magnitude = ~sample + 1'b1;       							// if negative find its magnitude
		
		else
		
		magnitude = sample;
	
end
	
endmodule





//===================================================
// END
//===================================================
 
 