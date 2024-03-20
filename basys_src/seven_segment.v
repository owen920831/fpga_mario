module toBCD(out, out_BCD);
    input [3:0] out;
    output [6:0] out_BCD;
    reg [6:0] out_BCD;
    always @(*) begin
        case (out)
            4'd0: out_BCD = 7'b0000001;   
            4'd1: out_BCD = 7'b1001111; 
            4'd2: out_BCD = 7'b0010010;  
            4'd3: out_BCD = 7'b0000110; 
            4'd4: out_BCD = 7'b1001100; 
            4'd5: out_BCD = 7'b0100100;  
            4'd6: out_BCD = 7'b0100000; 
            4'd7: out_BCD = 7'b0001111; 
            4'd8: out_BCD = 7'b0000000;  
            4'd9: out_BCD = 7'b0000100;
            4'd10: out_BCD = 7'b1111111; //empty
            default: out_BCD = 7'b1111110; // x
        endcase
    end
endmodule

module Clock_Divider (clk, reset, display_clk);
    input clk, reset;
    output reg display_clk;

    reg [16:0] d_counter;
    
    always @(posedge clk) begin
        d_counter <= (reset)? 1'b0 : d_counter + 1'b1;
    end

    always @(posedge clk) begin
        display_clk <= (reset)? 1'b0 : (d_counter == 17'b0);
    end
endmodule

module display_7seg (clk, reset, game_state, game_time, seg, an);
    input clk, reset;
    input [1:0] game_state;
    input [15:0] game_time; //
    output [6:0] seg;
    output [3:0] an;

    
    wire [6:0] next_seg;
    reg [6:0] seg;
    reg [3:0] an, next_an;
    reg [1:0] an_index;
    reg [3:0] displayed_item;
    
    reg [3:0] digit_00_01, digit_00_10, digit_01_00, digit_10_00;

    wire display_clk;

    Clock_Divider  c(clk, reset, display_clk);

    toBCD t(displayed_item, next_seg);

    wire [1:0] next_an_index = (display_clk == 1) ? an_index + 1 : an_index;

    always @(*) begin
        digit_00_01 = game_time % 16'd10;
        digit_00_10 = (game_time/16'd10) % 16'd10;
        digit_01_00 = (game_time/16'd100) % 16'd10;
        digit_10_00 = game_time/16'd1000;
    end

    always @(posedge clk) begin
        if (reset) begin
            seg <= 7'b1111111;
            an_index <= 2'b0;
            an <= 4'b1111;
        end
        else begin
            seg <= next_seg;
            an_index <= next_an_index;
            an <= next_an;
        end
    end

    always @(*) begin
        case (an_index)
            2'b11 : displayed_item = digit_10_00;
            2'b10 : displayed_item = digit_01_00;
            2'b01 : displayed_item = digit_00_10; 
            2'b00 : displayed_item = digit_00_01; 
        endcase
    end
    
    always @(*) begin
        case (an_index)
            2'b00 : next_an = 4'b1110; 
            2'b01 : next_an = 4'b1101; 
            2'b10 : next_an = 4'b1011; 
            2'b11 : next_an = 4'b0111; 
            default : next_an = 4'b1111;
        endcase 
    end
endmodule