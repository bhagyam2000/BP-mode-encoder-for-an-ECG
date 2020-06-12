
//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : Entropy_encoder.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for the 'TOP MODULE'  of the project which generates the final desired outputs synchronized with a clock input.
//	 DATE : 12/06/2020
//===================================================



//===================================================
// 	FILE INCLUSION
//===================================================


//* Including files of all the sub-modules. *//

`include "ecg_bitsreq.v"

`include "ecg_data_active.v"

`include "ecg_grpskip.v"

`include "CPEC_encoder.v"

`include "VEC_encoder.v"

`include "ecg_sign_bits.v"

`include "final_output_generator.v" 





//===================================================
// 	MODULE DEFINITION
//===================================================


module Entropy_encoder(clk,sample_1,sample_2,sample_3,sample_4,sign_bits_in,sizeof_sign_bits_in,sizeof_stuffing_bits,ecgidx,sub_sample_info,component_idx,component_skip,underflow_prevention,encoded_ECG,sizeof_encoded_ECG,valid_op,sign_bits_out,sizeof_sign_bits_out);


//===================================================
// 	PARAMETER DECLARATION
//===================================================


parameter DATA_WIDTH = 10 ;						// This parameter represent width of sample input data to be given at the time of MODULE instantiation.
												// This sample input data width can be 9 or 10 depending on the size of sample data [Quantized Residual] taken input as signed, belongs to which one of the Luma or Chroma component. 
												// By default 10 is taken.
									
												
//===================================================
// 	PORTS DECLARATION
//===================================================


input clk,component_skip,underflow_prevention;

input signed [DATA_WIDTH-1:0] sample_1,sample_2,sample_3,sample_4;

input [11:0] sign_bits_in;

input [3:0] sizeof_sign_bits_in;

input [7:0] sizeof_stuffing_bits;

input [1:0] ecgidx,sub_sample_info,component_idx;


output [49:0] encoded_ECG;

output [5:0] sizeof_encoded_ECG;

output [3:0] sign_bits_out;

output [2:0] sizeof_sign_bits_out;

output valid_op;


reg [49:0] encoded_ECG;

reg [5:0] sizeof_encoded_ECG;

reg [3:0] sign_bits_out;

reg [2:0] sizeof_sign_bits_out;

reg valid_op;


wire [3:0] Bits_req;

wire Data_Active, Group_skip_flag;

wire [39:0] CPEC_encoded;

wire [5:0] size_CPEC_encoded;

wire [6:0] VEC_prefix;

wire [4:0] VEC_suffix;

wire [2:0] size_VEC_prefix, size_VEC_suffix;

wire [3:0] sign_bits;

wire [2:0] size_sign_bits;

wire [49:0] encoded_ecg;

wire [5:0] sizeof_encoded_ecg;





//===================================================
//	 ARCHITECTURE
//===================================================




////// INSTANTIATION OF SUB-MODULES ////


//* Passing the parameter DATA_WIDTH to all those sub-modules which require this parameter, at time of their instantiation. *//


Bits_required #(DATA_WIDTH) u0(Bits_req, sample_1,sample_2,sample_3,sample_4,ecgidx);

ecg_DataActive u1(Data_Active,ecgidx,sub_sample_info,component_idx,component_skip);

ecg_skip u2(Data_Active,Bits_req,Group_skip_flag);

CPEC_encoder #(DATA_WIDTH) u3(sample_1,sample_2,sample_3,sample_4,ecgidx,Bits_req,Group_skip_flag,CPEC_encoded,size_CPEC_encoded);

VEC_encoder #(DATA_WIDTH) u4(sample_1,sample_2,sample_3,sample_4,ecgidx,Bits_req,Group_skip_flag,component_idx,VEC_prefix,size_VEC_prefix,VEC_suffix,size_VEC_suffix);

ecg_sign_bits #(DATA_WIDTH) u5(sample_1,sample_2,sample_3,sample_4,ecgidx,Group_skip_flag,sign_bits,size_sign_bits);

final_output_generator u6(Bits_req, Data_Active, Group_skip_flag,ecgidx,component_skip, CPEC_encoded,size_CPEC_encoded,VEC_prefix,size_VEC_prefix,VEC_suffix,size_VEC_suffix,underflow_prevention,sign_bits_in,sizeof_sign_bits_in,sizeof_stuffing_bits,encoded_ecg,sizeof_encoded_ecg);





//// MAIN BLOCK ///

//* Sensitivity list of this block only contains Clock. Which makes it synchronised to clock. *//
//* Check the size of the encoded ECG and if it exceeds 50 bits make all outputs zero including valid_op which will indicate that output is not valid. *//



always @(posedge clk)
begin

	

	if (sizeof_encoded_ecg > 50)
	begin
		
	encoded_ECG <= 0;
		
	sizeof_encoded_ECG <= 0;
		
	valid_op <= 0;
		
	sign_bits_out <= 0;
		
	sizeof_sign_bits_out <= 0;
		
	end

		
	else
	begin
		
	encoded_ECG <= encoded_ecg ;
		
	sizeof_encoded_ECG <= sizeof_encoded_ecg;
		
	valid_op <= 1;
		
	sign_bits_out <= sign_bits ;
		
	sizeof_sign_bits_out <= size_sign_bits;
		
	end
	

end


endmodule



//===================================================
// END
//===================================================