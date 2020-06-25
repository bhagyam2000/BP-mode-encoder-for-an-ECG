
//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : Entropy_encoderTB.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for the 'Test-bench'  to test the design. It uses File i/o to take test-vectors input and generate the desired outputs and errors files. 
//	 DATE : 23/06/2020
//===================================================



//===================================================
// 	FILE INCLUSION
//===================================================




`include "Entropy_encoder.v"												// Including top-module of the design.



//* DEFINING TIME SCALE *//


`timescale 1ns/1ps




//===================================================
// 	PORTS DECLARATION
//===================================================

 
module Entropy_encoderTB ;


reg clk,rst,component_skip,underflow_prevention;									// Declaring inputs to the top-module as register and outputs as wires.

reg signed [9:0] sample_1,sample_2,sample_3,sample_4;

reg [11:0] sign_bits_in;

reg [3:0] sizeof_sign_bits_in;

reg [7:0] sizeof_stuffing_bits;

reg [1:0] ecgidx,sub_sample_info,component_idx;

wire [49:0] encoded_ECG;

wire [6:0] sizeof_encoded_ECG;

wire [3:0] sign_bits_out;

wire [2:0] sizeof_sign_bits_out;

wire valid_op;



reg [129:0] test_vectors[10000:0];										// Array of testvectors.

reg [6:0] sign_bits_vectors[10000:0]; 									// Array of sign_bits vectors.

reg[31:0] vectornum;													// Keeps track of test-vector number.

reg[31:0] errors;														// To count errors (Mismatch).

reg [49:0] encoded_ECG_expected;										// Expected Encoded ecg output, to be taken from reference file.

reg [6:0] sizeof_encoded_ECG_expected;									// Expected size Encoded ecg output, to be taken from reference file.

reg valid_op_expected;													// Expected valid_ecg  output, to be taken from reference file.

reg [3:0] sign_bits_out_expected;										// Expected sign-bits output, to be taken from reference file.
	
reg [2:0] sizeof_sign_bits_out_expected;								// Expected size of sign-bits output, to be taken from reference file.


integer f,h;															// Used for file i/o.




//===================================================
//	 ARCHITECTURE
//===================================================



//* INSTANTIATING 'TOP-MODULE'. *//

// Data-width parameter is passed at the time of instantiation . Here 10 bits are used for representing quantized residuals in testvectors file. //



Entropy_encoder #(10) u(clk,rst,sample_1,sample_2,sample_3,sample_4,sign_bits_in,sizeof_sign_bits_in,sizeof_stuffing_bits,ecgidx,sub_sample_info,component_idx,component_skip,underflow_prevention,encoded_ECG,sizeof_encoded_ECG,valid_op,sign_bits_out,sizeof_sign_bits_out);




//* MAIN BLOCK *//


initial 																			// Will execute at the beginning once
begin

$readmemb("test_cases_tree.txt", test_vectors); 									// Read vectors. Provide the Reference files name.

$readmemb("sign_bits_tree.txt", sign_bits_vectors); 



clk = 1;

vectornum = 0; 																		// Initialize

errors = 0; 										

rst = 0; 

#24 rst = 1; 																		// Apply reset wait

end

always #5 clk = ~clk;



// Apply test-vectors on falling edge of clk. //



always @(negedge clk)

begin


	if(rst)																			// Skip for reset.
	begin

	{component_skip, sub_sample_info[1:0], component_idx[1:0], ecgidx[1:0], sample_1[9:0], sample_2[9:0] ,sample_3[9:0], sample_4[9:0], underflow_prevention, sizeof_stuffing_bits[7:0], sign_bits_in[11:0], sizeof_sign_bits_in[3:0], encoded_ECG_expected[49:0], sizeof_encoded_ECG_expected[6:0], valid_op_expected }  = test_vectors[vectornum];

	{sign_bits_out_expected[3:0], sizeof_sign_bits_out_expected[2:0]}  = sign_bits_vectors[vectornum];

	end


end


// Print outputs and check mismatches on rising edge of clock (after some delay). //


always @(posedge clk)
begin

# 3 ;																				//Provide some delay.

	if(rst)																				// 	Skip for reset.																													
	begin

	vectornum = vectornum + 1;															// Increment the vector number.

		if (vectornum < 5725)															// Check whether we have reached to the last line in the test cases file. If not print the outputs in a file.
		begin
		
		f = $fopen("encoded_ecg_tree.txt", "a+");											// Open file in append mode.
		
		$fwrite(f, "%50b_%7b_%b_%4b_%3b\n", encoded_ECG, sizeof_encoded_ECG, valid_op, sign_bits_out, sizeof_sign_bits_out);
		
		$fclose(f);

		
	
	
			if((encoded_ECG !== encoded_ECG_expected) || (sizeof_encoded_ECG !== sizeof_encoded_ECG_expected) || (valid_op !== valid_op_expected ) || (sign_bits_out !== sign_bits_out_expected) || (sizeof_sign_bits_out !== sizeof_sign_bits_out_expected))									// Check for Mismatches in generated outputs and expected outputs from the reference file.
			begin
			
			h = $fopen("Errors_tree.txt", "a+");
			
			$fwrite(h, " Error: at line %d ,%50b (%50b expected) , %7b (%7b expected) , %b (%b expected) , %4b (%4b expected) , %3b (%3b expected) \n", (vectornum),encoded_ECG,encoded_ECG_expected, sizeof_encoded_ECG, sizeof_encoded_ECG_expected, valid_op, valid_op_expected, sign_bits_out, sign_bits_out_expected, sizeof_sign_bits_out, sizeof_sign_bits_out_expected);				//In a file, print the line at which mismatch is encountered. Along with the generated and expected outputs.
			
			$fclose(h);
			
			errors = errors +1;														// Increment the errors count.
			
			end
			
		end

	


	
	
		else								// If reached to the last line in the reference file, print "simulation completed" in the Errors file. Along with the number of mismatches encountered.
		begin

		h = $fopen("Errors_tree.txt", "a+");
		
		$fwrite(h, " \n Simulation completed with %d errors",errors );
		
		$fclose(h);

		$finish;					

		end

	end

end



endmodule

