import numpy as np

def butterfly(A,B, W): #butterfly equation
    return A+W*B, A-W*B

def fft(x):
    N = len(x)
    #bit reversal and split
    #LOGICALLY THIS IS WHERE THE VALUES SPLIT APART
    #splitting does not need butterfly or twiddle factor
    x=[x[int('{:0{}b}'.format(i, int(np.log2(N)))[::-1],2)] for i in range(N)]

    #RECOMBINATION STAGE
    stages = int(np.log2(N))
    for stage in range(stages):
        #value diff between pairs
        span = 2**stage
        #basically how many we are splitting into
        group_size = span*2
        for group in range(0,N, group_size):
            for j in range(span):
                #first group
                idxA = group + j
                #seonnd group
                idxB = group + j + span
                k = j * (N//group_size)
                w = np.exp(-2j*np.pi*k/N)
                x[idxA], x[idxB] = butterfly(x[idxA], x[idxB], w)
    return x
t = 1024
x = np.zeros(t)
for i in range(t):
    x[i] = np.random.normal()
npFFTval = np.fft.fft(x)
customFFT = fft(x)
np.set_printoptions(threshold=np.inf)
rounded = [complex(round(v.real, 8), round(v.imag, 8)) for v in customFFT]
print(f'NP: {npFFTval}\nCustom: {rounded}')

with open("output.txt","w") as f:
    f.write(f'NPFFT:{npFFTval}\n')
    f.write(f'CustomFFT:{rounded}\n')
