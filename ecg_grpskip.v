module ecg_skip (Data_Active,Bits_req,Group_skipFlag);
input Data_Active;
input [3:0] Bits_req;
output reg Group_skipFlag;

always@(Data_Active,Bits_req)
begin
if((Data_Active==1)&&(Bits_req==0))
Group_skipFlag=1;
else
Group_skipFlag=0;
end
endmodule
