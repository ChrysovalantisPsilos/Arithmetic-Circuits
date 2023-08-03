module carry_lookahead_adder_32_bit(
    input wire[31:0] a,
    input wire[31:0] b,
    input wire cin,
    output wire[31:0] sum,
    output wire cout
);
wire c1,c2,c3,c4,c5,C6;


CLA_8bit_slice cla7(.iA(a[7:0]), .iB(b[7:0]), .iCarry(cin), .oSum(sum[7:0]), .oCarry(c1)); 
CLA_8bit_slice cla2(.iA(a[15:8]), .iB(b[15:8]), .iCarry(c1), .oSum(sum[15:8]), .oCarry(c2));
CLA_8bit_slice cla3(.iA(a[23:16]), .iB(b[23:16]), .iCarry(c2), .oSum(sum[23:16]), .oCarry(c3));
CLA_8bit_slice cla4(.iA(a[31:24]), .iB(b[31:24]), .iCarry(c3), .oSum(sum[31:24]), .oCarry(cout));

 
endmodule