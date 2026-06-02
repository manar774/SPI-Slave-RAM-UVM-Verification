package slave_seq_pkg;
import uvm_pkg::*;
import slave_sequence_item::*;
`include "uvm_macros.svh"

typedef enum bit [2:0] {
    CMD_WA = 3'b000,
    CMD_WD = 3'b001,
    CMD_RA = 3'b110,
    CMD_RD = 3'b111
} cmd_e;

class slave_reset_sequence extends uvm_sequence #(slave_seq_item);
  `uvm_object_utils(slave_reset_sequence)
  slave_seq_item reset_item;

  function new(string name="slave_reset_sequence");
    super.new(name);
  endfunction

  task body;
    // Alternate rst_n asserted/deasserted to guarantee a 50% duty reset pulse train.
    int unsigned total_cycles = 16;
    int unsigned rst_low_count = 0;
    int unsigned rst_high_count = 0;

    for (int idx = 0; idx < total_cycles; idx++) begin
      bit rst_n_val = (idx % 2) ? 1'b1 : 1'b0;
      reset_item = slave_seq_item::type_id::create($sformatf("rst_item_%0d", idx));
      start_item(reset_item);
        reset_item.rst_n    = rst_n_val;
        reset_item.SS_n     = 1;
        reset_item.tx_valid = 0;
        reset_item.MOSI     = 0;
        reset_item.tx_data  = '0;
        reset_item.cmd      = CMD_WA;
      finish_item(reset_item);

      if (rst_n_val)
        rst_high_count++;
      else
        rst_low_count++;
    end

    if (rst_low_count != rst_high_count) begin
      `uvm_error("RST_SEQ",
                 $sformatf("Reset sequence imbalance: rst low=%0d, high=%0d",
                           rst_low_count, rst_high_count))
    end else begin
      `uvm_info("RST_SEQ",
                $sformatf("Reset sequence issued %0d items with a 50%% duty cycle",
                          total_cycles),
                UVM_LOW)
    end
  endtask
endclass

class slave_main_sequence extends uvm_sequence #(slave_seq_item);
  `uvm_object_utils(slave_main_sequence)

  function new(string name="slave_main_sequence");
    super.new(name);
  endfunction

  task automatic drive_frame(cmd_e cmd_sel,
                             int rd_tx_mode = -1,
                             bit [7:0] forced_tx_data = 8'h00,
                             bit use_forced_tx = 0,
                             bit use_forced_payload = 0,
                             bit [7:0] forced_payload = 8'h00,
                             bit use_forced_lsb = 0,
                             bit forced_lsb_value = 0,
                             bit use_rx_payload = 0,
                             bit [7:0] forced_rx_payload = 8'h00,
                             bit use_rx_lsb = 0,
                             bit forced_rx_lsb = 0,
                             int drop_tx_valid_from = -1);
    int        low_len;
    bit [10:0] bits;
    bit [7:0]  frame_tx_data;
    bit [7:0]  payload;
    bit [7:0]  rx_payload;
    slave_seq_item gap;
    slave_seq_item beat;
    int i;
    static bit lsb_flip = 0;
    bit rd_tx_en;
    bit is_read_cmd;
    bit rd_rx_mode;

    low_len      = (cmd_sel == CMD_RD) ? 23 : 13;
    is_read_cmd  = (cmd_sel == CMD_RA) || (cmd_sel == CMD_RD);

    payload = (cmd_sel == CMD_RA) ? 8'hA5 : $urandom();
    if (use_forced_payload)
      payload = forced_payload;

    bits[10:8] = cmd_sel;
    bits[7:0]  = payload;

    if (use_forced_lsb) begin
      bits[0]   = forced_lsb_value;
      lsb_flip  = forced_lsb_value ^ 1'b1;
    end else begin
      bits[0]   = lsb_flip;
      lsb_flip ^= 1'b1;
    end

    frame_tx_data = use_forced_tx ? forced_tx_data : $urandom();
    if (cmd_sel == CMD_RD) begin
      if ((rd_tx_mode == 0) || (rd_tx_mode == 1))
        rd_tx_en = rd_tx_mode;
      else
        rd_tx_en = $urandom_range(0,1);
    end else begin
      rd_tx_en = 1'b0;
    end

    rd_rx_mode = (cmd_sel == CMD_RD) && (rd_tx_en == 0);
    rx_payload = $urandom();
    if (use_rx_payload)
      rx_payload = forced_rx_payload;

    gap = slave_seq_item::type_id::create("gap");
    start_item(gap);
      gap.rst_n    = 1;
      gap.SS_n     = 1;
      gap.MOSI     = (cmd_sel == CMD_RD) ? 1'b1 : 1'b0;
      gap.tx_valid = 0;
      gap.tx_data  = '0;
      gap.cmd      = cmd_sel;
    finish_item(gap);

    for (i = 0; i < low_len; i++) begin
      beat = slave_seq_item::type_id::create($sformatf("low_%0d", i));
      start_item(beat);
        beat.rst_n    = 1;
        beat.SS_n     = 0;
        beat.cmd      = cmd_sel;
        beat.tx_valid = (cmd_sel == CMD_RD) ? rd_tx_en : 1'b0;
        if ((cmd_sel == CMD_RD) &&
            (rd_tx_en == 1'b1) &&
            (drop_tx_valid_from >= 0) &&
            (i >= drop_tx_valid_from)) begin
          beat.tx_valid = 1'b0;
        end
        beat.tx_data  = frame_tx_data;
        if (i == 0) begin
          beat.MOSI = is_read_cmd ? 1'b1 : 1'b0;
        end else if (rd_rx_mode && (i >= 11) && (i < 19)) begin
          int rx_idx;
          bit rx_bit;
          rx_idx = i - 11;
          rx_bit = rx_payload[7 - rx_idx];
          if (use_rx_lsb && (rx_idx == 7))
            rx_bit = forced_rx_lsb;
          beat.MOSI = rx_bit;
        end else if (use_forced_lsb && (i == 10)) begin
          beat.MOSI = forced_lsb_value;
        end else if (i < 11) begin
          beat.MOSI = bits[10 - i];
        end else begin
          beat.MOSI = 1'b0;
        end
      finish_item(beat);
    end
  endtask

  task automatic drive_abort_chk();
    slave_seq_item gap;
    slave_seq_item first;
    slave_seq_item abort;

    gap = slave_seq_item::type_id::create("gap_abort");
    start_item(gap);
      gap.rst_n    = 1;
      gap.SS_n     = 1;
      gap.MOSI     = 0;
      gap.tx_valid = 0;
      gap.tx_data  = '0;
      gap.cmd      = CMD_WA;
    finish_item(gap);

    first = slave_seq_item::type_id::create("abort_chk_first");
    start_item(first);
      first.rst_n    = 1;
      first.SS_n     = 0;
      first.MOSI     = 1'b1;
      first.tx_valid = 0;
      first.tx_data  = '0;
      first.cmd      = CMD_RA;
    finish_item(first);

    abort = slave_seq_item::type_id::create("abort_chk_release");
    start_item(abort);
      abort.rst_n    = 1;
      abort.SS_n     = 1;
      abort.MOSI     = 0;
      abort.tx_valid = 0;
      abort.tx_data  = '0;
      abort.cmd      = CMD_RA;
    finish_item(abort);
  endtask

  function automatic cmd_e pick_cmd();
    int sel;
    sel = $urandom_range(0,99);
    if      (sel < 25) return CMD_WA;
    else if (sel < 50) return CMD_WD;
    else if (sel < 75) return CMD_RA;
    else               return CMD_RD;
  endfunction

  virtual task body();
    // deterministic coverage seed:
    drive_frame(CMD_RA);
    drive_frame(CMD_RD, 1, 8'hF0, 1);

    drive_frame(.cmd_sel(CMD_RA),
                .use_forced_payload(1),
                .forced_payload(8'h3C),
                .use_forced_lsb(1),
                .forced_lsb_value(1'b1));

    drive_frame(.cmd_sel(CMD_RD),
                .rd_tx_mode(0),
                .forced_tx_data(8'h0F),
                .use_forced_tx(1),
                .use_forced_payload(1),
                .forced_payload(8'hD3),
                .use_rx_payload(1),
                .forced_rx_payload(8'hA7),
                .use_rx_lsb(1),
                .forced_rx_lsb(1'b1));

    drive_frame(.cmd_sel(CMD_RA),
                .use_forced_payload(1),
                .forced_payload(8'h96),
                .use_forced_lsb(1),
                .forced_lsb_value(1'b0));

    drive_frame(.cmd_sel(CMD_RD),
                .rd_tx_mode(0),
                .forced_tx_data(8'hF0),
                .use_forced_tx(1),
                .use_forced_payload(1),
                .forced_payload(8'h4C),
                .use_rx_payload(1),
                .forced_rx_payload(8'h53),
                .use_rx_lsb(1),
                .forced_rx_lsb(1'b0));

    // Force tx_valid low late in the frame so counter drops to zero and exercises
    // the READ_DATA rx path where (counter > 0) evaluates to false.
    drive_frame(.cmd_sel(CMD_RD),
                .rd_tx_mode(1),
                .drop_tx_valid_from(21));

    drive_abort_chk();

    drive_frame(.cmd_sel(CMD_WD),
                .use_forced_payload(1),
                .forced_payload(8'h01),
                .use_forced_lsb(1),
                .forced_lsb_value(1'b1));

    drive_frame(.cmd_sel(CMD_WD),
                .use_forced_payload(1),
                .forced_payload(8'h00),
                .use_forced_lsb(1),
                .forced_lsb_value(1'b0));

    repeat (90) begin
      cmd_e cmd_sel;
      cmd_sel = pick_cmd();
      drive_frame(cmd_sel);
    end
  endtask
endclass
endpackage
