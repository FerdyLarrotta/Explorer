//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Create Date:    13:34:31 10/22/2019
// Design Name: 	 Ferney alberto Beltran Molina
// Module Name:    buffer_ram_dp
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module buffer_ram_dp#(
	parameter AW = 13, 				// Cantidad de bits  de la direccion
	parameter DW = 15, 				// Cantidad de bits de los datos
	parameter   imageFILE= "image.mem") // Archivo para inicializar la RAM
	(
	input  clk_w,						// Reloj de escritura
	input  [AW-1: 0] addr_in, 		// Direccion de entrada
	input  [DW-1: 0] data_in,		// Dato de entrada
	input  regwrite,

	input  clk_r,						// Reloj de lectura
	input [AW-1: 0] addr_out,  	// Direccion de salida
	output reg [DW-1: 0] data_out // Dato de salida
	);

// Calcular el numero de posiciones totales de memoria
localparam NPOS = 2 ** AW; 				// Tamanno de la memoria
reg [DW-1: 0] ram [0: NPOS-1]; 			// Memoria (bits datos x bits direccion)

// Escritura  de la memoria port 1
always @(posedge clk_w) begin 			// Flancos de subida reloj de escritura
       if (regwrite == 1)
             ram[addr_in] <= data_in;	// Escribir en memoria
end

//	Lectura  de la memoria port 2
always @(posedge clk_r) begin 			// Flancos de subida reloj de lectura
	data_out <= ram[addr_out]; 		// Leer de la memoria
end

initial begin
	$readmemb(imageFILE, ram); 			// Inicializando la memoria con image.men
end

endmodule
