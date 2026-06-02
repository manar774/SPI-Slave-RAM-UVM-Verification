module wrapper_sva (
    input logic clk,
    input logic rst_n,
    input logic SS_n,
    input logic MOSI,
    input logic MISO,
    input logic rx_valid,
    input logic tx_valid,
    input logic [9:0] rx_data,
    input logic [7:0] tx_data
);

    // 1️⃣ Outputs inactive during reset
    property p_reset_outputs_inactive;
        @(posedge clk)
        !rst_n |-> (MISO == 1'b0 && rx_valid == 1'b0 && rx_data == 10'b0);
    endproperty
    a_reset_outputs_inactive: assert property (p_reset_outputs_inactive)
        else $error("Reset outputs not inactive");
    cover property (p_reset_outputs_inactive);

    // 2️⃣ MISO stable during non-READ_DATA (not 3'b111)
    property p_miso_stable_non_read;
        @(posedge clk) disable iff(!rst_n)
        (SS_n == 1'b0 && rx_data[9:7] != 3'b111)
            |=> $stable(MISO);
    endproperty
    a_miso_stable_non_read: assert property (p_miso_stable_non_read)
        else $error("MISO changed during non-read operation");
    cover property (p_miso_stable_non_read);

    // 3️⃣ rx_valid must assert *exactly* 10 cycles after SS_n falls
    // but only for valid commands (000, 001, 110, 111)
    property p_rx_valid_after_command;
        @(posedge clk) disable iff(!rst_n)
        ($fell(SS_n) && (rx_data[9:7] inside {3'b000,3'b001,3'b110,3'b111}))
            |=> ##10 rx_valid;
    endproperty
    a_rx_valid_after_command: assert property (p_rx_valid_after_command)
        else $error("rx_valid did not assert 10 cycles after SS_n fell");
    cover property (p_rx_valid_after_command);

    // 4️⃣ SS_n rises after rx_valid: 
    // - within 13 cycles for write ops (000,001)
    // - within 23 cycles for read ops (110,111)
    property p_ss_n_rise_after_rx_valid;
        @(posedge clk) disable iff(!rst_n)
        (rx_valid && (rx_data[9:7] inside {3'b000,3'b001}))
            |-> ##[1:13] SS_n;
    endproperty

    property p_ss_n_rise_after_rx_valid_read;
        @(posedge clk) disable iff(!rst_n)
        (rx_valid && (rx_data[9:7] inside {3'b110,3'b111}))
            |-> ##[1:23] SS_n;
    endproperty

    a_ss_n_rise_after_rx_valid_write: assert property (p_ss_n_rise_after_rx_valid)
        else $error("SS_n not released in 13 cycles after rx_valid (write)");

    a_ss_n_rise_after_rx_valid_read: assert property (p_ss_n_rise_after_rx_valid_read)
        else $error("SS_n not released in 23 cycles after rx_valid (read)");

endmodule
