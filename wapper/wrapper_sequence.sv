package wrapper_sequence_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_seq_item_pkg::*;

    class wrapper_reset_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_reset_sequence)
        wrapper_seq_item seq_item;

        function new(string name = "wrapper_reset_sequence");
            super.new(name);
        endfunction

        task body;
            seq_item = wrapper_seq_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.rst_n = 0;
            seq_item.SS_n = 1;
            seq_item.MOSI = 0;
            seq_item.mosi_bits = 0;
            finish_item(seq_item);
        endtask
    endclass

    class wrapper_write_only_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_write_only_sequence)
        wrapper_seq_item seq_item;
        bit [1:0] last_cmd = WA;

        function new(string name = "wrapper_write_only_sequence");
            super.new(name);
        endfunction

        task body;
            repeat(50) begin
                seq_item = wrapper_seq_item::type_id::create("seq_item");
                start_item(seq_item);
                assert(seq_item.randomize() with {
                    mosi_bits[9:8] inside {WA, WD};
                    if (last_cmd inside {WA, WD}) mosi_bits[9:8] inside {WA, WD};
                    else mosi_bits[9:8] == WA;
                });
                finish_item(seq_item);
                last_cmd = seq_item.mosi_bits[9:8];
            end
        endtask
    endclass

    class wrapper_read_only_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_read_only_sequence)
        wrapper_seq_item seq_item;
        bit [1:0] last_cmd = RA;

        function new(string name = "wrapper_read_only_sequence");
            super.new(name);
        endfunction

        task body;
            repeat(50) begin
                seq_item = wrapper_seq_item::type_id::create("seq_item");
                start_item(seq_item);
                assert(seq_item.randomize() with {
                    mosi_bits[9:8] inside {RA, RD};
                    if (last_cmd inside {RA, RD}) mosi_bits[9:8] inside {RA, RD};
                    else mosi_bits[9:8] == RA;
                });
                finish_item(seq_item);
                last_cmd = seq_item.mosi_bits[9:8];
            end
        endtask
    endclass

    class wrapper_write_read_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_write_read_sequence)
        wrapper_seq_item seq_item;
        bit [1:0] last_cmd = WA;

        function new(string name = "wrapper_write_read_sequence");
            super.new(name);
        endfunction

        task body;
            repeat(50) begin
                seq_item = wrapper_seq_item::type_id::create("seq_item");
                start_item(seq_item);
                assert(seq_item.randomize() with {
                    mosi_bits[9:8] inside {WA, WD, RA, RD};
                    if (last_cmd inside {WA, WD}) mosi_bits[9:8] inside {RA, RD};
                    else if (last_cmd inside {RA, RD}) mosi_bits[9:8] inside {WA, WD};
                    else mosi_bits[9:8] == WA;
                });
                finish_item(seq_item);
                last_cmd = seq_item.mosi_bits[9:8];
            end
        endtask
    endclass
endpackage
