module RGB_pixel_sorter (
  input clk,rst,sort_pixels,
  input [14:0] pixel_data,
  output reg [12:0] addr_out,
  output reg [11:0] red_pixel_cnt,green_pixel_cnt,blue_pixel_cnt,
  output reg done);

  parameter IDLE = 0, EVALUATE_END = 1, READ_PIXEL_DATA = 2, DECIDE_PIXEL = 3,
            COUNT_PIXEL = 4;


  reg [2:0] state;
  reg [14:0] pixel_data_aux;


 wire red_pixel, green_pixel, blue_pixel;

assign red_pixel =  (pixel_data_aux[14:10]>(pixel_data_aux[9:5]+5'd3))
                   &(pixel_data_aux[4:0]>(pixel_data_aux[9:5]+5'd3))
                   &(pixel_data_aux[14:10]<5'd27)
                   &(pixel_data_aux[9:5]<5'd27)
                   &(pixel_data_aux[4:0]<5'd27);                   
assign green_pixel = (pixel_data_aux[9:5]>(pixel_data_aux[14:10]+5'd1))
                    &(pixel_data_aux[9:5]>(pixel_data_aux[4:0]+5'd1))
                    &(pixel_data_aux[14:10]<5'd24)
                    &(pixel_data_aux[9:5]<5'd24)
                    &(pixel_data_aux[4:0]<5'd24);
assign blue_pixel =  (pixel_data_aux[14:10]<5'd19)
                    &(pixel_data_aux[9:5]<5'd19)
                    &(pixel_data_aux[4:0]<5'd19)
                    &(pixel_data_aux[14:10]>5'd8)
                    &(pixel_data_aux[9:5]>5'd8)
                    &(pixel_data_aux[4:0]>5'd8)
                    &(pixel_data_aux[14:10]<(pixel_data_aux[9:5]+2'd2))
                    &(pixel_data_aux[9:5]<(pixel_data_aux[14:10]+2'd2))
                    &(pixel_data_aux[4:0]<(pixel_data_aux[9:5]+2'd2));



  always @ ( posedge clk ) begin

    if (rst)
    begin
      state <= IDLE;
      pixel_data_aux <= 15'd0;
      addr_out <= 13'd0;
      red_pixel_cnt <= 12'd0;
      green_pixel_cnt <= 12'd0;
      blue_pixel_cnt <= 12'd0;
      done <= 1'b0;
    end
    else
    begin
      case (state)
        IDLE:
        begin
          pixel_data_aux <= 15'd0;
          addr_out <= 13'd0;
          done <= 1'b0;
          red_pixel_cnt <= 12'd0;
          green_pixel_cnt <= 12'd0;
          blue_pixel_cnt <= 12'd0;
          if (sort_pixels) state <= EVALUATE_END;
          else state <= IDLE;
        end
        EVALUATE_END:
        begin
          addr_out <= addr_out;
          red_pixel_cnt <= red_pixel_cnt;
          green_pixel_cnt <= green_pixel_cnt;
          blue_pixel_cnt <= blue_pixel_cnt;
          pixel_data_aux <= 15'd0;
          if (addr_out == 13'd3072)
          begin
            done <= 1'b1;
            state <= IDLE;
          end
          else
          begin
            done <= 1'b0;
            state <= READ_PIXEL_DATA;
          end
        end
        READ_PIXEL_DATA:
        begin
          pixel_data_aux <= pixel_data;
          addr_out <= addr_out;
          red_pixel_cnt <= red_pixel_cnt;
          green_pixel_cnt <= green_pixel_cnt;
          blue_pixel_cnt <= blue_pixel_cnt;
          done <= 1'b0;
          state <= DECIDE_PIXEL;
        end
        DECIDE_PIXEL:
        begin
          pixel_data_aux <= pixel_data_aux;
          addr_out <= addr_out;
          red_pixel_cnt <= red_pixel_cnt;
          green_pixel_cnt <= green_pixel_cnt;
          blue_pixel_cnt <= blue_pixel_cnt;
          done <= 1'b0;
          state <= COUNT_PIXEL;
        end
        COUNT_PIXEL:
        begin
          pixel_data_aux <= pixel_data_aux;
          addr_out <= addr_out + 1'b1;
          if (red_pixel)
          begin
            red_pixel_cnt <= red_pixel_cnt +1'b1;
            green_pixel_cnt <= green_pixel_cnt;
            blue_pixel_cnt <= blue_pixel_cnt;
          end
          else if (green_pixel)
          begin
            red_pixel_cnt <= red_pixel_cnt;
            green_pixel_cnt <= green_pixel_cnt +1'b1;
            blue_pixel_cnt <= blue_pixel_cnt;
          end
          else if (blue_pixel)
          begin
            red_pixel_cnt <= red_pixel_cnt;
            green_pixel_cnt <= green_pixel_cnt;
            blue_pixel_cnt <= blue_pixel_cnt +1'b1;
          end
          else
          begin
            red_pixel_cnt <= red_pixel_cnt;
            green_pixel_cnt <= green_pixel_cnt;
            blue_pixel_cnt <= blue_pixel_cnt;
          end
          done <= 1'b0;
          state <= EVALUATE_END;
        end
        default:
        begin
          state <= IDLE;
          pixel_data_aux <= 15'd0;
          addr_out <= addr_out;
          red_pixel_cnt <= 12'd0;
          green_pixel_cnt <= 12'd0;
          blue_pixel_cnt <= 12'd0;
          done <= 1'b0;
        end
      endcase
    end
  end


endmodule
