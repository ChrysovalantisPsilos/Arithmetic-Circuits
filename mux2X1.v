module mux2X1 #(parameter ADDER_WIDTH=1)(
    input wire[ADDER_WIDTH-1:0] iIn0,
    input wire[ADDER_WIDTH-1:0] iIn1,
    input iSel,
    output wire[ADDER_WIDTH-1:0] oOut
    );
    
    assign oOut = (iSel == 1)?iIn1:iIn0;
endmodule