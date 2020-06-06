module Bits_required (Bits_req, sample_1,sample_2,sample_3,sample_4,ecgidx);
parameter J = 10 ; // parameter is used for width of sample input, we need to be pass its value during module instatntiation. 

input signed [J-1:0] sample_1,sample_2,sample_3,sample_4;
input [1:0] ecgidx;
output[3:0] Bits_req;

reg [3:0] Bits_req;
wire [3:0] SM_bits_req,TC_bits_req; 
wire [J-1:0] magnitude1,magnitude2,magnitude3,magnitude4,SM_coded_sample,converted1,converted2,converted3,converted4,TC_coded_sample;


magnitude_calculator #(J) m1(sample_1,magnitude1);  //find magnitude of each sample
magnitude_calculator #(J) m2(sample_2,magnitude2);
magnitude_calculator #(J) m3(sample_3,magnitude3);
magnitude_calculator #(J) m4(sample_4,magnitude4);

Convert_to_negative #(J) c1(sample_1,converted1);	//convert each positive sample to negative except for the case in which positive sample is in power of 2's for which add 1 to it and than convert to negative.
Convert_to_negative #(J) c2(sample_2,converted2);
Convert_to_negative #(J) c3(sample_3,converted3);
Convert_to_negative #(J) c4(sample_4,converted4);


assign SM_coded_sample= magnitude1|magnitude2|magnitude3|magnitude4; // taking OR of all magnitude samples gives a coded sample data for which bits_required can be directly found in SM form.
assign TC_coded_sample= converted1&converted2&converted3&converted4; //taking AND of all negative converted samples gives a coded sample data for which bits_required can be directly found in TC form.

SM_bits_req #(J) u1(SM_coded_sample,SM_bits_req);
TC_bits_req #(J) u2(TC_coded_sample,TC_bits_req);

always@(*) 
begin
if (ecgidx==3)
Bits_req = TC_bits_req;
else
Bits_req = SM_bits_req;
end
endmodule



module SM_bits_req(sample,out);  // this module find bits_required for a positive sample input for the SM form output.
parameter K=10;

input signed [K-1:0] sample;
output [3:0] out;
reg [3:0] out;


always@(sample)  	//checks the occurence of 1st '1' going from MSB to LSB.
begin
 if(sample[K-1]==1)
 out=K;
 else if(sample[K-2]==1)
 out=K-1;
 else if(sample[K-3]==1)
 out=K-2;
 else if(sample[K-4]==1)
 out=K-3;
 else if(sample[K-5]==1)
 out=K-4;
 else if(sample[K-6]==1)
 out=K-5;
 else if(sample[K-7]==1)
 out=K-6;
 else if(sample[K-8]==1)
 out=K-7;
 else if(sample[K-9]==1)
 out=K-8;
 else if(K==9)
 out=0;
 else if(sample[K-10]==1)
 out=K-9;
 else
 out=0;
end
endmodule




module TC_bits_req(sample,out);  //this module finds the bits_required for a negative sample input for TC form output.
parameter K=10;

input signed [K-1:0] sample;
output [3:0] out;
reg [3:0] out;

always@(sample)		//checks the occurence of 1st '0' going from 2nd MSB to LSB 
begin
 if(sample[K-2]==0)
 out=K;
 else if(sample[K-3]==0)
 out=K-1;
 else if(sample[K-4]==0)
 out=K-2;
 else if(sample[K-5]==0)
 out=K-3;
 else if(sample[K-6]==0)
 out=K-4;
 else if(sample[K-7]==0)
 out=K-5;
 else if(sample[K-8]==0)
 out=K-6;
 else if(sample[K-9]==0)
 out=K-7;
 else if(K==9)
 out=1;
 else if(sample[K-10]==0)
 out=K-8;
 else
 out=1;
end

endmodule






module magnitude_calculator(sample,magnitude); // This module gives magnitude of a signed number 

parameter K = 10 ;

input signed [K-1:0] sample;
output [K-1:0] magnitude;
reg  [K-1:0] magnitude;

always@(*)
begin
if(sample[K-1]==1)             //check the msb of sample
magnitude=~sample+1'b1;       // if negative find its magnitude
else
magnitude=sample;
end
endmodule







module Convert_to_negative(sample,converted); // This module makes positive number negative except the positive number which is in power of twos for which it adds 1 to it and than gives negative of it. 

parameter K = 10 ;

input signed [K-1:0] sample;
output [K-1:0] converted;
reg  [K-1:0] converted,temp;

always@(*)
begin 
if(sample[K-1]==0) // checks if sample is positive
begin
 if(((sample)&(sample-1))==0)   //Logic to check if the positive sample is in power of 2's.
 begin
 temp=sample+1;   // if in power of 2's add 1 and then make negative. It helps in calculating correct bits_required.
 converted= ~temp +1 ; // converts positive to negative in 2's compliment representation.
 end
 else
 converted= ~sample +1 ;  // converts positive to negative in 2's compliment representation.
end
else
converted=sample; // if already negative donot convert.
end
endmodule


