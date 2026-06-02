module SLAVE (MOSI,MISO,SS_n,clk,rst_n,rx_data,rx_valid,tx_data,tx_valid);
localparam IDLE      = 3'b000;
localparam WRITE     = 3'b001;
localparam CHK_CMD   = 3'b010;
localparam READ_ADD  = 3'b011;
localparam READ_DATA = 3'b100;

input            MOSI, clk, rst_n, SS_n, tx_valid;
input      [7:0] tx_data;
output reg [9:0] rx_data;
output reg       rx_valid, MISO;
reg [3:0] counter;
reg       received_address;
reg [2:0] cs, ns;

always @(posedge clk) begin
    if (~rst_n) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        IDLE : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = CHK_CMD;
        end
        CHK_CMD : begin
            if (SS_n)
                ns = IDLE;
            else begin
                if (~MOSI)
                    ns = WRITE;
                else begin
                    if (!received_address) //when equal 0 not 1
                        ns = READ_ADD;  
                    else
                        ns = READ_DATA;
                end
            end
        end
        WRITE : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = WRITE;
        end
        READ_ADD : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = READ_ADD;
        end
        READ_DATA : begin
            if (SS_n)
                ns = IDLE;
            else
                ns = READ_DATA;
        end
        //missing default case
        default: ns = IDLE;
    endcase
end

always @(posedge clk) begin
    if (~rst_n) begin 
        rx_data <= 0;
        rx_valid <= 0;
        received_address <= 0;
        MISO <= 0;
        counter <= 0; //<--- missing
    end
    else begin
        case (cs)
            IDLE : begin
                rx_valid <= 0;
            end
            CHK_CMD : begin
                counter <= 10;      
            end
            WRITE : begin
                if (counter > 0) begin
                    rx_data[counter-1] <= MOSI;
                    counter <= counter - 1;
                end else 
                    rx_valid <= 1;
            end
            READ_ADD : begin
                if (counter > 0) begin
                    rx_data[counter-1] <= MOSI;
                    counter <= counter - 1;
                end else begin
                    rx_valid <= 1;
                    received_address <= 1;
                end
            end
            READ_DATA : begin
                if (tx_valid) begin
                    rx_valid <= 0;
                    if (counter > 0) begin
                        MISO <= tx_data[counter-1];
                        counter <= counter - 1;
                    end
                    else begin
                        received_address <= 0;
                    end   
                end
                else begin
                    if (counter > 0) begin
                        rx_data[counter-1] <= MOSI;
                        counter <= counter - 1;
                    end else begin
                            rx_valid <= 1;
                            counter <= 9; //bug detected
                            received_address <= 0;
                        end
                    end
                end
            endcase
        end
    end
`ifdef SIM
//assertion 1//
a_reset_outputs_low: assert property (@(posedge clk)
      !rst_n |=> (MISO==1'b0 && rx_valid==1'b0 && rx_data==10'b0))
else $error("RESET: outputs not low while rst_n==0.");
c_reset_outputs_low: cover property (@(posedge clk)
      !rst_n |=> (MISO==1'b0 && rx_valid==1'b0 && rx_data==10'b0));

//assertion 2//
a_counter_load_in_chk: assert property (@(posedge clk) disable iff(!rst_n)
    (cs==CHK_CMD && SS_n==0) |=> (counter==4'd10));
c_counter_load_in_chk:  cover  property (@(posedge clk) disable iff(!rst_n)
    (cs==CHK_CMD && SS_n==0) |=> (counter==4'd10));

a_ssn_rxvalid_write: assert property (@(posedge clk) disable iff(!rst_n)
    (((cs==WRITE) || (cs==READ_ADD)) && (counter==4'd10) && (SS_n==1'b0))
        |=> ( ((!rx_valid)[*10] ##1 rx_valid) ##[0:12] (SS_n==1) ))
    else $error("SS_n not released within 0..12 cycles after rx_valid for cs=%0d", cs);
c_ssn_rxvalid_write: cover property (@(posedge clk) disable iff(!rst_n)
    (((cs==WRITE) || (cs==READ_ADD)) && (counter==4'd10) && (SS_n==1'b0))
        |=> ( ((!rx_valid)[*10] ##1 rx_valid) ##[0:12] (SS_n==1) ));

a_ssn_rxvalid_read: assert property (@(posedge clk) disable iff(!rst_n)
    ((cs==READ_DATA) && (counter==4'd10) && !tx_valid && (SS_n==1'b0))
        |=> ( ((!rx_valid)[*10] ##1 rx_valid) ##[0:23] (SS_n==1) ))
    else $error("SS_n not released within 0..23 cycles after rx_valid in READ_DATA");
c_ssn_rxvalid_read: cover property (@(posedge clk) disable iff(!rst_n)
    ((cs==READ_DATA) && (counter==4'd10) && !tx_valid && (SS_n==1'b0))
        |=> ( ((!rx_valid)[*10] ##1 rx_valid) ##[0:23] (SS_n==1) ));

// FSM transition assertions
// IDLE -> CHK_CMD
property prop_idle_to_chk;
    @(posedge clk) disable iff (!rst_n)
        (cs == IDLE && SS_n == 1'b0) |=> (cs == CHK_CMD);
endproperty
assert property (prop_idle_to_chk)
    else $error("[SVA] FSM: IDLE -> CHK_CMD transition failed");
cover property (prop_idle_to_chk);

// IDLE hold while SS_n is high
property prop_idle_hold;
    @(posedge clk) disable iff (!rst_n)
        (cs == IDLE && SS_n == 1'b1) |=> (cs == IDLE);
endproperty
assert property (prop_idle_hold)
    else $error("[SVA] FSM: IDLE did not hold when SS_n stayed high");
cover property (prop_idle_hold);

// CHK_CMD -> IDLE when frame aborts
property prop_chk_to_idle;
    @(posedge clk) disable iff (!rst_n)
        (cs == CHK_CMD && SS_n == 1'b1) |=> (cs == IDLE);
endproperty
assert property (prop_chk_to_idle)
    else $error("[SVA] FSM: CHK_CMD -> IDLE transition failed");
cover property (prop_chk_to_idle);

// CHK_CMD -> WRITE
property prop_chk_to_write;
    @(posedge clk) disable iff (!rst_n)
        (cs == CHK_CMD && SS_n == 1'b0 && MOSI == 1'b0) |=> (cs == WRITE);
endproperty
assert property (prop_chk_to_write)
    else $error("[SVA] FSM: CHK_CMD -> WRITE transition failed");
cover property (prop_chk_to_write);

// CHK_CMD -> READ_ADD
property prop_chk_to_read_add;
    @(posedge clk) disable iff (!rst_n)
        (cs == CHK_CMD && SS_n == 1'b0 && MOSI == 1'b1 && received_address == 1'b0)
            |=> (cs == READ_ADD);
endproperty
assert property (prop_chk_to_read_add)
    else $error("[SVA] FSM: CHK_CMD -> READ_ADD transition failed");
cover property (prop_chk_to_read_add);

// CHK_CMD -> READ_DATA
property prop_chk_to_read_data;
    @(posedge clk) disable iff (!rst_n)
        (cs == CHK_CMD && SS_n == 1'b0 && MOSI == 1'b1 && received_address == 1'b1)
            |=> (cs == READ_DATA);
endproperty
assert property (prop_chk_to_read_data)
    else $error("[SVA] FSM: CHK_CMD -> READ_DATA transition failed");
cover property (prop_chk_to_read_data);

// WRITE holds while SS_n low
property prop_write_hold;
    @(posedge clk) disable iff (!rst_n)
        (cs == WRITE && SS_n == 1'b0) |=> (cs == WRITE);
endproperty
assert property (prop_write_hold)
    else $error("[SVA] FSM: WRITE did not hold while SS_n remained low");
cover property (prop_write_hold);

// WRITE -> IDLE
property prop_write_to_idle;
    @(posedge clk) disable iff (!rst_n)
        (cs == WRITE && SS_n == 1'b1) |=> (cs == IDLE);
endproperty
assert property (prop_write_to_idle)
    else $error("[SVA] FSM: WRITE -> IDLE transition failed");
cover property (prop_write_to_idle);

// READ_ADD holds while SS_n low
property prop_readadd_hold;
    @(posedge clk) disable iff (!rst_n)
        (cs == READ_ADD && SS_n == 1'b0) |=> (cs == READ_ADD);
endproperty
assert property (prop_readadd_hold)
    else $error("[SVA] FSM: READ_ADD did not hold while SS_n remained low");
cover property (prop_readadd_hold);

// READ_ADD -> IDLE
property prop_readadd_to_idle;
    @(posedge clk) disable iff (!rst_n)
        (cs == READ_ADD && SS_n == 1'b1) |=> (cs == IDLE);
endproperty
assert property (prop_readadd_to_idle)
    else $error("[SVA] FSM: READ_ADD -> IDLE transition failed");
cover property (prop_readadd_to_idle);

// READ_DATA holds while SS_n low
property prop_readdata_hold;
    @(posedge clk) disable iff (!rst_n)
        (cs == READ_DATA && SS_n == 1'b0) |=> (cs == READ_DATA);
endproperty
assert property (prop_readdata_hold)
    else $error("[SVA] FSM: READ_DATA did not hold while SS_n remained low");
cover property (prop_readdata_hold);

// READ_DATA -> IDLE
property prop_readdata_to_idle;
    @(posedge clk) disable iff (!rst_n)
        (cs == READ_DATA && SS_n == 1'b1) |=> (cs == IDLE);
endproperty
assert property (prop_readdata_to_idle)
    else $error("[SVA] FSM: READ_DATA -> IDLE transition failed");
cover property (prop_readdata_to_idle);
    
`endif
endmodule

