/********1*********2*********3*********4*********5*********6*********7*********8
* File : shiftreg.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            15/03/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Shift register.
*_______________________________________________________________________________

*********1*********2*********3*********4*********5*********6*********7*********/

module shiftreg #(parameter SIZE = 8) //Parametrizacion del shift register, a 8 FFs
  (
  input                 Clk,       // rellotge del sistema
  input                 Rst_n,     // reset del sistema asíncorn i actiu nivell baix
  input                 En,        // enable signal for the shift register
  input                 Load,      // shift register load data
  input      [SIZE-1:0] DataIn,    // shift register parallel data input
  output     [SIZE-1:0] DataOut,   // shift register parallel data output
  input                 SerIn,     // shift register serial data input
  output wire           SerOut     // shift register serial data output
);

  //___________________________________________________________________________
  
  //___________________________________________________________________________
                                // Main code //
reg [SIZE-1:0] tmp;                   //Variable temporal

assign SerOut = tmp[SIZE-1];          //Asignaciones para el Serial output y DataOutput desde la variable temporal
assign DataOut = tmp;                 //Guardamos la variable temporal como los datos de salida

always @(posedge Clk or negedge Rst_n) begin      //Bloque always con clock por flaco de subida del reloj y reset por flanco de bajada asincrono
  if(!Rst_n) begin                                //Con reset en 0, todos los valores pasan a ser 0        
     tmp <= {SIZE{1'b0}};
  end     
  else if (En) begin                              //Si hay un En desplazamos los datos de los FFs
		tmp[0] <= SerIn;                              //El primer FF seran Serial input
		tmp[SIZE-1:1] <= tmp[SIZE-2:0];                         
  end 
  else if(Load) begin                             //Si ocurre un load se cargan los datos en paralelo
	   tmp <= DataIn[SIZE-1:0];  
  end 
  else begin
    tmp <= tmp;                                   //En cualquier otro caso mantenemos los datos
  end
  end
endmodule