
interface wrapper_if (input clk);
parameter MEM_DEPTH = 256;
parameter ADDR_SIZE=8;
    logic rst_n, SS_n, MOSI, MISO;
endinterface