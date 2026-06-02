package shared_pkg;
    localparam MEM_DEPTH = 256;
    localparam ADDR_SIZE = $clog2(MEM_DEPTH);
    
    // State machine states for design
    typedef enum bit [2 : 0] {IDLE, CHK_CMD, WRITE, READ_ADD, READ_DATA} STATE_e;

    // Coverage-specific command states
    typedef enum bit [2 : 0] {IDLE_cov = 3'b000, WA_cov = 3'b001, WD_cov = 3'b010, RA_cov = 3'b110, RD_cov = 3'b111} CMD_cov_e;
    CMD_cov_e cs_cov;

endpackage