# FFT Hardware Accelerator

> A fixed-point, radix-2 Cooley-Tukey FFT architecture implemented in SystemVerilog on a Xilinx FPGA using Vivado and Vitis.

---

## Overview

The **Fast Fourier Transform (FFT)** is one of the most important algorithms in digital signal processing. It transforms a signal from the time domain into the frequency domain, enabling efficient analysis of frequency components.

This project implements a **hardware-accelerated FFT architecture** on a Xilinx FPGA using SystemVerilog, serving as a foundation for scalable FFT accelerator development.

---

## Motivation

Many real-world applications require fast frequency-domain analysis:

| Application | Domain |
|---|---|
| Radar Systems | Defense / Sensing |
| Wireless Communications | Telecom |
| OFDM Modems | Networking |
| Software Defined Radio (SDR) | RF |
| Medical Imaging | Healthcare |
| Audio Processing | Consumer Electronics |
| Scientific Instrumentation | Research |

Software implementations become computationally expensive for large FFT sizes. FPGA hardware acceleration provides:

-  High throughput
-  Parallel computation
-  Low latency
-  Energy efficiency

---

##  Mathematical Background

### Discrete Fourier Transform (DFT)

For an N-point input sequence $x[0], x[1], \ldots, x[N-1]$, the DFT is defined as:

$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot W_N^{kn}$$

where $W_N = e^{-j2\pi/N}$ is the **twiddle factor base**.

### Computational Complexity

Direct DFT has complexity $O(N^2)$:

| FFT Size | DFT Operations |
|---|---|
| 8 | 64 |
| 64 | 4,096 |
| 1024 | 1,048,576 |

The FFT reduces this to $O(N \log_2 N)$:

| Algorithm | Operations (N=1024) |
|---|---|
| DFT | 1,048,576 |
| FFT | 10,240 |

---

## Algorithm: Cooley-Tukey Radix-2

This project uses the **Radix-2 Cooley-Tukey** algorithm, which recursively decomposes a larger FFT into smaller ones:

```
8-point FFT
    ↓
Two 4-point FFTs
    ↓
Four 2-point FFTs
```

### Butterfly Operation

The radix-2 butterfly is the core processing element:

```
Y₀ = A + B·W
Y₁ = A - B·W
```

Where `A`, `B` are complex input samples and `W` is the twiddle factor.

### Complex Multiplication

For $(a + jb)(c + jd)$:

$$\text{Result} = (ac - bd) + j(ad + bc)$$

Implemented in `complex_mult.sv`.

### Twiddle Factors

$$W_N^k = e^{-j2\pi k/N} = \cos\left(\frac{2\pi k}{N}\right) - j\sin\left(\frac{2\pi k}{N}\right)$$

Example values for an 8-point FFT:

| k | Twiddle Factor |
|---|---|
| 0 | 1.000 + j0.000 |
| 1 | 0.707 − j0.707 |
| 2 | 0.000 − j1.000 |
| 3 | −0.707 − j0.707 |

---

##  Fixed-Point Representation

The design uses **Q1.15** fixed-point format:

- **16 bits total** — 1 sign bit + 15 fractional bits

| Real Value | Q1.15 Representation |
|---|---|
| 1.0 | 32767 |
| 0.5 | 16384 |
| 0.707 | 23170 |
| −1.0 | −32768 |

Fixed-point arithmetic is chosen for:
- Smaller hardware footprint
- Faster FPGA implementation
- Lower power consumption
- Efficient DSP block utilization

---

##  Hardware Architecture

```
              Twiddle ROM
                    │
                    ▼
Input B ──► Complex Multiplier
                    │
                    ▼
                  B·W
                    │
Input A ────────────┬────────────┐
                    ▼            ▼
               A + B·W      A − B·W
                    │
                    ▼
                Butterfly
```

---

##  Repository Structure

```
FFT_Hardware_Accelerator/
│
├── butterfly.sv          # Radix-2 butterfly unit
├── complex_mult.sv       # Signed complex multiplier
│
├── fft_bram.sv           # BRAM memory storage block
├── fft_controller.sv     # FFT stage sequencing & control
│
├── twiddle_rom.sv        # Twiddle factor ROM
├── twiddle_real.hex      # Precomputed real twiddle values
├── twiddle_imag.hex      # Precomputed imaginary twiddle values
├── twiddle_gen.py        # Twiddle coefficient generator script
│
├── tb_complex_mult.sv    # Testbench: complex multiplier
├── tb_butterfly.sv       # Testbench: butterfly unit
├── tb_bram.sv            # Testbench: BRAM
│
└── README.md
```

### Module Descriptions

| File | Description |
|---|---|
| `complex_mult.sv` | Computes $(a+jb)(c+jd)$; used inside FFT butterflies |
| `butterfly.sv` | Radix-2 butterfly: computes $A+BW$ and $A-BW$ |
| `twiddle_gen.py` | Generates `.hex` twiddle coefficient files |
| `twiddle_rom.sv` | Supplies twiddle factors to the FFT datapath |
| `fft_bram.sv` | Stores input samples, intermediate data, and output results |
| `fft_controller.sv` | Handles stage sequencing, BRAM addressing, and twiddle selection |

---

##  Verification Strategy

Each module is verified independently:

```
complex_mult.sv  →  tb_complex_mult.sv
butterfly.sv     →  tb_butterfly.sv
fft_bram.sv      →  tb_bram.sv
```

This modular approach simplifies debugging and isolates failures to individual components.

---

##  Development Roadmap

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | Core Arithmetic (Complex Multiplier, Butterfly, Twiddle ROM) | ✅ Complete |
| **Phase 2** | Verification (Testbenches for all core modules) | 🔄 In Progress |
| **Phase 3** | FFT Integration (Top-level, stage integration, end-to-end verification) | 🔲 Planned |
| **Phase 4** | Hardware Synthesis (Vivado synthesis, timing, resource utilization) | 🔲 Planned |
| **Phase 5** | Accelerator Integration (AXI interface, BRAM & controller integration) | 🔲 Planned |
| **Phase 6** | Vitis Integration (ARM control, host software, performance evaluation) | 🔲 Planned |

---

## 🔭 Long-Term Goal

```
ARM Processor (Vitis)
        │
        ▼
   AXI Interface
        │
        ▼
   FFT Controller
        │
        ▼
    Input BRAM
        │
        ▼
 FFT Butterfly Engine
        │
        ▼
    Output BRAM
        │
        ▼
    FFT Results
```

Future work includes scaling toward:
- 64-point FFT
- 256-point FFT
- 1024-point FFT

While exploring **folded datapaths**, **pipelining**, and **BRAM-based architectures**.

---

## Authors

**Faid Faisal**  
**Paddy Zheng**
