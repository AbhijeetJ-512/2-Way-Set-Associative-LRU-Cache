# 2-Way Set-Associative LRU CPU Cache Simulation

## Overview

This project implements a **2-way set-associative CPU cache** with **Least Recently Used (LRU)** replacement policy in Verilog. It includes an integrated main memory module and a top-level testbench to simulate typical cache operations such as reads, writes, hits, misses, writebacks, and refills.

The cache is designed to handle memory blocks efficiently with configurable parameters and simulates realistic memory behavior with latency and block transfers.

---

## Features

- ✅ 2-Way Set Associativity
- ✅ LRU Replacement Policy
- ✅ Configurable Address, Data, and Block Sizes
- ✅ Read & Write Support with Dirty Bit Tracking
- ✅ Write-Back and Write-Allocate Policy
- ✅ Main Memory Emulation with Optional Initialization
- ✅ Synthesizable RTL
- ✅ Testbench for Full Cache Behavior Simulation

---

## Parameters

The design supports the following configurable parameters (defined via `parameter`):

| Parameter        | Description                          | Default Value |
|------------------|--------------------------------------|---------------|
| `ADDRESS_WIDTH`  | Address bus width                    | `8`           |
| `DATA_WIDTH`     | Width of a word                      | `32` bits     |
| `BLOCK_SIZE`     | Size of one cache block              | `128` bits    |
| `INIT_MEM`       | Enable memory initialization         | `1` (enabled) |

---

## How It Works

1. **Address Decomposition:** Address is split into tag, index, and offset.
2. **Lookup Stage:** Determines hit/miss by comparing tags and valid bits.
3. **Hit:** Access data directly and update LRU.
4. **Miss:**
   - If dirty, **write back** the block.
   - Otherwise, **refill** from main memory.
5. **Refill Stage:** Fetched data is written into the cache with LRU update.

---

## Design Highlights
- Efficient block-based memory access
- LRU bit for dynamic victim selection
- Dirty bit for minimizing unnecessary writes
- Modular architecture suitable for integration with processors