module cache #(
    parameter ADDRESS_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter BLOCK_SIZE = 128
)
(
    // Global Signals
    input                       clk,
    input                       rst_n,

    // CPU to Cache
    input [ADDRESS_WIDTH-1:0]   addr,
    input                       read,
    input                       write,
    input [DATA_WIDTH-1:0]      w_data,

    // Cache to CPU
    output reg                  Done,
    output reg [DATA_WIDTH-1:0] r_data,

    // Cache to Main Memory
    output reg                      cache_req,
    output reg                      cache_write,
    output reg [ADDRESS_WIDTH-1:0]  cache_addr,
    output reg [BLOCK_SIZE-1:0]     cache_wdata,

    // Main memory to Cache
    input                       mem_valid,
    input [BLOCK_SIZE-1:0]      mem_data
);

// Constants
localparam INDEX_WIDTH = 3;
localparam OFFSET_WIDTH = 2;
localparam TAG_WIDTH = ADDRESS_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;
localparam NO_OF_SETS = 8;

// States
localparam  IDLE        = 2'b00,
            LOOKUP      = 2'b01,
            WRITEBACK   = 2'b10,
            REFILL      = 2'b11;

// State Registers
reg [1:0] state;
reg [1:0] next_state;

// Address decomposition
wire [TAG_WIDTH-1:0] tag = addr[7:5];
wire [INDEX_WIDTH-1:0] index = addr[4:2];
wire [OFFSET_WIDTH-1:0] offset = addr[1:0];

// Cache Structure
reg [TAG_WIDTH-1:0]  Tag         [0:NO_OF_SETS-1][1:0];
reg [BLOCK_SIZE-1:0] Data_block  [0:NO_OF_SETS-1][1:0];
reg                  valid       [0:NO_OF_SETS-1][1:0];
reg                  dirty       [0:NO_OF_SETS-1][1:0];
reg                  lru         [0:NO_OF_SETS-1];

wire way0 = valid[index][0] && (Tag[index][0] == tag);
wire way1 = valid[index][1] && (Tag[index][1] == tag);

wire HIT = way0 || way1 ;

// Word extraction from block
function [DATA_WIDTH-1:0] extract_word;
    input [BLOCK_SIZE-1:0] block;
    input [1:0]            offset;
    begin
        extract_word = block[offset * DATA_WIDTH +: DATA_WIDTH];
    end
endfunction

// Word Insertation into Block
function [BLOCK_SIZE-1:0] insert_word;
    input [BLOCK_SIZE-1:0] block;
    input [1:0]            offset;
    input [DATA_WIDTH-1:0] word;
    begin
        insert_word = block;
        insert_word[offset * DATA_WIDTH +: DATA_WIDTH] = word;
    end
endfunction

// State Transistion
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        state <= IDLE;
    else
        state <= next_state;
end

integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < NO_OF_SETS; i = i + 1) begin
            valid[i][0] <= 1'b0;
            valid[i][1] <= 1'b0;
            dirty[i][0] <= 1'b0;
            dirty[i][1] <= 1'b0;
        end
    end
    else begin
        case(state)
            IDLE : begin
                Done = 1'b0;
                cache_req <= 1'b0;
                cache_write <= 1'b0;
                next_state <= (read || write) ? LOOKUP : IDLE;
            end

            LOOKUP : begin
                if(HIT) begin
                    if(way0) begin
                        if(read) 
                            r_data <= extract_word(Data_block[index][0],offset);
                        else if(write) begin
                            dirty[index][0]<= 1'b1;
                            Data_block[index][0] <= insert_word(Data_block[index][0], offset, w_data);
                        end
                        lru[index] = 'b1;   // Accessed Latest first Set
                    end
                    else begin
                        if(read)
                            r_data <= extract_word(Data_block[index][1],offset);
                        else if(write) begin
                            dirty[index][1]<= 1'b1;
                            Data_block[index][1] <= insert_word(Data_block[index][1], offset, w_data);
                        end
                        lru[index] <= 1'b0; // Accesed Latest Second Set
                    end
                    Done <= 1'b1;
                    next_state <= IDLE;
                end
                else begin
                    if(lru[index] == 0  && dirty[index][0]) begin
                        cache_req   <= 1'b1;
                        cache_write <= 1'b1;
                        cache_addr  <= {Tag[index][0], index, 2'b00};
                        cache_wdata <= Data_block[index][0];
                        next_state <= WRITEBACK;
                    end
                    else if (lru[index] == 1 && dirty[index][1]) begin
                        cache_req   <= 1'b1;
                        cache_write <= 1'b1;
                        cache_addr  <= {Tag[index][1], index, 2'b00};
                        cache_wdata <= Data_block[index][1];
                        next_state <= WRITEBACK;
                    end
                    else begin
                        cache_req   <= 1'b1;
                        cache_write <= 1'b0;
                        cache_addr  <= {tag, index, 2'b00};
                        next_state <= REFILL;
                    end
                end
            end

            WRITEBACK : begin
                if (mem_valid) begin
                    cache_req <= 1'b1;
                    cache_write <= 1'b0;
                    cache_addr <= {tag, index, 2'b00};
                    next_state <= REFILL;
                end 
            end

            REFILL: begin
                if (mem_valid) begin
                    cache_req <= 1'b0;

                    if (lru[index] == 0) begin
                        Data_block[index][0] <= mem_data;
                        Tag[index][0] <= tag;
                        valid[index][0] <= 1'b1;
                        dirty[index][0] <= 1'b0;
                        if (read) 
                            r_data <= extract_word(mem_data, offset);
                        else if (write) begin
                            Data_block[index][0] <= insert_word(mem_data, offset, w_data);
                            dirty[index][0] <= 1'b1;
                        end
                        lru[index] <= 1;

                    end else begin
                        Data_block[index][1] <= mem_data;
                        Tag[index][1] <= tag;
                        valid[index][1] <= 1'b1;
                        dirty[index][1] <= 1'b0;
                        if (read) 
                            r_data <= extract_word(mem_data, offset);
                        else if (write) begin
                            Data_block[index][1] <= insert_word(mem_data, offset, w_data);
                            dirty[index][1] <= 1'b1;
                        end
                        lru[index] <= 1'b0;
                    end
                    Done <= 1'b1;
                    next_state <= IDLE;
                end
            end

            default : next_state <= IDLE;

        endcase
    end
end

endmodule 