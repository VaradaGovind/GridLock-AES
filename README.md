# 🔐 GridLock AES-128 Hardware Accelerator

![Language](https://img.shields.io/badge/Language-SystemVerilog-blue)
![Platform](https://img.shields.io/badge/Platform-Xilinx%20Vivado-red)
![Target](https://img.shields.io/badge/Target-Artix--7%20(XC7A100T)-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Fully%20Implemented-brightgreen)

## 📌 Overview

**GridLock AES** is a high-performance, area-optimized AES-128 encryption engine designed for FPGA-based security applications. It features a dual-interface architecture: **AXI4-Lite** for secure register-based key configuration and **AXI4-Stream** for high-throughput data processing.

The core utilizes an iterative architecture with a **BRAM-less S-Box** implementation (using Composite Field arithmetic), making it ideal for designs where memory resources are scarce but high security is required.

---

## 📊 Hardware Utilization & Metrics
Synthesized and routed using Xilinx Vivado 2022.2 for the **Artix-7 XC7A100T-1** fabric. The design successfully meets all timing constraints at a target frequency of 150 MHz.

| Metric | Value |
| :--- | :--- |
| **Max Frequency ($F_{max}$)** | 150 MHz |
| **Worst Negative Slack (WNS)** | +1.049 ns |
| **Look-Up Tables (LUTs)** | 2,581 (~4%) |
| **Registers (Flip-Flops)** | 539 (< 1%) |
| **Block RAM (BRAM)** | 0 (Optimized) |
| **Total On-Chip Power** | 1.585 W |

---

## ✨ Key Features

### ✔ Hybrid Interface Design
* **AXI4-Lite Slave:** Handles the 128-bit secret key expansion and status monitoring (Ready/Busy/Valid flags).
* **AXI4-Stream (Slave/Master):** 128-bit wide data path for plaintext input and ciphertext output, supporting backpressure through `tready`/`tvalid` handshaking.

### ✔ Architectural Optimizations
* **Iterative Core:** Processes one round per clock cycle (11 cycles total per 128-bit block) to minimize hardware area while maintaining Gbps throughput.
* **Composite Field S-Box:** Unlike standard LUT-based designs, this core implements the Rijndael S-Box using Galois Field $GF(2^4)$ inversion math, consuming 0 BRAM.
* **Fixed Combinatorial Loops:** Optimized Key Schedule logic ensuring stable physical implementation without logic feedback errors.

---

## 🚀 Verification & Results

The design has been verified using a self-checking SystemVerilog testbench against the **NIST FIPS-197 KAT (Known Answer Test)** vectors.

**Simulation Success:**
* Confirmed 128-bit encryption matching official NIST ciphertext.
* Verified AXI-Stream flow control and handshaking under stall conditions.
* Integrated Watchdog timer for FSM safety.

> Full reports and verification waveforms can be found in the [Results](./Results/) folder.

---

## 📂 Directory Structure
```text
GridLock-AES/
│
├── GridLock_AES/              # Vivado Project Root
│   └── GridLock_AES.srcs/
│       ├── sources_1/         # RTL: Wrapper, Core, S-Box, Key Expand
│       ├── sim_1/             # Testbench: NIST KAT Self-Checking TB
│       └── constrs_1/         # Constraints: 150MHz Timing definitions
│
├── Results/                   # Implementation Proofs & Reports
│   ├── timing_report.txt      # Slack and Clock Frequency analysis
│   ├── utilization_report.txt # Resource consumption (LUT/FF)
│   ├── power_report.txt       # Thermal and Power estimates
│   ├── TB_Result.png          # Simulation Success Waveform
│   └── Map.png                # Logic Placement Map
│
├── LICENSE                    # MIT License
└── README.md                  # Project Documentation
