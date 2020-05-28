module Bits_required (Bits_req, sample_1,sample_2,sample_3,sample_4,ecgidx);

parameter j = 10 ;

input signed [j-1:0] sample_1,sample_2,sample_3,sample_4;
input [1:0] ecgidx;
output[3:0] Bits_req;
reg [3:0] Bits_req,temp;
wire [3:0] SM_bits_req_sample1,SM_bits_req_sample2,SM_bits_req_sample3,SM_bits_req_sample4,TC_bits_req_sample1,TC_bits_req_sample2,TC_bits_req_sample3,TC_bits_req_sample4;

SM_bits_req #(j) u1(sample_1,SM_bits_req_sample1);
SM_bits_req #(j) u2(sample_2,SM_bits_req_sample2);
SM_bits_req #(j) u3(sample_3,SM_bits_req_sample3);
SM_bits_req #(j) u4(sample_4,SM_bits_req_sample4);

TC_bits_req #(j) m1(sample_1,TC_bits_req_sample1);
TC_bits_req #(j) m2(sample_2,TC_bits_req_sample2);
TC_bits_req #(j) m3(sample_3,TC_bits_req_sample3);
TC_bits_req #(j) m4(sample_4,TC_bits_req_sample4);


always@( *)
begin
if (ecgidx<3)
begin
if(SM_bits_req_sample1>SM_bits_req_sample2 && SM_bits_req_sample1>SM_bits_req_sample3 && SM_bits_req_sample1>SM_bits_req_sample4)
Bits_req=SM_bits_req_sample1;
else if (SM_bits_req_sample2>SM_bits_req_sample1 && SM_bits_req_sample2>SM_bits_req_sample3 && SM_bits_req_sample2>SM_bits_req_sample4)
Bits_req=SM_bits_req_sample2;
else if (SM_bits_req_sample3>SM_bits_req_sample1 && SM_bits_req_sample3>SM_bits_req_sample2 && SM_bits_req_sample3>SM_bits_req_sample4)
Bits_req=SM_bits_req_sample3;
else if (SM_bits_req_sample4>SM_bits_req_sample1 && SM_bits_req_sample4>SM_bits_req_sample2 && SM_bits_req_sample4>SM_bits_req_sample3)
Bits_req=SM_bits_req_sample4;
end

else if (ecgidx==3)
begin
if(TC_bits_req_sample1>TC_bits_req_sample2 && TC_bits_req_sample1>TC_bits_req_sample3 && TC_bits_req_sample1>TC_bits_req_sample4)
Bits_req=TC_bits_req_sample1;
else if(TC_bits_req_sample2>TC_bits_req_sample1 && TC_bits_req_sample2>TC_bits_req_sample3 && TC_bits_req_sample2>TC_bits_req_sample4)
Bits_req=TC_bits_req_sample2;
else if(TC_bits_req_sample3>TC_bits_req_sample1 && TC_bits_req_sample3>TC_bits_req_sample2 && TC_bits_req_sample3>TC_bits_req_sample4)
Bits_req=TC_bits_req_sample3;
else if(TC_bits_req_sample4>TC_bits_req_sample1 && TC_bits_req_sample4>TC_bits_req_sample3 && TC_bits_req_sample4>TC_bits_req_sample2)
Bits_req=TC_bits_req_sample4;
end
end
endmodule





module SM_bits_req(sample,out);
parameter k=10;

input signed [k-1:0] sample;
output [3:0] out;
reg [3:0] out;

always@(sample)
begin
if (sample==0)
out=0;
else if(sample>=-1 && sample<= 1)
out=1;
else if(sample>=-3 && sample<= 3)
out=2;
else if(sample>=-7 && sample<= 7)
out=3;
else if(sample>=-15 && sample<= 15)
out=4;
else if(sample>=-31 && sample<= 31)
out=5;
else if(sample>=-63 && sample<= 63)
out=6;
else if(sample>=-127 && sample<= 127)
out=7;
else if(sample>=-255 && sample<= 255)
out=8;
else if(sample>=-511 && sample<= 511)
out=9;
else if(sample>=-1023 && sample<= 1023)
out=10;

else 
out=15;
end
endmodule




module TC_bits_req(sample,out);
parameter l=10;

input signed [l-1:0] sample;
output [3:0] out;
reg [3:0] out;

always@(sample)
begin
if (sample==0)
out=0;
else if(sample>=-1 && sample<= 0)
out=1;
else if(sample>=-2 && sample<= 1)
out=2;
else if(sample>=-4 && sample<= 3)
out=3;
else if(sample>=-8 && sample<= 7)
out=4;
else if(sample>=-16 && sample<= 15)
out=5;
else if(sample>=-32 && sample<= 31)
out=6;
else if(sample>=-64 && sample<= 63)
out=7;
else if(sample>=-128 && sample<= 127)
out=8;
else if(sample>=-256 && sample<= 255)
out=9;
else if(sample>=-512 && sample<= 511)
out=10;

else 
out=15; //indicates problem
end
endmodule







// magnitude_calculator #(j)m1(sample_1,mag1);
// magnitude_calculator #(j)m2(sample_2,mag2);
// magnitude_calculator #(j)m3(sample_3,mag3);
// magnitude_calculator #(j)m4(sample_4,mag4);













// module magnitude_calculator(sample,magnitude,sign);

// parameter k = 10 ;

// input signed [k-1:0] sample;
// output [k-1:0] magnitude;
// output sign;
// reg  [k-1:0] magnitude;
// reg [k-1:0] temp;

// always@(sample)
// begin
// if(sample<0)
// begin
// temp=~sample;
// magnitude=temp+1;
// sign=1;
// end
// else
// begin
// magnitude=sample;
// sign=0;
// end
// endmodule



