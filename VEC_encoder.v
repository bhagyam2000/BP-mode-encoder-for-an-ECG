module VEC_encoder (sample_1,sample_2,sample_3,sample_4,ecgidx,Bits_req,Group_skip_flag,component_idx,VEC_prefix,size_VEC_prefix,VEC_suffix,size_VEC_suffix);

parameter J=10;			// parameter represent width of data to be given at the time of its instantiation.

input signed [J-1:0] sample_1,sample_2,sample_3,sample_4;
input [1:0] ecgidx,component_idx;
input [3:0] Bits_req;
input Group_skip_flag;
output [6:0] VEC_prefix;
output [2:0] size_VEC_prefix;
output [4:0] VEC_suffix;
output [2:0] size_VEC_suffix;
reg [6:0] VEC_prefix;
reg [2:0] size_VEC_prefix;
reg [4:0] VEC_suffix;
reg [2:0] size_VEC_suffix;
wire [7:0] VEC_code_symbol;
wire [7:0] VEC_code_number;
wire luma_chroma,SM_2C ;
wire [2:0] vecGrK;
wire [7:0] quotient;
wire [4:0] suffix;
wire [6:0] prefix;
wire [2:0] size_prefix;



assign luma_chroma = (component_idx==0)?0:1;     // differentiate between luma and chroma component and assign a varibale accordingly.
assign SM_2C = (ecgidx==3)?1:0; 				// differentiate between SM or 2's complement form and assign a varibale accordingly.



VEC_vector_to_scalar #(J) u1(sample_1,sample_2,sample_3,sample_4,Bits_req,VEC_code_symbol);		//instantiating sub-modules

VEC_symbol_to_number u2(VEC_code_symbol,Bits_req,luma_chroma,SM_2C,VEC_code_number) ;


VEC_vecGrK_calculator  u3(SM_2C,Bits_req,vecGrK);

VEC_get_suffix u4(VEC_code_number,vecGrK,quotient,suffix);

VEC_get_prefix u5(quotient,prefix,size_prefix);


always@(*)			
begin
if ((Group_skip_flag)||(Bits_req>2))		// if group skip flag is active or bits required is more than two than assign all the outputs zero.
begin
VEC_prefix=0;
size_VEC_prefix=0;
VEC_suffix=0;
size_VEC_suffix=0;
end
else										// else assign outputs as given by sub modules.
begin
VEC_prefix=prefix;
size_VEC_prefix=size_prefix;
VEC_suffix=suffix;
size_VEC_suffix=vecGrK;						// size of suffix is same as vecGrK.
end
end
endmodule


// Following submodule converts 4 samples vector into a scalar symbol generated uniquely for each possible combination of samples data. 


module VEC_vector_to_scalar(sample_1,sample_2,sample_3,sample_4,Bits_req,VEC_code_symbol);

parameter K=10;

input [K-1:0] sample_1,sample_2,sample_3,sample_4;
input [3:0] Bits_req;
output [7:0] VEC_code_symbol;
reg [7:0] VEC_code_symbol;


always @(*)
begin
VEC_code_symbol=0;			//initially assigned zero.

case(Bits_req[1:0])				// implementation of table 4-64 in specs.


// case with zero bits required leads to group skip flag activation, covered in top module.

2'b01:
VEC_code_symbol[3:0] = {sample_1[0],sample_2[0],sample_3[0],sample_4[0]} ;			// for case in which bits required is 1, symbol is made up of 1 bit (LSB) from each sample. 

2'b10:
VEC_code_symbol[7:0] = {sample_1[1:0],sample_2[1:0],sample_3[1:0],sample_4[1:0]} ;		// if bits required is 2 than, symbol is made up of 2 bits (LSB) from each sample.

default: VEC_code_symbol = 8'bz;

endcase
end
endmodule




// Following submodule tells the vecGrK parameter required in encoding.



module VEC_vecGrK_calculator(SM_2C,Bits_req,vecGrK);

input  SM_2C;
input [3:0] Bits_req;
output [2:0] vecGrK;
reg [2:0] vecGrK;

always@ (*)
begin
case({SM_2C,Bits_req[1:0]})				// case structure is used with MSB telling the SM or 2's complement form and the rest 2 bits telling the bits required.
3'b001: vecGrK = 2;
3'b101: vecGrK = 1;						// implementation of table 4-65 from specs.
3'b010: vecGrK = 5;
3'b110: vecGrK = 5;
default: vecGrK = 0;

endcase
end
endmodule


// Following submodule calculates quotient and remainder required for Golomb-Rice coding and thus gives the suffix (Remainder).


module VEC_get_suffix(VEC_code_number,vecGrK,quotient,suffix);

input [7:0] VEC_code_number;
input [2:0] vecGrK;
output [7:0] quotient;
output [4:0] suffix;
reg [4:0] suffix;
reg [7:0] quotient;
reg [7:0] remainder;
											
always@(*)										 // Impelmentation of logic shown in table 4-66 (for the suffix part) and examples in tables 4-67, 4-68 ,4-69  from specs.
begin
if(vecGrK==1)									
begin
quotient = VEC_code_number>>1;					// For case in which vecGrK is 1 divide the number by 2 and get quotient and remainder. 
remainder = VEC_code_number - (quotient<<1);
suffix = remainder[4:0];
end

else if(vecGrK==2)
begin
quotient = VEC_code_number>>2;						// For case in which vecGrK is 2 divide the number by 4 and get quotient and remainder. 
remainder = VEC_code_number - (quotient<<2);
suffix = remainder[4:0];
end
else if(vecGrK==5)
begin
quotient = VEC_code_number>>5;
remainder = VEC_code_number - (quotient<<5);		// For case in which vecGrK is 5 divide the number by 32 and get quotient and remainder. 
suffix = remainder[4:0];
end
end
endmodule



// Following submodule takes quotient calculated in above submodule and generates the prefix and its size for Golomb-Rice coding.


module VEC_get_prefix (quotient,prefix,size_prefix);

input [7:0] quotient;
output [6:0] prefix;
output [2:0] size_prefix;
reg [6:0] prefix;
reg [2:0] size_prefix;

always@(*)						// Impelmentation of logic shown in table 4-66 (for the prefix part) and examples in tables 4-67, 4-68 ,4-69  from specs.
begin
case(quotient[2:0])				// case structure with three bits taken from LSB (because 3 bits can represent the maximum quotient) of quotient is taken.

3'b000: 
begin
prefix = 7'b0000000;			
size_prefix = 1;
end

3'b001: 
begin
prefix = 7'b0000010;
size_prefix = 2;
end

3'b010: 
begin
prefix = 7'b0000110;
size_prefix = 3;
end

3'b011: 
begin
prefix = 7'b0001110;
size_prefix = 4;
end

3'b100: 
begin
prefix = 7'b0011110;
size_prefix = 5;
end

3'b101: 
begin
prefix = 7'b0111110;
size_prefix = 6;
end

3'b110: 
begin
prefix = 7'b1111110;
size_prefix = 7;
end

3'b111: 
begin
prefix = 7'b1111111;
size_prefix = 7;
end
endcase
end
endmodule


// Following submodule converts the code symbol to the number referring to lookup tables.

module VEC_symbol_to_number (VEC_code_symbol,Bits_req,luma_chroma,SM_2C,VEC_code_number) ;

input [7:0] VEC_code_symbol;
input [3:0] Bits_req;
input luma_chroma,SM_2C;
output [7:0] VEC_code_number;
reg [7:0] VEC_code_number;

always @(*)
begin
if(Bits_req==1)
begin
case({luma_chroma,SM_2C,VEC_code_symbol[3:0]})		// case structure with MSB telling whether the group belongs to Luma or chroma followed by a bit telling SM or 2's complementform used followed by 4 bits of symbol ( since bits required is 1) from LSB is taken


//  Lookup table for case in which bits required is 1 and group belongs to Luma and SM form =  { 15, 1, 0, 6, 3, 5, 8, 10, 2, 7, 4, 11, 9, 13, 12, 14 } 
//  Lookup table for case in which bits required is 1 and group belongs to Chroma and SM form = { 15, 1, 0, 4, 2, 7, 8, 11, 3, 9, 6, 10, 5, 12, 13, 14 }  
//Lookup table for case in which bits required is 1 and group belongs to Luma and 2's complement form = { 15, 1, 0, 4, 3, 5, 9, 10, 2, 8, 6, 11, 7, 13, 12, 14 }
//Lookup table for case in which bits required is 1 and group belongs to Chroma and 2's complement form = { 15, 1, 0, 4, 2, 6, 8, 11, 3, 9, 7, 12, 5, 13, 14, 10 }

6'b000000: VEC_code_number= 15;
6'b000001: VEC_code_number= 1;				 
6'b000010: VEC_code_number= 0;
6'b000011: VEC_code_number= 6;					// bits required is 1 and group belongs to Luma and SM form
6'b000100: VEC_code_number= 3;
6'b000101: VEC_code_number= 5;
6'b000110: VEC_code_number= 8;
6'b000111: VEC_code_number= 10;
6'b001000: VEC_code_number= 2;
6'b001001: VEC_code_number= 7;
6'b001010: VEC_code_number= 4;
6'b001011: VEC_code_number= 11;
6'b001100: VEC_code_number= 9;
6'b001101: VEC_code_number= 13;
6'b001110: VEC_code_number= 12;
6'b001111: VEC_code_number= 14;

6'b100000: VEC_code_number= 15;
6'b100001: VEC_code_number= 1;				//bits required is 1 and group belongs to Chroma and SM form
6'b100010: VEC_code_number= 0;
6'b100011: VEC_code_number= 4;
6'b100100: VEC_code_number= 2;
6'b100101: VEC_code_number= 7;
6'b100110: VEC_code_number= 8;
6'b100111: VEC_code_number= 11;
6'b101000: VEC_code_number= 3;
6'b101001: VEC_code_number= 9;
6'b101010: VEC_code_number= 6;
6'b101011: VEC_code_number= 10;
6'b101100: VEC_code_number= 5;
6'b101101: VEC_code_number= 12;
6'b101110: VEC_code_number= 13;
6'b101111: VEC_code_number= 14;

6'b010000: VEC_code_number= 15;
6'b010001: VEC_code_number= 1;
6'b010010: VEC_code_number= 0;				//bits required is 1 and group belongs to Luma and 2's complement form
6'b010011: VEC_code_number= 4;
6'b010100: VEC_code_number= 2;
6'b010101: VEC_code_number= 5;
6'b010110: VEC_code_number= 9;
6'b010111: VEC_code_number= 10;
6'b011000: VEC_code_number= 2;
6'b011001: VEC_code_number= 8;
6'b011010: VEC_code_number= 6;
6'b011011: VEC_code_number= 11;
6'b011100: VEC_code_number= 7;
6'b011101: VEC_code_number= 13;
6'b011110: VEC_code_number= 12;
6'b011111: VEC_code_number= 14;

6'b110000: VEC_code_number= 15;
6'b110001: VEC_code_number= 1;
6'b110010: VEC_code_number= 0;
6'b110011: VEC_code_number= 4;				// bits required is 1 and group belongs to Chroma and 2's complement form
6'b110100: VEC_code_number= 2;
6'b110101: VEC_code_number= 6;
6'b110110: VEC_code_number= 8;
6'b110111: VEC_code_number= 11;
6'b111000: VEC_code_number= 3;
6'b111001: VEC_code_number= 9;
6'b111010: VEC_code_number= 7;
6'b111011: VEC_code_number= 12;
6'b111100: VEC_code_number= 5;
6'b111101: VEC_code_number= 13;
6'b111110: VEC_code_number= 14;
6'b111111: VEC_code_number= 10;

endcase
end


//Lookup table for case in which bits required is 2 and group belongs to Luma and SM form = { 255, 247, 0, 30, 251, 243, 4, 43, 1, 5, 12, 64, 29, 45, 66, 48, 253, 245, 6, 46, 249, 241, 16, 67, 13, 20, 44, 108, 63, 79, 109, 124, 3, 10, 34, 85, 17, 27, 59, 112, 61, 68, 114, 166, 140, 146, 180, 205, 40, 54, 95, 107, 72, 89, 126, 164, 137, 144, 178, 213, 189, 197, 220, 236, 254, 246, 14, 62, 250, 242, 21, 77, 7, 18, 42, 113, 47, 71, 110, 134, 252, 244, 23, 80, 248, 240, 26, 87, 24, 28, 38, 106, 83, 93, 102, 94, 8, 22, 55, 119, 32, 35, 50, 122, 74, 82, 99, 157, 145, 149, 171, 188, 49, 86, 121, 168, 97, 100, 133, 154, 155, 158, 175, 198, 210, 203, 215, 228, 2, 15, 56, 138, 11, 31, 69, 151, 37, 60, 111, 184, 96, 117, 161, 206, 9, 33, 78, 148, 25, 36, 76, 153, 65, 51, 98, 170, 132, 128, 142, 191, 19, 53, 120, 196, 57, 41, 101, 183, 118, 103, 81, 169, 199, 174, 181, 147, 84, 123, 185, 208, 135, 127, 162, 204, 194, 186, 173, 200, 231, 219, 227, 223, 39, 70, 136, 182, 52, 88, 152, 207, 92, 129, 176, 224, 115, 172, 211, 235, 58, 90, 143, 195, 91, 105, 156, 216, 131, 139, 177, 221, 165, 163, 217, 238, 75, 125, 192, 234, 130, 116, 179, 226, 187, 160, 190, 229, 230, 212, 201, 214, 73, 150, 225, 233, 141, 104, 193, 237, 209, 202, 159, 218, 239, 232, 222, 167 };
//Lookup table for case in which bits required is 2 and group belongs to Chroma and SM form = { 255, 247, 1, 19, 251, 243, 4, 40, 0, 5, 34, 84, 18, 39, 82, 120, 253, 245, 6, 42, 249, 241, 16, 62, 11, 20, 56, 102, 46, 65, 109, 154, 3, 9, 35, 85, 13, 24, 55, 100, 44, 61, 103, 156, 97, 125, 171, 193, 29, 45, 88, 135, 52, 76, 113, 153, 99, 126, 167, 203, 151, 180, 204, 223, 254, 246, 10, 47, 250, 242, 21, 64, 7, 17, 54, 110, 41, 60, 106, 150, 252, 244, 23, 63, 248, 240, 32, 89, 22, 33, 67, 136, 66, 86, 139, 174, 15, 27, 58, 115, 31, 38, 75, 131, 72, 87, 111, 165, 128, 145, 187, 201, 50, 74, 112, 157, 80, 92, 144, 158, 133, 143, 178, 213, 179, 192, 211, 231, 2, 12, 48, 96, 8, 25, 68, 134, 36, 57, 101, 163, 90, 108, 159, 197, 14, 30, 71, 132, 26, 37, 83, 141, 59, 70, 117, 172, 114, 140, 170, 216, 43, 73, 105, 160, 69, 81, 116, 188, 107, 119, 123, 198, 176, 186, 195, 225, 94, 122, 161, 202, 138, 146, 182, 210, 175, 185, 194, 221, 219, 220, 233, 236, 28, 53, 98, 149, 49, 77, 121, 169, 91, 104, 164, 199, 130, 152, 196, 224, 51, 79, 124, 181, 78, 93, 148, 191, 118, 127, 189, 217, 155, 162, 208, 226, 95, 137, 177, 218, 129, 142, 190, 215, 166, 183, 200, 229, 206, 209, 227, 235, 147, 173, 207, 234, 168, 184, 205, 228, 212, 214, 222, 239, 232, 230, 237, 238 };
//Lookup table for case in which bits required is 2 and group belongs to Luma and TC form = { 255, 0, 21, 247, 1, 6, 71, 18, 20, 70, 79, 42, 251, 19, 31, 243, 3, 5, 67, 15, 9, 27, 127, 36, 69, 121, 160, 94, 13, 39, 97, 32, 24, 66, 80, 55, 65, 110, 179, 135, 140, 196, 209, 174, 74, 129, 162, 98, 253, 14, 33, 245, 12, 34, 143, 57, 75, 132, 154, 109, 249, 54, 85, 241, 2, 8, 52, 11, 4, 26, 116, 30, 60, 93, 164, 102, 17, 58, 91, 38, 7, 29, 120, 41, 28, 72, 171, 96, 111, 184, 206, 157, 37, 107, 161, 83, 73, 100, 180, 128, 136, 181, 218, 176, 183, 223, 237, 235, 145, 159, 228, 201, 23, 50, 95, 46, 49, 99, 165, 87, 131, 158, 231, 188, 56, 89, 190, 112, 25, 64, 146, 78, 63, 106, 186, 134, 81, 177, 210, 169, 51, 125, 197, 139, 76, 141, 198, 137, 117, 185, 222, 173, 195, 213, 236, 227, 142, 178, 232, 207, 86, 155, 216, 163, 170, 208, 238, 221, 215, 239, 217, 229, 168, 230, 226, 205, 61, 104, 191, 124, 113, 166, 233, 193, 153, 224, 214, 194, 92, 189, 211, 152, 254, 10, 77, 246, 16, 43, 144, 62, 45, 133, 149, 84, 250, 48, 105, 242, 22, 44, 130, 68, 47, 115, 175, 88, 126, 172, 225, 200, 59, 90, 192, 119, 53, 114, 167, 103, 101, 156, 219, 187, 182, 234, 220, 212, 122, 204, 202, 151, 252, 35, 118, 244, 40, 82, 199, 123, 108, 203, 150, 148, 248, 138, 147, 240 };
//Lookup table for case in which bits required is 2 and group belongs to Luma and TC form = { 255, 1, 22, 247, 0, 4, 64, 16, 23, 75, 31, 33, 251, 14, 32, 243, 3, 6, 79, 20, 9, 27, 169, 68, 62, 150, 143, 100, 12, 43, 117, 41, 25, 85, 74, 55, 63, 135, 179, 114, 160, 221, 203, 197, 82, 172, 142, 103, 253, 19, 38, 245, 11, 35, 125, 53, 71, 165, 108, 95, 249, 73, 81, 241, 2, 8, 61, 10, 7, 28, 126, 49, 86, 168, 144, 127, 15, 59, 96, 34, 5, 29, 137, 44, 30, 26, 208, 128, 140, 196, 133, 154, 46, 112, 155, 57, 78, 157, 182, 132, 146, 204, 205, 190, 220, 226, 238, 235, 166, 214, 232, 207, 17, 60, 111, 50, 52, 116, 178, 90, 164, 216, 222, 211, 67, 153, 199, 122, 24, 65, 162, 84, 83, 131, 217, 163, 80, 181, 195, 156, 54, 118, 193, 106, 77, 141, 223, 175, 167, 201, 227, 215, 185, 200, 237, 225, 145, 183, 233, 213, 47, 151, 202, 138, 158, 134, 239, 228, 212, 236, 115, 174, 130, 229, 177, 92, 37, 104, 189, 110, 129, 159, 234, 206, 152, 231, 180, 147, 91, 194, 187, 102, 254, 13, 72, 246, 21, 45, 171, 70, 42, 136, 109, 76, 250, 51, 97, 242, 18, 48, 173, 66, 69, 121, 218, 149, 124, 176, 219, 186, 56, 89, 210, 113, 36, 120, 148, 88, 101, 161, 224, 188, 191, 230, 170, 184, 105, 192, 139, 99, 252, 39, 107, 244, 40, 58, 209, 119, 98, 198, 87, 94, 248, 123, 93, 240 };


else if(Bits_req==2);
begin
case({luma_chroma,SM_2C,VEC_code_symbol})		//case structure with MSB telling whether the group belongs to Luma or chroma followed by a bit telling SM or 2's complementform used followed by  all 8 bits of symbol ( since bits required is 2) from LSB is taken

10'b0000000000: VEC_code_number=255;
10'b0000000001: VEC_code_number=247;
10'b0000000010: VEC_code_number=0;
10'b0000000011: VEC_code_number=30;
10'b0000000100: VEC_code_number=251;				// bits required is 2 and group belongs to Luma and SM form
10'b0000000101: VEC_code_number=243;
10'b0000000110: VEC_code_number=4;
10'b0000000111: VEC_code_number=43;
10'b0000001000: VEC_code_number=1;
10'b0000001001: VEC_code_number=5;
10'b0000001010: VEC_code_number=12;
10'b0000001011: VEC_code_number=64;
10'b0000001100: VEC_code_number=29;
10'b0000001101: VEC_code_number=45;
10'b0000001110: VEC_code_number=66;
10'b0000001111: VEC_code_number=48;
10'b0000010000: VEC_code_number=253;
10'b0000010001: VEC_code_number=245;
10'b0000010010: VEC_code_number=6;
10'b0000010011: VEC_code_number=46;
10'b0000010100: VEC_code_number=249;
10'b0000010101: VEC_code_number=241;
10'b0000010110: VEC_code_number=16;
10'b0000010111: VEC_code_number=67;
10'b0000011000: VEC_code_number=13;
10'b0000011001: VEC_code_number=20;
10'b0000011010: VEC_code_number=44;
10'b0000011011: VEC_code_number=108;
10'b0000011100: VEC_code_number=63;
10'b0000011101: VEC_code_number=79;
10'b0000011110: VEC_code_number=109;
10'b0000011111: VEC_code_number=124;
10'b0000100000: VEC_code_number=3;
10'b0000100001: VEC_code_number=10;
10'b0000100010: VEC_code_number=34;
10'b0000100011: VEC_code_number=85;
10'b0000100100: VEC_code_number=17;
10'b0000100101: VEC_code_number=27;
10'b0000100110: VEC_code_number=59;
10'b0000100111: VEC_code_number=112;
10'b0000101000: VEC_code_number=61;
10'b0000101001: VEC_code_number=68;
10'b0000101010: VEC_code_number=114;
10'b0000101011: VEC_code_number=166;
10'b0000101100: VEC_code_number=140;
10'b0000101101: VEC_code_number=146;
10'b0000101110: VEC_code_number=180;
10'b0000101111: VEC_code_number=205;
10'b0000110000: VEC_code_number=40;
10'b0000110001: VEC_code_number=54;
10'b0000110010: VEC_code_number=95;
10'b0000110011: VEC_code_number=107;
10'b0000110100: VEC_code_number=72;
10'b0000110101: VEC_code_number=89;
10'b0000110110: VEC_code_number=126;
10'b0000110111: VEC_code_number=164;
10'b0000111000: VEC_code_number=137;
10'b0000111001: VEC_code_number=144;
10'b0000111010: VEC_code_number=178;
10'b0000111011: VEC_code_number=213;
10'b0000111100: VEC_code_number=189;
10'b0000111101: VEC_code_number=197;
10'b0000111110: VEC_code_number=220;
10'b0000111111: VEC_code_number=236;
10'b0001000000: VEC_code_number=254;
10'b0001000001: VEC_code_number=246;
10'b0001000010: VEC_code_number=14;
10'b0001000011: VEC_code_number=62;
10'b0001000100: VEC_code_number=250;
10'b0001000101: VEC_code_number=242;
10'b0001000110: VEC_code_number=21;
10'b0001000111: VEC_code_number=77;
10'b0001001000: VEC_code_number=7;
10'b0001001001: VEC_code_number=18;
10'b0001001010: VEC_code_number=42;
10'b0001001011: VEC_code_number=113;
10'b0001001100: VEC_code_number=47;
10'b0001001101: VEC_code_number=71;
10'b0001001110: VEC_code_number=110;
10'b0001001111: VEC_code_number=134;
10'b0001010000: VEC_code_number=252;
10'b0001010001: VEC_code_number=244;
10'b0001010010: VEC_code_number=23;
10'b0001010011: VEC_code_number=80;
10'b0001010100: VEC_code_number=248;
10'b0001010101: VEC_code_number=240;
10'b0001010110: VEC_code_number=26;
10'b0001010111: VEC_code_number=87;
10'b0001011000: VEC_code_number=24;
10'b0001011001: VEC_code_number=28;
10'b0001011010: VEC_code_number=38;
10'b0001011011: VEC_code_number=106;
10'b0001011100: VEC_code_number=83;
10'b0001011101: VEC_code_number=93;
10'b0001011110: VEC_code_number=102;
10'b0001011111: VEC_code_number=94;
10'b0001100000: VEC_code_number=8;
10'b0001100001: VEC_code_number=22;
10'b0001100010: VEC_code_number=55;
10'b0001100011: VEC_code_number=119;
10'b0001100100: VEC_code_number=32;
10'b0001100101: VEC_code_number=35;
10'b0001100110: VEC_code_number=50;
10'b0001100111: VEC_code_number=122;
10'b0001101000: VEC_code_number=74;
10'b0001101001: VEC_code_number=82;
10'b0001101010: VEC_code_number=99;
10'b0001101011: VEC_code_number=157;
10'b0001101100: VEC_code_number=145;
10'b0001101101: VEC_code_number=149;
10'b0001101110: VEC_code_number=171;
10'b0001101111: VEC_code_number=188;
10'b0001110000: VEC_code_number=49;
10'b0001110001: VEC_code_number=86;
10'b0001110010: VEC_code_number=121;
10'b0001110011: VEC_code_number=168;
10'b0001110100: VEC_code_number=97;
10'b0001110101: VEC_code_number=100;
10'b0001110110: VEC_code_number=133;
10'b0001110111: VEC_code_number=154;
10'b0001111000: VEC_code_number=155;
10'b0001111001: VEC_code_number=158;
10'b0001111010: VEC_code_number=175;
10'b0001111011: VEC_code_number=198;
10'b0001111100: VEC_code_number=210;
10'b0001111101: VEC_code_number=203;
10'b0001111110: VEC_code_number=215;
10'b0001111111: VEC_code_number=228;
10'b0010000000: VEC_code_number=2;
10'b0010000001: VEC_code_number=15;
10'b0010000010: VEC_code_number=56;
10'b0010000011: VEC_code_number=138;
10'b0010000100: VEC_code_number=11;
10'b0010000101: VEC_code_number=31;
10'b0010000110: VEC_code_number=69;
10'b0010000111: VEC_code_number=151;
10'b0010001000: VEC_code_number=37;
10'b0010001001: VEC_code_number=60;
10'b0010001010: VEC_code_number=111;
10'b0010001011: VEC_code_number=184;
10'b0010001100: VEC_code_number=96;
10'b0010001101: VEC_code_number=117;
10'b0010001110: VEC_code_number=161;
10'b0010001111: VEC_code_number=206;
10'b0010010000: VEC_code_number=9;
10'b0010010001: VEC_code_number=33;
10'b0010010010: VEC_code_number=78;
10'b0010010011: VEC_code_number=148;
10'b0010010100: VEC_code_number=25;
10'b0010010101: VEC_code_number=36;
10'b0010010110: VEC_code_number=76;
10'b0010010111: VEC_code_number=153;
10'b0010011000: VEC_code_number=65;
10'b0010011001: VEC_code_number=51;
10'b0010011010: VEC_code_number=98;
10'b0010011011: VEC_code_number=170;
10'b0010011100: VEC_code_number=132;
10'b0010011101: VEC_code_number=128;
10'b0010011110: VEC_code_number=142;
10'b0010011111: VEC_code_number=191;
10'b0010100000: VEC_code_number=19;
10'b0010100001: VEC_code_number=53;
10'b0010100010: VEC_code_number=120;
10'b0010100011: VEC_code_number=196;
10'b0010100100: VEC_code_number=57;
10'b0010100101: VEC_code_number=41;
10'b0010100110: VEC_code_number=101;
10'b0010100111: VEC_code_number=183;
10'b0010101000: VEC_code_number=118;
10'b0010101001: VEC_code_number=103;
10'b0010101010: VEC_code_number=81;
10'b0010101011: VEC_code_number=169;
10'b0010101100: VEC_code_number=199;
10'b0010101101: VEC_code_number=174;
10'b0010101110: VEC_code_number=181;
10'b0010101111: VEC_code_number=147;
10'b0010110000: VEC_code_number=84;
10'b0010110001: VEC_code_number=123;
10'b0010110010: VEC_code_number=185;
10'b0010110011: VEC_code_number=208;
10'b0010110100: VEC_code_number=135;
10'b0010110101: VEC_code_number=127;
10'b0010110110: VEC_code_number=162;
10'b0010110111: VEC_code_number=204;
10'b0010111000: VEC_code_number=194;
10'b0010111001: VEC_code_number=186;
10'b0010111010: VEC_code_number=173;
10'b0010111011: VEC_code_number=200;
10'b0010111100: VEC_code_number=231;
10'b0010111101: VEC_code_number=219;
10'b0010111110: VEC_code_number=227;
10'b0010111111: VEC_code_number=223;
10'b0011000000: VEC_code_number=39;
10'b0011000001: VEC_code_number=70;
10'b0011000010: VEC_code_number=136;
10'b0011000011: VEC_code_number=182;
10'b0011000100: VEC_code_number=52;
10'b0011000101: VEC_code_number=88;
10'b0011000110: VEC_code_number=152;
10'b0011000111: VEC_code_number=207;
10'b0011001000: VEC_code_number=92;
10'b0011001001: VEC_code_number=129;
10'b0011001010: VEC_code_number=176;
10'b0011001011: VEC_code_number=224;
10'b0011001100: VEC_code_number=115;
10'b0011001101: VEC_code_number=172;
10'b0011001110: VEC_code_number=211;
10'b0011001111: VEC_code_number=235;
10'b0011010000: VEC_code_number=58;
10'b0011010001: VEC_code_number=90;
10'b0011010010: VEC_code_number=143;
10'b0011010011: VEC_code_number=195;
10'b0011010100: VEC_code_number=91;
10'b0011010101: VEC_code_number=105;
10'b0011010110: VEC_code_number=156;
10'b0011010111: VEC_code_number=216;
10'b0011011000: VEC_code_number=131;
10'b0011011001: VEC_code_number=139;
10'b0011011010: VEC_code_number=177;
10'b0011011011: VEC_code_number=221;
10'b0011011100: VEC_code_number=165;
10'b0011011101: VEC_code_number=163;
10'b0011011110: VEC_code_number=217;
10'b0011011111: VEC_code_number=238;
10'b0011100000: VEC_code_number=75;
10'b0011100001: VEC_code_number=125;
10'b0011100010: VEC_code_number=192;
10'b0011100011: VEC_code_number=234;
10'b0011100100: VEC_code_number=130;
10'b0011100101: VEC_code_number=116;
10'b0011100110: VEC_code_number=179;
10'b0011100111: VEC_code_number=226;
10'b0011101000: VEC_code_number=187;
10'b0011101001: VEC_code_number=160;
10'b0011101010: VEC_code_number=190;
10'b0011101011: VEC_code_number=229;
10'b0011101100: VEC_code_number=230;
10'b0011101101: VEC_code_number=212;
10'b0011101110: VEC_code_number=201;
10'b0011101111: VEC_code_number=214;
10'b0011110000: VEC_code_number=73;
10'b0011110001: VEC_code_number=150;
10'b0011110010: VEC_code_number=225;
10'b0011110011: VEC_code_number=233;
10'b0011110100: VEC_code_number=141;
10'b0011110101: VEC_code_number=104;
10'b0011110110: VEC_code_number=193;
10'b0011110111: VEC_code_number=237;
10'b0011111000: VEC_code_number=209;
10'b0011111001: VEC_code_number=202;
10'b0011111010: VEC_code_number=159;
10'b0011111011: VEC_code_number=218;
10'b0011111100: VEC_code_number=239;
10'b0011111101: VEC_code_number=232;
10'b0011111110: VEC_code_number=222;
10'b0011111111: VEC_code_number=167;

10'b1000000000: VEC_code_number =255 ;
10'b1000000001: VEC_code_number =247;
10'b1000000010: VEC_code_number =1 ;
10'b1000000011: VEC_code_number =19 ;
10'b1000000100: VEC_code_number =251 ;
10'b1000000101: VEC_code_number =243 ;
10'b1000000110: VEC_code_number =4 ;						// bits required is 2 and group belongs to Chroma and SM form
10'b1000000111: VEC_code_number =40 ;
10'b1000001000: VEC_code_number = 0;
10'b1000001001: VEC_code_number = 5;
10'b1000001010: VEC_code_number = 34;
10'b1000001011: VEC_code_number = 84;
10'b1000001100: VEC_code_number = 18;
10'b1000001101: VEC_code_number = 39;
10'b1000001110: VEC_code_number = 82;
10'b1000001111: VEC_code_number = 120;
10'b1000010000: VEC_code_number = 253;
10'b1000010001: VEC_code_number = 245;
10'b1000010010: VEC_code_number = 6;
10'b1000010011: VEC_code_number = 42;
10'b1000010100: VEC_code_number = 249;
10'b1000010101: VEC_code_number = 241;
10'b1000010110: VEC_code_number = 16;
10'b1000010111: VEC_code_number = 62;
10'b1000011000: VEC_code_number = 11;
10'b1000011001: VEC_code_number = 20;
10'b1000011010: VEC_code_number = 56;
10'b1000011011: VEC_code_number = 102;
10'b1000011100: VEC_code_number = 46;
10'b1000011101: VEC_code_number = 65;
10'b1000011110: VEC_code_number = 109;
10'b1000011111: VEC_code_number = 154;
10'b1000100000: VEC_code_number = 3;
10'b1000100001: VEC_code_number = 9;
10'b1000100010: VEC_code_number = 35;
10'b1000100011: VEC_code_number = 85;
10'b1000100100: VEC_code_number = 13;
10'b1000100101: VEC_code_number = 24;
10'b1000100110: VEC_code_number = 55;
10'b1000100111: VEC_code_number = 100;
10'b1000101000: VEC_code_number = 44;
10'b1000101001: VEC_code_number = 61;
10'b1000101010: VEC_code_number = 103;
10'b1000101011: VEC_code_number = 156;
10'b1000101100: VEC_code_number = 97;
10'b1000101101: VEC_code_number = 125;
10'b1000101110: VEC_code_number = 171;
10'b1000101111: VEC_code_number = 193;
10'b1000110000: VEC_code_number = 29;
10'b1000110001: VEC_code_number = 45;
10'b1000110010: VEC_code_number = 88;
10'b1000110011: VEC_code_number = 135;
10'b1000110100: VEC_code_number = 52;
10'b1000110101: VEC_code_number = 76;
10'b1000110110: VEC_code_number = 113;
10'b1000110111: VEC_code_number = 153;
10'b1000111000: VEC_code_number = 99;
10'b1000111001: VEC_code_number = 126;
10'b1000111010: VEC_code_number = 167;
10'b1000111011: VEC_code_number = 203;
10'b1000111100: VEC_code_number = 151;
10'b1000111101: VEC_code_number = 180;
10'b1000111110: VEC_code_number = 204;
10'b1000111111: VEC_code_number = 223;
10'b1001000000: VEC_code_number = 254;
10'b1001000001: VEC_code_number = 246;
10'b1001000010: VEC_code_number = 10;
10'b1001000011: VEC_code_number = 47;
10'b1001000100: VEC_code_number = 250;
10'b1001000101: VEC_code_number = 242;
10'b1001000110: VEC_code_number = 21;
10'b1001000111: VEC_code_number = 64;
10'b1001001000: VEC_code_number = 7;
10'b1001001001: VEC_code_number = 17;
10'b1001001010: VEC_code_number = 54;
10'b1001001011: VEC_code_number = 110;
10'b1001001100: VEC_code_number = 41;
10'b1001001101: VEC_code_number = 60;
10'b1001001110: VEC_code_number = 106;
10'b1001001111: VEC_code_number = 150;
10'b1001010000: VEC_code_number = 252;
10'b1001010001: VEC_code_number = 244;
10'b1001010010: VEC_code_number = 23;
10'b1001010011: VEC_code_number = 63;
10'b1001010100: VEC_code_number = 248;
10'b1001010101: VEC_code_number = 240;
10'b1001010110: VEC_code_number = 32;
10'b1001010111: VEC_code_number = 89;
10'b1001011000: VEC_code_number = 22;
10'b1001011001: VEC_code_number = 33;
10'b1001011010: VEC_code_number = 67;
10'b1001011011: VEC_code_number = 136;
10'b1001011100: VEC_code_number = 66;
10'b1001011101: VEC_code_number = 86;
10'b1001011110: VEC_code_number = 139;
10'b1001011111: VEC_code_number = 174;
10'b1001100000: VEC_code_number = 15;
10'b1001100001: VEC_code_number = 27;
10'b1001100010: VEC_code_number = 58;
10'b1001100011: VEC_code_number = 115;
10'b1001100100: VEC_code_number = 31;
10'b1001100101: VEC_code_number = 38;
10'b1001100110: VEC_code_number = 75;
10'b1001100111: VEC_code_number = 131;
10'b1001101000: VEC_code_number = 72;
10'b1001101001: VEC_code_number = 87;
10'b1001101010: VEC_code_number = 111;
10'b1001101011: VEC_code_number = 165;
10'b1001101100: VEC_code_number = 128;
10'b1001101101: VEC_code_number = 145;
10'b1001101110: VEC_code_number = 187;
10'b1001101111: VEC_code_number = 201;
10'b1001110000: VEC_code_number = 50;
10'b1001110001: VEC_code_number = 74;
10'b1001110010: VEC_code_number = 112;
10'b1001110011: VEC_code_number = 157;
10'b1001110100: VEC_code_number = 80;
10'b1001110101: VEC_code_number = 92;
10'b1001110110: VEC_code_number = 144;
10'b1001110111: VEC_code_number = 158;
10'b1001111000: VEC_code_number = 133;
10'b1001111001: VEC_code_number = 143;
10'b1001111010: VEC_code_number = 178;
10'b1001111011: VEC_code_number = 213;
10'b1001111100: VEC_code_number = 179;
10'b1001111101: VEC_code_number = 192;
10'b1001111110: VEC_code_number = 211;
10'b1001111111: VEC_code_number = 231;
10'b1010000000: VEC_code_number = 2;
10'b1010000001: VEC_code_number = 12;
10'b1010000010: VEC_code_number = 48;
10'b1010000011: VEC_code_number = 96;
10'b1010000100: VEC_code_number = 8;
10'b1010000101: VEC_code_number = 25;
10'b1010000110: VEC_code_number = 68;
10'b1010000111: VEC_code_number = 134;
10'b1010001000: VEC_code_number = 36;
10'b1010001001: VEC_code_number = 57;
10'b1010001010: VEC_code_number = 101;
10'b1010001011: VEC_code_number = 163;
10'b1010001100: VEC_code_number = 90;
10'b1010001101: VEC_code_number = 108;
10'b1010001110: VEC_code_number = 159;
10'b1010001111: VEC_code_number = 197;
10'b1010010000: VEC_code_number = 14;
10'b1010010001: VEC_code_number = 30;
10'b1010010010: VEC_code_number = 71;
10'b1010010011: VEC_code_number = 132;
10'b1010010100: VEC_code_number = 26;
10'b1010010101: VEC_code_number = 37;
10'b1010010110: VEC_code_number = 83;
10'b1010010111: VEC_code_number = 141;
10'b1010011000: VEC_code_number = 59;
10'b1010011001: VEC_code_number = 70;
10'b1010011010: VEC_code_number = 117;
10'b1010011011: VEC_code_number = 172;
10'b1010011100: VEC_code_number = 114;
10'b1010011101: VEC_code_number = 140;
10'b1010011110: VEC_code_number = 170;
10'b1010011111: VEC_code_number = 216;
10'b1010100000: VEC_code_number = 43;
10'b1010100001: VEC_code_number = 73;
10'b1010100010: VEC_code_number = 105;
10'b1010100011: VEC_code_number = 160;
10'b1010100100: VEC_code_number = 69;
10'b1010100101: VEC_code_number = 81;
10'b1010100110: VEC_code_number = 116;
10'b1010100111: VEC_code_number = 188;
10'b1010101000: VEC_code_number = 107;
10'b1010101001: VEC_code_number = 119;
10'b1010101010: VEC_code_number = 123;
10'b1010101011: VEC_code_number = 198;
10'b1010101100: VEC_code_number = 176;
10'b1010101101: VEC_code_number = 186;
10'b1010101110: VEC_code_number = 195;
10'b1010101111: VEC_code_number = 225;
10'b1010110000: VEC_code_number = 94;
10'b1010110001: VEC_code_number = 122;
10'b1010110010: VEC_code_number = 161;
10'b1010110011: VEC_code_number = 202;
10'b1010110100: VEC_code_number = 138;
10'b1010110101: VEC_code_number = 146;
10'b1010110110: VEC_code_number = 182;
10'b1010110111: VEC_code_number = 210;
10'b1010111000: VEC_code_number = 175;
10'b1010111001: VEC_code_number = 185;
10'b1010111010: VEC_code_number = 194;
10'b1010111011: VEC_code_number = 221;
10'b1010111100: VEC_code_number = 219;
10'b1010111101: VEC_code_number = 220;
10'b1010111110: VEC_code_number = 233;
10'b1010111111: VEC_code_number = 236;
10'b1011000000: VEC_code_number = 28;
10'b1011000001: VEC_code_number = 53;
10'b1011000010: VEC_code_number = 98;
10'b1011000011: VEC_code_number = 149;
10'b1011000100: VEC_code_number = 49;
10'b1011000101: VEC_code_number = 77;
10'b1011000110: VEC_code_number = 121;
10'b1011000111: VEC_code_number = 169;
10'b1011001000: VEC_code_number = 91;
10'b1011001001: VEC_code_number = 104;
10'b1011001010: VEC_code_number = 164;
10'b1011001011: VEC_code_number = 199;
10'b1011001100: VEC_code_number = 130;
10'b1011001101: VEC_code_number = 152;
10'b1011001110: VEC_code_number = 196;
10'b1011001111: VEC_code_number = 224;
10'b1011010000: VEC_code_number = 51;
10'b1011010001: VEC_code_number = 79;
10'b1011010010: VEC_code_number = 124;
10'b1011010011: VEC_code_number = 181;
10'b1011010100: VEC_code_number = 78;
10'b1011010101: VEC_code_number = 93;
10'b1011010110: VEC_code_number = 148;
10'b1011010111: VEC_code_number = 191;
10'b1011011000: VEC_code_number = 118;
10'b1011011001: VEC_code_number = 127;
10'b1011011010: VEC_code_number = 189;
10'b1011011011: VEC_code_number = 217;
10'b1011011100: VEC_code_number = 155;
10'b1011011101: VEC_code_number = 162;
10'b1011011110: VEC_code_number = 208;
10'b1011011111: VEC_code_number = 226;
10'b1011100000: VEC_code_number = 95;
10'b1011100001: VEC_code_number = 137;
10'b1011100010: VEC_code_number = 177;
10'b1011100011: VEC_code_number = 218;
10'b1011100100: VEC_code_number = 129;
10'b1011100101: VEC_code_number = 142;
10'b1011100110: VEC_code_number = 190;
10'b1011100111: VEC_code_number = 215;
10'b1011101000: VEC_code_number = 166;
10'b1011101001: VEC_code_number = 183;
10'b1011101010: VEC_code_number = 200;
10'b1011101011: VEC_code_number = 229;
10'b1011101100: VEC_code_number = 206;
10'b1011101101: VEC_code_number = 209;
10'b1011101110: VEC_code_number = 227;
10'b1011101111: VEC_code_number = 235;
10'b1011110000: VEC_code_number = 147;
10'b1011110001: VEC_code_number = 173;
10'b1011110010: VEC_code_number = 207;
10'b1011110011: VEC_code_number = 234;
10'b1011110100: VEC_code_number = 168;
10'b1011110101: VEC_code_number = 184;
10'b1011110110: VEC_code_number = 205;
10'b1011110111: VEC_code_number = 228;
10'b1011111000: VEC_code_number = 212;
10'b1011111001: VEC_code_number = 214;
10'b1011111010: VEC_code_number = 222;
10'b1011111011: VEC_code_number = 239;
10'b1011111100: VEC_code_number = 232;
10'b1011111101: VEC_code_number = 230;
10'b1011111110: VEC_code_number = 237;
10'b1011111111: VEC_code_number = 238;

10'b0100000000: VEC_code_number=255;
10'b0100000001: VEC_code_number=0; 
10'b0100000010: VEC_code_number=21;
10'b0100000011: VEC_code_number=247;
10'b0100000100: VEC_code_number= 1; 
10'b0100000101: VEC_code_number=6; 						// bits required is 2 and group belongs to Luma and TC form
10'b0100000110: VEC_code_number=71; 
10'b0100000111: VEC_code_number=18;
10'b0100001000: VEC_code_number= 20; 
10'b0100001001: VEC_code_number=70; 
10'b0100001010: VEC_code_number=79; 
10'b0100001011: VEC_code_number=42; 
10'b0100001100: VEC_code_number=251; 
10'b0100001101: VEC_code_number=19; 
10'b0100001110: VEC_code_number=31; 
10'b0100001111: VEC_code_number=243; 
10'b0100010000: VEC_code_number=3; 
10'b0100010001: VEC_code_number=5; 
10'b0100010010: VEC_code_number=67; 
10'b0100010011: VEC_code_number=15;
10'b0100010100: VEC_code_number=9;
10'b0100010101: VEC_code_number= 27; 
10'b0100010110: VEC_code_number=127; 
10'b0100010111: VEC_code_number=36; 
10'b0100011000: VEC_code_number=69; 
10'b0100011001: VEC_code_number=121; 
10'b0100011010: VEC_code_number=160; 
10'b0100011011: VEC_code_number=94; 
10'b0100011100: VEC_code_number=13; 
10'b0100011101: VEC_code_number=39; 
10'b0100011110: VEC_code_number=97; 
10'b0100011111: VEC_code_number=32; 
10'b0100100000: VEC_code_number=24;
10'b0100100001: VEC_code_number= 66;
10'b0100100010: VEC_code_number= 80; 
10'b0100100011: VEC_code_number=55; 
10'b0100100100: VEC_code_number=65; 
10'b0100100101: VEC_code_number=110; 
10'b0100100110: VEC_code_number=179; 
10'b0100100111: VEC_code_number=135; 
10'b0100101000: VEC_code_number=140; 
10'b0100101001: VEC_code_number=196; 
10'b0100101010: VEC_code_number=209; 
10'b0100101011: VEC_code_number=174; 
10'b0100101100: VEC_code_number=74; 
10'b0100101101: VEC_code_number=129; 
10'b0100101110: VEC_code_number=162; 
10'b0100101111: VEC_code_number=98; 
10'b0100110000: VEC_code_number=253; 
10'b0100110001: VEC_code_number=14; 
10'b0100110010: VEC_code_number=33; 
10'b0100110011: VEC_code_number=245; 
10'b0100110100: VEC_code_number=12; 
10'b0100110101: VEC_code_number=34; 
10'b0100110110: VEC_code_number=143; 
10'b0100110111: VEC_code_number=57; 
10'b0100111000: VEC_code_number=75; 
10'b0100111001: VEC_code_number=132;
10'b0100111010: VEC_code_number=154; 
10'b0100111011: VEC_code_number=109; 
10'b0100111100: VEC_code_number=249; 
10'b0100111101: VEC_code_number=54;
10'b0100111110: VEC_code_number=85; 
10'b0100111111: VEC_code_number=241; 
10'b0101000000: VEC_code_number=2; 
10'b0101000001: VEC_code_number=8;
10'b0101000010: VEC_code_number=52; 
10'b0101000011: VEC_code_number=11; 
10'b0101000100: VEC_code_number=4;
10'b0101000101: VEC_code_number=26;
10'b0101000110: VEC_code_number=116; 
10'b0101000111: VEC_code_number=30; 
10'b0101001000: VEC_code_number=60; 
10'b0101001001: VEC_code_number=93; 
10'b0101001010: VEC_code_number=164; 
10'b0101001011: VEC_code_number=102; 
10'b0101001100: VEC_code_number=17; 
10'b0101001101: VEC_code_number=58; 
10'b0101001110: VEC_code_number=91; 
10'b0101001111: VEC_code_number=38; 
10'b0101010000: VEC_code_number=7; 
10'b0101010001: VEC_code_number=29; 
10'b0101010010: VEC_code_number=120; 
10'b0101010011: VEC_code_number=41; 
10'b0101010100: VEC_code_number=28; 
10'b0101010101: VEC_code_number=72; 
10'b0101010110: VEC_code_number=171; 
10'b0101010111: VEC_code_number=96; 
10'b0101011000: VEC_code_number=111; 
10'b0101011001: VEC_code_number=184; 
10'b0101011010: VEC_code_number=206; 
10'b0101011011: VEC_code_number=157; 
10'b0101011100: VEC_code_number=37; 
10'b0101011101: VEC_code_number=107; 
10'b0101011110: VEC_code_number=161; 
10'b0101011111: VEC_code_number=83; 
10'b0101100000: VEC_code_number=73; 
10'b0101100001: VEC_code_number=100; 
10'b0101100010: VEC_code_number=180; 
10'b0101100011: VEC_code_number=128; 
10'b0101100100: VEC_code_number=136; 
10'b0101100101: VEC_code_number=181; 
10'b0101100110: VEC_code_number=218; 
10'b0101100111: VEC_code_number=176; 
10'b0101101000: VEC_code_number=183; 
10'b0101101001: VEC_code_number=223; 
10'b0101101010: VEC_code_number=237; 
10'b0101101011: VEC_code_number=235; 
10'b0101101100: VEC_code_number=145; 
10'b0101101101: VEC_code_number=159; 
10'b0101101110: VEC_code_number=228; 
10'b0101101111: VEC_code_number=201; 
10'b0101110000: VEC_code_number=23; 
10'b0101110001: VEC_code_number=50; 
10'b0101110010: VEC_code_number=95; 
10'b0101110011: VEC_code_number=46; 
10'b0101110100: VEC_code_number=49; 
10'b0101110101: VEC_code_number=99; 
10'b0101110110: VEC_code_number=165; 
10'b0101110111: VEC_code_number=87; 
10'b0101111000: VEC_code_number=131; 
10'b0101111001: VEC_code_number=158; 
10'b0101111010: VEC_code_number=231; 
10'b0101111011: VEC_code_number=188; 
10'b0101111100: VEC_code_number=56; 
10'b0101111101: VEC_code_number=89; 
10'b0101111110: VEC_code_number=190; 
10'b0101111111: VEC_code_number=112; 
10'b0110000000: VEC_code_number=25; 
10'b0110000001: VEC_code_number=64; 
10'b0110000010: VEC_code_number=146; 
10'b0110000011: VEC_code_number=78; 
10'b0110000100: VEC_code_number=63; 
10'b0110000101: VEC_code_number=106; 
10'b0110000110: VEC_code_number=186; 
10'b0110000111: VEC_code_number=134; 
10'b0110001000: VEC_code_number=81; 
10'b0110001001: VEC_code_number=177; 
10'b0110001010: VEC_code_number=210; 
10'b0110001011: VEC_code_number=169; 
10'b0110001100: VEC_code_number=51; 
10'b0110001101: VEC_code_number=125; 
10'b0110001110: VEC_code_number=197; 
10'b0110001111: VEC_code_number=139; 
10'b0110010000: VEC_code_number=76; 
10'b0110010001: VEC_code_number=141; 
10'b0110010010: VEC_code_number=198; 
10'b0110010011: VEC_code_number=137; 
10'b0110010100: VEC_code_number=117; 
10'b0110010101: VEC_code_number=185; 
10'b0110010110: VEC_code_number=222; 
10'b0110010111: VEC_code_number=173; 
10'b0110011000: VEC_code_number=195; 
10'b0110011001: VEC_code_number=213; 
10'b0110011010: VEC_code_number=236; 
10'b0110011011: VEC_code_number=227; 
10'b0110011100: VEC_code_number=142; 
10'b0110011101: VEC_code_number=178; 
10'b0110011110: VEC_code_number=232; 
10'b0110011111: VEC_code_number=207; 
10'b0110100000: VEC_code_number=86; 
10'b0110100001: VEC_code_number=155; 
10'b0110100010: VEC_code_number=216; 
10'b0110100011: VEC_code_number=163; 
10'b0110100100: VEC_code_number=170; 
10'b0110100101: VEC_code_number=208; 
10'b0110100110: VEC_code_number=238; 
10'b0110100111: VEC_code_number=221; 
10'b0110101000: VEC_code_number=215; 
10'b0110101001: VEC_code_number=239; 
10'b0110101010: VEC_code_number=217; 
10'b0110101011: VEC_code_number=229; 
10'b0110101100: VEC_code_number=168; 
10'b0110101101: VEC_code_number=230; 
10'b0110101110: VEC_code_number=226; 
10'b0110101111: VEC_code_number=205; 
10'b0110110000: VEC_code_number=61; 
10'b0110110001: VEC_code_number=104; 
10'b0110110010: VEC_code_number=191; 
10'b0110110011: VEC_code_number=124; 
10'b0110110100: VEC_code_number=113; 
10'b0110110101: VEC_code_number=166; 
10'b0110110110: VEC_code_number=233; 
10'b0110110111: VEC_code_number=193; 
10'b0110111000: VEC_code_number=153; 
10'b0110111001: VEC_code_number=224; 
10'b0110111010: VEC_code_number=214;
10'b0110111011: VEC_code_number=194; 
10'b0110111100: VEC_code_number=92; 
10'b0110111101: VEC_code_number=189; 
10'b0110111110: VEC_code_number=211; 
10'b0110111111: VEC_code_number=152; 
10'b0111000000: VEC_code_number=254; 
10'b0111000001: VEC_code_number=10; 
10'b0111000010: VEC_code_number=77; 
10'b0111000011: VEC_code_number=246; 
10'b0111000100: VEC_code_number=16; 
10'b0111000101: VEC_code_number=43; 
10'b0111000110: VEC_code_number=144; 
10'b0111000111: VEC_code_number=62; 
10'b0111001000: VEC_code_number=45; 
10'b0111001001: VEC_code_number=133; 
10'b0111001010: VEC_code_number=149; 
10'b0111001011: VEC_code_number=84; 
10'b0111001100: VEC_code_number=250; 
10'b0111001101: VEC_code_number=48; 
10'b0111001110: VEC_code_number=105; 
10'b0111001111: VEC_code_number=242; 
10'b0111010000: VEC_code_number=22; 
10'b0111010001: VEC_code_number=44; 
10'b0111010010: VEC_code_number=130; 
10'b0111010011: VEC_code_number=68; 
10'b0111010100: VEC_code_number=47; 
10'b0111010101: VEC_code_number=115; 
10'b0111010110: VEC_code_number=175; 
10'b0111010111: VEC_code_number=88; 
10'b0111011000: VEC_code_number=126; 
10'b0111011001: VEC_code_number=172; 
10'b0111011010: VEC_code_number=225; 
10'b0111011011: VEC_code_number=200; 
10'b0111011100: VEC_code_number=59; 
10'b0111011101: VEC_code_number=90; 
10'b0111011110: VEC_code_number=192; 
10'b0111011111: VEC_code_number=119; 
10'b0111100000: VEC_code_number=53; 
10'b0111100001: VEC_code_number=114; 
10'b0111100010: VEC_code_number=167; 
10'b0111100011: VEC_code_number=103; 
10'b0111100100: VEC_code_number=101; 
10'b0111100101: VEC_code_number=156; 
10'b0111100110: VEC_code_number=219; 
10'b0111100111: VEC_code_number=187; 
10'b0111101000: VEC_code_number=182; 
10'b0111101001: VEC_code_number=234; 
10'b0111101010: VEC_code_number=220; 
10'b0111101011: VEC_code_number=212; 
10'b0111101100: VEC_code_number=122; 
10'b0111101101: VEC_code_number=204; 
10'b0111101110: VEC_code_number=202; 
10'b0111101111: VEC_code_number=151; 
10'b0111110000: VEC_code_number=252; 
10'b0111110001: VEC_code_number=35; 
10'b0111110010: VEC_code_number=118; 
10'b0111110011: VEC_code_number=244; 
10'b0111110100: VEC_code_number=40; 
10'b0111110101: VEC_code_number=82; 
10'b0111110110: VEC_code_number=199; 
10'b0111110111: VEC_code_number=123; 
10'b0111111000: VEC_code_number=108; 
10'b0111111001: VEC_code_number=203; 
10'b0111111010: VEC_code_number=150; 
10'b0111111011: VEC_code_number=148; 
10'b0111111100: VEC_code_number=248; 
10'b0111111101: VEC_code_number=138; 
10'b0111111110: VEC_code_number=147; 
10'b0111111111: VEC_code_number=240;


10'b1100000000: VEC_code_number= 255;
10'b1100000001: VEC_code_number= 1;
10'b1100000010: VEC_code_number= 22;
10'b1100000011: VEC_code_number= 247;							// bits required is 2 and group belongs to Chroma and TC form
10'b1100000100: VEC_code_number= 0;
10'b1100000101: VEC_code_number= 4;
10'b1100000110: VEC_code_number= 64;
10'b1100000111: VEC_code_number= 16;
10'b1100001000: VEC_code_number= 23;
10'b1100001001: VEC_code_number= 75;
10'b1100001010: VEC_code_number= 31;
10'b1100001011: VEC_code_number= 33;
10'b1100001100: VEC_code_number= 251;
10'b1100001101: VEC_code_number= 14;
10'b1100001110: VEC_code_number= 32;
10'b1100001111: VEC_code_number= 243;
10'b1100010000: VEC_code_number= 3;
10'b1100010001: VEC_code_number= 6;
10'b1100010010: VEC_code_number= 79;
10'b1100010011: VEC_code_number= 20;
10'b1100010100: VEC_code_number= 9;
10'b1100010101: VEC_code_number= 27;
10'b1100010110: VEC_code_number= 169;
10'b1100010111: VEC_code_number= 68;
10'b1100011000: VEC_code_number= 62;
10'b1100011001: VEC_code_number= 150;
10'b1100011010: VEC_code_number= 143;
10'b1100011011: VEC_code_number= 100;
10'b1100011100: VEC_code_number= 12;
10'b1100011101: VEC_code_number= 43;
10'b1100011110: VEC_code_number= 117;
10'b1100011111: VEC_code_number= 41;
10'b1100100000: VEC_code_number= 25;
10'b1100100001: VEC_code_number= 85;
10'b1100100010: VEC_code_number= 74; 
10'b1100100011: VEC_code_number= 55; 
10'b1100100100: VEC_code_number= 63; 
10'b1100100101: VEC_code_number=135; 
10'b1100100110: VEC_code_number=179; 
10'b1100100111: VEC_code_number=114; 
10'b1100101000: VEC_code_number=160; 
10'b1100101001: VEC_code_number=221; 
10'b1100101010: VEC_code_number=203; 
10'b1100101011: VEC_code_number=197; 
10'b1100101100: VEC_code_number=82; 
10'b1100101101: VEC_code_number=172; 
10'b1100101110: VEC_code_number=142; 
10'b1100101111: VEC_code_number=103; 
10'b1100110000: VEC_code_number=253; 
10'b1100110001: VEC_code_number=19; 
10'b1100110010: VEC_code_number=38; 
10'b1100110011: VEC_code_number=245; 
10'b1100110100: VEC_code_number=11; 
10'b1100110101: VEC_code_number=35; 
10'b1100110110: VEC_code_number=125; 
10'b1100110111: VEC_code_number=53; 
10'b1100111000: VEC_code_number=71; 
10'b1100111001: VEC_code_number=165;
10'b1100111010: VEC_code_number=108; 
10'b1100111011: VEC_code_number=95; 
10'b1100111100: VEC_code_number=249; 
10'b1100111101: VEC_code_number=73;
10'b1100111110: VEC_code_number=81; 
10'b1100111111: VEC_code_number=241; 
10'b1101000000: VEC_code_number=2; 
10'b1101000001: VEC_code_number=8;
10'b1101000010: VEC_code_number=61; 
10'b1101000011: VEC_code_number=10; 
10'b1101000100: VEC_code_number=7;
10'b1101000101: VEC_code_number=28;
10'b1101000110: VEC_code_number=126; 
10'b1101000111: VEC_code_number=49; 
10'b1101001000: VEC_code_number=86; 
10'b1101001001: VEC_code_number=168; 
10'b1101001010: VEC_code_number=144; 
10'b1101001011: VEC_code_number=127; 
10'b1101001100: VEC_code_number=15; 
10'b1101001101: VEC_code_number=59; 
10'b1101001110: VEC_code_number=96; 
10'b1101001111: VEC_code_number=34; 
10'b1101010000: VEC_code_number=5; 
10'b1101010001: VEC_code_number=29; 
10'b1101010010: VEC_code_number=137; 
10'b1101010011: VEC_code_number=44; 
10'b1101010100: VEC_code_number=30; 
10'b1101010101: VEC_code_number=26; 
10'b1101010110: VEC_code_number=208; 
10'b1101010111: VEC_code_number=128; 
10'b1101011000: VEC_code_number=140; 
10'b1101011001: VEC_code_number=196; 
10'b1101011010: VEC_code_number=133; 
10'b1101011011: VEC_code_number=154; 
10'b1101011100: VEC_code_number=46; 
10'b1101011101: VEC_code_number=112; 
10'b1101011110: VEC_code_number=155; 
10'b1101011111: VEC_code_number=57; 
10'b1101100000: VEC_code_number=78; 
10'b1101100001: VEC_code_number=157; 
10'b1101100010: VEC_code_number=182; 
10'b1101100011: VEC_code_number=132; 
10'b1101100100: VEC_code_number=146; 
10'b1101100101: VEC_code_number=204; 
10'b1101100110: VEC_code_number=205; 
10'b1101100111: VEC_code_number=190; 
10'b1101101000: VEC_code_number=220; 
10'b1101101001: VEC_code_number=226; 
10'b1101101010: VEC_code_number=238; 
10'b1101101011: VEC_code_number=235; 
10'b1101101100: VEC_code_number=166; 
10'b1101101101: VEC_code_number=214; 
10'b1101101110: VEC_code_number=232; 
10'b1101101111: VEC_code_number=207; 
10'b1101110000: VEC_code_number=17; 
10'b1101110001: VEC_code_number=60; 
10'b1101110010: VEC_code_number=111; 
10'b1101110011: VEC_code_number=50; 
10'b1101110100: VEC_code_number=52; 
10'b1101110101: VEC_code_number=116; 
10'b1101110110: VEC_code_number=178; 
10'b1101110111: VEC_code_number=90; 
10'b1101111000: VEC_code_number=164; 
10'b1101111001: VEC_code_number=216; 
10'b1101111010: VEC_code_number=222; 
10'b1101111011: VEC_code_number=211; 
10'b1101111100: VEC_code_number=67; 
10'b1101111101: VEC_code_number=153; 
10'b1101111110: VEC_code_number=199; 
10'b1101111111: VEC_code_number=122; 
10'b1110000000: VEC_code_number=24; 
10'b1110000001: VEC_code_number=65; 
10'b1110000010: VEC_code_number=162; 
10'b1110000011: VEC_code_number=84; 
10'b1110000100: VEC_code_number=83; 
10'b1110000101: VEC_code_number=131; 
10'b1110000110: VEC_code_number=217; 
10'b1110000111: VEC_code_number=163; 
10'b1110001000: VEC_code_number=80; 
10'b1110001001: VEC_code_number=181; 
10'b1110001010: VEC_code_number=195; 
10'b1110001011: VEC_code_number=156; 
10'b1110001100: VEC_code_number=54; 
10'b1110001101: VEC_code_number=118; 
10'b1110001110: VEC_code_number=193; 
10'b1110001111: VEC_code_number=106; 
10'b1110010000: VEC_code_number=77; 
10'b1110010001: VEC_code_number=141; 
10'b1110010010: VEC_code_number=223; 
10'b1110010011: VEC_code_number=175; 
10'b1110010100: VEC_code_number=167; 
10'b1110010101: VEC_code_number=201; 
10'b1110010110: VEC_code_number=227; 
10'b1110010111: VEC_code_number=215; 
10'b1110011000: VEC_code_number=185; 
10'b1110011001: VEC_code_number=200; 
10'b1110011010: VEC_code_number=237; 
10'b1110011011: VEC_code_number=225; 
10'b1110011100: VEC_code_number=145; 
10'b1110011101: VEC_code_number=183; 
10'b1110011110: VEC_code_number=233; 
10'b1110011111: VEC_code_number=213; 
10'b1110100000: VEC_code_number=47; 
10'b1110100001: VEC_code_number=151; 
10'b1110100010: VEC_code_number=202; 
10'b1110100011: VEC_code_number=138; 
10'b1110100100: VEC_code_number=158; 
10'b1110100101: VEC_code_number=134; 
10'b1110100110: VEC_code_number=239; 
10'b1110100111: VEC_code_number=228; 
10'b1110101000: VEC_code_number=212; 
10'b1110101001: VEC_code_number=236; 
10'b1110101010: VEC_code_number=115; 
10'b1110101011: VEC_code_number=174; 
10'b1110101100: VEC_code_number=130; 
10'b1110101101: VEC_code_number=229; 
10'b1110101110: VEC_code_number=177; 
10'b1110101111: VEC_code_number=92; 
10'b1110110000: VEC_code_number=37; 
10'b1110110001: VEC_code_number=104; 
10'b1110110010: VEC_code_number=189; 
10'b1110110011: VEC_code_number=110; 
10'b1110110100: VEC_code_number=129; 
10'b1110110101: VEC_code_number=159; 
10'b1110110110: VEC_code_number=234; 
10'b1110110111: VEC_code_number=206; 
10'b1110111000: VEC_code_number=152; 
10'b1110111001: VEC_code_number=231; 
10'b1110111010: VEC_code_number=180;
10'b1110111011: VEC_code_number=147; 
10'b1110111100: VEC_code_number=91; 
10'b1110111101: VEC_code_number=194; 
10'b1110111110: VEC_code_number=187; 
10'b1110111111: VEC_code_number=102; 
10'b1111000000: VEC_code_number=254; 
10'b1111000001: VEC_code_number=13; 
10'b1111000010: VEC_code_number=72; 
10'b1111000011: VEC_code_number=246; 
10'b1111000100: VEC_code_number=21; 
10'b1111000101: VEC_code_number=45; 
10'b1111000110: VEC_code_number=171; 
10'b1111000111: VEC_code_number=70; 
10'b1111001000: VEC_code_number=42; 
10'b1111001001: VEC_code_number=136; 
10'b1111001010: VEC_code_number=109; 
10'b1111001011: VEC_code_number=76; 
10'b1111001100: VEC_code_number=250; 
10'b1111001101: VEC_code_number=51; 
10'b1111001110: VEC_code_number=97; 
10'b1111001111: VEC_code_number=242; 
10'b1111010000: VEC_code_number=18; 
10'b1111010001: VEC_code_number=48; 
10'b1111010010: VEC_code_number=173; 
10'b1111010011: VEC_code_number=66; 
10'b1111010100: VEC_code_number=69; 
10'b1111010101: VEC_code_number=121; 
10'b1111010110: VEC_code_number=218; 
10'b1111010111: VEC_code_number=149; 
10'b1111011000: VEC_code_number=124; 
10'b1111011001: VEC_code_number=176; 
10'b1111011010: VEC_code_number=219; 
10'b1111011011: VEC_code_number=186; 
10'b1111011100: VEC_code_number=56; 
10'b1111011101: VEC_code_number=89; 
10'b1111011110: VEC_code_number=210; 
10'b1111011111: VEC_code_number=113; 
10'b1111100000: VEC_code_number=36; 
10'b1111100001: VEC_code_number=120; 
10'b1111100010: VEC_code_number=148; 
10'b1111100011: VEC_code_number=88; 
10'b1111100100: VEC_code_number=101; 
10'b1111100101: VEC_code_number=161; 
10'b1111100110: VEC_code_number=224; 
10'b1111100111: VEC_code_number=188; 
10'b1111101000: VEC_code_number=191; 
10'b1111101001: VEC_code_number=230; 
10'b1111101010: VEC_code_number=170; 
10'b1111101011: VEC_code_number=184; 
10'b1111101100: VEC_code_number=105; 
10'b1111101101: VEC_code_number=192; 
10'b1111101110: VEC_code_number=139; 
10'b1111101111: VEC_code_number=99; 
10'b1111110000: VEC_code_number=252; 
10'b1111110001: VEC_code_number=39; 
10'b1111110010: VEC_code_number=107; 
10'b1111110011: VEC_code_number=244; 
10'b1111110100: VEC_code_number=40; 
10'b1111110101: VEC_code_number=58; 
10'b1111110110: VEC_code_number=209; 
10'b1111110111: VEC_code_number=119; 
10'b1111111000: VEC_code_number=98; 
10'b1111111001: VEC_code_number=198; 
10'b1111111010: VEC_code_number=87; 
10'b1111111011: VEC_code_number=94; 
10'b1111111100: VEC_code_number=248; 
10'b1111111101: VEC_code_number=123; 
10'b1111111110: VEC_code_number=93; 
10'b1111111111: VEC_code_number=240;

endcase
end
end
endmodule

