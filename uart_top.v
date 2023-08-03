`timescale 1ns / 1ps

module uart_top #(
    parameter   OPERAND_WIDTH = 512,
    parameter   ADDER_WIDTH   = 32,
    parameter   NBYTES        = OPERAND_WIDTH / 8,
    // values for the UART (in case we want to change them)
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
  )  
  (
    input   wire   iClk, iRst,
    input   wire   iRx,
    output  wire   oTx
  );
  
  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [OPERAND_WIDTH-1:0] rBufferA, rBufferB;
  reg [7:0]  rBufferC;
  

  
// State definition  
  localparam s_IDLE         = 4'b0000;
  localparam s_WAIT_RX_C    = 4'b0001;
  localparam s_WAIT_RX_A    = 4'b0010;
  localparam s_WAIT_RX_B    = 4'b0011;
  localparam s_COMMAND      = 4'b0100;
  localparam s_ADDITION     = 4'b0101;
  localparam s_OUT          = 4'b0110;
  localparam s_TX           = 4'b0111;
  localparam s_WAIT_TX      = 4'b1000;
  localparam s_DONE         = 4'b1001;
  
  // Declare all variables needed for the finite state machine 
  // -> the FSM state
  reg [3:0]   rFSM;  
  
  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg [7:0]   rTxByte;  
  wire        wTxBusy;
  wire        wTxDone;
  
      
  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );
     
   wire[7:0]  wRxByte;
   wire wRxDone;  
     
   uart_rx#( .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))
   UART_RX_INST(
   .iClk(iClk),
   .iRst(iRst),
   .iRxSerial(iRx),
   .oRxByte(wRxByte),
   .oRxDone(wRxDone)
   );
   
   reg  rSub;
   reg  iStart;
   reg [(NBYTES)*8:0] rRes=0;
   wire wDone;
   wire [(NBYTES)*8:0] wRes;
   wire [OPERAND_WIDTH-1:0] iOpA,iOpB;
   
   mp_adder#(.OPERAND_WIDTH(OPERAND_WIDTH),.ADDER_WIDTH(ADDER_WIDTH))
   mp_adder_inst(
    .iAddSub(rSub),
    .iClk(iClk),
    .iRst(iRst),
    .iStart(iStart),
    .iOpA(iOpA),
    .iOpB(iOpB),
    .oRes(wRes),
    .oDone(wDone)
   );
     
  reg [$clog2(NBYTES):0] rCnt;
  
  assign iOpA = rBufferA;
  assign iOpB = rBufferB;
 
  
 always@(*)
     begin
         if(rFSM==s_ADDITION)
         iStart=1;
         else 
         iStart=0;   
       end
  
  always @(posedge iClk)
  begin
  
  // reset all registers upon reset
  if (iRst == 1 ) 
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      rCnt <= 0;
      rTxByte <= 0;
      rBufferA <= 0;
      rBufferB <= 0;
      rBufferC <=0;
      rSub <= 0;
    end 
  else 
    begin
      
      case (rFSM)
        
        s_IDLE :
          begin
            rFSM <= s_WAIT_RX_C;
            rCnt <= 0; 
          end
          
        s_WAIT_RX_C:
            begin
                if(wRxDone)
                    begin
                        rFSM <= s_WAIT_RX_A;
                        rBufferC <= wRxByte;
                        //if (rBufferC == 8'h2d || rBufferC == 8'h3d) rSub = 1;
                        
                     end
             end
                 
        s_WAIT_RX_A :
          begin
            if(rCnt<NBYTES)
                begin
                    if(wRxDone)
                        begin
                            rFSM <= s_WAIT_RX_A;
                            rBufferA <= {rBufferA[NBYTES*8-9:0],wRxByte};    
                            rCnt <= rCnt+1;  
                        end
                  end
             else
                begin
                    rCnt <= 0;
                    rFSM <= s_WAIT_RX_B; 
                 end   
          end
          
          s_WAIT_RX_B :
            begin
             if(rCnt<NBYTES)
                begin
                      if(wRxDone)
                         begin
                             rFSM <= s_WAIT_RX_B;
                             rBufferB <= {rBufferB[NBYTES*8-9:0],wRxByte};  
                             rCnt <= rCnt+1; 
                          end
                   end
             else
                    begin
                        rCnt <= 0;
                        rFSM <= s_COMMAND;
                    end
          end
         
          s_COMMAND:
            begin
                case (rBufferC)
                    8'h2d: //-
                        begin
                            rSub <= 1;
                        end
                    8'h2b: //+
                        begin
                            rSub <= 0;
                        end
                    8'h3d: //=
                        begin
                            rSub <= 1;
                        end
                        
                    default:
                        begin
                            rSub <= 0;
                        end
                 endcase
                 rFSM <= s_ADDITION;
             end
             
          s_ADDITION:
            begin
                if(wDone)
                    begin
                        rFSM<=s_OUT;
                        rRes<=wRes;
                    end
                else
                    begin
                        rFSM<=s_ADDITION;
                    end
            end
            
            
            
            s_OUT:
                begin
                // send the first bit
                    rFSM<=s_WAIT_TX;
                    rTxStart <= 1;
                    rTxByte <= {3'b000,rRes[NBYTES*8]} ;
                    rCnt<=0;     
                end
                
        s_WAIT_TX :
            begin
                if (wTxDone) begin
                rFSM <= s_TX;
                end else begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 0;           
                end
            end 
        
        s_TX :
          begin
            if( (rCnt < NBYTES) && (wTxBusy ==0))
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1; 
                rTxByte <= rRes[(NBYTES)*8-1:(NBYTES)*8-8];            // we send the uppermost byte
                rRes <= {rRes[(NBYTES)*8-9:0] , 8'b0000_0000};    // we shift from right to left
                rCnt <= rCnt + 1;
               end
            else 
              begin
                rFSM <= s_DONE;
                rTxStart <= 0;
                rTxByte <= 0;
                rCnt <= 0;
              end
            end 
              
            s_DONE :
              begin
                rFSM <= s_IDLE;
                rTxStart <= 0;
                rCnt <= 0;
                rTxByte <= 0;
                rBufferA <= 0;
                rBufferB <= 0;
                rBufferC <=0;
                rSub <= 0;
                rRes <= 0;
              end 

            default: 
             begin 
                 rFSM <= s_IDLE;
                 
              end
             
          endcase
      end
    end            
    
endmodule