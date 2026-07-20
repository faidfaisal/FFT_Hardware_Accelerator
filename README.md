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

# Project Demonstration

The FFT accelerator was successfully synthesized, implemented, and validated on the **Xilinx MiniZed (Zynq-7000)** platform. The complete design was verified through RTL simulation, compared against a NumPy software reference, and executed on physical FPGA hardware using embedded software developed in **Vitis**.

The following sections highlight the complete implementation and verification flow.

---

## Vivado Block Design

The FFT accelerator was packaged as a custom **AXI4-Lite IP** and integrated into the Zynq Processing System using **Vivado IP Integrator**.

<p align="center">
<img src="images/block_design.png" width="950">
</p>

<p align="center">
<i>Figure 1. Vivado block design integrating the custom FFT accelerator with the ARM Cortex-A9 Processing System.</i>
</p>

---

## RTL Simulation

Prior to FPGA implementation, the complete RTL design was verified through simulation to ensure correct functionality.

<p align="center">
<img src="images/waveform.png" width="950">
</p>

<p align="center">
<i>Figure 2. RTL simulation waveform demonstrating successful FFT execution.</i>
</p>

---

## Verification Against NumPy

To verify the numerical accuracy of the hardware implementation, the FFT accelerator was compared against a software reference generated using **NumPy's FFT library**. The hardware outputs were collected from RTL simulation and evaluated against the floating-point software implementation using identical input vectors.

Because the accelerator uses **Q1.15 fixed-point arithmetic**, small numerical differences are expected due to quantization and finite precision. Despite these limitations, the accelerator closely matches the NumPy reference while maintaining significantly lower hardware complexity than a floating-point implementation.

### Random Input Verification

The first verification uses a randomly generated input signal. The upper plot compares the magnitude spectrum produced by the RTL simulation with the NumPy reference, while the lower plot illustrates the absolute error between the two implementations measured in Q1.15 least significant bits (LSBs).

<p align="center">
<img src="images/numpy_random.png" width="900">
</p>

<p align="center">
<i>Figure 3. Comparison of the RTL FFT output against the NumPy reference for a random input signal. The lower plot shows the absolute fixed-point error across all 1024 frequency bins.</i>
</p>

The two spectra closely overlap, demonstrating that the hardware implementation accurately reproduces the expected frequency-domain response. The remaining error is primarily due to fixed-point quantization and arithmetic rounding rather than algorithmic inaccuracies.

---

### Two-Tone Signal Verification

A second verification was performed using a two-tone input signal consisting of two sinusoidal frequencies. This test validates that the accelerator correctly identifies discrete frequency components and places spectral peaks at the expected frequency bins.

<p align="center">
<img src="images/numpy_tone.png" width="900">
</p>

<p align="center">
<i>Figure 4. Comparison between the FFT accelerator and the NumPy reference for a two-tone input signal.</i>
</p>

The RTL simulation produces spectral peaks at the exact same frequency bins as the NumPy reference, confirming that the butterfly operations, twiddle factor lookups, addressing logic, and FFT sequencing are functioning correctly. The lower logarithmic plot highlights the small numerical differences introduced by fixed-point arithmetic while demonstrating excellent agreement between the hardware and software implementations.

Overall, these verification results provide strong evidence that the custom FFT accelerator performs the expected 1024-point Radix-2 Cooley–Tukey transform with high numerical accuracy while operating entirely in FPGA hardware.

---

## Embedded Software (Vitis)

The ARM Cortex-A9 processor communicates with the accelerator through the AXI4-Lite interface. Software running in **Vitis** loads the input samples into the FFT accelerator, initiates computation, waits for completion, and reads back the resulting frequency-domain data.

<p align="center">
<img src="images/vitis_output.png" width="850">
</p>

<p align="center">
<i>Figure 4. Successful end-to-end hardware validation using Vitis.</i>
</p>

---

## FPGA Implementation

Following verification, the design was synthesized and implemented using **Vivado** for the Xilinx MiniZed platform.

### Device Placement

<p align="center">
<img src="images/placement.png" width="900">
</p>

<p align="center">
<i>Figure 5. FPGA device placement after implementation.</i>
</p>

### Resource Utilization

<p align="center">
<img src="images/utilization.png" width="900">
</p>

<p align="center">
<i>Figure 6. FPGA resource utilization reported by Vivado.</i>
</p>

---

## Hardware Test Results

The completed design successfully passed all hardware validation tests executed on the MiniZed FPGA.

```text
=== FFT accelerator hardware test (N=1024) ===

[mem] PASS

[impulse] PASS

[dc] PASS

[tone] PASS

=== ALL TESTS PASSED ===
```

These tests verified:

- Successful AXI communication
- Correct BRAM read/write functionality
- Correct FFT computation
- Successful frequency-domain output generation
- End-to-end hardware/software integration
