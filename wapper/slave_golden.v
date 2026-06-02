module slave_golden (MOSI,MISO,SS_n,clk,rst_n,rx_data,rx_valid,tx_data,tx_valid);
input MOSI;
input clk, rst_n, SS_n, tx_valid;
input [7:0] tx_data;
output reg [9:0] rx_data;
output reg rx_valid, MISO;
reg [3:0] counter;
reg received_address;
reg [2:0] cs, ns;
localparam [2:0]
    IDLE      = 3'b000,
    WRITE     = 3'b001,
    CHK_CMD   = 3'b010,
    READ_ADD  = 3'b011,
    READ_DATA = 3'b100;

always @(posedge clk) begin
    if (~rst_n) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end
always @(*) begin
ns = cs; 
case (cs)
    IDLE: begin
    if (SS_n) ns = IDLE; else ns = CHK_CMD;
    end
    CHK_CMD: begin
    if (SS_n) ns = IDLE;
    else if (~MOSI) ns = WRITE;                  
    else if (!received_address) ns = READ_ADD;   
    else ns = READ_DATA;                         
    end
    WRITE:     ns = (SS_n ? IDLE : WRITE);
    READ_ADD:  ns = (SS_n ? IDLE : READ_ADD);
    READ_DATA: ns = (SS_n ? IDLE : READ_DATA);

    default:   ns = IDLE;
endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
      rx_data          <= 10'b0;
      rx_valid         <= 1'b0;
      MISO             <= 1'b0;
      counter          <= 4'd0;
      received_address <= 1'b0;
      end else begin
    case (cs)
        IDLE: begin
            rx_valid <= 1'b0;
        end
        CHK_CMD: counter <= 10; 
        WRITE: begin
        // Receive 10 bits MSB-first into rx_data[9:0]
        if (counter > 0) begin
            rx_data[counter-1] <= MOSI;
            counter <= counter - 1;
        end else rx_valid <= 1'b1; 
        end

        READ_ADD: begin
        // Receive 10-bit address
        if (counter > 0) begin
            rx_data[counter-1] <= MOSI;
            counter <= counter - 1;
        end else begin
            rx_valid         <= 1'b1;
            received_address <= 1'b1;
        end
            end

        READ_DATA: begin
        if (tx_valid) begin
            rx_valid <=0;
            if (counter != 0) begin
            MISO <= tx_data[counter-1]; 
            counter <= counter - 1;
            end else begin
                received_address <= 1'b0; 
            end
        end else begin
            // Receive 8 bits from MOSI
            if (counter != 0) begin
            rx_data[counter-1] <= MOSI; // fill bits [7..0]
            counter            <= counter - 1;
            end else begin
                rx_valid <= 1'b1; 
                counter  <= 9;    
                received_address <= 1'b0;
            end
        end
        end
        endcase
      end
    end

endmodule


