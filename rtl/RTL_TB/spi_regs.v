/********1*********2*********3*********4*********5*********6*********7*********8
* File : spi_regs.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
* Description
* Configuration and Status Registers for SPI Bus.
*
* ============================================================================== 
*  SPI_CTRL:   Serial Peripheral Interface Control Register           
*              (Write/Read) Default: 0x00
* ------------------------------------------------------------------------------
*    bit[7]  : BUSY ? SPI Bus Busy Flag (Read only)
*                 1 = Transmission not complete.
*                 0 = Transmission completed.
*    bit[5:1]: Reserved bits.
*    bit[0]  : ENABLE ? Serial Peripheral Master Enable
*                0 = SPI master off
*                1 = SPI master on
* 
* ============================================================================== 
*  SPI_BUFFER: Serial Peripheral Interface Transmited/Received Data Register 
*              (Write/Read) Default: 0x00
*
* ============================================================================== 
*  SPI_CONFIG: Serial Preipheral Interface SCK Configuration Register
*              (Write/Read) Default: 0x00
* ------------------------------------------------------------------------------
*    bit[7:0]: Reserved bits.
*    bit[5]  : CPOL ? Clock Polarity
*                0 = the base value of the clock is zero
*                1 = the base value of the clock is one
*    bit[4]  : CPHA ? Clock Phase
*                At CPOL=0 the base value of the clock is zero:
*                  - For CPHA=0: data are captured on the clock's rising 
*                    edge (low2high transition) and data are propagated on a 
*                    falling edge.
*                  - For CPHA=1: data are captured on the clock's falling edge
*                    and data are propagated on a rising edge.
*                At CPOL=1 the base value of the clock is one (inversion of CPOL=0)
*                  - For CPHA=0: data are captured on clock's falling edge and 
*                    data are propagated on a rising edge.
*                  - For CPHA=1: data are captured on clock's rising edge and 
*                    data are propagated on a falling edge.
*    bit[3:0]: CPre ? Prescaled Value used to determine the bus baud rate. The
*              SCK clock obtained is given by: SCK = Clk/[2(CPre+1)] where Clk is 
*              the system clock.
*
* ==============================================================================
*  SPI_SSELEC: Serial Peripheral Interface Slave Selector Register       
*              (Write/Read) Default: 0xFF
* ------------------------------------------------------------------------------
*    Each bit is used to select one slave.  
*_______________________________________________________________________________ 
*
* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/


`include "spi_defines.vh"         // Include del archivo que contiene las macros

module spi_regs #(
  parameter DATA_WIDTH = 8,       // definicion de los parametros para la "anchura" de los datos y direcciones.
  parameter ADDR_WIDTH = 2
)(
  input  Clk,                      // system cloc
  input  Rst_n,                    // system reset asynch, active low
  input  [ADDR_WIDTH-1:0] Addr,    // registers addres
  input  Wr,                       // registers write enable
  input  [DATA_WIDTH-1:0] DataWr,  // registers data input
  output reg [DATA_WIDTH-1:0] DataRd,  // registers data output

  output CPol,                     // Used to select the SCK polarization
  output CPha,                     // Used to select the SCK phase
  output [4-1:0] CPre,             // SCK clock prescale, number of clk ticks to defin one SCK semi period
  output reg StartTx,              // Initiates the transmission.
  input  EndTx,                    // Indicates the end of transission
  output [DATA_WIDTH-1:0] TxData,  // "anchura" de los vectores de transmision y recepciones
  input  [DATA_WIDTH-1:0] RxData,
  output [DATA_WIDTH-1:0] SlaveSelectors // Anchura del vector de slave selecctor.
);

  // spi registers
  reg [DATA_WIDTH-1:0] ctrl;       // SPI_CTRL register with busy flag and enable bits
  reg [DATA_WIDTH-1:0] buffer;     // SPI_BUFFER register
  reg [DATA_WIDTH-1:0] sckConfig;  // SPI SCK COnfiguration registers CPOL CPHA CPRE
  reg [DATA_WIDTH-1:0] sselect;    // SPI Slave Selector register

  // other registers
  reg busy;          // flag to indicate there is a transmission in course
  wire enable;       // used to mask de start signal enabling or disabling the spi master

  // output assignaments
  assign enable = ctrl[0];  // Se asigna que el bit de enable es el bit menos significativo de "ctrl"
  assign CPol = sckConfig[5]; // CPol se define con el bit 5 de sckconfig
  assign CPha = sckConfig[4]; // Cpha se define con el bit 4 de sckconfig
  assign CPre = sckConfig[3:0]; // CPre se define con los bits 0,1,2 y 3 de sckconfig

  assign SlaveSelectors = sselect;  // Se asigna el output de slave selector a sslect que es el reg que nos indica con que slave nos comunicamos

  assign TxData = buffer; // Se asigna el output txdata al reg buffer

  // write synch
  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n
  //Escritura sincrona, primeramente si ocurre un reset reseteamos el registro de control
  //Si tenemos peticion de escritura (wr=1) y nos "entra" por addr la direccion del registro
  //de control entonces escribimos los datos de DataWr en el reg ctrl, en cualquier otro
  //caso mantenemos el valor en el registro.
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      ctrl <= {DATA_WIDTH{1'b0}};
    else if(Wr==1'b1 && Addr==`SPI_CTRL)
      ctrl <= DataWr;
    else
      ctrl <= ctrl;

  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n
  //Escritura sincrona, primeramente si ocurre un reset reseteamos el registro de configuracion SPI
  //Si tenemos peticion de escritura (wr=1) y nos "entra" por addr la direccion del registro
  //de configuracion del SPI entonces escribimos los datos de DataWr en el reg sckconfig, en cualquier otro
  //caso mantenemos el valor en el registro.
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      sckConfig <= {DATA_WIDTH{1'b0}};
    else if(Wr==1'b1 && Addr==`SPI_CONFIG)
      sckConfig <= DataWr;
    else
      sckConfig <= sckConfig;
  
  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n
  //Escritura sincrona, primeramente si ocurre un reset reseteamos el registro de seleccion de slave
  // En este caso en vez de pone todo el registro a 0 lo que hacemos es decirle que lo ponga todo a 1 es decir
  // que no seleccione ningun slave
  //Si tenemos peticion de escritura (wr=1) y nos "entra" por addr la direccion del registro
  //de slave select entonces escribimos los datos de DataWr en el reg sselect, en cualquier otro
  //caso mantenemos el valor en el registro.
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      sselect <= {DATA_WIDTH{1'b1}};
    else if(Wr==1'b1 && Addr==`SPI_SSELEC)
      sselect <= DataWr;
    else
      sselect <= sselect;

  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n 
  //Escritura sincrona, primeramente si ocurre un reset reseteamos el registro de seleccion de buffer
  //Si tenemos peticion de escritura (wr=1) y nos "entra" por addr la direccion del registro
  //de bufer select entonces escribimos los datos de DataWr en el reg buffer, en cualquier otro
  //caso mantenemos el valor en el registro.
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      buffer <= {DATA_WIDTH{1'b0}};
    else if(EndTx)
      buffer <= RxData;
    else if(Wr==1'b1 && Addr==`SPI_BUFFER)
      buffer <= DataWr;
    else
      buffer <= buffer;

  // logic to generate Start and loadTx signals
  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n
  //Priramente como siempre, hay que mirar si ocurre un reset, en caso de reset la salida StartTx es 0
  //en caso de peticion de escritura (wr=1) y a su vez la direccion (addr) es la del buffer del SPI
  //el output reg StartTx pasa a estado "enable" se habilita el master SPI, en cualquier otro caso StartTx pasa a valor bajo ("0")
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      StartTx <= 1'b0;
    else if(Wr==1'b1 && Addr==`SPI_BUFFER)
      StartTx <= enable;
    else
      StartTx <= 1'b0;

  // logic to generate the busy flag
  // busy es el bit mas significativo del registro de control
  // Bloque always activado por flanco positivo de reloj o flanco de bajada de rst_n
  // Comprobamos si ha ocurrido un flanco de bajada del rst_n para hacer reset y poner el bit 
  // de busy a 0, si ocurre un StartTx entonces ponemos el bit de busy a 1 para decir que 
  // estamos en medio de una transmision en caso de que ocurra un EndTx entonces pasamos el bit de busy
  // a "0" lo cual quiere decir que dejamos de estar ocupados y en cualquier otro caso mantenemos el valor
  // de busy.
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      busy <= 1'b0;
    else if(StartTx)
      busy <= 1'b1;
    else if(EndTx)
      busy <= 1'b0;
    else
      busy <= busy;

  // asynch read
  //Lectura asincrona donde tenemos un * en la lista de sensitividad lo cual incluye a todas las señales que 
  // intervienen en el always, donde tenemos un case activado con la señal Addr (input) entonces dependiendo 
  // del registro seleccionado dataRd pasa a tener los valores asignados.
  always @(*)
    case(Addr)
      `SPI_CTRL   : DataRd = {busy, ctrl[DATA_WIDTH-2:0]};
      `SPI_BUFFER : DataRd = buffer;
      `SPI_CONFIG : DataRd = sckConfig;
      `SPI_SSELEC : DataRd = sselect;
      default : DataRd = {DATA_WIDTH{1'b0}};
    endcase

endmodule

