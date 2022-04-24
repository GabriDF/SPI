
/********1*********2*********3*********4*********5*********6*********7*********8
* File : tb_spi_top.v
*_______________________________________________________________________________
*
* Revision history
*
* Name         								 Date        	Observations
* ------------------------------------------------------------------------------
* -Gabriel Diaz & Christian Doblas           14/04/2022   	First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Testbench del SPI master top
*_______________________________________________________________________________


*********1*********2*********3*********4*********5*********6*********7*********/
// time scale definiton
`timescale 1 ns / 1 ps
//Definicon de los registros
`define DELAY 2
`define CLK_HALFPERIOD 10
`include "../rtl/spi_defines.vh"         // Include del archivo que contiene las macros

module tb_spi_top();

    //___________________________________________________________________________
    // input output signals for the DUT
        reg           clk;                      // system cloc
        reg           rst_n;                    // system reset asynch, active low
        reg  [1:0]    addr;               // registers addres
        reg           wr;                       // registers write enable
        reg  [7:0]    dataWr;             // registers data input
        wire [7:0]    dataRd;             // registers data output


        wire [7:0]    slaveSelectors; // Anchura del vector de slave selecctor.
        wire          sCK;
        wire          mOSI;
        reg           mISO;

    // input output signals for the DUT
        reg  [1:0]    mode;
        reg           sDI;
        wire          cS;
        wire          sDO;
        
        assign cS = slaveSelectors[0];
        assign sDI = mOSI;
        assign mISO = sDO;
    //___________________________________________________________________________
    // test signals
        integer         errors;    // Accumulated errors during the simulation
        integer         vExpected;  // expected value
        integer         vObtained; // obtained value
        reg     [7:0]   data2write; // data to load in the shift register
        reg     [1:0]   addr2write; // data to load in the shift register
        //reg [1:0] modoc; //Modo de control
        reg     [3:0]   pre_c;
        reg             ejem;

    //___________________________________________________________________________
    // Instantiation of the module to be verified

        spi_top DUT(
            .Clk					(clk),			// rellotge del sistema
            .Rst_n					(rst_n),			// reset del sistema asíncorn i actiu nivell baix
            .DataWr			        (dataWr),         // registers data input
            .Wr				        (wr),             // registers write enable
            .Addr			        (addr),           // registers addres
            .DataRd			        (dataRd),         // registers data output
            .MISO					(mISO),
            .MOSI	      			(mOSI),
            .SCK					(sCK),
            .SlaveSelectors			(slaveSelectors)
        );

        spislave_fm SLA(
            .Mode                   (mode),
            .SCK                    (sCK),
            .SDI                    (sDI),
            .CS                     (cS),
            .SDO                    (sDO)
        );

    //___________________________________________________________________________
    // 100 MHz clock generation
        initial clk = 1'b0; 
        always #10 clk = ~ clk;

    //___________________________________________________________________________
    // signals and vars initialization
        initial begin
            rst_n <= 1'b1;
            wr <= 1'b0;
            addr <= 1'b0;
            dataWr <= 8'b0;
            mode <= 2'b0;
            errors = 0;                                 // initialize the errors counter
            waitCycles(1);
        end
        
    //___________________________________________________________________________
    // Test Vectors
    initial begin
      $timeformat(-9, 2, " ns", 10);                    // format for the time print
      waitCycles(10);                                   
      resetDUT();                                       //hacemos un reset para tener valores conocidos
      mode = 2'b00;                                     //estado inicial de comunicacion con el slave
      pre_c = 4'b0000;                                  //estado inicial del cPre

      //Habilitamos el enable del SPI MASTER
      addr2write = `SPI_CTRL;                           //registro de control  
      data2write = 8'b1;                                //ponemos en 1 el bit de enable
      writeReg(data2write, addr2write);                 //Escribimos los datos en el registro de control
      waitCycles(1);
    
      //Leemos el registro que acabamos de escribir para comprobar que esta todo ok
      vExpected = data2write;
      readReg(addr2write, vObtained);                   //comprobamos que esta habilitado el SPI MASTER
      $display("[Info- %t] Deberiamos tener Enable a 00000001 y tenemos %b ", $time, vObtained);
      //Checks de los errores y displays
      asyncCheck;
      checkErrors;
      errors = 0;                    
      waitCycles(1);

      //Seleccionamos el Slave numero 1, escribimos en el registro de sslect  
      addr2write = `SPI_SSELEC;                         //registro del SlaveSeelector    
      data2write = 8'b11111110;                         //Indicamos que nos conectaremos con el primer slave
      writeReg(data2write, addr2write);                 
      waitCycles(1);

      //Leemos el registro que acabamos de escribir para comprobar que esta ok
      vExpected = data2write;
      readReg(addr2write, vObtained);                   //comprobamos que 
      $display("[Info- %t] Deberiamos tener Slave 00000001 y tenemos %b ", $time, vObtained);
      //Checks de los errores y displays
      asyncCheck;
      checkErrors;
      errors = 0;                                    // initialize the errors counter
      waitCycles(1);
      
        repeat(4) begin
            $display("[Info- %t] Test SPI with mode %b, pre = %b", $time, mode, pre_c);
            //Elegimos el modo a usar y el prescalado, empezamos con modo 0000 y luego 0001,0010,0011
            modo_data(mode, pre_c);
            waitCycles(1);
            //Leemos el registro que acabamos de escribir
            vExpected = {2'b00, mode, pre_c};
            addr2write = `SPI_CONFIG;
            readReg(addr2write, vObtained);     
            asyncCheck;                                 //comprobamos que esta correcto la escritura de la config del SCK
            checkErrors;
            errors = 0;                                 // initialize the errors counter
            waitCycles(1);
            
            addr2write = `SPI_BUFFER;                   //registro del buffer    
            data2write = 8'hBB;  
            writeReg(data2write, addr2write);           //enviamos un dato al slave
            waitCycles(1);
            readReg(addr2write, vObtained);            //comprobamos que el dato a enviar es el deseado
            vExpected = data2write;
            asyncCheck;
            checkErrors;
            errors = 0;                    // initialize the errors counter

            WaitEnd;                                //espera hasta un flag de EndTx para saber que ha recibido el dat del SLAVE    
            //waitCycles(200);              //se utiliza para poder separacion entre cada test
                                
            case (mode)                     //en funcion del mode del SCK recibiremos un dato despislave_fm
                2'b00 : vExpected = 8'hAA;
                2'b01 : vExpected = 8'h72; 
                2'b10 : vExpected = 8'hC3; 
                2'b11 : vExpected = 8'h5D; 
                default :  vExpected = 8'h00;       //ponemos un default para indicar que el mode no esta bien indicado en el salve
            endcase 

            wr = 1'b0;
            addr = 2'b01;                   //registro del buffer 
            waitClk;
            
            readReg(addr2write, vObtained);        //miramos si el valor recibido del slave
            waitClk;
            $display("%h y %b o %h y %b", dataRd, dataRd, vExpected, vExpected);
            waitCycles(3);
            
            syncCheck;
            checkErrors;
            errors = 0;                    // initialize the errors counter 
            

            //para cambiar el valor de transmision del slave tenemos que cambiar el valor de CS
            //para eso ponemos primero a 1 y luego a 0
            addr2write = `SPI_SSELEC;  //registro del SlaveSeelector    
            data2write = 8'b11111111;  //apagamos el SlaveSlector

            mode = mode + 1'b1;       //indicamos al slave como vamos a escribir
            pre_c = pre_c + 1'b1;
                
            //data2write = !data2write;
            writeReg(data2write, addr2write);
            waitCycles(1);
            data2write = 8'b11111110;  //indimos que nos conectaremos con el primer slave
            writeReg(data2write, addr2write);
            waitCycles(3);
    
        end
        $stop;
    end
    
    //___________________________________________________________________________
    // Test tasks and functions
    
        task  modo_data(input [1:0] modo, input [3:0] prescale); 
            //Si CPRE = 0 y CPHA = 0 MODO 0
            //SI CPRE = 0 y CPHA = 1 MODO 1
            //SI CPRE = 1 y CPHA = 0 MODO 2
            //SI CPRE = 1 y CPHA = 1 MODO 3
            begin
            data2write = {2'b00, modo, prescale};     
            writeReg(data2write,`SPI_CONFIG);
            end
        endtask

    //Wait end task
        task WaitEnd; begin
            addr2write = `SPI_CTRL;  //registro de control  
            readReg(addr2write, vObtained);
            ejem= 1'b1;
            while (dataRd[7] == 1'b1)   waitClk;
            ejem= 1'b0;
        end
        endtask

    // Synchronous output check
        task syncCheck;
        begin
            waitClk;
            if (vExpected != vObtained) begin
            $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
            errors = errors + 1;
            end else begin
            $display("[Info- %t] Successful check at time", $time);
            end
        end
        endtask

        // Asynchronous output check
        task asyncCheck;
        begin
            #`DELAY;
            if (vExpected != vObtained) begin
            $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
            errors = errors + 1;
            end else begin
            $display("[Info- %t] Successful check", $time);
            end
        end
        endtask

        // generation of reset pulse
        task resetDUT;
        begin
            $display("[Info- %t] Reset", $time);
            rst_n = 1'b0;
            waitCycles(3);
            rst_n = 1'b1;
        end
        endtask

        // wait for N clock cycles
        task waitCycles;
        input [32-1:0] Ncycles;
        begin
            repeat(Ncycles) begin
            waitClk;
            end
        end

        endtask

        // wait the next posedge clock
        task waitClk;
        begin
            @(posedge clk);
            #`DELAY;
        end //begin
        endtask

        // Check for errors during the simulation
        task checkErrors;
            begin
                if (errors==0) begin
                    $display("********** TEST PASSED **********");
                end else begin
                    $display("********** TEST FAILED **********");
                end
            end
        endtask

        task writeReg(input [8-1:0] data, input [2-1:0] addr_tk);
        // Task automatically generates a write to a register.
        // Inputs data to write and reg address.
        begin
        dataWr = data;          //introducimos el valor en el registro
        addr = addr_tk;         //indicamos la direccion del registro
        wr = 1'b1;              //habilitamos la escritura
        waitClk;
        wr = 1'b0;              //deshabilitamos la escritura
        end
        endtask

        task readReg(input [2-1:0] addr_tk, output [8-1:0] data);
        // Task automatically generates a write to a register.
        // Input reg address. Output read data.
        begin
        data = dataRd;        //Leesmos el valor del registro
        addr = addr_tk;       //indicamos que registro queremos leer
        end
        endtask

        // function [8-1:0] regMasks (input [2-1:0] addr_tk, input [8-1:0] data);
        // // The functions masks the MSB of the control register with the internal busy flag
        // // HELP: use the verilog hierachical reference scope to access the busy flag
        // //       tb_spi_regs.DUT.busy
        // // HELP2: use the `ifdef `else `endif diretive to add compativility with the gate-level verification
        // begin
        // if (addr_tk==2'b0)begin //si leemos el registro de control
        //     `ifdef RTL_LVL        //en RTL level
        //     regMasks = {tb_spi_regs.DUT.busy, data[8-2:0]}; //el bit 7 sera el bit de busy
        //     `else                 //en gate level
        //     regMasks = {tb_spi_regs.DUT.busy.q, data[8-2:0]}; //el bit 7 sera el bit de busy
        //     `endif
        // end
        // else begin   //si no es el registrol de ctrl
        //     regMasks = data[2-1:0]; //La salida directamente es el dato sin ninguna mascara
        // end
        // end
        // endfunction

endmodule
