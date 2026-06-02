interface slave_if(clk);
input bit clk;
logic rst_n, SS_n, MOSI, rx_valid;
logic MISO, tx_valid;
logic [7:0] tx_data;
logic [9:0] rx_data;
//golden model outputs
logic MISO_ref;
logic rx_valid_ref;
logic [9:0] rx_data_ref;
endinterface