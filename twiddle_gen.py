import numpy as np

N = 8

real_vals = []
imag_vals = []

for k in range(N // 2):
    w = np.exp(-2j * np.pi * k / N)
    wr = int(np.round(w.real * 32767)) & 0xFFFF
    wi = int(np.round(w.imag * 32767)) & 0xFFFF
    real_vals.append(wr)
    imag_vals.append(wi)

with open(f'twiddle_real{N}.hex', "w") as f:
    for val in real_vals:
        f.write(f"{val:04X}\n")

with open(f'twiddle_imag{N}.hex', "w") as f:
    for val in imag_vals:
        f.write(f"{val:04X}\n")

print(f"Generated {N//2} twiddle factors")
print(f"W^0 real: {real_vals[0]:04X}  imag: {imag_vals[0]:04X}")  # should be 7FFF 0000
print(f"W^1 real: {real_vals[1]:04X}  imag: {imag_vals[1]:04X}")  # slight rotation