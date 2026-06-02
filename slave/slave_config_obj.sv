package slave_config_pkg ;
import uvm_pkg::*;
`include "uvm_macros.svh"

class slave_config extends uvm_object;
 `uvm_object_utils(slave_config)
virtual slave_if slave_vif;
function new (string name="slave_config");
   super.new(name);  
endfunction
endclass
endpackage