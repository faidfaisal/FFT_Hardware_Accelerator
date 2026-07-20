# FFT Hardware Accelerator

> A **1024-point fixed-point Radix-2 Cooley–Tukey Fast Fourier Transform (FFT) accelerator** implemented in **SystemVerilog** for the **Xilinx MiniZed (Zynq-7000 SoC)**. The accelerator is integrated as a custom **AXI4-Lite IP**, controlled through **Vitis**, and successfully validated on FPGA hardware.

---

# Project Overview

The Fast Fourier Transform (FFT) is one of the most widely used algorithms in digital signal processing, enabling efficient conversion of signals from the time domain into their frequency-domain representation. Because FFT computation is computationally intensive, software implementations can become a performance bottleneck in applications that require real-time processing.

This project accelerates FFT computation by implementing a **1024-point fixed-point Radix-2 Cooley–Tukey FFT** entirely in FPGA hardware using **SystemVerilog**. The accelerator is packaged as a custom **AXI4-Lite IP core** and integrated into a **Xilinx Zynq-7000 (MiniZed)** platform, where it communicates with the ARM Cortex-A9 Processing System through the AXI bus.

Software developed in **Vitis** loads input samples into the accelerator, initiates the FFT computation, and retrieves the frequency-domain results after execution. The complete design was functionally verified through RTL simulation, compared against a NumPy reference implementation, synthesized and implemented in Vivado, and successfully validated on physical FPGA hardware.

This repository demonstrates the complete FPGA accelerator development workflow, including RTL design, simulation, custom IP development, AXI integration, hardware implementation, embedded software development, and end-to-end hardware verification.

---

# Features

-  1024-Point Radix-2 Cooley–Tukey FFT
-  Q1.15 Fixed-Point Arithmetic
-  SystemVerilog RTL Implementation
-  Custom AXI4-Lite Hardware Accelerator
-  BRAM-Based Memory Architecture
-  Twiddle Factor ROM with Precomputed Coefficients
-  Vivado IP Packaging and Integration
-  ARM Cortex-A9 Software Interface (Vitis)
-  RTL Simulation and Verification
-  NumPy Reference Comparison
-  End-to-End FPGA Hardware Validation on MiniZed

---

# Project Highlights

- Designed and implemented a custom FFT accelerator in **SystemVerilog**
- Packaged the design as a reusable **Vivado IP**
- Integrated the accelerator with the **Zynq-7000 Processing System**
- Developed embedded software in **Vitis** to control the hardware
- Verified functionality through RTL simulation and comparison with **NumPy**
- Successfully executed the accelerator on the **MiniZed FPGA**
- Passed memory, impulse, DC, and single-tone hardware validation tests

---
