import uvm_pkg::*;
`include "uvm_macros.svh"
import ram_test_pkg::*;

module top();

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  ram_if ramif(clk);
  RAM dut (
    .clk     (clk),
    .rst_n     (ramif.rst_n),
    .din     (ramif.din),
    .rx_valid(ramif.rx_valid),
    .dout    (ramif.dout),
    .tx_valid(ramif.tx_valid)
  );
  RAM_golden golden(
    .clk     (clk),
    .rst_n     (ramif.rst_n),
    .din     (ramif.din),
    .rx_valid(ramif.rx_valid),
    .dout    (ramif.dout_ref),
    .tx_valid(ramif.tx_valid_ref)
  );
    // === Bind SVA module to DUT ===
    bind RAM ram_sva ram_inst(
        .clk     (clk),
        .rst_n     (ramif.rst_n),
        .din     (ramif.din),
        .rx_valid(ramif.rx_valid),
        .dout    (ramif.dout),
        .tx_valid(ramif.tx_valid)
        );
    
  initial begin
    uvm_config_db#(virtual ram_if)::set(null,"uvm_test_top","RAM_IF",ramif);
    run_test("ram_test");
  end

endmodule
