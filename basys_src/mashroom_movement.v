`timescale 1ns / 1ps
module mario_movement(
    input wire clk, reset,
    input wire umovable, dmovable,
    input wire up, input wire backward, input wire forward, input wire down, input wire stop,
    input wire [7:0] shift_map,
    input wire vga_clk,
    input wire [1:0] game_state,
    output reg beginning,
    output reg [2:0] mario_movement,
    output reg [4:0] mario_x, mario_y
);

    // mario's state
    parameter UP = 3'd0;
	parameter BACKWARD = 3'd1;
	parameter FORWARD = 3'd2;
	parameter DOWN = 3'd3;
	parameter UP_FORWARD = 3'd4;
	parameter UP_BACKWARD = 3'd5;
	parameter STOP = 3'd6;
	parameter OTHER = 3'd7;

	// game end, gaming
	parameter GAME_END = 2'd0;
	parameter GAME_ING = 2'd1;
	parameter GAME_START = 2'd2;

    // mario's position
	reg [4:0] mario_next_x;
	reg [4:0] mario_next_y;

    // up counter (at most 6)
	// down counter (at most 6)
	reg [2:0] up_counter, next_up_counter;

	// state
	reg [2:0] next_mario_movement;

    // mario_movement squential
	always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			mario_movement <= OTHER;
		end
		else begin
			mario_movement <= next_mario_movement;
		end
	end

    // mario_movement transfer
	always @(*) begin
		case (mario_movement)
			UP: begin
				if (game_state == GAME_END) begin
					if (up_counter == 3) // or collision
						next_mario_movement = DOWN;
					else 
						next_mario_movement = UP;
				end
				else begin
					if (up_counter == 6 || !umovable) // or collision
						next_mario_movement = DOWN;
					else 
						next_mario_movement = UP;
				end
			end
			DOWN: begin
				if (!dmovable || mario_y == 15) // or collision
					next_mario_movement = OTHER;
				else 
					next_mario_movement = DOWN;			
			end
			OTHER: begin
				if (game_state == GAME_END) 
					next_mario_movement = UP;
				else if (up) 
					next_mario_movement = UP;
				else if (dmovable)
					next_mario_movement = DOWN;
				else 
					next_mario_movement = OTHER;
			end
			default: next_mario_movement = OTHER;
		endcase
	end

    // check can the map or mario move
	always @* begin
		if (beginning) begin
			if (forward) begin
				mario_next_x = mario_x + 1;
			end
			else if (backward && mario_x > 1) begin
				mario_next_x = mario_x - 1;
			end
			else mario_next_x = mario_x;
		end
		else if (shift_map <= 0 && backward && mario_x >= 1) begin
			mario_next_x = mario_x - 1;
		end
		else mario_next_x = mario_x;
	end

    always @* begin
		if (mario_x <= 10) begin
			beginning = 1;
		end
		else begin
			beginning = 0;
		end
	end

    always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			mario_x <= 1;
			mario_y <= 12;
		end
		else begin
			mario_x <= mario_next_x;
			mario_y <= mario_next_y;
		end
	end

    // jump part 
	// up, down counter
	always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			up_counter <= 1;
		end
		else begin
			up_counter <= next_up_counter;
		end
	end

	always @(*) begin
		case (mario_movement)
			UP: begin
				if (up_counter == 6 || !umovable) //or collision
					next_up_counter = 1;
				else 
					next_up_counter = (vga_clk == 1)? up_counter + 1 : up_counter;
			end
			DOWN: begin
				next_up_counter = up_counter;
			end
			OTHER: begin
				next_up_counter = 1;
			end
			default: begin
				next_up_counter = up_counter;
			end
		endcase
	end	

	always @* begin
		case (mario_movement)
			UP: begin
				mario_next_y = mario_y - vga_clk;
			end
			DOWN: begin
				mario_next_y = mario_y + vga_clk;
			end
			OTHER: begin
				mario_next_y = mario_y;
			end
			default: begin
				mario_next_y = mario_y;
			end
		endcase
	end

endmodule