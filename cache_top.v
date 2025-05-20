`include "cache.v"
`include "main_mem.v"
module cache_top #(
    parameter ADDRESS_WIDTH = 8,
    parameter DATA_WIDTH    = 32,
    parameter BLOCK_SIZE    = 128,
    parameter INIT_MEM      = 0
)(
    // Global Signals
    input                     clk,
    input                     rst_n,

    // CPU Interface
    input  [ADDRESS_WIDTH-1:0] addr,
    input                      read,
    input                      write,
    input  [DATA_WIDTH-1:0]    w_data,
    output                     Done,
    output [DATA_WIDTH-1:0]    r_data
);

    // Internal Signals
    wire                      cache_req;
    wire                      cache_write;
    wire [ADDRESS_WIDTH-1:0]  cache_addr;
    wire [BLOCK_SIZE-1:0]     cache_wdata;
    wire                      mem_valid;
    wire [BLOCK_SIZE-1:0]     mem_data;

    // Instantiate Cache
    cache #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) cache_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .read(read),
        .write(write),
        .w_data(w_data),
        .Done(Done),
        .r_data(r_data),
        .cache_req(cache_req),
        .cache_write(cache_write),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .mem_valid(mem_valid),
        .mem_data(mem_data)
    );

    // Instantiate Main Memory
    main_mem #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE),
        .INIT_MEM(INIT_MEM)
    ) main_mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cache_req(cache_req),
        .cache_write(cache_write),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .mem_valid(mem_valid),
        .mem_data(mem_data)
    );

endmodule
