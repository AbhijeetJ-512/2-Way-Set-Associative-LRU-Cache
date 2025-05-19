module main_mem #(
    parameter ADDRESS_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter BLOCK_SIZE = 128,
    parameter INIT_MEM = 0
) (
    // Global Signals
    input                       clk,
    input                       rst_n,

    // Cache to Main Memory Interface
    input                      cache_req,
    input                      cache_write,
    input [ADDRESS_WIDTH-1:0]  cache_addr,
    input [BLOCK_SIZE-1:0]     cache_wdata,

    // Main Memory to Cache Interface
    output reg                  mem_valid,
    output reg [BLOCK_SIZE-1:0] mem_data
);

// Calculate number of words per block and memory depth
localparam WORDS_PER_BLOCK = BLOCK_SIZE / DATA_WIDTH;
localparam MEM_DEPTH = (1 << ADDRESS_WIDTH);

// Main Memory Declaration
reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

// Internal Signals
reg [ADDRESS_WIDTH-1:0] addr_reg;
reg [1:0] state;
localparam IDLE = 2'd0, WAIT = 2'd1, RESP = 2'd2;

integer i;

// Optional Initialization
generate
    if (INIT_MEM) begin : init_memory
        initial begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                mem[i] = i;
            end
        end
    end
endgenerate

// Main FSM Logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        mem_valid <= 1'b0;
        mem_data  <= {BLOCK_SIZE{1'b0}};
        addr_reg  <= {ADDRESS_WIDTH{1'b0}};
    end else begin
        case (state)
            IDLE: begin
                mem_valid <= 1'b0;
                if (cache_req) begin
                    addr_reg <= cache_addr;
                    state <= WAIT;
                end
            end

            WAIT: begin
                // One-cycle wait to simulate memory latency
                state <= RESP;
            end

            RESP: begin
                if (cache_write) begin
                    // Unpack and write BLOCK_SIZE bits to memory
                    for (i = 0; i < WORDS_PER_BLOCK; i = i + 1) begin
                        mem[addr_reg + i] <= cache_wdata[i*DATA_WIDTH +: DATA_WIDTH];
                    end
                    mem_valid <= 1'b1; 
                end else begin
                    // Pack memory words into mem_data
                    for (i = 0; i < WORDS_PER_BLOCK; i = i + 1) begin
                        mem_data[i*DATA_WIDTH +: DATA_WIDTH] <= mem[addr_reg + i];
                    end
                    mem_valid <= 1'b1;
                end
                state <= IDLE;
            end
        endcase
    end
end
endmodule
