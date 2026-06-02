package slave_driver_pkg;
import uvm_pkg::*;
import slave_sequence_item::*;
`include "uvm_macros.svh"
class slave_driver extends uvm_driver #(slave_seq_item);
`uvm_component_utils(slave_driver)
virtual slave_if slave_vif;
slave_seq_item stim_seq_item;
function new(string name="slave_driver",uvm_component parent=null);
super.new(name,parent);
endfunction

task run_phase(uvm_phase phase);
  super.run_phase(phase);
  forever begin
    stim_seq_item=slave_seq_item::type_id::create("stim_seq_item");
    seq_item_port.get_next_item(stim_seq_item);
      slave_vif.SS_n=stim_seq_item.SS_n;
      slave_vif.rst_n=stim_seq_item.rst_n; 
      slave_vif.MOSI = stim_seq_item.MOSI;
      slave_vif.tx_valid=stim_seq_item.tx_valid;
      slave_vif.tx_data=stim_seq_item.tx_data;
      @(negedge slave_vif.clk);
      seq_item_port.item_done(); 
      `uvm_info("run_phase",stim_seq_item.convert2string_stimulus(),UVM_HIGH)
  end
endtask
endclass
endpackage