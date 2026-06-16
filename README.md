# FFT Hardware Accelerator

> A fixed-point Radix-2 Cooley-Tukey Fast Fourier Transform (FFT) accelerator implemented in **SystemVerilog** and targeted for **Xilinx FPGAs** using **Vivado** and **Vitis**.

---

## Overview

The **Fast Fourier Transform (FFT)** is one of the most widely used algorithms in digital signal processing, enabling efficient conversion of signals from the **time domain** into the **frequency domain**.

This project implements a hardware-accelerated FFT architecture using a **fixed-point Radix-2 Cooley-Tukey algorithm**, providing a scalable foundation for high-performance FPGA-based signal processing systems.

The design emphasizes:

- High-throughput computation
- Low-latency signal processing
- Efficient FPGA resource utilization
- Modular and scalable architecture
- Fixed-point arithmetic optimization

---

## Key Features

- Radix-2 Cooley-Tukey FFT architecture
- Q1.15 fixed-point arithmetic
- Hardware butterfly processing elements
- Signed complex multiplication unit
- Twiddle factor ROM with precomputed coefficients
- BRAM-based data storage architecture
- Modular SystemVerilog implementation
- Independent verification testbenches
- Compatible with Xilinx FPGA development flows

---

## Motivation

Fast frequency-domain analysis is critical across numerous engineering applications.

| Application | Industry |
|---|---|
| Radar Systems | Defense & Aerospace |
| Wireless Communications | Telecommunications |
| OFDM Modems | Networking |
| Software Defined Radio (SDR) | RF Engineering |
| Medical Imaging | Healthcare |
| Audio Processing | Consumer Electronics |
| Scientific Instrumentation | Research Computing |

While software implementations are flexible, FFT workloads become computationally expensive as transform sizes increase. FPGA acceleration enables performance improvements through parallelism and dedicated hardware resources.

Benefits of hardware acceleration include:

- Parallel execution
- Deterministic timing
- Reduced latency
- Improved energy efficiency
- Higher sustained throughput

---

## Mathematical Background

### Discrete Fourier Transform

For an N-point sequence:

```text
x[0], x[1], ..., x[N-1]
```

the Discrete Fourier Transform is defined as:

```text
X[k] = sum from n=0 to N-1 of x[n] * W_N^(kn)

where:

W_N = e^(-j2*pi/N)
```

is the fundamental twiddle factor.

### Computational Complexity

A direct DFT requires:

```text
O(N^2)
```

operations.

| FFT Size | DFT Operations |
|---|---|
| 8 | 64 |
| 64 | 4,096 |
| 1024 | 1,048,576 |

The FFT reduces complexity to:

```text
O(N log2 N)
```

| Algorithm | Operations for N = 1024 |
|---|---|
| DFT | 1,048,576 |
| FFT | 10,240 |

This reduction makes FFTs essential for modern signal processing systems.

### Algorithm: Radix-2 Cooley-Tukey FFT

The FFT recursively decomposes a larger transform into smaller transforms.

```text
8-Point FFT
     |
     v
Two 4-Point FFTs
     |
     v
Four 2-Point FFTs
```

Each stage consists of butterfly operations connected through twiddle factor multiplication.

### Butterfly Operation

The radix-2 butterfly is the fundamental computational block.

```text
Y0 = A + B * W
Y1 = A - B * W

where:

A and B are complex inputs
W is the corresponding twiddle factor
```

### Complex Multiplication

For:

```text
(a + jb)(c + jd)
```

the result is:

```text
(ac - bd) + j(ad + bc)
```

This operation is implemented in:

```text
complex_mult.sv
```

### Twiddle Factors

Twiddle coefficients are defined as:

```text
W_N^k = e^(-j2*pi*k/N)
```

or equivalently:

```text
W_N^k = cos(2*pi*k/N) - j*sin(2*pi*k/N)
```

Example values for an 8-point FFT:

| k | Twiddle Factor |
|---|---|
| 0 | 1.000 + j0.000 |
| 1 | 0.707 - j0.707 |
| 2 | 0.000 - j1.000 |
| 3 | -0.707 - j0.707 |

### Fixed-Point Representation

The accelerator uses Q1.15 fixed-point arithmetic.

```text
16-bit signed representation
1 sign bit
15 fractional bits
```

| Decimal Value | Q1.15 Representation |
|---|---|
| 1.0 | 32767 |
| 0.5 | 16384 |
| 0.707 | 23170 |
| -1.0 | -32768 |

Fixed-point arithmetic was selected to:

```text
Reduce hardware resource utilization
Increase operating frequency
Improve DSP block efficiency
Lower power consumption
Simplify FPGA implementation
```

### Hardware Architecture

```text
                    Twiddle ROM
                          |
                          v
Input B -----> Complex Multiplier
                          |
                          v
                        B * W
                          |
Input A ------------------+-------------+
                          |             |
                          v             v
                     A + B * W     A - B * W
                          |
                          v
                      Butterfly
```

The architecture consists of:

```text
Twiddle ROM
Complex Multiplier
Butterfly Processing Element
BRAM Storage
FFT Control Logic
```

Together, these modules implement the FFT computation pipeline.

### Repository Structure

```text
FFT_Hardware_Accelerator/
|
├── butterfly.sv
├── complex_mult.sv
|
├── fft_bram.sv
├── fft_controller.sv
|
├── twiddle_rom.sv
├── twiddle_real.hex
├── twiddle_imag.hex
├── twiddle_gen.py
|
├── tb_complex_mult.sv
├── tb_butterfly.sv
├── tb_bram.sv
|
└── README.md
```

### Module Descriptions

| Module | Description |
|---|---|
| complex_mult.sv | Signed fixed-point complex multiplier |
| butterfly.sv | Radix-2 butterfly processing element |
| twiddle_gen.py | Generates fixed-point twiddle coefficient tables |
| twiddle_rom.sv | Twiddle factor lookup memory |
| fft_bram.sv | Input, intermediate, and output data storage |
| fft_controller.sv | FFT sequencing, addressing, and control logic |

### Verification Strategy

Each hardware module is verified independently through dedicated SystemVerilog testbenches.

```text
complex_mult.sv  -> tb_complex_mult.sv
butterfly.sv     -> tb_butterfly.sv
fft_bram.sv      -> tb_bram.sv
```

This modular verification methodology:

```text
Simplifies debugging
Improves test coverage
Isolates failures quickly
Supports scalable system integration
```

### Development Environment

| Tool | Purpose |
|---|---|
| SystemVerilog | RTL design |
| Vivado | Synthesis and implementation |
| Vitis | FPGA development flow |
| Python | Twiddle coefficient generation |
| Xilinx FPGA | Target hardware platform |

### Results

The current implementation demonstrates the core computational building blocks required for a scalable FFT accelerator, including:

```text
Fixed-point complex multiplication
Radix-2 butterfly processing
Twiddle factor generation and storage
BRAM-based memory architecture
FFT control and sequencing infrastructure
```

Future releases will include synthesis reports, timing analysis, FPGA resource utilization, and hardware benchmarking results.

### Future Work

Planned enhancements include:

```text
Full N-point FFT datapath integration
Streaming AXI-Stream interfaces
Pipelined butterfly architecture
Runtime-configurable FFT sizes
DMA-based host communication
FPGA resource and timing optimization
Hardware/software co-design acceleration
Comparison against Xilinx FFT IP cores
```

### Acknowledgements

The authors would like to express their sincere gratitude to Professor Peter A. Milder for his guidance, mentorship, and support throughout the development of this project. His expertise in digital systems design, FPGA architectures, and hardware acceleration greatly influenced the direction and quality of this work.

### Authors

Faid Faisal
Department of Electrical and Computer Engineering
Stony Brook University

Paddy Zheng
Department of Electrical and Computer Engineering
Stony Brook University

### License

This project is intended for educational and research purposes. Please contact the authors regarding commercial use or redistribution.
