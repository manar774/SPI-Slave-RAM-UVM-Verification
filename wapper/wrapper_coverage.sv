package wrapper_coverage_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_seq_item_pkg::*;
    import shared_pkg::*;

    class wrapper_coverage extends uvm_component;
        `uvm_component_utils(wrapper_coverage)

        uvm_analysis_export #(wrapper_seq_item) cov_export;
        uvm_tlm_analysis_fifo #(wrapper_seq_item) cov_fifo;
        wrapper_seq_item seq_item_cov;

covergroup cvgrp;
            W_cmd_cov_cp: coverpoint seq_item_cov.cmd iff (seq_item_cov.rst_n && ~seq_item_cov.SS_n) {
                bins wa_bin = {WA};
                bins wd_bin = {WD};
            }
            W_rst_cov_cp: coverpoint seq_item_cov.rst_n {
                bins reset_active  = {0};
                bins reset_inactive = {1};
            }
                    ssn_cov_cp: coverpoint seq_item_cov.SS_n {
            bins active   = {0};
            bins inactive = {1};
        }
            MISO_cov_cp: coverpoint seq_item_cov.MISO {
            bins miso_0 = {0};
            bins miso_1 = {1};
            }

            cmd_miso_cross : cross W_cmd_cov_cp, MISO_cov_cp {
                bins write_phase = binsof(W_cmd_cov_cp) intersect {WA, WD} && 
                                  binsof(MISO_cov_cp.miso_0);
                
                // All other combinations are illegal
                illegal_bins illegal_operations = 
                    (binsof(W_cmd_cov_cp) intersect {WA, WD} && binsof(MISO_cov_cp.miso_1)) ||
                    (binsof(W_cmd_cov_cp) intersect {RA, RD} && binsof(MISO_cov_cp.miso_0));
            }
        endgroup



        function new(string name = "wrapper_coverage", uvm_component parent = null);
            super.new(name, parent);
            cvgrp = new;
        endfunction 

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            cov_export = new("cov_export", this);
            cov_fifo = new("cov_fifo", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            cov_export.connect(cov_fifo.analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                cov_fifo.get(seq_item_cov);
                cvgrp.sample();
            end
        endtask 
    endclass 
endpackage