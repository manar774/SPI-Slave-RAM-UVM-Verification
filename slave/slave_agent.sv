package slave_agent_pkg;
import uvm_pkg::*;
import slave_driver_pkg::*;
import slave_config_pkg::*;
import slave_sequencer_pkg::*;
import slave_monitor_pkg::*;
import slave_sequence_item::*;
`include "uvm_macros.svh"
class slave_agent extends uvm_agent;
`uvm_component_utils(slave_agent)
slave_sequencer sqr;
slave_driver drv;
slave_config slave_cfg;
slave_monitor mon;
uvm_analysis_port #(slave_seq_item) agt_ap;

function new(string name="slave_agent",uvm_component parent=null);
super.new(name,parent);
endfunction

function void  build_phase(uvm_phase phase);
super.build_phase(phase);
 // pragma coverage off
 if(!uvm_config_db#(slave_config)::get(this,"","CFG",slave_cfg)) begin
    `uvm_fatal("build_phase","unable to get configuration object");
 end
 // pragma coverage on
 sqr=slave_sequencer::type_id::create("sqr",this);
 drv=slave_driver::type_id::create("drv",this);
 mon=slave_monitor::type_id::create("mon",this);
 agt_ap=new("agt_ap",this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  drv.slave_vif=slave_cfg.slave_vif;
  mon.slave_vif=slave_cfg.slave_vif;
  drv.seq_item_port.connect(sqr.seq_item_export);
  mon.mon_ap.connect(agt_ap);
endfunction

endclass
endpackage


