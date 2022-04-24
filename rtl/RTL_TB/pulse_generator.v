/**1**2**3**4**5**6**7*8
* File : pulse_generator.v
*__
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            22/03/2022   First version.
* ------------------------------------------------------------------------------
*__
*
* Description
* Pulse generator.
___

**1**2**3**4**5**6**7*/
module pulse_generator #(parameter SIZE = 8)
(
	input							Clk,		// rellotge del sistema
	input							Rst_n,  	// reset del sistema asíncorn i actiu nivell baix
	input		[SIZE-1:0]			CPre,		//senyal de Pre escalat per generar el pulse
	output 	reg						Pulse 		//sortida del sistema
	);

//////////////////    	MAIN CODE	//////////////////////////
reg [SIZE-1:0] cont;  //contador del sistema

always @(posedge Clk or negedge Rst_n) begin 	//Bloque para el contador
	if (!Rst_n) begin				
		cont <= {SIZE{1'b0}};					//Reseta el contador
	end
	else if (cont < CPre) begin 				//contador hasta CPre
		cont <= cont + 1'b1;
	end
	else begin 									//Cuando CPre == cont, reinica el contador
		cont <= {SIZE{1'b0}};
	end
end

always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) begin				
		Pulse <= 0;			//Reseta el contador
	end
	else if (cont != CPre-1) begin 				//Indica cuando pulse sera 1
		Pulse <= ~|CPre;						//NOR para cuando Cpre sea 0, pulse 1, el resto 0
	end
	else begin
		Pulse <= 1;
	end
end
endmodule 
