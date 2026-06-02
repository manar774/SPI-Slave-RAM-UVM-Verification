package slave_coverage_pkg;
  import uvm_pkg::*;
  import slave_sequence_item::*;
  `include "uvm_macros.svh"

  class slave_coverage extends uvm_component;
    `uvm_component_utils(slave_coverage)

    uvm_analysis_export #(slave_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(slave_seq_item) cov_fifo;
    slave_seq_item seq_item_cov;
    covergroup covcode;
    option.per_instance = 1;
    rx_data_cp: coverpoint seq_item_cov.rx_data[9:8] {
        bins WA = {2'b00};
        bins WD = {2'b01};
        bins RA = {2'b10};
        bins RD = {2'b11};
        illegal_bins others = default;
    }
    ss_cp: coverpoint seq_item_cov.SS_n{
        bins low_len_13 = (1 => 0[*13] => 1);
        bins low_len_23 = (1 => 0[*23] => 1);
        illegal_bins low_too_short = (1 => 0[*1:12]  => 1);
        illegal_bins low_mid_wrong = (1 => 0[*14:22] => 1);
        //illegal_bins low_too_long  = (1 => 0[*24:$]  => 1);
        bins gap_one = (1[*1] => 0);
    }
    cp_mosi_cmd: coverpoint seq_item_cov.MOSI iff (!seq_item_cov.SS_n) {
    bins WA = (0 => 0 => 0); // 000
    bins WD = (0 => 0 => 1); // 001
    bins RA = (1 => 1 => 0); // 110
    bins RD = (1 => 1 => 1); // 111
  }
    cross_ssn_mosi: cross ss_cp, rx_data_cp{
        illegal_bins rd_len_wrong = binsof(rx_data_cp.RD) && !binsof(ss_cp.low_len_23);
        illegal_bins nonrd_len_wrong =
        (binsof(rx_data_cp.WA) || binsof(rx_data_cp.WD) || binsof(rx_data_cp.RA))
        && !binsof(ss_cp.low_len_13);
    }
    endgroup

    function new(string name="slave_coverage",uvm_component parent=null);
      super.new(name,parent);
      covcode = new();
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cov_export = new("cov_export",this);
      cov_fifo   = new("cov_fifo",this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        cov_fifo.get(seq_item_cov);
        covcode.sample();
      end
    endtask
  endclass
endpackage
