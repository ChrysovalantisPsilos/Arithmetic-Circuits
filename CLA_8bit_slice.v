module CLA_8bit_slice#(
    parameter   ADDER_WIDTH = 8
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
    );
    
    wire [ADDER_WIDTH-1:0] wS0, wS1;
    wire wC0, wC1;
    
    carry_lookahead_adder_8_bit carry_lookahead_adder_8b_inst1 (
        .a( iA ), 
        .b( iB ),
        .cin( 1'b0 ),
        .sum( wS0 ),
        .cout( wC0 )
        );

    carry_lookahead_adder_8_bit carry_lookahead_adder_8b_inst2 (
        .a( iA ), 
        .b( iB ),
        .cin( 1'b1 ),
        .sum( wS1 ),
        .cout( wC1 )
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