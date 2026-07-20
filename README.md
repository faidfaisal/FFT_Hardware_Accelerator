# Introduction

The **Fast Fourier Transform (FFT)** is one of the most important algorithms in digital signal processing (DSP). It efficiently converts a discrete signal from the **time domain** into its **frequency-domain representation**, allowing engineers to analyze the spectral content of signals that would otherwise be difficult to observe directly.

FFT algorithms are fundamental to numerous modern engineering applications including wireless communications, radar systems, software-defined radio (SDR), medical imaging, audio processing, image compression, scientific computing, and real-time signal analysis. Because these applications often require thousands or millions of FFT computations per second, software implementations running on general-purpose processors can become a significant computational bottleneck.

Field Programmable Gate Arrays (FPGAs) provide an attractive platform for accelerating FFT computation by exploiting massive parallelism, dedicated arithmetic hardware, and deterministic execution. Unlike software implementations that execute instructions sequentially, FPGA hardware performs multiple arithmetic operations simultaneously, significantly reducing execution latency while increasing throughput.

This project implements a **1024-point fixed-point Radix-2 Cooley–Tukey FFT accelerator** entirely in **SystemVerilog** and integrates it as a custom **AXI4-Lite peripheral** within a Xilinx Zynq-7000 (MiniZed) system. The accelerator communicates with the ARM Cortex-A9 Processing System through an AXI interface, allowing software developed in **Vitis** to load input samples, initiate FFT execution, and retrieve the resulting frequency-domain data from programmable logic.

The project demonstrates a complete hardware/software co-design workflow including RTL development, functional verification, custom IP packaging, AXI integration, FPGA implementation, embedded software development, and end-to-end hardware validation.

---

# Fast Fourier Transform (FFT) Theory

## The Discrete Fourier Transform

Most real-world signals are naturally represented in the **time domain**, where the amplitude of a signal varies with time. While this representation is useful, many signal-processing applications require understanding the frequency components contained within the signal.

The **Discrete Fourier Transform (DFT)** transforms a sequence of time-domain samples into their corresponding frequency-domain coefficients.

For an input sequence

\[
x[0],x[1],...,x[N-1]
\]

the DFT is defined as

\[
X[k]=\sum_{n=0}^{N-1}x[n]W_N^{kn}
\]

where

\[
W_N=e^{-j2\pi/N}
\]

is known as the **twiddle factor**, representing a complex sinusoidal basis function.

Each output coefficient \(X[k]\) represents the magnitude and phase of a particular frequency component present within the original signal.

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
