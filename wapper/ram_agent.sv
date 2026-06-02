package ram_agent_pkg;
import uvm_pkg::*;
import ram_driver_pkg::*;
import ram_config_pkg::*;
import ram_sequencer_pkg::*;
import ram_monitor_pkg::*;
import ram_sequence_item::*;
`include "uvm_macros.svh"
class ram_agent extends uvm_agent;
`uvm_component_utils(ram_agent)
ram_sequencer sqr;
ram_driver drv;
ram_config ram_cfg;
ram_monitor mon;
uvm_analysis_port #(ram_seq_item) agt_ap;

function new(string name="ram_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

function void  build_phase(uvm_phase phase);
super.build_phase(phase);
 if(!uvm_config_db#(ram_config)::get(this,"","CFG",ram_cfg)) begin
    `uvm_fatal("build_phase","unable to get configuration object");
 end
 
  if (ram_cfg.active == UVM_ACTIVE) begin
      sqr    = ram_sequencer::type_id::create("sqr", this);
      drv    = ram_driver::type_id::create("drv", this);
  end
  mon    = ram_monitor::type_id::create("mon", this);
  agt_ap = new("agt_ap", this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (ram_cfg.active == UVM_ACTIVE) begin
      drv.ram_vif=ram_cfg.ram_vif;
      drv.seq_item_port.connect(sqr.seq_item_export);
  end
  mon.mon_ap.connect(agt_ap);
  mon.ram_vif=ram_cfg.ram_vif;
endfunction

endclass
endpackage