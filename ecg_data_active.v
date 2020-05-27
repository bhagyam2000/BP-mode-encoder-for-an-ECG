module ecg_DataActive (DataActive,ecgidx,sub_sample_info,component_idx,component_skip);
input component_skip;
input [1:0] ecgidx,sub_sample_info,component_idx;
output reg DataActive;

always@(ecgidx,sub_sample_info,component_idx,component_skip)
begin 
if(component_skip)
DataActive=1'b0;
else if( (component_skip==0)&&(sub_sample_info==0))
DataActive=1'b1;
else if ( (component_skip==0)&&(sub_sample_info==1))
begin 
case({ecgidx,component_idx})
4'b1001: DataActive=1'b0;
4'b1010: DataActive=1'b0;
4'b1101: DataActive=1'b0;
4'b1110: DataActive=1'b0;
default: DataActive=1'b1;
endcase
end

else if((component_skip==0)&&(sub_sample_info==2))
begin 
case({ecgidx,component_idx})
4'b1001: DataActive=1'b0;
4'b1010: DataActive=1'b0;
4'b1101: DataActive=1'b0;
4'b1110: DataActive=1'b0;
4'b0101: DataActive=1'b0;
4'b0110: DataActive=1'b0;
default: DataActive=1'b1;
endcase
end
end
endmodule


