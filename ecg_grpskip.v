//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : ecg_grpskip.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for a submodule which generates the output signal telling whether the Group skip flag is kept active in encoded ECG. This signal is used by other submodules.
//	 DATE : 26/05/2020
//===================================================



module ecg_skip (Data_Active,Bits_req,Group_Skip_Flag);


//===================================================
// 	PORTS DECLARATION
//===================================================

input Data_Active;
input [3:0] Bits_req;
output reg Group_Skip_Flag;




//===================================================
//	 ARCHITECTURE
//===================================================



always@(*)
begin

	if((Data_Active==1)&&(Bits_req==0))					// If Data part is active and the maximum bits required to represet any of four samples is zero than make Group_Skip_Flag High.
	
	Group_Skip_Flag=1;
	
	
	else												// else make it Low.
	
	Group_Skip_Flag=0;


end

endmodule




//===================================================
// END
//===================================================
