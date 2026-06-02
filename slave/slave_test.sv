package slave_test_pkg;
import slave_env_pkg::*;
import slave_config_pkg::*;
import uvm_pkg::*;
import slave_seq_pkg::*;
import slave_agent_pkg::*;
import slave_sequencer_pkg::*;
`include "uvm_macros.svh"


class slave_test extends uvm_test;
   `uvm_component_utils(slave_test)
   slave_env env;
   slave_config slave_cfg;
   virtual slave_if slave_vif;
   slave_main_sequence main_seq;
   slave_reset_sequence reset_seq;
     function new(string name="slave_test",uvm_component parent=null);
  super.new(name,parent);
endfunction
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  env=slave_env::type_id::create("env",this);
  slave_cfg=slave_config::type_id::create("slave_cfg");
  main_seq=slave_main_sequence::type_id::create("main_seq");
  reset_seq=slave_reset_sequence::type_id::create("reset_seq");
  // pragma coverage off
  if(!uvm_config_db #(virtual slave_if) :: get(this,"","slave_IF",slave_cfg.slave_vif)) begin
      `uvm_fatal("build_phase","unable to get configuration object");
  end
  // pragma coverage on
  uvm_config_db #(slave_config)::set(this,"*","CFG",slave_cfg);
endfunction

task run_phase(uvm_phase phase);
  super.run_phase(phase);
  phase.raise_objection(this);
  `uvm_info("run_phase","reset asserted ",UVM_LOW);
  reset_seq.start(env.agt.sqr);
  `uvm_info("run_phase","reset deasserted ",UVM_LOW);
  `uvm_info("run_phase","stimulus generation",UVM_LOW);
   main_seq.start(env.agt.sqr);
   `uvm_info("run_phase","stimulus generation ended",UVM_LOW);
  phase.drop_objection(this);
 endtask: run_phase
endclass: slave_test
endpackage
