module ov7670_driver_and_image_processing (
  input clk,rst,pclk,v_sync,h_ref,
  input [7:0] cam_data,
  output reg xclk = 1'b0,
  output Tx_data_image,Tx_data_mine);


  parameter IDLE = 0, SEND_IMAGE = 1, WAIT_SND_IM = 2, DETECT_COLOR = 3,
            WAIT_DET_COL = 4, SEND_MINE_INFO = 5;


  wire pclk_rising_edge, begin_frame, regwrite, image_memory_block,
       im_send_done, col_det_done, Tx_active, Tx_done_mine;
  wire [12:0] addr_in, addr_out_im_snd, addr_out_col_det;
  wire [7:0] color_decision_aux;
  wire [14:0] data_in,data_out;

  reg divider_31_25M = 1'b0;
  reg send_image, detect_color, send_mine;
  reg [2:0] state;
  reg [12:0] addr_out;
  reg [7:0] color_decision;
 

  rising_edge_detector pclk_re(
      .clk(clk),
      .rst(rst),
      .signal_in(pclk),
      .signal_out(pclk_rising_edge));
  pixel_reader pxReader(
      .clk(clk),
      .rst(rst),
      .v_sync(v_sync),
      .h_ref(h_ref),
      .pclk(pclk_rising_edge),
      .cam_data(cam_data),
      .pixel_data(data_in),
      .addr_in(addr_in),
      .regwrite(regwrite),
      .begin_frame(begin_frame),
      .image_memory_block(image_memory_block));
buffer_ram_dp image_ram(
      .clk_w(clk),
      .addr_in(addr_in),
      .data_in(data_in),
      .regwrite(regwrite),
      .clk_r(clk),
      .addr_out(addr_out),
      .data_out(data_out));



image_sender im_snd (
      .clk(clk),
      .rst(rst),
      .send_image(send_image),
      .pixel_data(data_out),
      .addr_out(addr_out_im_snd),
      .Tx_data(Tx_data_image),
      .done(im_send_done));
color_detector col_det(
      .clk(clk),
      .rst(rst),
      .detect_color(detect_color),
      .pixel_data(data_out),
      .addr_out(addr_out_col_det),
      .color_decision(color_decision_aux),
      .done(col_det_done));
uart_tx #(.CLKS_PER_BIT(1085),.N(11)) image_sender (
      .i_Clock(clk),
      .i_Tx_DV(send_mine),
      .rst(rst),
      .i_Tx_Byte(color_decision),
      .o_Tx_Active(Tx_active),
      .o_Tx_Serial(Tx_data_mine),
      .o_Tx_Done(Tx_done_mine));


always @ ( posedge(clk) ) begin

  if (rst)
  begin
    state <= IDLE;
    send_image <= 1'b0;
    detect_color <= 1'b0;
    addr_out <= 13'd0;
    color_decision <= 8'd0;
    send_mine <= 1'b0;
  end
  else
  begin
    case (state)
      IDLE:
      begin
        if (begin_frame) state <= SEND_IMAGE;
        else state <= IDLE;
        send_image <= 1'b0;
        detect_color <= 1'b0;
        addr_out <= 13'd0;
        send_mine <= 1'b0;
        color_decision <= color_decision;
      end
      SEND_IMAGE:
      begin
        state <= WAIT_SND_IM;
        send_image <= 1'b1;
        detect_color <= 1'b0;
        addr_out <= addr_out_im_snd + (13'd3072 & {13{!image_memory_block}});
        send_mine <= 1'b0;
        color_decision <= color_decision;
      end
      WAIT_SND_IM:
      begin
        send_image <= 1'b0;
        detect_color <= 1'b0;
        addr_out <= addr_out_im_snd + (13'd3072 & {13{!image_memory_block}});
        send_mine <= 1'b0;
        color_decision <= color_decision;
        if (im_send_done) state <= DETECT_COLOR;
        else state <= WAIT_SND_IM;
      end
      DETECT_COLOR:
      begin
        state <= WAIT_DET_COL;
        send_image <= 1'b0;
        detect_color <= 1'b1;
        send_mine <= 1'b0;
        color_decision <= color_decision;
        addr_out <= addr_out_col_det + (13'd3072 & {13{!image_memory_block}});
      end
      WAIT_DET_COL:
      begin
        send_image <= 1'b0;
        detect_color <= 1'b0;
        send_mine <= 1'b0;
        addr_out <= addr_out_col_det + (13'd3072 & {13{!image_memory_block}});
        if (col_det_done)
        begin
          state <= SEND_MINE_INFO;
          color_decision <= color_decision_aux;
        end
        else
        begin
          state <= WAIT_DET_COL;
          color_decision <= color_decision;
        end
      end
      SEND_MINE_INFO:
      begin
        state <= IDLE;
        send_image <= 1'b0;
        detect_color <= 1'b0;
        addr_out <= 13'd0;
        send_mine <= 1'b1;
        color_decision <= color_decision;
      end
      default:
      begin
        state <= IDLE;
        send_image <= 1'b0;
        send_mine <= 1'b0;
        detect_color <= 1'b0;
        color_decision <= color_decision;
        addr_out <= 13'd0;
      end
    endcase
  end
end






  always @ ( posedge(clk) )
  begin
    if (divider_31_25M == 1'b1)
    begin
      xclk = !xclk;
      divider_31_25M = 1'b0;
    end
    else
    begin
      divider_31_25M = divider_31_25M + 1'b1;
    end
  end

endmodule
