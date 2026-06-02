interface ram_if(clk);
parameter MEM_DEPTH = 256;
parameter ADDR_SIZE=8;
input clk;
logic rst_n, rx_valid;
logic[9:0] din;
logic[7:0] dout;
logic tx_valid;
  // Golden outputs
  logic [7:0] dout_ref;
  logic       tx_valid_ref;
endinterface