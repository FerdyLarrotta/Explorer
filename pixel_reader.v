
module pixel_reader (
  input clk,rst,v_sync,h_ref,pclk,
  input [7:0] cam_data,
  output reg [14:0] pixel_data,
  output [12:0] addr_in,
  output reg regwrite, begin_frame, image_memory_block);


  parameter WAIT_VSYNC = 0, BEGIN_FRAME = 1, READ_FIRST_BYTE = 2, NO_OP = 3,
            READ_SECOND_BYTE = 4, SAVE = 5, UPDATE_ADDR = 6;

  reg [2:0] state;
  reg [12:0] addr_cnt;

  assign addr_in = addr_cnt + (13'd3072 & {13{image_memory_block}});

  always @ ( posedge(clk) ) begin
    if (rst)
    begin
      state = WAIT_VSYNC;
      pixel_data = 15'd0;
      regwrite = 1'b0;
      begin_frame = 1'b0;
      addr_cnt = 13'd0;
      image_memory_block = 1'b0;
    end
    else
    begin
      case (state)
        WAIT_VSYNC:
        begin
          pixel_data = 15'd0;
          regwrite = 1'b0;
          begin_frame = 1'b0;
          addr_cnt = 13'd0;
          image_memory_block = 1'b0;
          if (v_sync) state = BEGIN_FRAME;
          else state = WAIT_VSYNC;
        end
        BEGIN_FRAME:
        begin
          pixel_data = 15'd0;
          regwrite = 1'b0;
          begin_frame = 1'b1;
          addr_cnt = 13'd0;
          image_memory_block = image_memory_block;
          if (!v_sync) state = READ_FIRST_BYTE;
          else state = BEGIN_FRAME;
        end
        READ_FIRST_BYTE:
        begin
          regwrite = 1'b0;
          addr_cnt = addr_cnt;
          if (h_ref & pclk)
          begin
            state = NO_OP;
            begin_frame = 1'b0;
            pixel_data[14:10] = cam_data [6:2];//R
            pixel_data[9:8] = cam_data [1:0];//G
            pixel_data[7:0] = pixel_data[7:0];
            image_memory_block = image_memory_block;
          end
          else if (v_sync)
          begin
            state = BEGIN_FRAME;
            pixel_data = 15'd0;
            begin_frame = 1'b1;
            image_memory_block = !image_memory_block;
        end
          else
          begin
            begin_frame = 1'b0;
            state = READ_FIRST_BYTE;
            pixel_data = pixel_data;
            image_memory_block = image_memory_block;
        end
        end
        NO_OP:
        begin
          state = READ_SECOND_BYTE;
          pixel_data = pixel_data;
          regwrite = 1'b0;
          begin_frame = 1'b0;
          addr_cnt = addr_cnt;
          image_memory_block = image_memory_block;
        end
        READ_SECOND_BYTE:
        begin
          begin_frame = 1'b0;
          regwrite = 1'b0;
          addr_cnt = addr_cnt;
          image_memory_block = image_memory_block;
          if (h_ref & pclk)
          begin
            state = SAVE;
            pixel_data[14:8] = pixel_data[14:8];
            pixel_data[7:5] = cam_data [7:5];//G
            pixel_data[4:0] = cam_data[4:0];//B
          end
          else
          begin
            state = READ_SECOND_BYTE;
            pixel_data = pixel_data;
          end
        end
        SAVE:
        begin
          state = UPDATE_ADDR;
          pixel_data = pixel_data;
          regwrite = 1'b1;
          begin_frame = 1'b0;
          addr_cnt = addr_cnt;
          image_memory_block = image_memory_block;
        end
        UPDATE_ADDR:
        begin
          state = READ_FIRST_BYTE;
          pixel_data = pixel_data;
          regwrite = 1'b0;
          begin_frame = 1'b0;
          image_memory_block = image_memory_block;
          addr_cnt = addr_cnt + 1'b1;
        end
        default:
        begin
          state = WAIT_VSYNC;
          pixel_data = 15'd0;
          regwrite = 1'b0;
          begin_frame = 1'b0;
        end
      endcase
    end
  end

endmodule
