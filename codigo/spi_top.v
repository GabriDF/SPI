
/********1*********2*********3*********4*********5*********6*********7*********8
* File : spi_top.v
*_______________________________________________________________________________
*
* Revision history
*
* Name         								 Date        	Observations
* ------------------------------------------------------------------------------
* -Gabriel Diaz & Christian Doblas           11/04/2022   	First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* SPI master top
*_______________________________________________________________________________


*********1*********2*********3*********4*********5*********6*********7*********/
module spi_top 
(
	input					Clk,			// rellotge del sistema
	input					Rst_n,			// reset del sistema asíncorn i actiu nivell baix
	input	[7:0]			DataWr,         // registers data input
	input					Wr,             // registers write enable
	input	[1:0]			Addr,           // registers addres
	output	[7:0]			DataRd,         // registers data output
	input					MISO,
	output	      			MOSI,
	output					SCK,
	output	[7:0]			SlaveSelectors
	);

wire rst_pulse;
wire        CPol;
wire        CPha;
wire [3:0]  CPre;
wire        StartTx;
wire        EndTx;
wire [7:0]  TxData;
wire [7:0]  RxData;
wire        Pulse;
wire        Load;
wire        PulseEnable;
wire        ShiftRx;
wire        ShiftTx;

assign rst_pulse = Rst_n & PulseEnable;

spi_regs regSPI
(
    .Clk              (Clk),
    .Rst_n            (Rst_n),
    .Addr             (Addr),
    .Wr               (Wr),
    .DataWr           (DataWr),
    .DataRd           (DataRd),
    .CPol             (CPol),
    .CPha             (CPha),
    .CPre             (CPre),
    .StartTx          (StartTx),
    .EndTx            (EndTx),
    .TxData           (TxData),
    .RxData           (RxData),
    .SlaveSelectors   (SlaveSelectors)
);

spi_cu fsmSPI
(	
    .Clk              (Clk),
    .Rst_n            (Rst_n),
    .CPol             (CPol),
    .CPha             (CPha),
    .StartTx          (StartTx),
    .EndTx            (EndTx),
	.Pulse			  (Pulse),
	.SCK			  (SCK),
	.Load			  (Load),
	.PulseEnable	  (PulseEnable),
	.ShiftRx		  (ShiftRx),
	.ShiftTx		  (ShiftTx)
);

shiftreg shifMOSI 
(
    .Clk           (Clk),
    .Rst_n         (Rst_n),
    .En            (ShiftTx),
    .Load          (Load),
    .DataIn        (TxData),
    //.DataOut       (DataOut),
    //.SerIn         (SerIn),
    .SerOut        (MOSI)
);

shiftreg shiftMISO 
(
    .Clk           (Clk),
    .Rst_n         (Rst_n),
    .En            (ShiftRx),
    //.Load          (Load),
    //.DataIn        (DataIn),
    .DataOut       (RxData),
    .SerIn         (MISO)
    //.SerOut        (SerOut)
);

pulse_generator pulseSPI
(
    .Clk           (Clk),
    .Rst_n         (rst_pulse),
    .CPre          (CPre),
    .Pulse         (Pulse)
);

endmodule
	