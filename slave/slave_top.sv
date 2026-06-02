import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_test_pkg::*;

module slave_top();
  bit clk;
  // Clock generator
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  slave_if slaveif(clk);
  SLAVE dut(
    .clk     (clk),
    .rst_n   (slaveif.rst_n),
    .SS_n    (slaveif.SS_n),
    .MOSI    (slaveif.MOSI),
    .rx_valid(slaveif.rx_valid),
    .MISO    (slaveif.MISO),
    .tx_valid(slaveif.tx_valid),
    .tx_data (slaveif.tx_data),
    .rx_data (slaveif.rx_data)
  );
  slave_golden golden(
    .clk     (clk),
    .rst_n   (slaveif.rst_n),
    .SS_n    (slaveif.SS_n),
    .MOSI    (slaveif.MOSI),
    .rx_valid(slaveif.rx_valid_ref),
    .MISO    (slaveif.MISO_ref),
    .tx_valid(slaveif.tx_valid),
    .tx_data (slaveif.tx_data),
    .rx_data (slaveif.rx_data_ref)
  ); 
    
  initial begin
    uvm_config_db#(virtual slave_if)::set(null,"uvm_test_top","slave_IF",slaveif);
    run_test("slave_test");
  end

endmodule
