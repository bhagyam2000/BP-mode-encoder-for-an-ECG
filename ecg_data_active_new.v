module ecg_DataActive (DataActive,ecgidx,sub_sample_info,component_idx,component_skip);
input component_skip;
input [1:0] ecgidx,sub_sample_info,component_idx;
wire temp;
output reg DataActive;

assign temp= (component_idx==0)?0:1; // differentiate between luma and chroma component and assign a temporary varibale accordingly

always@(*)
begin 
if(component_skip)  //checks if the component skip flag is active and makes data_active low if it is
DataActive=1'b0;
else
begin
case({ecgidx,temp,sub_sample_info})  //5 cases for which data_active is false from table 4-61 in specs.
5'b01110: DataActive=1'b0;             
5'b10101: DataActive=1'b0;
5'b10110: DataActive=1'b0; 
5'b11101: DataActive=1'b0;
5'b11110: DataActive=1'b0;
default: DataActive=1'b1;
endcase
end
end
endmodule
