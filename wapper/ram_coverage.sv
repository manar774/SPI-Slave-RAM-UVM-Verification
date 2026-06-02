package ram_coverage_pkg;
  import uvm_pkg::*;
  import ram_sequence_item::*;
  `include "uvm_macros.svh"

  class ram_coverage extends uvm_component;
    `uvm_component_utils(ram_coverage)

    uvm_analysis_export #(ram_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(ram_seq_item) cov_fifo;
    ram_seq_item seq_item_cov;

    covergroup covcode;
      din_cp: coverpoint seq_item_cov.din[9:8]{
            bins wr_addr = {2'b00};  
            bins wr_data = {2'b01};   
            bins rd_addr = {2'b10};  
            bins rd_data = {2'b11};   
      }

      //check write data after write address
        wr_data_cp: coverpoint seq_item_cov.din[7:0] iff(seq_item_cov.din[9:8]==2'b01) {
            bins wr_data_0       = {8'h00};
            bins wr_data_max     = {8'hFF};
            bins wr_data_min     = {8'h01};
            bins wr_data_default = default;
        }
        //check read data after read address
        rd_data_cp: coverpoint seq_item_cov.din[7:0] iff(seq_item_cov.din[9:8]==2'b11) {
            bins rd_data_0       = {8'h00};
            bins rd_data_max     = {8'hFF};
            bins rd_data_min     = {8'h01};
            bins rd_data_default = default;
        }
        //check write address= => write data => read address => read data 
        trans_cp: coverpoint seq_item_cov.din[9:8] {
            bins wraddr_to_wrdata = (2'b00 => 2'b01);
            bins wrdata_to_rdaddr = (2'b01 => 2'b10);
            bins rdaddr_to_rddata = (2'b10 => 2'b11);
            bins full_sequence = (2'b00 => 2'b01 => 2'b10 => 2'b11);
        }
        rx_valid_cp: coverpoint seq_item_cov.rx_valid {
            bins low  = {1'b0};
            bins high = {1'b1};
        }

        tx_valid_cp: coverpoint seq_item_cov.tx_valid {
            bins low  = {1'b0};
            bins high = {1'b1};
        }
        cross_din_rxvalid: cross din_cp,rx_valid_cp {
            bins active_cross = binsof(din_cp) && binsof(rx_valid_cp.high) ;
        }

        cross_rddata_txvalid: cross din_cp, tx_valid_cp {
            bins valid_read = binsof(din_cp.rd_data) && binsof(tx_valid_cp.high);
            illegal_bins ra_high = binsof(din_cp.rd_addr) && binsof(tx_valid_cp.high);
            illegal_bins wr_high = binsof(din_cp.wr_addr) && binsof(tx_valid_cp.high);
            illegal_bins wd_high = binsof(din_cp.wr_data) && binsof(tx_valid_cp.high);

            
        }
 
    endgroup

    function new(string name="ram_coverage",uvm_component parent=null);
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
