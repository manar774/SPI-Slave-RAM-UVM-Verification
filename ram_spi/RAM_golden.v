module RAM_golden (clk,rst_n,rx_valid,din,dout,tx_valid);
parameter MEM_DEPTH=256;
parameter ADDR_SIZE=8;
input [9:0] din;
input clk,rst_n,rx_valid;
output reg [7:0] dout;
output reg tx_valid;
reg[7:0] mem[MEM_DEPTH-1:0];
reg [ADDR_SIZE-1:0] w_addr, r_addr;
always@(posedge clk ) begin
    if(~rst_n) begin
        dout<=0;
        tx_valid<=0;
         w_addr <= 0;
        r_addr <= 0; 
    end
    else begin
        if(rx_valid) begin
            if(~din[9]) begin
                case(din[8]) 
                0: begin 
                    w_addr<=din[7:0] ;
                    tx_valid<=0;
                end
                1: begin 
                    mem[w_addr]<=din[7:0];
                    tx_valid<=0;
                end
                endcase
            end
            else if(din[9]) begin
                case(din[8]) 
                0: begin
                     r_addr<=din[7:0] ;
                     tx_valid<=0;
                end
                1: begin 
                    dout<=mem[r_addr];
                    tx_valid<=1;
                end
                endcase  
            end
        end
    end
end
endmodule 
