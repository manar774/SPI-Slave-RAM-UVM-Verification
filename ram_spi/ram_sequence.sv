package ram_seq_pkg;
import uvm_pkg::*;
import ram_sequence_item::*;
`include "uvm_macros.svh"
class ram_reset_sequence extends uvm_sequence #(ram_seq_item);
`uvm_object_utils(ram_reset_sequence)
 ram_seq_item seq_item;

function new(string name="ram_reset_sequence");
 super.new(name);
endfunction

task body;
 seq_item=ram_seq_item::type_id::create("seq_item");
 start_item(seq_item);
 seq_item.rst_n=0;
 seq_item.din=0;
 seq_item.rx_valid=0;
 finish_item(seq_item);
endtask
endclass

class ram_write_only_sequence extends uvm_sequence #(ram_seq_item);
  `uvm_object_utils(ram_write_only_sequence)
  ram_seq_item seq_item;
  bit [1:0] last_op;

  function new(string name="ram_write_only_sequence");
    super.new(name);
  endfunction

   task body();
    repeat (50) begin
      seq_item = ram_seq_item::type_id::create("seq_item");
      start_item(seq_item);

      assert(seq_item.randomize() with {
        if (last_op == 2'b00 || last_op == 2'b01)
          din[9:8] inside {2'b00, 2'b01}; // WA or WD
        else
          din[9:8] == 2'b00; // First must be WA
        rx_valid == 1;
      });

      finish_item(seq_item);
      last_op = seq_item.din[9:8];
    end
  endtask

  function void post_randomize();
    if (last_op == 2'b00 || last_op == 2'b01)
      assert(seq_item.din[9:8] inside {2'b00, 2'b01})
        else `uvm_error("WRITE_ONLY_SEQ","Ordering violation: WA/WD must be followed by WA or WD");
  endfunction
endclass

 class ram_read_only_sequence extends uvm_sequence #(ram_seq_item);
  `uvm_object_utils(ram_read_only_sequence)
  ram_seq_item seq_item;
  bit [1:0] last_op;

  function new(string name="ram_read_only_sequence");
    super.new(name);
  endfunction

 task body();
    repeat (50) begin
      seq_item = ram_seq_item::type_id::create("seq_item");
      start_item(seq_item);

      assert(seq_item.randomize() with {
      /*  if (last_op == 2'b10 || last_op == 2'b11)
          din[9:8] inside {2'b10, 2'b11}; // RA or RD
        else
          din[9:8] == 2'b10; // First must be RA
        rx_valid == 1;
      });*/
      if (last_op == 2'b10)         // RA -> must be RD
        din[9:8] == 2'b11;
      else if (last_op == 2'b11)    // RD -> must be RA
        din[9:8] == 2'b10;
      else                          // first operation
        din[9:8] == 2'b10;          // start with RA
      rx_valid == 1;
    });

      finish_item(seq_item);
      last_op = seq_item.din[9:8];
    end
  endtask

  function void post_randomize();
   /* if (last_op == 2'b10 || last_op == 2'b11)
      assert(seq_item.din[9:8] inside {2'b10, 2'b11})
        else `uvm_error("READ_ONLY_SEQ","Ordering violation: RA/RD must be followed by RA or RD");*/
   case (last_op)
    2'b10: assert(seq_item.din[9:8] == 2'b11)
             else `uvm_error("READ_ONLY_SEQ", "After RA must be RD")
    2'b11: assert(seq_item.din[9:8] == 2'b10)
             else `uvm_error("READ_ONLY_SEQ", "After RD must be RA")
  endcase
  endfunction
endclass

class ram_write_read_sequence extends uvm_sequence #(ram_seq_item);
  `uvm_object_utils(ram_write_read_sequence)
  ram_seq_item seq_item;
  bit [1:0] last_op;

  function new(string name="ram_write_read_sequence");
    super.new(name);
  endfunction

  task body();
    repeat (1000) begin
      seq_item = ram_seq_item::type_id::create("seq_item");
      start_item(seq_item);

      case (last_op)
        2'b00: assert(seq_item.randomize() with { // WA -> WA or WD
          din[9:8] inside {2'b00, 2'b01}; rx_valid == 1;
        });

        2'b01: assert(seq_item.randomize() with { // WD -> 60% RA, 40% WA
          rx_valid == 1;
          din[9:8] dist {2'b10:/60, 2'b00:/40};
        });

        2'b10: assert(seq_item.randomize() with { // RA -> RA or RD
          din[9:8] inside {2'b10, 2'b11}; rx_valid == 1;
        });

        2'b11: assert(seq_item.randomize() with { // RD -> 60% WA, 40% RA
          rx_valid == 1;
          din[9:8] dist {2'b00:/60, 2'b10:/40};
        });

        default: assert(seq_item.randomize() with { // First op must be WA
          din[9:8] == 2'b00; rx_valid == 1;
        });
      endcase

      finish_item(seq_item);
      last_op = seq_item.din[9:8];
    end
  endtask

function void post_randomize();
  case (last_op)
    2'b00: assert(seq_item.din[9:8] inside {2'b00, 2'b01})
             else begin
               `uvm_error("WR_SEQ","WA must be followed by WA or WD")
             end
    2'b01: assert(seq_item.din[9:8] inside {2'b00, 2'b10})
             else begin
               `uvm_error("WR_SEQ","WD must be followed by WA or RA")
             end
    2'b10: assert(seq_item.din[9:8] inside {2'b10, 2'b11})
             else begin
               `uvm_error("WR_SEQ","RA must be followed by RA or RD")
             end
    2'b11: assert(seq_item.din[9:8] inside {2'b00, 2'b10})
             else begin
               `uvm_error("WR_SEQ","RD must be followed by WA or RA")
             end
  endcase
endfunction
endclass

  class ram_main_sequence extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_main_sequence)
    ram_seq_item seq_item;

    function new(string name="ram_main_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (15000) begin
        seq_item = ram_seq_item::type_id::create("seq_item");
        start_item(seq_item);
        assert(seq_item.randomize()); 
        finish_item(seq_item);
      end
    endtask
  endclass



endpackage