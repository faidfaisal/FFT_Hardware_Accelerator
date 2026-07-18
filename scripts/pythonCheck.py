import numpy as np
x = [0.125, -0.0625, 0.25, 0.0, -0.125, 0.1875, -0.25, 0.0625]
result = np.fft.fft(x)
for k in range(8):
    print(f"X[{k}] = {result[k].real:.6f} + j{result[k].imag:.6f}")
