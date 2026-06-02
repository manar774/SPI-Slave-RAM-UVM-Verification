# SPI UVM Verification Project

A complete **Universal Verification Methodology (UVM)** testbench for an SPI (Serial Peripheral Interface) Slave and its integration with a RAM module. The project is organized in three verification tiers: standalone SPI Slave verification, standalone RAM verification, and full Wrapper (SPI Slave + RAM) integration verification.

---

## Table of Contents

- [Overview](#overview)
- [Design Under Test](#design-under-test)
- [Project Structure](#project-structure)
- [UVM Architecture](#uvm-architecture)
- [Verification Features](#verification-features)
- [Simulation Setup](#simulation-setup)
- [Coverage Results](#coverage-results)
- [File Descriptions](#file-descriptions)

---

## Overview

This project verifies a synchronous SPI Slave module interfaced with a 256×8-bit RAM. The SPI Slave decodes serial frames into parallel commands, and the RAM executes four operations based on a 2-bit command encoded in the received data:

| Command Bits `[9:8]` | Operation          |
|----------------------|--------------------|
| `2'b00`              | Write Address (WA) |
| `2'b01`              | Write Data (WD)    |
| `2'b10`              | Read Address (RA)  |
| `2'b11`              | Read Data (RD)     |

---

## Design Under Test

### SPI Slave (`SPI_slave.v`)

A Moore FSM-based SPI slave with five states:

```
IDLE → CHK_CMD → WRITE
                → READ_ADD → READ_DATA
```

- **Inputs:** `MOSI`, `SS_n`, `clk`, `rst_n`, `tx_valid`, `tx_data[7:0]`
- **Outputs:** `MISO`, `rx_data[9:0]`, `rx_valid`
- Receives 10-bit serial frames (2-bit command + 8-bit payload)
- Shifts out `tx_data` on `MISO` during READ_DATA phase when `tx_valid` is asserted

### RAM (`RAM.v`)

- 256 × 8-bit synchronous RAM
- Decodes `rx_data[9:8]` to select the operation
- Asserts `tx_valid` and drives `dout` only on a Read Data command

### Wrapper (`SPI_wrapper.v`)

Structural top-level integrating `SLAVE` and `RAM`, exposing only the raw SPI interface (`MOSI`, `MISO`, `SS_n`, `clk`, `rst_n`).

---

## Project Structure

```
SPI_UVM_Project/
├── Description/                   # Reference design and project brief
│   ├── SPI_slave.v                # RTL: SPI Slave FSM
│   ├── RAM.v                      # RTL: 256×8 synchronous RAM
│   ├── SPI_wrapper.v              # RTL: SPI + RAM wrapper
│   └── UVM Project.pdf            # Project specification document
│
├── slave/                         # Tier 1 – SPI Slave UVM testbench
│   ├── SPI_slave.v                # DUT
│   ├── slave_golden.v             # Reference model
│   ├── slave_if.sv                # Virtual interface
│   ├── slave_seq_item.sv          # Transaction / sequence item
│   ├── slave_seq.sv               # Reset & main sequences
│   ├── slave_sequencer.sv
│   ├── slave_driver.sv
│   ├── slave_monitor.sv
│   ├── slave_scoreboard.sv        # Self-checking scoreboard
│   ├── slave_cov.sv               # Functional coverage
│   ├── slave_agent.sv
│   ├── slave_env.sv
│   ├── slave_test.sv
│   ├── slave_top.sv               # Top-level testbench module
│   ├── slave_config_obj.sv
│   ├── slave_sva.sv               # SystemVerilog assertions (SVA)
│   ├── src_list.list              # Compilation filelist
│   ├── run_slave.do               # ModelSim run script
│   ├── slave_top.ucdb             # Coverage database
│   └── slave_rpt.txt              # Coverage report
│
├── ram_spi/                       # Tier 2 – RAM UVM testbench
│   ├── RAM.v / RAM_golden.v
│   ├── ram_if.sv
│   ├── ram_seq_item.sv / ram_sequence.sv
│   ├── ram_driver.sv / ram_monitor.sv
│   ├── ram_scoreboard.sv / ram_coverage.sv
│   ├── ram_agent.sv / ram_env.sv
│   ├── ram_test.sv / ram_top.sv
│   ├── ram_sva.sv
│   ├── src_list.list
│   └── ram.do
│
└── wapper/                        # Tier 3 – Wrapper integration testbench
    ├── SPI_slave.v / RAM.v / wrapper.sv
    ├── slave_golden.v / RAM_golden.v
    ├── shared_pkg.sv              # Shared command enum (WA/WD/RA/RD)
    ├── *_if.sv                    # Interfaces: wrapper, slave, ram
    ├── *_seq_item.sv              # Sequence items per sub-block
    ├── *_sequence*.sv             # Write-only, read-only, write-read sequences
    ├── *_driver.sv / *_monitor.sv
    ├── *_scoreboard.sv / *_coverage.sv
    ├── *_agent.sv / *_env.sv
    ├── wrapper_test.sv            # Top-level UVM test
    ├── wrapper_top.sv
    ├── *_sva.sv                   # Assertions per sub-block
    ├── src_list.list
    ├── run.do
    └── fcover_report.txt
```

---

## UVM Architecture

Each verification tier follows the standard UVM layered architecture:

```
┌─────────────────────────────────────────────┐
│                  uvm_test                   │
│  ┌───────────────────────────────────────┐  │
│  │              uvm_env                  │  │
│  │  ┌──────────────┐  ┌───────────────┐  │  │
│  │  │  uvm_agent   │  │  Scoreboard   │  │  │
│  │  │ ┌──────────┐ │  │  (self-check) │  │  │
│  │  │ │Sequencer │ │  └───────────────┘  │  │
│  │  │ │ Driver   │ │  ┌───────────────┐  │  │
│  │  │ │ Monitor  │ │  │   Coverage    │  │  │
│  │  │ └──────────┘ │  └───────────────┘  │  │
│  │  └──────────────┘                     │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
           │ virtual interface │
    ┌──────▼───────────────────▼──────┐
    │         DUT (RTL)               │
    └─────────────────────────────────┘
```

### Wrapper Test — Multi-Environment

The wrapper test instantiates **three independent environments** simultaneously:

- `wrapper_env` (ACTIVE) — drives the wrapper-level SPI interface
- `slave_env` (PASSIVE) — monitors SPI slave signals for scoreboard checking
- `ram_env` (PASSIVE) — monitors RAM signals for scoreboard checking

### Sequences

| Sequence                       | Tier    | Description                                   |
|-------------------------------|---------|-----------------------------------------------|
| `slave_reset_sequence`        | Slave   | 16-cycle balanced reset with 50% duty cycle   |
| `slave_main_sequence`         | Slave   | Drives all four SPI commands with constraints |
| `wrapper_reset_sequence`      | Wrapper | Resets the full design                        |
| `wrapper_write_only_sequence` | Wrapper | Write address then write data transactions    |
| `wrapper_read_only_sequence`  | Wrapper | Read address then read data transactions      |
| `wrapper_write_read_sequence` | Wrapper | Combined write followed by readback           |

---

## Verification Features

### Constrained-Random Stimulus

The `slave_seq_item` applies the following constraints:

- `rst_n`: 90% active-high, 10% reset
- `SS_n`: biased low (active) — 12× when `tx_valid=0`, 22× when `tx_valid=1`
- `MOSI_array`: generates all four distinct command headers (`WA`, `WD`, `RA`, `RD`) in each randomization
- `cmd_map_c`: ensures `rx_data[9:7]` maps to a valid command
- `tx_valid_c`: forces `tx_valid=1` only for Read Data (`RD`) transactions

### Golden Reference Model

Both the `slave_golden.v` and `RAM_golden.v` serve as independent reference models. The scoreboard compares DUT outputs (`MISO`, `rx_valid`, `rx_data`) against reference outputs on every transaction.

### SystemVerilog Assertions (SVA)

Each sub-block includes a dedicated `*_sva.sv` file with:

- **Assert properties** verifying all FSM state transitions
- **Cover properties** confirming all transitions are exercised
- Reset output checks, counter-load checks, and `SS_n`/`rx_valid` protocol checks

---

## Simulation Setup

### Requirements

- **Simulator:** ModelSim / QuestaSim (supports `-cover bcesft` and UVM)
- **Language standard:** SystemVerilog IEEE 1800, UVM 1.2

### Running the SPI Slave Testbench

```tcl
cd slave/
vsim -do run_slave.do
```

The script:
1. Compiles all files in `src_list.list` with coverage enabled (`-cover bcesft`)
2. Launches simulation with UVM debug controls
3. Adds all interface signals to the waveform viewer
4. Runs to completion
5. Excludes two unreachable lines from the coverage report
6. Saves coverage database to `slave_top.ucdb`

### Running the Wrapper Testbench

```tcl
cd wapper/
vsim -do run.do
```

The script compiles with `+cover -covercells`, adds all three interface signal groups to waveforms (`wrapperif`, `ramif`, `slaveif`), and saves the coverage database.

---

## Coverage Results

### SPI Slave — Simulation Report (`slave_rpt.txt`)

| Metric                   | Result       |
|--------------------------|--------------|
| Total coverage (filtered)| **92.56%**   |
| Directive coverage       | **100.00%**  |
| Assertion failures       | **0**        |
| Assertions passed        | **15 / 15**  |

All 15 SVA assertions pass with zero failures, and all 16 cover directives are hit (100% directive coverage).

**Functional coverpoints (slave):**

| Coverpoint         | Bins covered            |
|--------------------|-------------------------|
| `rx_data_cp`       | WA, WD, RA, RD          |
| `ss_cp`            | `SS_n` low-13 and low-23 pulse widths |
| `cp_mosi_cmd`      | All four command transitions on MOSI |
| `cross_ssn_mosi`   | Cross of `SS_n` width × command type |

**Functional coverpoints (wrapper):**

| Coverpoint         | Bins covered                          |
|--------------------|---------------------------------------|
| `W_cmd_cov_cp`     | WA, WD                                |
| `W_rst_cov_cp`     | Reset active / inactive               |
| `ssn_cov_cp`       | `SS_n` active / inactive              |
| `MISO_cov_cp`      | MISO = 0 / 1                          |
| `cmd_miso_cross`   | Write-phase (MISO=0 during WA/WD)     |

---

## File Descriptions

| File | Purpose |
|------|---------|
| `SPI_slave.v` | RTL DUT — 5-state Moore FSM SPI slave |
| `RAM.v` | RTL DUT — 256×8 synchronous RAM with 4-command decode |
| `SPI_wrapper.v` / `wrapper.sv` | Structural integration of SLAVE + RAM |
| `slave_golden.v` / `RAM_golden.v` | Reference models for scoreboard self-checking |
| `*_if.sv` | Virtual interface declarations |
| `*_seq_item.sv` | UVM transaction class with randomization constraints |
| `*_seq.sv` / `*_sequence*.sv` | UVM sequence library |
| `*_driver.sv` | Converts sequence items to pin-level DUT stimulus |
| `*_monitor.sv` | Samples DUT outputs and broadcasts via analysis port |
| `*_scoreboard.sv` | Compares DUT vs. reference model; reports pass/fail counts |
| `*_cov.sv` / `*_coverage.sv` | Functional coverage collector with covergroups |
| `*_agent.sv` | Bundles sequencer, driver, and monitor |
| `*_env.sv` | Top-level UVM environment |
| `*_test.sv` | Test class — configures env and starts sequences |
| `*_top.sv` | SystemVerilog top module — DUT + testbench + clock gen |
| `*_sva.sv` | Concurrent SVA assertions and cover properties |
| `shared_pkg.sv` | Shared command enum (`WA`, `WD`, `RA`, `RD`) |
| `src_list.list` | Compilation filelist for ModelSim `-f` flag |
| `*.do` | ModelSim TCL run scripts |
| `*.ucdb` | Unified coverage database (ModelSim format) |
| `*_rpt.txt` / `fcover_report.txt` | Human-readable coverage reports |
