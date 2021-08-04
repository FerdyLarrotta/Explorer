module image_sender (
  input clk,rst,send_image,
  input [14:0] pixel_data,
  output reg [12:0] addr_out,
  output Tx_data,
  output reg done);


parameter IDLE = 0, EVALUATE_END = 1, READ_PIXEL_DATA = 2, SEND_FIRST_BYTE = 3,
          SEND_SECOND_BYTE = 4, WAIT_TX_DONE = 5, END_FRAME = 6;

wire Tx_active,Tx_done;

reg send_byte;
reg byte_select;
reg [2:0] state;
reg [7:0] Tx_byte;
reg [15:0] pixel_data_aux;



uart_tx #(.CLKS_PER_BIT(543),.N(10)) image_sender (
      .i_Clock(clk),
      .i_Tx_DV(send_byte),
      .rst(rst),
      .i_Tx_Byte(Tx_byte),
      .o_Tx_Active(Tx_active),
      .o_Tx_Serial(Tx_data),
      .o_Tx_Done(Tx_done));


always @ ( posedge clk ) begin

  if (rst)
  begin
    state <= IDLE;
    send_byte <= 1'b0;
    Tx_byte <= 8'd0;
    pixel_data_aux <= 16'd0;
    byte_select <= 1'b0;
    addr_out <= 13'd0;
    done <= 1'b0;
  end
  else
  begin
    case (state)
      IDLE:
      begin
        send_byte <= 1'b0;
        Tx_byte <= 8'd0;
        pixel_data_aux <= 16'd0;
        byte_select <= 1'b0;
        addr_out <= 13'd0;
        done <= 1'b0;
        if (send_image) state <= EVALUATE_END;
        else state <= IDLE;
      end
      EVALUATE_END:
      begin
        send_byte <= 1'b0;
        byte_select <= 1'b0;
        addr_out <= addr_out;
        done <= 1'b0;
        if (addr_out == 13'd3072)
        begin
          pixel_data_aux <= 16'hFFFF;
          Tx_byte <= 8'hFF;
          state <= END_FRAME;
        end
        else
        begin
          pixel_data_aux <= {1'b0,pixel_data};
          Tx_byte <= 8'd0;
          state <= READ_PIXEL_DATA;
        end
      end
      READ_PIXEL_DATA:
      begin
        send_byte <= send_byte;
        Tx_byte <= Tx_byte;
        pixel_data_aux <= {1'b0,pixel_data};
        byte_select <= byte_select;
        addr_out <= addr_out;
        state <= SEND_FIRST_BYTE;
        done <= 1'b0;
      end
      SEND_FIRST_BYTE:
      begin
        send_byte <= 1'b1;
        Tx_byte <= pixel_data_aux [15:8];
        pixel_data_aux <= pixel_data_aux;
        state <= WAIT_TX_DONE;
        byte_select <= 1'b0;
        addr_out <= addr_out;
        done <= 1'b0;
      end
      SEND_SECOND_BYTE:
      begin
        send_byte <= 1'b1;
        if (pixel_data_aux[7:0] == 8'hFF) Tx_byte <= {pixel_data_aux [7:1],1'b0};
        else Tx_byte <= pixel_data_aux [7:0];
        pixel_data_aux <= pixel_data_aux;
        state <= WAIT_TX_DONE;
        byte_select <= 1'b1;
        addr_out <= addr_out + 1'b1;
        done <= 1'b0;
      end
      END_FRAME:
      begin
        send_byte <= 1'b1;
        Tx_byte <= 8'hFF;
        pixel_data_aux <= 16'd0;
        state <= IDLE;
        byte_select <= 1'b1;
        addr_out <= 13'd0;
        done <= 1'b1;
      end
      WAIT_TX_DONE:
      begin
        send_byte <= 1'b0;
        Tx_byte <= 8'd0;
        pixel_data_aux <= pixel_data_aux;
        byte_select <= byte_select;
        addr_out <= addr_out;
        done <= 1'b0;
        if (Tx_done)
        begin
          if (byte_select == 1'b0) state <= SEND_SECOND_BYTE;
          else state <= EVALUATE_END;
        end
        else state <= WAIT_TX_DONE;
        end
      default:
      begin
        state <= IDLE;
        send_byte <= 1'b0;
        Tx_byte <= 8'd0;
        pixel_data_aux <= 16'd0;
        byte_select <= 1'b0;
        addr_out <= addr_out;
        done <= 1'b0;
      end
    endcase
  end
end

endmodule
