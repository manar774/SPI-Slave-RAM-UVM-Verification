package ram_sequencer_pkg;
import uvm_pkg::*;
import ram_sequence_item::*;
`include "uvm_macros.svh"
class ram_sequencer extends uvm_sequencer #(ram_seq_item);
`uvm_component_utils(ram_sequencer)
function new(string name="ram_sequencer",uvm_component parent =null);
   super.new(name,parent);
endfunction
endclass
endpackage