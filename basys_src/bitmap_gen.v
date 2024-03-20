`timescale 1ns / 1ps
module bitmap_gen(
	input wire clk, reset,
	input wire video_on,
	input wire up, input wire backward, input wire forward, input wire down, input wire stop,
	input wire beginning,
	input wire [4:0] mario_x, mario_y,
	input wire [2:0] mario_movement,
	input wire [9:0] pix_x, pix_y,
	input wire coin_display,
	input wire mario_dir_in,
	output reg [11:0] bit_rgb,
	output reg [7:0] shift_map,
	output reg vga_clk,
	output reg umovable, 
	output reg dmovable,
	output reg [1:0] game_state,
	output reg [15:0] game_time 
);  
	//rgb thing
	parameter TRANSPARENT_COLOR = 12'b111101001111;
    parameter SKY_COLOR = 12'b001010011000; 

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

	// map scrolling using buttons
	wire [7:0] shift_map_next;

	// mario neighbor block
	wire [10:0] mario_front_addr = shift_map * 15 + 15 * mario_x + mario_y - 1;
	wire [10:0] mario_back_addr = shift_map * 15 + 15 * (mario_x - 2) + mario_y - 1;
	wire [4:0] mario_front_sprite;
	wire [4:0] mario_back_sprite;

	wire [10:0] mario_up_addr = shift_map * 15 + 15*(mario_x - 1) + mario_y - 2;
	wire [10:0] mario_down_addr = shift_map * 15 + 15*(mario_x - 1) + mario_y;
	wire [4:0] mario_up_sprite;
	wire [4:0] mario_down_sprite;

	// to determine whether mario can move right or left
	reg rmovable;
	reg lmovable;

	// memory address management
	wire [14-1:0] addr_next;
	wire [10:0] addr_map_next;
	reg sum1, sum2;
	
	reg [13:0] addr_map_next_reg;
	
	// game state
	reg [1:0] next_game_state;

	// actually value of sprite1 (pixel), sprite2 (pixel), map (block)
	wire [11:0] sprite1_out, sprite2_out;
	wire [4:0] sprite_block;

	parameter [8:0] KEY_CODES_a = 9'b0_0001_1100; // a => 1c
    parameter [8:0] KEY_CODES_d = 9'b0_0010_0011; // d => 23

	// create vga counter
	reg [30:0] vga_counter, next_vga_counter;
	always @* begin
		vga_clk = (vga_counter == 15*800*525)? 1 : 0;
	end

	// restart
	// fall, touch HCl, touch green light

	wire restart = (mario_y == 15)|| (mario_down_sprite == 13)||
					(mario_down_sprite == 1)|| (mario_up_sprite == 1)|| (mario_front_sprite == 1)|| (mario_back_sprite == 1);

	// after 3 vga_clk, restart the game
	reg [5:0] restart_counter, next_restart_counter;

	// time shit
	reg [15:0] next_game_time;
	reg [29:0] ms_counter, next_ms_counter;

	always @(posedge clk) begin
		if (reset || game_state == GAME_START) begin
			vga_counter <= 1;
		end
		else begin
			vga_counter <= next_vga_counter;
		end
	end

	always @(*) begin
		if (mario_movement == UP || mario_movement == DOWN || game_state == GAME_END) begin
			if (vga_counter == 15*800*525)
				next_vga_counter = 1;
			else 
				next_vga_counter = vga_counter+1;
		end
		else begin
			next_vga_counter = 1;
		end
	end

	// assembly in memory of maps and sprite
	map map1(.clk(clk), .en(1'b1), .addr(addr_map_next), .dataout(sprite_block));
	
	sprite1 sprite1(.clk(clk), .en(1'b1), .addr(addr_next), .dataout(sprite1_out));
	sprite2 sprite2(.clk(clk), .en(1'b1), .addr(addr_next), .dataout(sprite2_out));
	
	// game state squential
	always @(posedge clk) begin
		if (reset) begin
			game_state <= GAME_START;
			restart_counter <= 1;
		end
		else begin
			game_state <= next_game_state;
			restart_counter <= next_restart_counter;
		end
	end

	// game state transfer
	always @(*) begin
		case (game_state)
			GAME_START: begin 
				next_game_state = (up|| down|| forward|| backward)? GAME_ING : GAME_START;
			end
			GAME_ING: begin
				if (restart)
					next_game_state = GAME_END;
				else 
					next_game_state = GAME_ING;
			end
			GAME_END: begin
				if (restart_counter == 6) // or collision
					next_game_state = GAME_START;
				else 
					next_game_state = GAME_END;			
			end
			default: next_game_state = game_state;
		endcase
	end

	// game state thing
	always @(*) begin
		case (game_state)
			GAME_START: begin 
				next_restart_counter = 1;
			end
			GAME_ING: begin
				next_restart_counter = 1;
			end
			GAME_END: begin
				next_restart_counter = restart_counter + vga_clk;
			end
			default: next_restart_counter = restart_counter;
		endcase
	end


	// calculation of memory positions
	always @(*) begin
		if (pix_x >= 32 * (mario_x - 1) && pix_x < 32 * mario_x - 1 && pix_y >= 32 * (mario_y - 1)  && pix_y <= 32 * mario_y - 1) begin
			if (mario_dir_in == 0) begin
				addr_map_next_reg = 1497;
			end
			else begin
				addr_map_next_reg = 1499;
			end
		end
		else
			addr_map_next_reg = shift_map*15+((pix_x >>5)*15)+(pix_y>>5);
	end

	// assign addr_map_next = shift_map*15+((pix_x >>5)*15)+(pix_y>>5);
	assign addr_map_next = addr_map_next_reg;
	assign addr_next = (pix_x % 32)+((pix_y%32)<<5)+(sprite_block-1)*32*32;
	
	// use module map to check what is in front of and back of mario
	map mario_check_front(.clk(clk), .en(1'b1), .addr(mario_front_addr), .dataout(mario_front_sprite));
	map mario_check_back(.clk(clk), .en(1'b1), .addr(mario_back_addr), .dataout(mario_back_sprite));
	map mario_check_up(.clk(clk), .en(1'b1), .addr(mario_up_addr), .dataout(mario_up_sprite));
	map mario_check_down(.clk(clk), .en(1'b1), .addr(mario_down_addr), .dataout(mario_down_sprite));

	always @* begin
		if (beginning) begin
			rmovable = 0;
		end
		else if (
			game_state == GAME_END ||
			mario_front_sprite == 1 ||
			mario_front_sprite == 3 ||
			mario_front_sprite == 5 ||
			mario_front_sprite == 6 ||
			mario_front_sprite == 11 ||
			mario_front_sprite == 14 ||
			mario_front_sprite == 20 ||
			mario_front_sprite == 21 ||
			mario_front_sprite == 22 ||
			mario_front_sprite == 23 ||
			mario_front_sprite == 26 ||
			mario_front_sprite == 27 ||
			mario_front_sprite == 28 ||
			mario_front_sprite == 15 ||
			mario_front_sprite == 29 
		) begin
			rmovable = 0;
		end
		else rmovable = 1;
	end

	always @* begin
		if (beginning) begin
			lmovable = 0;
		end
		else if (
			game_state == GAME_END||
			mario_back_sprite == 1 ||
			mario_back_sprite == 3 ||
			mario_back_sprite == 5 ||
			mario_back_sprite == 6 ||
			mario_back_sprite == 11 ||
			mario_back_sprite == 14 ||
			mario_back_sprite == 20 ||
			mario_back_sprite == 21 ||
			mario_back_sprite == 22 ||
			mario_back_sprite == 23 ||
			mario_back_sprite == 26 ||
			mario_back_sprite == 27 ||
			mario_back_sprite == 28 ||
			mario_back_sprite == 15 ||
			mario_back_sprite == 29 
		) begin
			lmovable = 0;
		end
		else lmovable = 1;
	end

	always @* begin
		if (
			mario_up_sprite == 1 ||
			mario_up_sprite == 3 ||
			mario_up_sprite == 5 ||
			mario_up_sprite == 6 ||
			mario_up_sprite == 11 ||
			mario_up_sprite == 14 ||
			mario_up_sprite == 20 ||
			mario_up_sprite == 21 ||
			mario_up_sprite == 22 ||
			mario_up_sprite == 23 ||
			mario_up_sprite == 26 ||
			mario_up_sprite == 27 ||
			mario_up_sprite == 28 ||
			mario_up_sprite == 15 ||
			mario_up_sprite == 29 
		) begin
			umovable = 0;
		end
		else umovable = 1;
	end

	always @* begin
		if (
			mario_down_sprite == 1 ||
			mario_down_sprite == 3 ||
			mario_down_sprite == 5 ||
			mario_down_sprite == 6 ||
			mario_down_sprite == 11 ||
			mario_down_sprite == 14 ||
			mario_down_sprite == 20 ||
			mario_down_sprite == 21 ||
			mario_down_sprite == 22 ||
			mario_down_sprite == 23 ||
			mario_down_sprite == 26 ||
			mario_down_sprite == 27 ||
			mario_down_sprite == 28 ||
			mario_down_sprite == 15 ||
			mario_down_sprite == 29 
		) begin
			dmovable = 0;
		end
		else dmovable = 1;
	end

	always @* begin
		if (rmovable) begin
			sum1 = shift_map < 80? forward:0;
		end
		else sum1 = 0;
	end

	always @* begin
		if (lmovable) begin
			sum2 = shift_map > 0? backward:0;
		end
		else sum2 = 0;
	end	
	
	assign shift_map_next = shift_map + sum1 - sum2; 
	
	
	always @(posedge clk)
		if (reset || game_state == GAME_START) begin
			shift_map <= 0;
		end
		else begin
			shift_map <= shift_map_next;
		end

	// pixel return
	wire is_sprite2, is_sky;
   
	assign is_sprite2 = (sprite_block > 16);
	assign is_sky = (sprite_block == 5'b00000) ||
					(!coin_display && sprite_block == 5'b01100) ||
					(is_sprite2 && (sprite2_out == TRANSPARENT_COLOR)) ||
					((!is_sprite2) && sprite1_out == TRANSPARENT_COLOR);
	
	always @(*) begin
		bit_rgb = 12'b000000000000;
		if (video_on)begin
			if (is_sky)
				bit_rgb = SKY_COLOR;
			else 
				bit_rgb = (is_sprite2) ? sprite2_out : sprite1_out;
		end
	end	

	// ms counter seq
	always @(*) begin
        if (ms_counter == 30'd1000000) next_ms_counter = 30'd0;
        else begin
            if (game_state == GAME_ING) next_ms_counter = ms_counter + 1;
            else next_ms_counter = 30'd0;    
        end
    end

	// game time seq
	always @(posedge clk) begin
		if (reset || (game_state == GAME_START && (up|| down|| forward|| backward))) begin
			game_time <= 0;
			ms_counter <= 0;
		end
		else begin
			game_time <= next_game_time;
			ms_counter <= next_ms_counter;
		end
	end

	// game time combinational

	always @(*) begin
		case (game_state)
			GAME_START :
				next_game_time = game_time;
			GAME_ING :
				next_game_time = (ms_counter == 30'd1000000) ? game_time + 1 : game_time;
			GAME_END : 
				next_game_time = game_time; 
		endcase
	end

endmodule