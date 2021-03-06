/********1*********2*********3*********4*********5*********6*********7*********8
* File : spi_cu.v
*_______________________________________________________________________________
*
* Revision history
*
* Name         								 Date        	Observations
* ------------------------------------------------------------------------------
* -Gabriel Diaz & Christian Doblas           05/04/2022   	First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* FSM maquina de estados de nuestro SPI master
*_______________________________________________________________________________

*********1*********2*********3*********4*********5*********6*********7*********/

module spi_cu
(
input					Clk,			// rellotge del sistema
input					Rst_n,			// reset del sistema asíncorn i actiu nivell baix
input					CPol,			// CPol polaridad de nuestro SCK
input					CPha,			// CPha fase de nuestro SCK
input					Pulse,			//Pulse del pulse_generator
input					StartTx,		//indica la transmisió de dades del spi_reg
output					SCK,			//Señal SCK
output					EndTx,			//Transmissio de dades del shiftMISO al buffer
output					Load,			//Carrega de dades al shiftMOSI
output					PulseEnable,	//Habilitem el pulse_generator
output					ShiftRx,		//Desplaçament del ShiftMISO
output					ShiftTx			//Desplaçament del ShiftMOSI
);

reg[4:0] 	state;
reg[4:0] 	next_state;
parameter	IDLE 		= 5'b00001,
			state_load 	= 5'b00010,
			state_tx 	= 5'b00100,
			state_rx 	= 5'b01000,
			state_EndTx = 5'b10000;
reg[4:0]	contador;
reg 		sck_reg;
reg 		EndTx_reg;
reg 		PulseEnable_reg;
reg 		ShiftRx_reg;
reg 		ShiftTx_reg;
reg 		Load_reg;
assign EndTx = EndTx_reg;
assign PulseEnable = PulseEnable_reg;
assign ShiftRx = ShiftRx_reg;
assign ShiftTx = ShiftTx_reg;
assign Load = Load_reg;
assign SCK = sck_reg;


//Cambio de estados
always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always @(posedge Clk or negedge Rst_n) begin //contador de nuestra maquina de estados
	if (!Rst_n) begin
		contador <= 5'b0;
	end
	else if (Pulse) begin
		if (contador > 16) begin
			contador = 0;
		end
		else begin
			contador = contador + 1'b1;
		end
	end
end

//caculo de siguiente estado
always @(state or StartTx or Pulse or contador) begin
	case (state)
		IDLE 		: 	if (StartTx)						next_state = state_load;	//salimos del estado inicial
						else 								next_state = IDLE;			//mantenemos el estado
		state_load 	:	if (Pulse)							next_state = state_tx;		//estado cargar el dato a enviar
						else 								next_state = state_load;	//mantenemos el estado
		state_tx 	:	if (Pulse)							next_state = state_rx;		//estado de envio de datos
						else 								next_state = state_tx;		//mantenemos el estado
		state_rx 	:	if ((contador==16) && (Pulse)) 		next_state = state_EndTx;//hemos terminado de leer y recivir datos
						else if (Pulse)   					next_state = state_tx; 		//estado de lectura de datos
						else 								next_state = state_rx;		//mantenemos el estado
		state_EndTx : 										next_state = IDLE;			//acabamos y volvemos al estado inical
		default		:										next_state = IDLE;
	endcase 
end


//salidas para cada estado menos SCK
always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) begin
		EndTx_reg <= 1'b0;
		PulseEnable_reg <= 1'b0;
		ShiftRx_reg <= 1'b0;
		ShiftTx_reg <= 1'b0;
		Load_reg <= 1'b0;
		sck_reg <= 1'b0;
	end
	else begin
		case(state) 
			IDLE 			:	begin 	
								EndTx_reg <= 1'b0;
								PulseEnable_reg <= 1'b0;
								ShiftRx_reg <= 1'b0;
								ShiftTx_reg <= 1'b0;
								Load_reg <= 1'b0;
								sck_reg <= CPol;
								end

			state_load 		:	begin 
								EndTx_reg <= 1'b0;
								PulseEnable_reg <= 1'b1;   //activamos el generador de pulsos
								ShiftRx_reg <= 1'b0;
								ShiftTx_reg <= 1'b0;
								Load_reg <= 1'b1;			//cargamos nuestro dato a enviar
								if (Pulse && !CPha) begin
									sck_reg <= CPol;
								end
								else if (Pulse)	sck_reg <= ~sck_reg;
								else sck_reg <= CPol;
								
								end

			state_tx 		:	begin
								EndTx_reg <= 1'b0;
								PulseEnable_reg <= 1'b1;	//activamos el generador de pulsos
								if (Pulse) 	begin
									ShiftRx_reg <= 1'b1;
									sck_reg <= ~sck_reg;
								end
								else begin
									ShiftRx_reg <= 1'b0;
									sck_reg <= sck_reg;
								end								
								ShiftTx_reg <= 1'b0;
								Load_reg <= 1'b0;										
								end
								

			state_rx 		:	begin
								EndTx_reg <= 1'b0;
								PulseEnable_reg <= 1'b1;	//activamos el generador de pulsos
								ShiftRx_reg <= 1'b0;								
								Load_reg <= 1'b0;
								if (Pulse) begin
									if ((CPha == 1'b1) && (contador > 5'b10000)) 	sck_reg <= CPol;
									else											sck_reg <= ~sck_reg;
									if (contador < 5'b10000)						ShiftTx_reg <= 1'b1;
									else 											ShiftTx_reg <= 1'b0;
								end
								else sck_reg <= sck_reg;
								end
								

			state_EndTx 	:	begin
								PulseEnable_reg <= 1'b0;
								ShiftRx_reg <= 1'b0;
								ShiftTx_reg <= 1'b0;
								Load_reg <= 1'b0;
								sck_reg <= CPol;
								EndTx_reg <= 1'b1;
								contador <=0;
								end
		endcase
	end
end

endmodule