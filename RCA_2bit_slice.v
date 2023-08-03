module RCA_2bit_slice#(
    parameter   ADDER_WIDTH = 2
    )
(
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);
wire [ADDER_WIDTH-1:0] wS0, wS1;
wire wC0, wC1;

ripple_carry_adder_Nb #( .ADDER_WIDTH(ADDER_WIDTH)) ripple_carry_inst0
        (
        .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b0 ),
        .oSum(wS0),
        .oCarry(wC0)
      );
      
ripple_carry_adder_Nb #( .ADDER_WIDTH(ADDER_WIDTH)) ripple_carry_inst1
        (
        .iA( iA ), 
        .iB( iB ),
        .iCarry( 1'b1 ),
        .oSum(wS1),
        .oCarry(wC1)
      );
      
      mux2X1 #(ADDER_WIDTH) mux2X1_inst_sum(
        .iIn0( wS0 ),
        .iIn1( wS1 ),
        .iSel( iCarry ),
        .oOut( oSum )
        );
    
    mux2X1 #(1) mux2X1_inst_carry(
        .iIn0( wC0 ),
        .iIn1( wC1 ),
        .iSel( iCarry ),
        .oOut( oCarry )
        );
endmodule