module encoder(clk,rst,sample_1,sample_2,sample_3,sample_4,sign_bits,sizeof_sign_bits,sizeof_stuffing_bits,ecgidx,sub_sample_info,component_idx,component_skip,underflow_prevention,encoded_ecg,sizeof_encoded_ecg,valid_op);

parameter Data_width = 10 ;

input clk,rst,component_skip,underflow_prevention;
input signed [Data_width-1:0] sample_1,sample_2,sample_3,sample_4;
input [11:0] sign_bits;
input [3:0] sizeof_sign_bits;
input [7:0] sizeof_stuffing_bits;
input [1:0] ecgidx,sub_sample_info,component_idx;
output [49:0] encoded_ecg;
output [5:0] sizeof_encoded_ecg;
output valid_op;

endmodule