module ram_sva  (
  input  logic   clk,
  input  logic   rst_n,      
  input  logic [9:0]  din,
  input  logic   rx_valid,
  input  logic [7:0]  dout,
  input  logic   tx_valid
);

  // 1. Reset clears outputs
  property reset_clear;
    @(posedge clk)
      (!rst_n) |=> (dout == 0 && tx_valid == 0);
  endproperty

  // 2. During WA/WD/RA, tx_valid must stay low
  property tx_valid_off;
    @(posedge clk) disable iff (!rst_n)
      (rx_valid && (din[9:8] inside {2'b00,2'b01,2'b10})) |=> !tx_valid;
  endproperty

  // 3. After RD, tx_valid must rise then eventually fall
  property tx_valid_on;
    @(posedge clk) disable iff (!rst_n)
      (rx_valid && din[9:8]==2'b11) |=> (tx_valid ##1 !tx_valid[->1]);
  endproperty

  // 4. WA must eventually be followed by WD
  property write_operation;
    @(posedge clk) disable iff (!rst_n)
      (rx_valid && din[9:8]==2'b00) |-> ##[1:$] (rx_valid && din[9:8]==2'b01);
  endproperty

  // 5. RA must eventually be followed by RD
  property read_operation;
    @(posedge clk) disable iff (!rst_n)
      (rx_valid && din[9:8]==2'b10) |-> ##[1:$] (rx_valid && din[9:8]==2'b11);
  endproperty

  // Assertions
  assert property (reset_clear);
  assert property (tx_valid_off);
  assert property (tx_valid_on);
  assert property (write_operation);
  assert property (read_operation);

  // Coverage
  cover property (reset_clear);
  cover property (tx_valid_off);
  cover property (tx_valid_on);
  cover property (write_operation);
  cover property (read_operation);

endmodule
