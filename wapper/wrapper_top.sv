import uvm_pkg::*;
`include "uvm_macros.svh"
import wrapper_test_pkg::*;

module wrapper_top ();
    bit clk;
    localparam MEM_DEPTH = 256;

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Instantiate interfaces
    wrapper_if wrapperif (clk);
    ram_if ramif(clk);
    slave_if slaveif(clk);

    wrapper DUT (
        .MOSI(wrapperif.MOSI),
        .MISO(wrapperif.MISO),
        .SS_n(wrapperif.SS_n),
        .clk(wrapperif.clk),
        .rst_n(wrapperif.rst_n)
    );

    RAM_golden #(
        .MEM_DEPTH(MEM_DEPTH)
    ) ram_ref (
        .clk(wrapperif.clk),
        .rst_n(wrapperif.rst_n),
        .rx_valid(slaveif.rx_valid_ref),
        .din(slaveif.rx_data_ref),
        .dout(ramif.dout_ref),
        .tx_valid(ramif.tx_valid_ref)
    );

    slave_golden slave_ref (
        .MOSI(wrapperif.MOSI),
        .MISO(slaveif.MISO_ref),
        .SS_n(wrapperif.SS_n),
        .clk(wrapperif.clk),
        .rst_n(wrapperif.rst_n),
        .rx_data(slaveif.rx_data_ref),
        .rx_valid(slaveif.rx_valid_ref),
        .tx_data(ramif.dout_ref),
        .tx_valid(ramif.tx_valid_ref)
    );
   
 
    // Initial block for configuration and test run
    initial begin
        $readmemh("RAM_data.dat", DUT.memory.MEM, 0, 255); // Fixed memory load path
        uvm_config_db #(virtual wrapper_if)::set(null, "uvm_test_top", "wrapper_if", wrapperif);
        uvm_config_db #(virtual slave_if)::set(null, "uvm_test_top", "slave_vif", slaveif);
        uvm_config_db #(virtual ram_if)::set(null, "uvm_test_top", "ram_vif", ramif);
        run_test("wrapper_test");
    end

    assign slaveif.rst_n    = DUT.rst_n;
    assign slaveif.SS_n     = DUT.SS_n;
    assign slaveif.MOSI     = DUT.MOSI;
    assign slaveif.rx_valid = DUT.slave.rx_valid; 
    assign slaveif.rx_data  = DUT.slave.rx_data;  
    assign slaveif.tx_valid = DUT.memory.tx_valid; 
    assign slaveif.tx_data  = DUT.memory.dout;     
    assign slaveif.MISO     = DUT.MISO;

    assign ramif.rst_n      = DUT.rst_n;
    assign ramif.rx_valid   = DUT.slave.rx_valid;  
    assign ramif.din        = DUT.slave.rx_data;   
    assign ramif.tx_valid   = DUT.memory.tx_valid; 
    assign ramif.dout       = DUT.memory.dout;     

endmodule