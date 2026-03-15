# 🚀 AXI4-Lite Design and Verification

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Protocol](https://img.shields.io/badge/Protocol-AMBA_AXI4--Lite-orange.svg)](https://developer.arm.com/documentation/ihi0022/e/)
[![Verification](https://img.shields.io/badge/Verification-Functional-success.svg)](#)

## 📋 Overview
This project presents a robust design and comprehensive verification environment for the **AMBA AXI4-Lite** protocol. Written in **SystemVerilog**, the project includes fully compliant Master and Slave modules, alongside a rigorously structured testbench architecture. 

The implementation focuses on reliable, low-latency, point-to-point communication ideal for memory-mapped register interfaces, demonstrating both Register Transfer Level (RTL) design skills and advanced verification techniques.

---

## 🏛️ RTL Design Architecture
The core design consists of modular and scalable AXI4-Lite compliant Master and Slave components.

- **Channel Handling:** Properly implemented the five distinct AXI4-Lite channels:
  - 📥 Read Address Channel (`AR`)
  - 📤 Read Data Channel (`R`)
  - 📥 Write Address Channel (`AW`)
  - 📤 Write Data Channel (`W`)
  - 📩 Write Response Channel (`B`)
- **VALID/READY Handshaking:** Mastered the implementation of the complex `VALID`/`READY` mutual-handshake protocol across all channels to ensure zero data loss during high-speed transfers and prevent pipeline stalls.
- **Protocol Compliance:** Ensured strict adherence to AXI4-Lite rules, including aligned 32-bit (or 64-bit) data transfers and the removal of burst lengths, making the interface highly optimized for control register access.

---

## 🛠️ Verification Environment
A professional, layered SystemVerilog verification setup was constructed to validate the RTL modules. The environment embraces layered testing concepts foundational to UVM (Universal Verification Methodology).

**Testbench Components included:**
* 🔌 **Interfaces:** Used SystemVerilog interfaces/modports to cleanly bundle the complex AXI signal clusters.
* 🚗 **Drivers:** Responsible for intelligently translating high-level transaction objects into pin-level AXI signals.
* 👁️ **Monitors:** Passively observes bus activity and reconstructs transactions for analysis.
* 📊 **Scoreboards:** Compares the actual observed outputs against expected reference data to automatically flag functional regressions.

---

## 💻 Technologies & Methodologies
- **Languages:** SystemVerilog (Design & Verification)
- **Specification:** ARM AMBA AXI4-Lite (v4.0)
- **Methodology:** Synchronous Digital Logic, Layered Testbenches, Functional Verification

---

## 🎯 Learning Outcomes
This project demonstrates practical competence in:
- High-performance, memory-mapped bus protocols (AMBA AXI).
- Implementing complex, multi-channel synchronous handshaking.
- Architecting professional SystemVerilog testbenches.
- Designing reusable, modular Verification Intellectual Property (VIP) components.

---
*If you find this project interesting or helpful, feel free to ⭐ star the repository!*
