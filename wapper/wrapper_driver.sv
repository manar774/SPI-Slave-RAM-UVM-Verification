package wrapper_driver_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import shared_pkg::*;
    import wrapper_seq_item_pkg::*;
    import wrapper_config_obj_pkg::*;

    class wrapper_driver extends uvm_driver #(wrapper_seq_item);
        `uvm_component_utils(wrapper_driver)

        virtual wrapper_if #(MEM_DEPTH) wrapper_driver_if;
        wrapper_seq_item stim_seq_item;

        function new(string name = "wrapper_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction 

        task automatic drive_reset(bit rst_n_val);
            wrapper_driver_if.rst_n = rst_n_val;
            wrapper_driver_if.SS_n  = 1'b1;
            wrapper_driver_if.MOSI  = 1'b0;
            @(posedge wrapper_driver_if.clk);
        endtask

        task automatic drive_frame(wrapper_seq_item item);
            // Hold SS_n low while streaming out the 10-bit frame MSB-first
            wrapper_driver_if.SS_n = 1'b0;
            for (int bit_idx = 9; bit_idx >= 0; bit_idx--) begin
                @(negedge wrapper_driver_if.clk);
                wrapper_driver_if.MOSI = item.mosi_bits[bit_idx];
                @(posedge wrapper_driver_if.clk);
            end

            // Allow the slave one extra beat to assert rx_valid while SS_n remains low
            @(negedge wrapper_driver_if.clk);
            wrapper_driver_if.MOSI = 1'b0;
            @(posedge wrapper_driver_if.clk);

            // For read commands keep clocking the interface so the slave can drive MISO
            if (item.cmd == RD) begin
                for (int rd_bit = 7; rd_bit >= 0; rd_bit--) begin
                    @(negedge wrapper_driver_if.clk);
                    wrapper_driver_if.MOSI = 1'b0;
                    @(posedge wrapper_driver_if.clk);
                end
            end

            // Return the bus to idle
            @(negedge wrapper_driver_if.clk);
            wrapper_driver_if.SS_n = 1'b1;
            wrapper_driver_if.MOSI = 1'b0;
            @(posedge wrapper_driver_if.clk);
        endtask

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin
                seq_item_port.get_next_item(stim_seq_item);
                if (stim_seq_item == null) begin
                    `uvm_fatal("run_phase", "Received a null sequence item")
                end

                // Drive reset immediately; skip transaction when reset asserted
                drive_reset(stim_seq_item.rst_n);
                if (!stim_seq_item.rst_n) begin
                    seq_item_port.item_done();
                    `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH)
                    continue;
                end

                drive_frame(stim_seq_item);
                seq_item_port.item_done();
                `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH)
            end
        endtask 
    endclass 
endpackage
