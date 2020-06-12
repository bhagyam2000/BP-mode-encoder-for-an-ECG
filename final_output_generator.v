
//===================================================
//   PROJECT: ENTROPY ENCODER USED FOR BLOCK PREDICTION MODE IN DISPLAY COMPRESSION
//   FILE : final_output_generator.v
//	 WRITTEN BY: BHAGYAM GUPTA
//   DESCRIPTION: Verilog code for a submodule which generates the final encoded ECG of 50 bits and the exact used size of it. 
//	 DATE : 10/06/2020
//===================================================





module final_output_generator (Bits_req, Data_Active, Group_skip_flag,ecgidx,component_skip, CPEC_encoded,size_CPEC_encoded,VEC_prefix,size_VEC_prefix,VEC_suffix,size_VEC_suffix,underflow_prevention,sign_bits_in,sizeof_sign_bits_in,sizeof_stuffing_bits,encoded_ecg,sizeof_encoded_ecg);


//===================================================
// 	PORTS DECLARATION
//===================================================


input Data_Active,Group_skip_flag,component_skip,underflow_prevention;

input [1:0] ecgidx;

input [3:0] Bits_req;

input [39:0] CPEC_encoded;

input [5:0] size_CPEC_encoded;

input [6:0] VEC_prefix;

input [2:0] size_VEC_prefix;

input [4:0] VEC_suffix;

input [2:0] size_VEC_suffix;

input [11:0] sign_bits_in;

input [3:0] sizeof_sign_bits_in;

input [7:0] sizeof_stuffing_bits;


output [49:0] encoded_ecg;

output [5:0] sizeof_encoded_ecg;


reg [49:0] encoded_ecg, Data_part, Data_part_unary_prefix, Data_part_VEC_prefix, Data_part_VEC_suffix, stuffing_bits_part, sign_bits_part;

reg [5:0] sizeof_encoded_ecg;


wire sign_bits_present, stuffing_bits_present,VEC_or_CPEC;

wire [5:0] Data_size, Sum_of_data_and_stuffing_size, Sum_of_bits_req_and_VEC_prefix_size;

reg [9:0] Unary_prefix_data;




//===================================================
//	 ARCHITECTURE
//===================================================



	///// USING ASSIGN STATEMENTS TO GENERATE SIGNALS USED LATER //////


assign sign_bits_present = ((ecgidx==3) && (!component_skip)) ? 1:0;					// Checking required condition for sign bits to be present in current ECG.

assign stuffing_bits_present = ((ecgidx>0) && underflow_prevention) ? 1:0;				// Checking required condition for stuffing bits to be present in current ECG.


assign VEC_or_CPEC = (Bits_req>2) ? 1:0;												// To check which one of CPEC or VEC is to be used for encoding samples.


assign Data_size = (Data_Active)? ((VEC_or_CPEC) ? ( 1 + Bits_req + size_CPEC_encoded ) :  ( 1 + Bits_req + size_VEC_prefix + size_VEC_suffix )) : 0 ;			// Determining size of data part depending on Data Active signal whether VEC or CPEC used.


assign Sum_of_data_and_stuffing_size = Data_size + sizeof_stuffing_bits ;				// Getting sum of data size and size of stuffing bits to know how much the sign bits needed to be shifted.

assign Sum_of_bits_req_and_VEC_prefix_size = Bits_req + size_VEC_prefix;				// Getting sum of Bits required and size of VEC prefix to know how much the suffix part needed to be shifted in VEC coded ECG.





	///// MAIN BLOCK ////

//* Generate three parts (Data, Stuffing_bits, and sign_bits) each of size 50 bits. *//
//* Generating final encoded ECG using 'OR' operation for three parts (Data, Stuffing_bits, and sign_bits)  obtained in later blocks *//
//* Getting its exact size using case structure *// 


always@ (*)
begin

sizeof_encoded_ecg = 0;

encoded_ecg = Data_part | sign_bits_part | stuffing_bits_part ;					// 'OR' all three part.


	case({Data_Active,sign_bits_present,stuffing_bits_present})				// Generating size of ECG Based on which of the three parts are active in it. 

	3'b000:sizeof_encoded_ecg = 0;
	
	3'b001:sizeof_encoded_ecg = sizeof_stuffing_bits;
	
	3'b010:sizeof_encoded_ecg = sizeof_sign_bits_in;
	
	3'b011:sizeof_encoded_ecg = sizeof_sign_bits_in + sizeof_stuffing_bits ;
	
	3'b100:sizeof_encoded_ecg = Data_size;
	
	3'b101:sizeof_encoded_ecg = Data_size + sizeof_stuffing_bits ;
	
	3'b111:sizeof_encoded_ecg = Data_size + sizeof_stuffing_bits + sizeof_sign_bits_in;
	
	default: sizeof_encoded_ecg =0;

	
	endcase

end




/// BLOCK FOR OBTAINING DATA PART ///

//* First check Data Active signal if it is inactive assign  data part 0 *//
//* If active then check status of Group Skip Flag and if it is assign only MSB as 1 to generate Data part *//
//* If not then check whether CPEC or VEC is to be used. *//
//* If CPEC used then obtain Data part directly using Unary coded prefix and CPEC encoded data. Leave space(MSB) for GSF which will take value 0 as initially assigned.  *//
//* If VEC used then generate three sub-parts namely unary-prefix, prefix and suffix and use 'OR' operation to club these sub-parts. Leave space for GSF. *//


always@(*)
begin

	if (!Data_Active)									// Check Data Active signal.
	
	Data_part = 0;
	
	else
	begin
	
	Data_part = 0;

		if (Group_skip_flag)							// Check Group_skip_flag.
		
			Data_part[49] = 1'b1;						// Generate GSF in Data part by assigning MSB '1'.
			
		else
		begin
			
		Unary_prefix_data = 10'b1111111110;				// Store unary coded prefix data (for 10 bits) in temporary register and generate the unary prefix part depending on the Bits required . 
			
			if (VEC_or_CPEC)							// Check whether CPEC or VEC to be used.
			begin

		////// CPEC ////////
				
				
				case(Bits_req)																		// In CPEC, Data part can be directly obtained from Bits required. Use case to determine Bits_req.
				
				4'd3: Data_part[48:34] = {Unary_prefix_data[2:0],CPEC_encoded[11:0]};				// Concatenate unary prefix and CPEC code samples.
				
				4'd4: Data_part[48:29] = {Unary_prefix_data[3:0],CPEC_encoded[15:0]};
				
				4'd5: Data_part[48:24] = {Unary_prefix_data[4:0],CPEC_encoded[19:0]};
				
				4'd6: Data_part[48:19] = {Unary_prefix_data[5:0],CPEC_encoded[23:0]};
				
				4'd7: Data_part[48:14] = {Unary_prefix_data[6:0],CPEC_encoded[27:0]};
				
				4'd8: Data_part[48:9] = {Unary_prefix_data[7:0],CPEC_encoded[31:0]};
				
				4'd9: Data_part[48:4] = {Unary_prefix_data[8:0],CPEC_encoded[35:0]};
				
				4'd10: Data_part[48:0] = {Unary_prefix_data[9:1],CPEC_encoded[39:0]};			
				
				default: Data_part=0;

				endcase
			
			end

		
		
		///////// VEC ////////
		
		// Make three sub-parts each of size 50 bits. //
			
			else
			begin
			
			Data_part_unary_prefix = 0;									// Initially assign all three sub parts as 0;		
			
			Data_part_VEC_prefix = 0;
			
			Data_part_VEC_suffix = 0;
				
				
			/// Unary prefix sub-part ////
				
				case(Bits_req)											// Get bits required using case.
				
				
				4'd1: Data_part_unary_prefix[48] = Unary_prefix_data[0];			// Generate unary_prefix sub-part from initially assigned temporary register value.
				
				4'd2: Data_part_unary_prefix[48:47] = Unary_prefix_data[1:0];
				
				default: Data_part_unary_prefix = 0;
				
				endcase

				
			//// VEC prefix sub-part ///	
				
				case(size_VEC_prefix)											// Get the size of VEC prefix. 
				
				3'd0: Data_part_VEC_prefix = 0;
				
				3'd1: Data_part_VEC_prefix[48] = VEC_prefix[0];					// Generate VEC prefix part from VEC_prefix generated in VEC_encoder sub module.			
				
				3'd2: Data_part_VEC_prefix[48:47] = VEC_prefix[1:0];
				
				3'd3: Data_part_VEC_prefix[48:46] = VEC_prefix[2:0];
				
				3'd4: Data_part_VEC_prefix[48:45] = VEC_prefix[3:0];
				
				3'd5: Data_part_VEC_prefix[48:44] = VEC_prefix[4:0];
				
				3'd6: Data_part_VEC_prefix[48:43] = VEC_prefix[5:0];
				
				3'd7: Data_part_VEC_prefix[48:42] = VEC_prefix[6:0];
				
				default: Data_part_VEC_prefix = 0;
				
				endcase

				
				
				case (Bits_req)														// Depending on Bits required, which is also the size of unary prefix, right shift the VEC prefix sub-part and store it back in itself.
				
				4'd1: Data_part_VEC_prefix = Data_part_VEC_prefix>>1;
				
				4'd2: Data_part_VEC_prefix = Data_part_VEC_prefix>>2;
				
				default: Data_part_VEC_prefix=0;
				
				endcase

				
			///// VEC Suffix sub-part ///
				
				case(size_VEC_suffix)							// Get the size of VEC suffix.
				
				3'd0: Data_part_VEC_suffix = 0;					// Generate VEC suffix part from VEC_suffix generated in VEC_encoder sub module.
				
				3'd1: Data_part_VEC_suffix[48] = VEC_suffix[0];
				
				3'd2: Data_part_VEC_suffix[48:47] = VEC_suffix[1:0];
				
				3'd3: Data_part_VEC_suffix[48:46] = VEC_suffix[2:0];
				
				3'd4: Data_part_VEC_suffix[48:45] = VEC_suffix[3:0];
				
				3'd5: Data_part_VEC_suffix[48:44] = VEC_suffix[4:0];
				
				default: Data_part_VEC_suffix = 0;
				
				endcase

				// Depending on sum of Bits required and size of vec prefix, right shift the VEC suffix sub-part and store it back in itself.
				
				case (Sum_of_bits_req_and_VEC_prefix_size)
				
				6'd1: Data_part_VEC_suffix = Data_part_VEC_suffix >> 1;
				
				6'd2: Data_part_VEC_suffix = Data_part_VEC_suffix >> 2;
				
				6'd3: Data_part_VEC_suffix = Data_part_VEC_suffix >> 3;
				
				6'd4: Data_part_VEC_suffix = Data_part_VEC_suffix >> 4;
				
				6'd5: Data_part_VEC_suffix = Data_part_VEC_suffix >> 5; 
				
				6'd6: Data_part_VEC_suffix = Data_part_VEC_suffix >> 6;
				
				6'd7: Data_part_VEC_suffix = Data_part_VEC_suffix >> 7;
				
				6'd8: Data_part_VEC_suffix = Data_part_VEC_suffix >> 8;
				
				6'd9: Data_part_VEC_suffix = Data_part_VEC_suffix >> 9; 
				
				default: Data_part_VEC_suffix= 0;
				
				endcase

		//// Take 'OR' of all three sub-parts to generate Data part in case in which VEC coding is used. ////		
			
			
			Data_part = Data_part_unary_prefix | Data_part_VEC_prefix | Data_part_VEC_suffix;

			end
		
		end
	
	end


	

end






/// BLOCK FOR OBTAINING STUFFING_BITS PART ///

//* First assign the stuffing_bits data using cases for its size (starting from MSB)  *//
//* Shift this data to the right by the amount mentioned by size of data part. Use cases for it *//




always@(*) 
begin
	
	if(stuffing_bits_present)							// First check whether the sign part is present or not.
	begin

	stuffing_bits_part=0;

		case(sizeof_stuffing_bits)

		8'd0: stuffing_bits_part = 0;
			
		8'd1: stuffing_bits_part[49] = 1'b1;
			
		8'd2: stuffing_bits_part[49:48] = 2'b11;
			
		8'd3: stuffing_bits_part[49:47] = 3'b111;
			
		8'd4: stuffing_bits_part[49:46] = 4'b1111;
			
		8'd5: stuffing_bits_part[49:45] = 5'b11111;
			
		8'd6: stuffing_bits_part[49:44] = 6'b111111;
			
		8'd7: stuffing_bits_part[49:43] = 7'b1111111;
			
		8'd8: stuffing_bits_part[49:42] = 8'b11111111;
			
		8'd9: stuffing_bits_part[49:41] = 9'b111111111;
			
		8'd10: stuffing_bits_part[49:40] = 10'b1111111111;
		
		8'd11: stuffing_bits_part[49:39] = 11'b11111111111;
			
		8'd12: stuffing_bits_part[49:38] = 12'b111111111111;
			
		8'd13: stuffing_bits_part[49:37] = 13'b1111111111111;
			
		8'd14: stuffing_bits_part[49:36] = 14'b11111111111111;
			
		8'd15: stuffing_bits_part[49:35] = 15'b111111111111111;
			
		8'd16: stuffing_bits_part[49:34] = 16'b1111111111111111;
			
		8'd17: stuffing_bits_part[49:33] = 17'b11111111111111111;
			
		default: stuffing_bits_part = 0;
		
		endcase
			
//* Using case structure to check the amount we need to right shift the sign bits part. *// 
		
		
		case(Data_size)
		
		6'd0: stuffing_bits_part = stuffing_bits_part>>0;
			
		6'd1: stuffing_bits_part = stuffing_bits_part>> 1;
			
		6'd2: stuffing_bits_part = stuffing_bits_part >> 2;
			
		6'd3: stuffing_bits_part = stuffing_bits_part >> 3;
			
		6'd4: stuffing_bits_part = stuffing_bits_part >> 4;
			
		6'd5: stuffing_bits_part = stuffing_bits_part >> 5;
			
		6'd6: stuffing_bits_part = stuffing_bits_part >> 6;
			
		6'd7: stuffing_bits_part = stuffing_bits_part >> 7;
			
		6'd8: stuffing_bits_part = stuffing_bits_part >> 8;
			
		6'd9: stuffing_bits_part = stuffing_bits_part >> 9;
			
		6'd10: stuffing_bits_part = stuffing_bits_part >> 10;
			
		6'd11: stuffing_bits_part = stuffing_bits_part >> 11;
			
		6'd12: stuffing_bits_part = stuffing_bits_part >> 12;
			
		6'd13: stuffing_bits_part = stuffing_bits_part >> 13;
			
		6'd14: stuffing_bits_part = stuffing_bits_part >> 14;
			
		6'd15: stuffing_bits_part = stuffing_bits_part >> 15;
			
		6'd16: stuffing_bits_part = stuffing_bits_part >> 16;
			
		6'd17: stuffing_bits_part = stuffing_bits_part >> 17;
			
		6'd18: stuffing_bits_part = stuffing_bits_part >> 18;
			
		6'd19: stuffing_bits_part = stuffing_bits_part >> 19;
			
		6'd20: stuffing_bits_part = stuffing_bits_part >> 20;
			
		6'd21: stuffing_bits_part = stuffing_bits_part >> 21;
			
		6'd22: stuffing_bits_part = stuffing_bits_part >> 22;
			
		6'd23: stuffing_bits_part = stuffing_bits_part >> 23;
			
		6'd24: stuffing_bits_part = stuffing_bits_part >> 24;
			
		6'd25: stuffing_bits_part = stuffing_bits_part >> 25;
			
		6'd26: stuffing_bits_part = stuffing_bits_part >> 26;
			
		6'd27: stuffing_bits_part = stuffing_bits_part >> 27;
			
		6'd28: stuffing_bits_part = stuffing_bits_part >> 28;
			
		6'd29: stuffing_bits_part = stuffing_bits_part >> 29;
			
		6'd30: stuffing_bits_part = stuffing_bits_part >> 30;
			
		6'd31: stuffing_bits_part = stuffing_bits_part >> 31;
			
		6'd32: stuffing_bits_part = stuffing_bits_part >> 32;
			
		6'd33: stuffing_bits_part = stuffing_bits_part >> 33;
			
		6'd34: stuffing_bits_part = stuffing_bits_part >> 34;
			
		6'd35: stuffing_bits_part = stuffing_bits_part >> 35;
			
		6'd36: stuffing_bits_part = stuffing_bits_part >> 36;
			
		6'd37: stuffing_bits_part = stuffing_bits_part >> 37;
			
		6'd38: stuffing_bits_part = stuffing_bits_part >> 38;
			
		6'd39: stuffing_bits_part = stuffing_bits_part >> 39;
			
		6'd40: stuffing_bits_part = stuffing_bits_part >> 40;
			
		6'd41: stuffing_bits_part = stuffing_bits_part >> 41;
			
		6'd42: stuffing_bits_part = stuffing_bits_part >> 42;
		
		6'd43: stuffing_bits_part = stuffing_bits_part >> 43;
			
		6'd44: stuffing_bits_part = stuffing_bits_part >> 44;
			
		6'd45: stuffing_bits_part = stuffing_bits_part >> 45;
			
		6'd46: stuffing_bits_part = stuffing_bits_part >> 46;
			
		6'd47: stuffing_bits_part = stuffing_bits_part >> 47;
			
		6'd48: stuffing_bits_part = stuffing_bits_part >> 48;
			
		6'd49: stuffing_bits_part = stuffing_bits_part >> 49;
			
		6'd50: stuffing_bits_part = stuffing_bits_part >> 50;
			
		default: stuffing_bits_part = stuffing_bits_part>>50;		
			
			
		endcase
		
	end

		else
		stuffing_bits_part=0;

end



		/// BLOCK FOR OBTAINING SIGN_BITS PART ///

//* First assign the sign_bits data using cases for its size (starting from MSB)  *//
//* Shift this data to the right by the amount mentioned by sum of data size and size of stuffing bits. Use cases for it *//



always@ (*) 
begin

	if(!sign_bits_present) 						// First check whether the sign part is present or not.
	
	sign_bits_part=0;							// If not assign sign_bits_part as 0.
	
	else
	begin
	
	sign_bits_part=0;						// initially assign sign_bits_part as 0.

		case(sizeof_sign_bits_in)				// If it is present use case structure to get the size we need to take from input and assign it to sign_bits_part.

		4'b0000: sign_bits_part = 0;
		
		4'b0001: sign_bits_part[49] = sign_bits_in[0];
		
		4'b0010: sign_bits_part[49:48] = sign_bits_in[1:0];
		
		4'b0011: sign_bits_part[49:47] = sign_bits_in[2:0];
		
		4'b0100: sign_bits_part[49:46] = sign_bits_in[3:0];
		
		4'b0101: sign_bits_part[49:45] = sign_bits_in[4:0];
		
		4'b0110: sign_bits_part[49:44] = sign_bits_in[5:0];
		
		4'b0111: sign_bits_part[49:43] = sign_bits_in[6:0];
		
		4'b1000: sign_bits_part[49:42] = sign_bits_in[7:0];
		
		4'b1001: sign_bits_part[49:41] = sign_bits_in[8:0];
		
		4'b1010: sign_bits_part[49:40] = sign_bits_in[9:0];
		
		4'b1011: sign_bits_part[49:39] = sign_bits_in[10:0];
		
		4'b1100: sign_bits_part[49:38] = sign_bits_in[11:0];
		
		default: sign_bits_part = 0;

		endcase
	
	
	//* Using case structure to check the amount we need to right shift the sign bits part. *// 
	
	
		case(Sum_of_data_and_stuffing_size)
		
		6'd0: sign_bits_part = sign_bits_part>>0;
		
		6'd1: sign_bits_part = sign_bits_part >> 1;						
		
		6'd2: sign_bits_part = sign_bits_part >> 2;
		
		6'd3: sign_bits_part = sign_bits_part >> 3;
		
		6'd4: sign_bits_part = sign_bits_part >> 4;
		
		6'd5: sign_bits_part = sign_bits_part >> 5;
		
		6'd6: sign_bits_part = sign_bits_part >> 6;
		
		6'd7: sign_bits_part = sign_bits_part >> 7;
		
		6'd8: sign_bits_part = sign_bits_part >> 8;
		
		6'd9: sign_bits_part = sign_bits_part >> 9;
		
		6'd10: sign_bits_part = sign_bits_part >> 10;
		
		6'd11: sign_bits_part = sign_bits_part >> 11;
		
		6'd12: sign_bits_part = sign_bits_part >> 12;
		
		6'd13: sign_bits_part = sign_bits_part >> 13;
		
		6'd14: sign_bits_part = sign_bits_part >> 14;
		
		6'd15: sign_bits_part = sign_bits_part >> 15;
		
		6'd16: sign_bits_part = sign_bits_part >> 16;
		
		6'd17: sign_bits_part = sign_bits_part >> 17;
		
		6'd18: sign_bits_part = sign_bits_part >> 18;
		
		6'd19: sign_bits_part = sign_bits_part >> 19;
		
		6'd20: sign_bits_part = sign_bits_part >> 20;
		
		6'd21: sign_bits_part = sign_bits_part >> 21;
		
		6'd22: sign_bits_part = sign_bits_part >> 22;
		
		6'd23: sign_bits_part = sign_bits_part >> 23;
		
		6'd24: sign_bits_part = sign_bits_part >> 24;
		
		6'd25: sign_bits_part = sign_bits_part >> 25;
		
		6'd26: sign_bits_part = sign_bits_part >> 26;
		
		6'd27: sign_bits_part = sign_bits_part >> 27;
		
		6'd28: sign_bits_part = sign_bits_part >> 28;
		
		6'd29: sign_bits_part = sign_bits_part >> 29;
		
		6'd30: sign_bits_part = sign_bits_part >> 30;
		
		6'd31: sign_bits_part = sign_bits_part >> 31;
		
		6'd32: sign_bits_part = sign_bits_part >> 32;
		
		6'd33: sign_bits_part = sign_bits_part >> 33;
		
		6'd34: sign_bits_part = sign_bits_part >> 34;
		
		6'd35: sign_bits_part = sign_bits_part >> 35;
		
		6'd36: sign_bits_part = sign_bits_part >> 36;
		
		6'd37: sign_bits_part = sign_bits_part >> 37;
		
		6'd38: sign_bits_part = sign_bits_part >> 38;
		
		6'd39: sign_bits_part = sign_bits_part >> 39;
		
		6'd40: sign_bits_part = sign_bits_part >> 40;
		
		6'd41: sign_bits_part = sign_bits_part >> 41;
		
		6'd42: sign_bits_part = sign_bits_part >> 42;
		
		6'd43: sign_bits_part = sign_bits_part >> 43;
		
		6'd44: sign_bits_part = sign_bits_part >> 44;
		
		6'd45: sign_bits_part = sign_bits_part >> 45;
		
		6'd46: sign_bits_part = sign_bits_part >> 46;
		
		6'd47: sign_bits_part = sign_bits_part >> 47;
		
		6'd48: sign_bits_part = sign_bits_part >> 48;
		
		6'd49: sign_bits_part = sign_bits_part >> 49;
		
		6'd50: sign_bits_part = sign_bits_part >> 50;
		
		default: sign_bits_part = sign_bits_part>>50;

		endcase

	end

	

end



endmodule


//===================================================
// END
//===================================================
 

	  




	












		



	