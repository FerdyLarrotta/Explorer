
module rising_edge_detector (
  input rst,signal_in,clk,
  output reg signal_out);


  parameter DETECT_RISING_EDGE = 0, WAIT = 1;

  reg state = DETECT_RISING_EDGE;

  always @ ( posedge(clk) ) begin

    if ( rst )
    begin
      state = DETECT_RISING_EDGE;
      signal_out = 1'b0;
    end

    case (state)
      DETECT_RISING_EDGE:
      begin
        if ( signal_in )
        begin
          signal_out = 1'b1;
          state = WAIT;
        end
        else
        begin
          signal_out = 1'b0;
          state = DETECT_RISING_EDGE;
        end
      end
      WAIT:
      begin
        signal_out = 1'b0;
        if ( signal_in )
        begin
          state = WAIT;
        end
        else
        begin
          state = DETECT_RISING_EDGE;
        end
      end
      default:
      begin
      signal_out = 1'b0;
      state = DETECT_RISING_EDGE;
      end
    endcase
  end


endmodule
