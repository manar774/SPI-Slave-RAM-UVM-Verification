package slave_sequence_item;
import uvm_pkg::*;
`include "uvm_macros.svh"
class slave_seq_item extends uvm_sequence_item;
`uvm_object_utils(slave_seq_item)
rand bit clk, rst_n, rx_valid, rx_valid_ref;
rand bit [7:0] tx_data;
rand bit tx_valid;
rand bit[9:0] rx_data_ref, rx_data;
rand bit MISO, MISO_ref;
rand bit MOSI, SS_n;
rand bit [2:0] cmd; // 3'b000, 001, 110, 111 only

////////constraints//////////
constraint rst_c {rst_n dist {1:/90, 0:/10};}
constraint SS_n_c {
    solve tx_valid before SS_n;
    (!tx_valid) -> SS_n dist {1:=1, 0:=12};
    (tx_valid) -> SS_n dist{1:=1, 0:=22};
}
rand bit [10:0] MOSI_array [0:3];
constraint MOSI_c {
      foreach (MOSI_array[i]) MOSI_array[i][10:8] inside {3'b000,3'b001,3'b110,3'b111};

      // all-different on the 3-bit headers:
      MOSI_array[0][10:8] != MOSI_array[1][10:8];
      MOSI_array[0][10:8] != MOSI_array[2][10:8];
      MOSI_array[0][10:8] != MOSI_array[3][10:8];
      MOSI_array[1][10:8] != MOSI_array[2][10:8];
      MOSI_array[1][10:8] != MOSI_array[3][10:8];
      MOSI_array[2][10:8] != MOSI_array[3][10:8];
    }
//The tx_valid signal to be high in case of read data
constraint cmd_c { cmd inside {3'b000, 3'b001, 3'b110, 3'b111}; }
constraint cmd_map_c  { rx_data[9:7] == cmd; }
constraint tx_valid_c {
    (cmd == 3'b111) -> (tx_valid == 1);
    (!cmd == 3'b111) -> (tx_valid == 0);
}
function new(string name="slave_seq_item");
super.new(name);
endfunction

function string convert2string();
return $sformatf("%s rst_n=0b%0b rx_valid=0b%0b MISO=0b%0b MOSI=0b%0b SS_n=0b%0b, tx_data=0b%0b, tx_valid=0b%0b, rx_data=0b%0b, rx_valid_ref=0b%0b, MISO_ref=0b%0b, rx_data_ref=0b%0b",super.convert2string(),
rst_n,rx_valid,MISO,MOSI,SS_n,tx_data,tx_valid,rx_data,rx_valid_ref,MISO_ref,rx_data_ref);
endfunction

function string convert2string_stimulus();
 return $sformatf("rst_n=0b%0b rx_valid=0b%0b MISO=0b%0b MOSI=0b%0b SS_n=0b%0b, tx_data=0b%0b, tx_valid=0b%0b, rx_data=0b%0b, rx_valid_ref=0b%0b, MISO_ref=0b%0b, rx_data_ref=0b%0b",
 rst_n,rx_valid,MISO,MOSI,SS_n,tx_data,tx_valid,rx_data,rx_valid_ref,MISO_ref,rx_data_ref);
endfunction
endclass
endpackage