package ram_sequence_item;
import uvm_pkg::*;
`include "uvm_macros.svh"
class ram_seq_item extends uvm_sequence_item;
`uvm_object_utils(ram_seq_item)
rand bit clk;
rand bit [9:0] din;
rand bit rst_n;
rand bit rx_valid;
rand bit [7:0] dout;
rand bit tx_valid;
rand bit[7:0] dout_ref;
rand bit tx_valid_ref;
    constraint rst_c {rst_n dist {1:/90, 0:/10};}

    constraint rx_valid_c {rx_valid dist {1:/80, 0:/20};}
    constraint din_c {
      if (rx_valid) {
        din[9:8] dist {2'b11:/50, 2'b00:/20, 2'b01:/20, 2'b10:/10}; // 50% read data
      }
    }

function new(string name="ram_seq_item");
super.new(name);
endfunction

function string convert2string();
return $sformatf("%s rst=0b%0b din=0b%0b,rx valid=0b%0b,dout=%0s,tx valid=0b%0b,dout_ref=%0s,tx valid_ref=0b%0b",super.convert2string(),rst_n,din,rx_valid,dout,tx_valid,dout_ref,tx_valid_ref);
endfunction

function string convert2string_stimulus();
 return $sformatf(" rst=0b%0b din=0b%0b,rx valid=0b%0b",rst_n,din,rx_valid);
endfunction


endclass
endpackage