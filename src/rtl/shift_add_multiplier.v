`default_nettype none `timescale 1ns / 1ns

module shift_add_multiplier #(
    parameter WIDTH = 16
) (
    input wire clk,
    input wire reset_n,
    input wire tvalid_slave_1,
    input signed [WIDTH-1:0] tdata_slave_1,
    output wire tready_slave_1,
    input wire tvalid_slave_2,
    input signed [WIDTH-1:0] tdata_slave_2,
    output wire tready_slave_2,
    output reg tvalid_master,
    output reg signed [WIDTH-1:0] tdata_master,
    input wire tready_master
);

  localparam StateInput = 0;
  localparam StateSignCorrection = 1;
  localparam StateCalc = 2;
  localparam StateOutput = 3;

  reg signed [2*WIDTH:0] product;
  wire input_transaction_1;
  wire input_transaction_2;
  wire output_transaction;
  reg [2:0] state;
  reg received_1;
  reg received_2;
  reg signed [WIDTH-1:0] factor_a;
  reg signed [WIDTH-1:0] factor_b;
  reg [$clog2(WIDTH-1):0] counter;

  assign input_transaction_1 = tvalid_slave_1 & tready_slave_1;
  assign input_transaction_2 = tvalid_slave_2 & tready_slave_2;
  assign output_transaction = tvalid_master & tready_master;
  assign tready_slave_1 = !received_1 & reset_n;
  assign tready_slave_2 = !received_2 & reset_n;

  always @(posedge clk) begin
    case (state)
      StateInput: begin
        if ((input_transaction_1 | received_1) & (input_transaction_2 | received_2)) begin
          state <= StateSignCorrection;
        end
        if (input_transaction_1) begin
          received_1 <= 1;
          factor_a   <= tdata_slave_1;
        end
        if (input_transaction_2) begin
          received_2 <= 1;
          factor_b   <= tdata_slave_2;
        end
      end

      StateSignCorrection: begin
        state <= StateCalc;
        product[2*WIDTH:WIDTH] <= {factor_a[WIDTH-1], {(WIDTH) {1'b0}}};
        if (factor_a < 0) begin
          factor_a <= ~factor_a + 1;
          product[WIDTH-1:0] <= ~factor_b + 1;
        end else begin
          product[WIDTH-1:0] <= factor_b;
        end
      end

      StateCalc: begin
        if (product[0] == 1) begin
          if (counter == WIDTH) begin
            product <= ({product[2*WIDTH:WIDTH] - factor_a, product[WIDTH-1:0]}) >>> 1;
          end else begin
            product <= ({product[2*WIDTH:WIDTH] + factor_a, product[WIDTH-1:0]}) >>> 1;
          end
        end

        if (counter == WIDTH) begin
          state <= StateOutput;
          tvalid_master <= 1;
          tdata_master <= counter <= 0;
        end else begin
          counter <= counter + 1;
        end
      end

      StateOutput: begin
        if (output_transaction) begin
          state <= StateInput;
          tvalid_master <= 0;
          tdata_master <= product[2*WIDTH-2:WIDTH-1];
          received_1 <= 0;
          received_2 <= 0;
        end
      end
      default: begin

      end
    endcase
    if (!reset_n) begin
      state <= StateInput;
      product <= 0;
      received_1 <= 0;
      received_2 <= 0;
      factor_a <= 0;
      factor_b <= 0;
      counter <= 0;
      tvalid_master <= 0;
      tdata_master <= 0;
    end
  end

`ifdef FORMAL
  `include "formal.v"
`endif

endmodule
