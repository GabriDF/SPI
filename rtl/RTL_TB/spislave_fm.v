/********1*********2*********3*********4*********5*********6*********7*********8
* File : slave_fm.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* SPI slave functional module. Used to test the correct tansmission.
* It sends different byte depending on the communication mode selected:
* 
*    | MODE | Data |
*    | -----|------|
*    |  0   | xAA  |
*    |  1   | x72  |
*    |  2   | xC3  |
*    |  3   | x5D  |
* 
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/
`timescale 1 ns / 1 ps
// delay between clock posedge and check
`define DELAY_TRX 3

module spislave_fm #(
  parameter DATA_WIDTH = 8
)(
  input [2-1:0] Mode,   // SPI communication mode 
  input SCK, SDI, CS,   // SPI BUS signals
  output SDO
);
  
  reg bitTX;
  reg [8-1:0] dataTx;
  reg [8-1:0] dataRx;

  assign SDO = CS ? 1'bz : bitTX;

  always @(negedge CS)
    case(Mode)
      2'd0 : dataTx = 8'hAA;
      2'd1 : dataTx = 8'h72;
      2'd2 : dataTx = 8'hC3;
      2'd3 : dataTx = 8'h5D;
    endcase

  always @(SCK or CS) begin
    if(CS)
      case(Mode)
        2'd0 : dataTx = 8'hAA;
        2'd1 : dataTx = 8'h72;
        2'd2 : dataTx = 8'hC3;
        2'd3 : dataTx = 8'h5D;
      endcase
    else begin
      if(Mode == 2'b01 || Mode == 2'b11) begin
        @(SCK);
          #`DELAY_TRX;
      end
      bitTX = dataTx[7];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[6];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[5];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[4];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[3];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[2];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[1];
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      @(SCK);
        #`DELAY_TRX;
      bitTX = dataTx[0];    
      @(SCK);
        #`DELAY_TRX;
      dataRx = {dataRx[6:0],SDI};
      if(Mode == 2'b00 || Mode == 2'b10) begin
        @(SCK);
          #`DELAY_TRX;
      end
    end
  end
endmodule
