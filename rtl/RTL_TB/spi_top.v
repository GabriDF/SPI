
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
	input					MISO,           // entrada de lectura del slave
	output	      			MOSI,           // salida de escritura del master
	output					SCK,            // señal de sincronismo
	output	[7:0]			SlaveSelectors  // selecion del slave a comunicarse
	);

//______________________________________________________________
//cables entre modulos
wire rst_pulse;
wire        cPol;
wire        cPha;
wire [3:0]  cPre;
wire        startTx;
wire        endTx;
wire [7:0]  txData;
wire [7:0]  rxData;
wire        pulse;
wire        load;
wire        pulseEnable;
wire        shiftRx;
wire        shiftTx;

assign rst_pulse = Rst_n & pulseEnable;

//__________________________________________________________
//modulos del SPI MASTER
spi_regs regSPI                     
(
    .Clk              (Clk),
    .Rst_n            (Rst_n),
    .Addr             (Addr),
    .Wr               (Wr),
    .DataWr           (DataWr),
    .DataRd           (DataRd),
    .CPol             (cPol),
    .CPha             (cPha),
    .CPre             (cPre),
    .StartTx          (startTx),
    .EndTx            (endTx),
    .TxData           (txData),
    .RxData           (rxData),
    .SlaveSelectors   (SlaveSelectors)
);

spi_cu fsmSPI                       
(	
    .Clk              (Clk),
    .Rst_n            (Rst_n),
    .CPol             (cPol),
    .CPha             (cPha),
    .StartTx          (startTx),
    .EndTx            (endTx),
	.Pulse			  (pulse),
	.SCK			  (SCK),
	.Load			  (load),
	.PulseEnable	  (pulseEnable),
	.ShiftRx		  (shiftRx),
	.ShiftTx		  (shiftTx)
);

shiftreg shifMOSI 
(
    .Clk           (Clk),
    .Rst_n         (Rst_n),
    .En            (shiftTx),
    .Load          (load),
    .DataIn        (txData),
    .DataOut       (),    //no la utilizamos
    .SerIn         (),       //no la utilizamos
    .SerOut        (MOSI)
);

shiftreg shiftMISO 
(
    .Clk           (Clk),
    .Rst_n         (Rst_n),
    .En            (shiftRx),
    .Load          (),        //no la utiliamos
    .DataIn        (),      //no la utilizamos
    .DataOut       (rxData),
    .SerIn         (MISO),
    .SerOut        ()
);

pulse_generator #(.SIZE(4)) pulseSPI
(
    .Clk           (Clk),
    .Rst_n         (rst_pulse),
    .CPre          (cPre),
    .Pulse         (pulse)
);

endmodule
	