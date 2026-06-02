package wrapper_seq_item_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import shared_pkg::*;

    typedef enum bit [1 : 0] {WA = 2'b00, WD = 2'b01, RA = 2'b10, RD = 2'b11} cmd_e;

    class wrapper_seq_item extends uvm_sequence_item;
        `uvm_object_utils(wrapper_seq_item)
        
        rand bit rst_n;
        bit SS_n;
        bit MOSI;
        rand bit [9:0] mosi_bits;
        bit tx_valid;
        bit MISO;
        cmd_e cmd;

        constraint rst_c { rst_n dist { 1 := 90, 0 := 10 }; }

        constraint mosi_bits_c {
            mosi_bits[9:8] inside {WA, WD, RA, RD};
            mosi_bits[7:0] dist { [0:255] := 1 };
        }

        function void post_randomize();
            cmd      = cmd_e'(mosi_bits[9:8]);
            tx_valid = (cmd == RD);
            if (!rst_n) cs_cov = IDLE_cov;
            else case (mosi_bits[9:8])
                WA: cs_cov = WA_cov;
                WD: cs_cov = WD_cov;
                RA: cs_cov = RA_cov;
                RD: cs_cov = RD_cov;
            endcase
        endfunction

        function new(string name = "wrapper_seq_item");
            super.new(name);
            SS_n     = 1'b1;
            MOSI     = 1'b0;
            tx_valid = 1'b0;
            cmd      = WA;
        endfunction

        function string convert2string();
            return $sformatf("%s rst_n=%0b, SS_n=%0b, MOSI=%0b, mosi_bits=%b, tx_valid=%0b, MISO=%0b, cmd=%s", 
                super.convert2string(), rst_n, SS_n, MOSI, mosi_bits, tx_valid, MISO, cmd.name());
        endfunction

        function string convert2string_stimulus();
            return $sformatf("rst_n=%0b, SS_n=%0b, MOSI=%0b, mosi_bits=%b, tx_valid=%0b, cmd=%s", 
                rst_n, SS_n, MOSI, mosi_bits, tx_valid, cmd.name());
        endfunction
    endclass 
endpackage
