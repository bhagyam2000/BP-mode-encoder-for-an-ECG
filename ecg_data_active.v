//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : ecg_data_active.v
//	 WRITTEN BY: BHAGYAM GUPTA
//	 DESCRIPTION: Verilog code for a submodule which generates the output signal telling whether the Data part in the encoded ECG is active or not. This signal is used by many other submodules.
//	 DATE : 26/05/2020
//===================================================


module ecg_DataActive (DataActive,ecgidx,sub_sample_info,component_idx,component_skip);




//===================================================
//	PORTS DECLARATION
//===================================================



input component_skip;
input [1:0] ecgidx,sub_sample_info,component_idx;
wire temp;
output reg DataActive;




//===================================================
//	 ARCHITECTURE
//===================================================




assign temp= (component_idx==0)?0:1; 				// differentiate between luma and chroma component and assign a temporary varibale accordingly.



always@(*) 
begin 

	if(component_skip)  							//check if the component skip flag is active and make data_active low if it is.
	DataActive=1'b0;


	else
	begin
	
		case({ecgidx,temp,sub_sample_info})  		//Implementation of table 4-61 from specs(VDC-M V.2).
		
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



//===================================================
// END
//===================================================
