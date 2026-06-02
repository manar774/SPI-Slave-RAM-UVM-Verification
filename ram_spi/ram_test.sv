package ram_test_pkg;
import ram_env_pkg::*;
import ram_config_pkg::*;
import uvm_pkg::*;
import ram_seq_pkg::*;
import ram_agent_pkg::*;
import ram_sequencer_pkg::*;
`include "uvm_macros.svh"


class ram_test extends uvm_test;
   `uvm_component_utils(ram_test)
   ram_env env;
   ram_config ram_cfg;
   virtual ram_if ram_vif;
   ram_main_sequence main_seq;
   ram_reset_sequence reset_seq;
     function new(string name="ram_test",uvm_component parent=null);
  super.new(name,parent);
endfunction
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  env=ram_env::type_id::create("env",this);
  ram_cfg=ram_config::type_id::create("ram_cfg");
  main_seq=ram_main_sequence::type_id::create("main_seq");
  reset_seq=ram_reset_sequence::type_id::create("reset_seq");
  if(!uvm_config_db #(virtual ram_if) :: get(this,"","RAM_IF",ram_cfg.ram_vif)) begin
      `uvm_fatal("build_phase","unable to get configuration object");
  end
  uvm_config_db #(ram_config)::set(this,"*","CFG",ram_cfg);
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
endclass: ram_test
endpackage