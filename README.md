## Introduction

The Fast Fourier Transform (FFT) is one of the workhorse algorithms of digital signal processing. It takes a signal described in the time domain and converts it into the frequency domain, revealing the underlying frequency content that isn't obvious when just looking at a waveform over time.

This matters because so much of modern engineering depends on understanding what frequencies make up a signal. Wireless communications, radar, software-defined radio, medical imaging, audio processing, image compression, and scientific computing all lean on the FFT in one form or another. The catch is that many of these applications need to run thousands or even millions of FFTs per second, and once you're at that scale, a software implementation on a general-purpose CPU starts to become the bottleneck.

That's where FPGAs come in. Instead of executing instructions one after another like a processor does, an FPGA can be structured so that many arithmetic operations happen at the same time, in parallel, with predictable timing. That combination of parallelism and determinism makes FPGAs a natural fit for accelerating FFT computation.

This project takes advantage of that by implementing a 1024-point, fixed-point, Radix-2 Cooley–Tukey FFT accelerator written entirely in SystemVerilog. It's packaged as a custom AXI4-Lite peripheral and integrated into a Xilinx Zynq-7000 system on a MiniZed board, where it talks to the ARM Cortex-A9 processing system over the AXI bus. On the software side, Vitis is used to load input samples into the accelerator, kick off the FFT computation, and read back the resulting frequency-domain data once it's done.

Altogether, the project walks through a full hardware/software co-design flow: writing and verifying the RTL, packaging it as a custom IP block, integrating it over AXI, implementing the design on the FPGA, writing the embedded software to drive it, and validating the whole thing end-to-end on real hardware.

---

# Fast Fourier Transform (FFT) Theory

## The Discrete Fourier Transform (DFT)

Most real-world signals are naturally represented in the **time domain**, where the amplitude of a signal varies over time. While this representation is useful for observing how a signal changes, many signal-processing applications require analyzing the individual frequencies that compose the signal.

The **Discrete Fourier Transform (DFT)** converts a sequence of time-domain samples into their corresponding **frequency-domain coefficients**, revealing the amplitude and phase of each frequency component present in the original signal.

For an input sequence:

```text
x[0], x[1], x[2], ..., x[N−1]
```

the DFT is defined by:

```text
              N−1
X[k] =  Σ  x[n] · WN^(kn)
             n=0
```

where the twiddle factor is

```text
            -j2π/N
WN = e
```

or equivalently,

```text
WN = cos(2π/N) − j sin(2π/N)
```

where:

- **N** is the FFT size.
- **n** is the input sample index.
- **k** is the output frequency bin.
- **j** is the imaginary unit (√−1).

Each output coefficient **X[k]** represents the magnitude and phase of a particular frequency contained within the original signal.

Unlike the time-domain representation, the frequency-domain representation makes it possible to identify dominant frequencies, harmonics, noise components, and other spectral characteristics that are critical in modern digital signal processing applications.

---

## Computational Complexity

Although the DFT is mathematically straightforward, its computational cost grows rapidly with transform size.

A direct implementation requires

\[
O(N^2)
\]

complex multiplications and additions.

For a 1024-point transform this corresponds to over one million arithmetic operations.

| FFT Size | Direct DFT Operations |
|----------:|---------------------:|
| 8 | 64 |
| 64 | 4,096 |
| 256 | 65,536 |
| 1024 | 1,048,576 |

Such computational complexity becomes impractical for real-time systems.

---

## The Fast Fourier Transform

The **Fast Fourier Transform (FFT)** is an optimized algorithm for computing the DFT.

Instead of directly evaluating every output independently, the FFT recursively decomposes a large transform into a sequence of smaller transforms while exploiting mathematical symmetries within the Fourier matrix.

This reduces computational complexity from

\[
O(N^2)
\]

to

\[
O(N\log_2N)
\]

For a 1024-point transform, the required arithmetic operations decrease dramatically:

| Algorithm | Approximate Operations |
|-----------|----------------------:|
| Direct DFT | 1,048,576 |
| FFT | 10,240 |

This reduction is the primary reason FFTs are used in virtually every modern digital signal processing application.

---

## Radix-2 Cooley–Tukey Algorithm

The FFT architecture implemented in this project is based on the **Radix-2 Decimation-in-Time (DIT) Cooley–Tukey algorithm**, one of the most widely used FFT algorithms due to its simplicity and efficient hardware implementation.

Rather than solving one large transform directly, the algorithm recursively divides the input into progressively smaller transforms until only simple two-point operations remain.

For example,

```text
1024-point FFT

↓

512-point FFTs

↓

256-point FFTs

↓

...

↓

2-point FFTs
```

These smaller transforms are connected through a network of **butterfly operations**, which form the fundamental computational building block of the FFT.

---

## Butterfly Operation

Each butterfly accepts two complex input values and produces two transformed outputs using one complex multiplication and two additions/subtractions.

Mathematically,

\[
Y_0=A+BW
\]

\[
Y_1=A-BW
\]

where

- \(A\) and \(B\) are complex inputs
- \(W\) is the corresponding twiddle factor

The butterfly operation is repeated throughout every FFT stage until the complete frequency-domain spectrum has been computed.

Because every butterfly can operate independently, FPGA hardware can execute many butterflies simultaneously, making the architecture highly parallel and significantly faster than sequential software execution.

---

## Twiddle Factors

Twiddle factors are complex roots of unity that rotate complex numbers during each butterfly operation of the FFT. They are defined by the equation:

```text
                 -j2πk/N
W_N^k = e
```

Using Euler's identity, the same expression can be written as:

```text
W_N^k = cos(2πk/N) - j sin(2πk/N)
```

where:

- **N** is the FFT size.
- **k** is the twiddle factor index.
- **j** is the imaginary unit (√−1).

Each butterfly stage requires a different set of twiddle factors to correctly rotate the intermediate frequency components before they are combined with the remaining FFT data.

Because these coefficients depend only on the FFT size and not on the input signal, they are generated once before synthesis using a Python script (`twiddle_gen.py`). The coefficients are then converted into **Q1.15 fixed-point format** and stored inside FPGA Block RAM as two lookup tables:

- **twiddle_real.hex** — Real coefficients
- **twiddle_imag.hex** — Imaginary coefficients

During FFT execution, the hardware simply performs a memory lookup rather than computing sine and cosine values in real time. This approach significantly reduces computational complexity, improves throughput, minimizes FPGA resource utilization, and allows the accelerator to operate at higher clock frequencies.

The lookup memory is implemented in **twiddle_rom.sv**, which interfaces directly with the butterfly processing elements throughout each stage of the FFT computation.

## Fixed-Point Arithmetic

Floating-point arithmetic provides excellent numerical precision but requires significantly more FPGA resources and generally operates at lower clock frequencies.

To improve hardware efficiency, this project uses **Q1.15 fixed-point arithmetic**, where each value is represented as a signed 16-bit integer consisting of

- 1 sign bit
- 15 fractional bits

This representation provides an excellent balance between numerical accuracy, hardware cost, and computational performance while allowing arithmetic operations to map efficiently onto FPGA DSP slices.

---

# FFT Hardware Acceleration

Rather than executing the FFT entirely in software on the ARM Cortex-A9 processor, the computationally intensive FFT algorithm is implemented directly in programmable logic as a dedicated hardware accelerator.

The accelerator consists of several specialized hardware modules including:

- FFT Controller
- Butterfly Processing Element
- Complex Multiplier
- Twiddle Factor ROM
- BRAM-based Memory System

Software running on the ARM processor communicates with the accelerator through a custom **AXI4-Lite interface**. Input samples are written into the accelerator's memory, the FFT computation is initiated through a control register, and the processed frequency-domain results are read back after computation completes.

The overall system architecture is illustrated below.

```text
                 ARM Cortex-A9
                (Vitis Software)
                       │
                AXI4-Lite Interface
                       │
      ┌────────────────┴────────────────┐
      │      FFT Hardware Accelerator    │
      │                                 │
      │  FFT Controller                  │
      │       │                          │
      │  Butterfly Network               │
      │       │                          │
      │ Complex Multiplier               │
      │       │                          │
      │  Twiddle ROM                     │
      │       │                          │
      │     BRAM                         │
      └─────────────────────────────────┘
```

By moving the FFT computation from software into dedicated FPGA hardware, the processor is relieved of the most computationally intensive portion of the signal-processing pipeline. The resulting architecture offers significantly higher throughput, deterministic execution latency, and improved overall system performance while maintaining a simple software interface through the AXI bus.

---

---

# System Design

The FFT accelerator was designed as a hardware/software co-design targeting the **Xilinx MiniZed (Zynq-7000 SoC)** platform. Rather than computing the Fast Fourier Transform entirely in software, the computationally intensive FFT algorithm is offloaded to dedicated hardware implemented in the FPGA's **Programmable Logic (PL)**. The ARM Cortex-A9 Processing System (PS) is responsible for configuring the accelerator, loading input samples, initiating the FFT computation, and reading the resulting frequency-domain data.

Communication between the Processing System and the custom FFT accelerator is performed through an **AXI4-Lite interface**, allowing the accelerator to be accessed as a memory-mapped peripheral from software developed in **Vitis**.


The execution sequence consists of the following steps:

1. The ARM Cortex-A9 processor generates or loads the input signal.
2. The input samples are written into the accelerator's Block RAM through the AXI interface.
3. The processor writes to the control register to start the FFT.
4. The FFT controller sequences each stage of the Radix-2 Cooley–Tukey algorithm.
5. Twiddle coefficients are read from the Twiddle ROM and used during butterfly computations.
6. Intermediate results are stored within Block RAM throughout execution.
7. Upon completion, the controller asserts the **Done** signal.
8. The processor reads the frequency-domain output from the accelerator for analysis or further processing.

---

# Vivado Block Design

After verifying the RTL implementation, the FFT accelerator was packaged as a custom AXI4-Lite IP and integrated into the Xilinx Zynq-7000 Processing System using the Vivado IP Integrator.

The block design below illustrates the complete hardware system implemented on the MiniZed development board.

<p align="center">
<img src="docs/images/block_design.png" width="1000">
</p>

<p align="center">
<b>Figure 2.</b> Vivado Block Design showing the Zynq Processing System connected to the custom FFT accelerator through the AXI interconnect.
</p>

The Processing System provides software control of the accelerator through the AXI4-Lite interface. Input samples are transferred from software into the accelerator's memory, the FFT computation is initiated through the control registers, and the resulting frequency-domain data is read back by the processor once execution has completed.

This hardware/software partitioning enables the ARM processor to manage data movement while the FPGA performs the computationally intensive FFT operations entirely in programmable logic.


By moving the FFT computation into dedicated hardware, the processor is relieved of the most computationally expensive portion of the signal-processing pipeline. This hardware/software partitioning provides significantly higher throughput, deterministic execution latency, and efficient utilization of FPGA resources while maintaining a simple programming interface through AXI.
