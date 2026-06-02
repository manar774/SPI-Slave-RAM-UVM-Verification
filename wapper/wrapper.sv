
    module wrapper (MOSI, MISO, SS_n, clk, rst_n);
  
    // Input and output ports
    input  MOSI, clk, rst_n, SS_n;
    output MISO;

    wire [9:0] rx_data;
    wire rx_valid;
    wire [7:0] tx_data;
    wire tx_valid;
    // Instantiate SLAVE module
    SLAVE slave (
        .MOSI(MOSI),
        .MISO(MISO),
        .SS_n(SS_n),
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_data(tx_data),
        .tx_valid(tx_valid)
    );

    // Instantiate RAM module
    RAM memory (
        .clk(clk),
        .rst_n(rst_n),
        .din(rx_data),
        .rx_valid(rx_valid),
        .dout(tx_data),
        .tx_valid(tx_valid)
    );
 
    // Assertions
    `ifdef WRAPPER_SIM 
        // Check reset values
        always_comb begin
            if (!rst_n) begin
                wrap_rst_tx_valid_a:    assert final (tx_valid == 0);
                wrap_rst_rx_valid_a:    assert final (rx_valid == 0);
                wrap_rst_tx_data_a:     assert final (tx_data == 0);
                wrap_rst_rx_data_a:     assert final (rx_data == 0);
                wrap_rst_miso_a:        assert final (MISO == 0);
            end
        end

        // Check MISO stability during non-read operations
        property wrap_miso_stable_pr;
            @(posedge clk) disable iff(!rst_n) (SS_n == 0) ##1 ((!SS_n) && 
                ({$past(MOSI, 10), $past(MOSI, 9), $past(MOSI, 8)} != 3'b111)) |=> $stable(MISO);
        endproperty
        wrap_miso_stable_a:    assert property (wrap_miso_stable_pr);
        wrap_miso_stable_cov:  cover  property (wrap_miso_stable_pr);
        // Check rx_valid
        property wrap_rx_valid_pr;
            @(posedge clk) disable iff(!rst_n) (SS_n) ##1 (!SS_n) [*12:22] |=> (rx_valid);  
        endproperty
        wrap_rx_valid_a: assert property (wrap_rx_valid_pr);
        wrap_rx_valid_cov: cover property (wrap_rx_valid_pr);

        // Check tx_valid
        property wrap_tx_valid_pr;
            @(posedge clk) disable iff(!rst_n) (SS_n) ##1 (!SS_n) [*12:22] ##1 ((!SS_n) && 
                ({$past(MOSI, 10), $past(MOSI, 9), $past(MOSI, 8)} == 3'b111)) |=> (tx_valid);  
        endproperty
        wrap_tx_valid_a: assert property (wrap_tx_valid_pr);
        wrap_tx_valid_cov: cover property (wrap_tx_valid_pr);

        // Check rx_data
        property wrap_rx_data_pr;
            @(posedge clk) disable iff(!rst_n) (SS_n) ##1 (!SS_n) [*12:22] |=> (rx_valid |-> (rx_data == 
                {$past(MOSI, ADDR_SIZE+1), $past(MOSI, ADDR_SIZE), $past(MOSI, ADDR_SIZE-1), $past(MOSI, ADDR_SIZE-2),
                 $past(MOSI, ADDR_SIZE-3), $past(MOSI, ADDR_SIZE-4), $past(MOSI, ADDR_SIZE-5), $past(MOSI, ADDR_SIZE-6),
                 $past(MOSI, ADDR_SIZE-7), $past(MOSI, ADDR_SIZE-8)}));
        endproperty
        wrap_rx_data_a: assert property (wrap_rx_data_pr);
        wrap_rx_data_cov: cover property (wrap_rx_data_pr);
    `endif 
endmodule