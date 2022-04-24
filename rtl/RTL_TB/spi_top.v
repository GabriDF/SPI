
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
//el rst del generador de pulsos vendra en funcion del rst general y el enable del pulse
assign rst_pulse = Rst_n & pulseEnable;

//__________________________________________________________
//modulos del SPI MASTER

spi_regs #(.DATA_WIDTH(8), .ADDR_WIDTH(2)) regSPI                     
(//registros del SPI MASTER
    .Clk              (Clk),        //clk del sistema
    .Rst_n            (Rst_n),      //reset del sistema
    .Addr             (Addr),       //direccion del registro a w/r
    .Wr               (Wr),         //habilita la escritura
    .DataWr           (DataWr),     //señal de escritura
    .DataRd           (DataRd),     //señal de lectura
    .CPol             (cPol),       //Polaridad del SCK
    .CPha             (cPha),       //Fase del SCK
    .CPre             (cPre),       //Prescalado de la señal de sincronismo
    .StartTx          (startTx),    //señal de inicio de una operacion
    .EndTx            (endTx),      //indica que el valor en serie esta cargado
    .TxData           (txData),     //dato a transmitir
    .RxData           (rxData),     //dato a recibir
    .SlaveSelectors   (SlaveSelectors)//registro del Slave selector
);

spi_cu fsmSPI                       
(	//maquina de estados
    .Clk              (Clk),        //clk del sistema
    .Rst_n            (Rst_n),      //reset del sistema
    .CPol             (cPol),       //Polaridad del SCK
    .CPha             (cPha),       //Fase del SCK
    .StartTx          (startTx),    //señal de inicio de envio del dato
    .EndTx            (endTx),      //indica que el valor en serie esta cargado
	.Pulse			  (pulse),      //timer del SCK
	.SCK			  (SCK),        //señal de sincronismo
	.Load			  (load),       //carga del dato en paralelo al shift register
	.PulseEnable	  (pulseEnable),//enciende el generador de pulsos
	.ShiftRx		  (shiftRx),    //shiftea un valor por MISO
	.ShiftTx		  (shiftTx)     //shiftea un valor por MOSI
);

shiftreg #(.SIZE(8)) shifMOSI 
(
    .Clk           (Clk),           //clk del sistema
    .Rst_n         (Rst_n),         //reset del sistema
    .En            (shiftTx),       //shiftea un valor por MOSI
    .Load          (load),          //carga del dato en paralelo al shift register
    .DataIn        (txData),        //dato a transmitir
    .DataOut       (),              //no la utilizamos
    .SerIn         (),              //no la utilizamos
    .SerOut        (MOSI)           //salida en serie del MOSI
);

shiftreg #(.SIZE(8)) shiftMISO 
(
    .Clk           (Clk),           //clk del sistema
    .Rst_n         (Rst_n),         //reset del sistema
    .En            (shiftRx),       //shiftea un valor por MISO
    .Load          (),              //no la utiliamos
    .DataIn        (),              //no la utilizamos
    .DataOut       (rxData),        //valor en paralelo recibido por MISO
    .SerIn         (MISO),          //entrada del master del dato de los slaves
    .SerOut        ()               //no la utiliamos
);

pulse_generator #(.SIZE(4)) pulseSPI
(
    .Clk           (Clk),           //clk del sistema
    .Rst_n         (rst_pulse),     //enciende el generador de pulsos
    .CPre          (cPre),          //Prescalado de la señal de sincronismo
    .Pulse         (pulse)          //timer del SCK
);

endmodule
	