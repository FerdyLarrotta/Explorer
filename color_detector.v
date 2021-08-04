module color_detector (
  input clk,rst,detect_color,
  input [14:0] pixel_data,
  output [12:0] addr_out,
  output reg [7:0] color_decision,
  output reg done);

  parameter IDLE = 0, BEG_PX_SORT = 1, WAIT_SORTER = 2,
            DECIDE = 5, END = 6;


  wire sort_done;
  wire [11:0] red_pixel_cnt, green_pixel_cnt, blue_pixel_cnt;

  reg sort_pixels;
  reg [11:0] red_pixel_cnt_in, green_pixel_cnt_in, blue_pixel_cnt_in;
  reg [2:0] state;


  RGB_pixel_sorter px_sorter(
        .clk(clk),
        .rst(rst),
        .sort_pixels(sort_pixels),
        .pixel_data(pixel_data),
        .addr_out(addr_out),
        .red_pixel_cnt(red_pixel_cnt),
        .green_pixel_cnt(green_pixel_cnt),
        .blue_pixel_cnt(blue_pixel_cnt),
        .done(sort_done));



  always @ ( posedge(clk) ) begin

    if (rst)
    begin
      state <= IDLE;
      sort_pixels <= 1'b0;
      red_pixel_cnt_in <= 12'd0;
      green_pixel_cnt_in <= 12'd0;
      blue_pixel_cnt_in <= 12'd0;
      color_decision <= 8'd0;
      done <= 1'b0;
    end
    else
    begin
      case (state)
        IDLE:
        begin
          if (detect_color) state <= BEG_PX_SORT;
          else state <= IDLE;
          sort_pixels <= 1'b0;
          red_pixel_cnt_in <= 12'd0;
          green_pixel_cnt_in <= 12'd0;
          blue_pixel_cnt_in <= 12'd0;
          color_decision <= 8'd0;
          done <= 1'b0;
        end
        BEG_PX_SORT:
        begin
          state <= WAIT_SORTER;
          sort_pixels <= 1'b1;
          red_pixel_cnt_in <= 12'd0;
          green_pixel_cnt_in <= 12'd0;
          blue_pixel_cnt_in <= 12'd0;
          color_decision <= 8'd0;
          done <= 1'b0;
        end
        WAIT_SORTER:
        begin
          sort_pixels <= 1'b0;
          color_decision <= 8'd0;
          done <= 1'b0;
          if (sort_done)
          begin
            red_pixel_cnt_in <= red_pixel_cnt;
            green_pixel_cnt_in <= green_pixel_cnt;
            blue_pixel_cnt_in <= blue_pixel_cnt;
            state <= DECIDE;
          end
          else
          begin
            red_pixel_cnt_in <= 12'd0;
            green_pixel_cnt_in <= 12'd0;
            blue_pixel_cnt_in <= 12'd0;
            state <= WAIT_SORTER;
          end
        end
        DECIDE:
        begin
          sort_pixels <= 1'b0;
          red_pixel_cnt_in <= red_pixel_cnt_in;
          green_pixel_cnt_in <= green_pixel_cnt_in;
          blue_pixel_cnt_in <= blue_pixel_cnt_in;
          done <= 1'b0;
          if      (red_pixel_cnt_in > 12'd600)  color_decision <= 8'b01010010;
          else if (green_pixel_cnt_in > 12'd600)color_decision <= 8'b01000111;
          else if (blue_pixel_cnt_in > 12'd600) color_decision <= 8'b01000010;
          else                                  color_decision <= 8'b01001110;
          state <= END;
        end
        END:
        begin
          sort_pixels <= 1'b0;
          red_pixel_cnt_in <= red_pixel_cnt_in;
          green_pixel_cnt_in <= green_pixel_cnt_in;
          blue_pixel_cnt_in <= blue_pixel_cnt_in;
          done <= 1'b1;
          color_decision <= color_decision;
          state <= IDLE;
        end
        default:
        begin
          state <= IDLE;
          sort_pixels <= 1'b0;
          red_pixel_cnt_in <= 12'd0;
          green_pixel_cnt_in <= 12'd0;
          blue_pixel_cnt_in <= 12'd0;
          color_decision <= 8'd0;
          done <= 1'b0;
        end
      endcase
    end
  end






endmodule
