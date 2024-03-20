`timescale 1ns / 1ps

module mario(
	input wire clk, reset,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
	input wire coin_display,
	output wire hsync, vsync,
	output wire [11:0] rgb,
	output [6:0] seg,
    output [3:0] an
    );
	 
	wire [9:0] pixel_x, pixel_y;
	wire video_on, pixel_tick;
	reg [11:0] rgb_reg;
	wire [11:0] rgb_next;

	// keyboard variable
	// 0:w, 1:a, 2:s, 3:d
	reg [2:0] direction;
	reg up, backward, forward, down, stop;

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;

	wire beginning;
	wire [2:0] mario_movement;
	wire [7:0] shift_map;
	wire [4:0] mario_x, mario_y;
	wire [1:0] game_state;
	wire [15:0] game_time;
	wire vga_clk;
	wire umovable, dmovable;

	// 1 -> facing right, 0 -> facing left
	reg mario_dir = 1, mario_next_dir;
	wire mario_dir_in = mario_dir;

    parameter [8:0] KEY_CODES_w = 9'b0_0001_1101; // w => 1d
    parameter [8:0] KEY_CODES_a = 9'b0_0001_1100; // a => 1c
    parameter [8:0] KEY_CODES_s = 9'b0_0001_1011; // s => 1b
    parameter [8:0] KEY_CODES_d = 9'b0_0010_0011; // d => 23

    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(reset),
        .clk(clk)
    ); 

	vga_sync vga_unit(
		.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
		.video_on(video_on), .p_tick(pixel_tick),
		.pixel_x(pixel_x), .pixel_y(pixel_y)
	);
	
	mario_movement mario_move(
		.clk(clk),
		.reset(reset),
		.umovable(umovable),
		.dmovable(dmovable),
		.up(up),
		.backward(backward),
		.forward(forward),
		.down(down),
		.stop(stop),
		.shift_map(shift_map),
		.vga_clk(vga_clk),
		.beginning(beginning),
		.mario_movement(mario_movement),
		.mario_x(mario_x), .mario_y(mario_y),
		.game_state(game_state)
	);

	bitmap_gen bitmap_unit(
		.clk(clk), .reset(reset),
		.up(up), .backward(backward), .forward(forward), .down(down), .stop(stop),
		.beginning(beginning),
		.mario_x(mario_x),
		.mario_y(mario_y),
		.mario_movement(mario_movement),
		.video_on(video_on), .pix_x(pixel_x),
		.pix_y(pixel_y), .bit_rgb(rgb_next),
		.coin_display(coin_display),
		.shift_map(shift_map),
		.vga_clk(vga_clk),
		.umovable(umovable), 
		.dmovable(dmovable),
		.game_state(game_state),
		.game_time(game_time),
		.mario_dir_in(mario_dir_in)
	);

	// mashroom_movement mashroom1(
	// 	.clk(clk), .reset(reset),
	// 	.game_state(game_state),
	// 	.mashroom_direction(mashroom_direction), // 0: backward, 1: forward 
	// 	.mashroom_x(mashroom_x), .mashroom_y(mashroom_y),
	// 	.mashroom_x_led(mashroom_x_led)
	// );

	// mashroom_movement2 mashroom2(
	// 	.clk(clk), .reset(reset),
	// 	.game_state(game_state),
	// 	.mashroom_x(mashroom_x), .mashroom_y(mashroom_y),
	// 	.mashroom_x_led(mashroom_x_led)
	// );

	display_7seg display(.clk(clk), .reset(reset), 
						 .game_state(game_state), .game_time(game_time), 
						 .seg(seg), .an(an));

    always @ (*) begin
        case (last_change)
            KEY_CODES_w : direction = 3'b000;
            KEY_CODES_a : direction = 3'b001;
            KEY_CODES_s : direction = 3'b010;
            KEY_CODES_d : direction = 3'b011;
            default     : direction = 3'b100;
        endcase
    end

	always @ (*) begin
		up = 0;
		backward = 0;
		forward = 0;
		down = 0;
		stop = 0;
		if (been_ready && key_down[last_change] == 1'b1) begin
			case (direction)
				3'd0: up = 1;
				3'd1: backward = 1;
				3'd2: down = 1;
				3'd3: forward = 1;
				3'd4: stop = 1;
			endcase
		end
	end

	always @(posedge clk) begin
		if (pixel_tick)
			rgb_reg <=  rgb_next;
	end

	always @* begin
		if (last_change == KEY_CODES_d)	begin
			mario_next_dir = 1;
		end
		else if (last_change == KEY_CODES_a) begin
			mario_next_dir = 0;
		end
		else mario_next_dir = mario_dir;
	end

	always @(posedge clk) begin
		if (reset) begin
			mario_dir <= 1;
		end
		else mario_dir <= mario_next_dir;
	end

	assign rgb = rgb_reg;

	always @* begin
		if (last_change == KEY_CODES_d)	begin
			mario_next_dir = 1;
		end
		else if (last_change == KEY_CODES_a) begin
			mario_next_dir = 0;
		end
		else mario_next_dir = mario_dir;
	end

	always @(posedge clk) begin
		if (reset) begin
			mario_dir <= 1;
		end
		else mario_dir <= mario_next_dir;
	end

endmodule