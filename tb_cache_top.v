`timescale 1ns/1ps
`include "cache_top.v"

module tb_cache_top;

    // Parameters
    localparam ADDRESS_WIDTH = 8;
    localparam DATA_WIDTH    = 32;
    localparam BLOCK_SIZE    = 128;

    // Clock and Reset
    reg clk;
    reg rst_n;

    // CPU Interface
    reg  [ADDRESS_WIDTH-1:0] addr;
    reg                      read;
    reg                      write;
    reg  [DATA_WIDTH-1:0]    w_data;
    wire                     Done;
    wire [DATA_WIDTH-1:0]    r_data;

    // Instantiate DUT
    cache_top #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE),
        .INIT_MEM(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .read(read),
        .write(write),
        .w_data(w_data),
        .Done(Done),
        .r_data(r_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // Reset sequence
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Task: Write to address
    task write_to_cache(input [ADDRESS_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
        begin
            @(posedge clk);
            addr  = a;
            w_data = d;
            write = 1;
            read  = 0;
            wait(Done)
            write = 0;
            $display("Time=%0t | WRITE | Addr=0x%0h | Data=0x%0h", $time, a, d);
        end
    endtask

    // Task: Read from address
    task read_from_cache(input [ADDRESS_WIDTH-1:0] a);
        begin
            @(posedge clk);
            addr  = a;
            read  = 1;
            write = 0;
            wait(Done);
            read  = 0;
            $display("Time=%0t | READ | Addr=0x%0h | Data=0x%0h", $time, a, r_data);
        end
    endtask

    // Monitor
    initial begin
        // $monitor("Time=%0t | Addr=0x%0h | Read=%b | Write=%b | WData=0x%0h | RData=0x%0h | Done=%b",
        //          $time, addr, read, write, w_data, r_data, Done);
    end

    // Test sequence
    initial begin
        $dumpfile("cache_waveform.vcd");       // Name of the VCD file
        $dumpvars(0, tb_cache_top);            // Dump all variables in testbench
        // Wait for reset to complete
        @(posedge rst_n);

        // Write and Read to/from the same address to demonstrate cache fill
//        write_to_cache(8'h10, 32'hDEADBEEF);   // Miss, write after refill
        #20;
         read_from_cache(8'h10);                // Should be a cache hit
         #20;
         read_from_cache(8'h30);                // Should be a cache hit
         #20;
         read_from_cache(8'h11);
         #30;
         read_from_cache(8'h70);
         #30;
         write_to_cache(8'h90, 32'hCAFEBABE);
         #30;
         read_from_cache(8'h90);
        // // Access another block to cause replacement
        // write_to_cache(8'h90, 32'hCAFEBABE);   // Miss, may cause eviction
        // #20;
        // read_from_cache(8'h90);                // Hit again
        // read_from_cache(8'h10);                // Check if replaced

        // // Another address, same index, different tag → conflict
        // write_to_cache(8'h18, 32'h12345678);
        // #20;
        // read_from_cache(8'h18);
        // read_from_cache(8'h10); // Should detect if eviction happened

        // Finish simulation
        #100;
        $finish;
    end

endmodule
