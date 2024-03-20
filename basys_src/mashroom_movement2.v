`timescale 1ns / 1ps
module mashroom_movement2(
    input wire clk, reset,
    input wire [1:0] game_state,
    output reg [4:0] mashroom_x, mashroom_y, // which is display
    output reg [4:0] mashroom_x_led
);

    // mashroom's state
    parameter STOP = 1'd0;
	parameter MOVING = 1'd1;

	// game end, gaming
	parameter GAME_END = 2'd0;
	parameter GAME_ING = 2'd1;
	parameter GAME_START = 2'd2;

    // mashroom's position
	reg [4:0] mashroom_next_x;
	reg [4:0] mashroom_next_y;

	// state
	reg mashroom_movement, next_mashroom_movement;

	// create mashroom moving counter
	reg [37:0] mashroom_moving_counter, next_mashroom_moving_counter;
	wire mashroom_moving_clk = (mashroom_moving_counter == 90*800*525)? 1 : 0;

    reg mashroom_direction, next_mashroom_direction;

    always @(*) begin
        mashroom_x_led = mashroom_x;
    end

    // mashroom dir: 110011001100...
    // seq
    always @(posedge clk) begin
        if (reset || game_state == GAME_START)
            mashroom_direction <= 1;
        else 
            mashroom_direction <= next_mashroom_direction;
    end

    // comb
    always @(*) begin
        if (mashroom_x == 26)
            next_mashroom_direction = 0;
        else if (mashroom_x == 24)
            next_mashroom_direction = 1;
        else 
            next_mashroom_direction = mashroom_direction;
    end

    // mashroom moving counter seq
	always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			mashroom_moving_counter <= 1;
		end
		else begin
			mashroom_moving_counter <= next_mashroom_moving_counter;
		end
	end

    // mashroom moving counter comb

	always @(*) begin
		if (game_state == GAME_ING) begin
			if (mashroom_moving_counter == 90*800*525)
				next_mashroom_moving_counter = 1;
			else 
				next_mashroom_moving_counter = mashroom_moving_counter+1;
		end
		else begin
			next_mashroom_moving_counter = 1;
		end
	end

    // mashroom_movement squential
	always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			mashroom_movement <= STOP;
		end
		else begin
			mashroom_movement <= next_mashroom_movement;
		end
	end

    // mashroom_movement transfer
	always @(*) begin
		case (mashroom_movement)
			STOP: begin
				if (game_state == GAME_ING)
                    next_mashroom_movement = MOVING;
				else 
					next_mashroom_movement = STOP;
			end
			MOVING: begin
                if (game_state == GAME_END)
                    next_mashroom_movement = STOP;
                else 
                    next_mashroom_movement = MOVING;
            end
		endcase
	end

    // mashroom movement comb
    // 0: backward, 1: forward 
	always @* begin
        case (mashroom_movement)
        	STOP: begin
				mashroom_next_x = mashroom_x;
                mashroom_next_y = mashroom_y;
			end
			MOVING: begin
                if (mashroom_direction == 1)
                    mashroom_next_x = mashroom_x + mashroom_moving_clk;
                else 
                    mashroom_next_x = mashroom_x - mashroom_moving_clk;
            end
		endcase
	end

    
    always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			mashroom_x <= 24;
			mashroom_y <= 12;
		end
		else begin
			mashroom_x <= mashroom_next_x;
			mashroom_y <= mashroom_next_y;
		end
	end

endmodule