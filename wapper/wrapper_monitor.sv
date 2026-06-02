package wrapper_monitor_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import shared_pkg::*;
    import wrapper_seq_item_pkg::*;

    class wrapper_monitor extends uvm_monitor;
        `uvm_component_utils(wrapper_monitor)

        virtual wrapper_if #(MEM_DEPTH) wrapper_monitor_if;
        wrapper_seq_item rsp_seq_item;
        uvm_analysis_port #(wrapper_seq_item) mon_ap;

        function new(string name = "wrapper_monitor", uvm_component parent = null);
            super.new(name, parent);
        endfunction 

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap", this);
        endfunction

        // Track current command bits for diagnostics/coverage
        bit [9:0] sampled_bits;
        int bit_count;
        bit prev_ss_n;

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            sampled_bits = '0;
            bit_count    = 0;
            prev_ss_n    = 1'b1;

            forever begin
                rsp_seq_item = wrapper_seq_item::type_id::create("rsp_seq_item");
                @(posedge wrapper_monitor_if.clk);

                // Reset per-frame book-keeping on reset deassertion or SS_n rising edge
                if (!wrapper_monitor_if.rst_n) begin
                    sampled_bits = '0;
                    bit_count    = 0;
                end

                if (prev_ss_n && !wrapper_monitor_if.SS_n) begin
                    sampled_bits = '0;
                    bit_count    = 0;
                end

                if (!wrapper_monitor_if.SS_n && bit_count < 10) begin
                    sampled_bits[9 - bit_count] = wrapper_monitor_if.MOSI;
                    bit_count++;
                end

                rsp_seq_item.rst_n     = wrapper_monitor_if.rst_n;
                rsp_seq_item.SS_n      = wrapper_monitor_if.SS_n;
                rsp_seq_item.MOSI      = wrapper_monitor_if.MOSI;
                rsp_seq_item.MISO      = wrapper_monitor_if.MISO;
                rsp_seq_item.mosi_bits = sampled_bits;
                if (bit_count >= 2) begin
                    rsp_seq_item.cmd = cmd_e'(sampled_bits[9:8]);
                end

                mon_ap.write(rsp_seq_item);
                `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH)

                prev_ss_n = wrapper_monitor_if.SS_n;
            end
        endtask 
    endclass 
endpackage
