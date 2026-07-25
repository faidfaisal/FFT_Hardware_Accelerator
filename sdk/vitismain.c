/*
 * main.c - Software test for the FFT accelerator (fft_accelerator_v1_0, design_1).
 *
 * Register map (verified against ip_repo/fft_accelerator_1.0 HDL):
 *   0x00 CMD    (W): bit0 = start FFT, bit1 = write mem, bit2 = read mem
 *   0x04 STATUS (R): bit0 = busy, bit1 = done (sticky), bit2 = read data valid
 *   0x08 ADDR  (RW): FFT memory address, 0..1023
 *   0x0C DATA   (W): sample to write  (R): latched read data
 *
 * Sample: [31:16] real Q1.15, [15:0] imag Q1.15.  N = 1024.
 * Input must be loaded in BIT-REVERSED address order; output is natural.
 *
 * Memory write:  ADDR <= a; DATA <= d; CMD <= 0x2
 * Memory read:   ADDR <= a; CMD <= 0x4; poll STATUS bit2; read DATA
 * Run FFT:       CMD <= 0x1; poll STATUS bit1
 */

#include <stdint.h>
#include "xil_io.h"
#include "xil_printf.h"

#define FFT_BASE   0x43C00000U

#define R_CMD      0x00U
#define R_STATUS   0x04U
#define R_ADDR     0x08U
#define R_DATA     0x0CU

#define CMD_START  0x1U
#define CMD_WRITE  0x2U
#define CMD_READ   0x4U

#define ST_BUSY    0x1U
#define ST_DONE    0x2U
#define ST_RVALID  0x4U

#define N          1024
#define LOG2N      10
#define TIMEOUT    10000000

static inline void wr(uint32_t off, uint32_t v){ Xil_Out32(FFT_BASE+off, v); }
static inline uint32_t rd(uint32_t off){ return Xil_In32(FFT_BASE+off); }

static uint32_t bitrev(uint32_t x){
    uint32_t r = 0;
    for (int i = 0; i < LOG2N; i++){ r = (r<<1)|(x&1); x >>= 1; }
    return r;
}

static uint32_t pack(int16_t re, int16_t im){
    return ((uint32_t)(uint16_t)re << 16) | (uint16_t)im;
}

/* Load x[n] (natural index) at bit-reversed address. */
static void mem_write(uint32_t n, int16_t re, int16_t im){
    wr(R_ADDR, bitrev(n));
    wr(R_DATA, pack(re, im));
    wr(R_CMD,  CMD_WRITE);
}

/* Read X[k] (natural order). Returns 0 on success. */
static int mem_read(uint32_t k, int16_t *re, int16_t *im){
    wr(R_ADDR, k);
    wr(R_CMD,  CMD_READ);
    int t = TIMEOUT;
    while (!(rd(R_STATUS) & ST_RVALID)) if (--t == 0) return -1;
    uint32_t v = rd(R_DATA);
    *re = (int16_t)(v >> 16);
    *im = (int16_t)(v & 0xFFFF);
    return 0;
}

static int run_fft(void){
    wr(R_CMD, CMD_START);
    int t = TIMEOUT;
    while (!(rd(R_STATUS) & ST_DONE)) if (--t == 0) return -1;
    return 0;
}

/* Test 1: impulse. x[0]=A -> X[k]=A exactly, for all k. */
static int test_impulse(void){
    const int16_t A = 0x1000;   /* 0.125 in Q1.15 */
    int errors = 0;

    xil_printf("\r\n[impulse] loading...\r\n");
    for (uint32_t n = 0; n < N; n++)
        mem_write(n, (n==0) ? A : 0, 0);

    if (run_fft()){ xil_printf("[impulse] TIMEOUT\r\n"); return 1; }

    for (uint32_t k = 0; k < N; k++){
        int16_t re, im;
        if (mem_read(k, &re, &im)){ xil_printf("read timeout k=%d\r\n", k); return 1; }
        if (re != A || im != 0){
            if (errors < 10)
                xil_printf("  X[%d]=(%d,%d) expected (%d,0)\r\n", k, re, im, A);
            errors++;
        }
    }
    xil_printf("[impulse] %s (%d errors)\r\n", errors ? "FAIL":"PASS", errors);
    return errors ? 1 : 0;
}

/* Test 2: DC. x[n]=A -> X[0] = N*A, all other bins ~0.
 * A kept small so N*A does not overflow the 16-bit Q1.15 output. */
static int test_dc(void){
    const int16_t A = 0x0010;          /* 16: N*A = 16384, fits in Q1.15 */
    int errors = 0;
    int16_t re, im;

    xil_printf("\r\n[dc] loading...\r\n");
    for (uint32_t n = 0; n < N; n++)
        mem_write(n, A, 0);

    if (run_fft()){ xil_printf("[dc] TIMEOUT\r\n"); return 1; }

    mem_read(0, &re, &im);
    int32_t x0 = re;
    xil_printf("  X[0]=(%d,%d) expected ~%d\r\n", re, im, N*A);
    if (x0 < (N*A*3)/4){ xil_printf("  ^ X[0] too small\r\n"); errors++; }

    /* Fixed-point rounding leaves a little energy in other bins.
     * Accept anything below ~5%% of the peak as noise. */
    int32_t thresh = (N*A) / 20;       /* ~5% of peak */
    for (uint32_t k = 1; k < N; k++){
        mem_read(k, &re, &im);
        if (re > thresh || re < -thresh || im > thresh || im < -thresh){
            if (errors < 10)
                xil_printf("  X[%d]=(%d,%d) exceeds +/-%d\r\n", k, re, im, thresh);
            errors++;
        }
    }
    xil_printf("[dc] %s (%d errors, thresh=%d)\r\n", errors ? "FAIL":"PASS", errors, thresh);
    return errors ? 1 : 0;
}

/* Test 3: cosine at bin 16 -> energy only in bins 16 and 1008. */
static int test_tone(void){
    const uint32_t f = 16;
    int errors = 0;

    /* Q1.15 rotation per step for 2*pi*16/1024.
     * Amplitude kept small: this FFT core does not scale per stage, so a
     * tone's bin grows to ~A*N/2. A=0x20 -> peak ~16384, no 16-bit overflow. */
    const int32_t c = 32610, s = 3212;
    int32_t xr = 0x0020, xi = 0;

    xil_printf("\r\n[tone f=16] loading...\r\n");
    for (uint32_t n = 0; n < N; n++){
        mem_write(n, (int16_t)xr, 0);
        int32_t nr = (xr*c - xi*s) >> 15;
        int32_t ni = (xr*s + xi*c) >> 15;
        xr = nr; xi = ni;
    }

    if (run_fft()){ xil_printf("[tone] TIMEOUT\r\n"); return 1; }

    /* Diagnostic: find and print the 8 largest bins by energy so we can
     * see the spectral structure (expect peaks only at 16 and 1008). */
    int32_t topmag[8] = {0};
    uint32_t topbin[8] = {0};
    for (uint32_t k = 0; k < N; k++){
        int16_t re, im;
        mem_read(k, &re, &im);
        int32_t mag = ((int32_t)re*re + (int32_t)im*im) >> 8;
        /* insertion into top-8 */
        for (int i = 0; i < 8; i++){
            if (mag > topmag[i]){
                for (int j = 7; j > i; j--){ topmag[j]=topmag[j-1]; topbin[j]=topbin[j-1]; }
                topmag[i] = mag; topbin[i] = k;
                break;
            }
        }
    }
    xil_printf("  top bins (bin:energy):\r\n");
    for (int i = 0; i < 8; i++)
        xil_printf("    %4d : %d\r\n", topbin[i], topmag[i]);

    /* Pass if the two largest bins are exactly {16, 1008}. */
    int b0 = topbin[0], b1 = topbin[1];
    int ok = ((b0==(int)f && b1==(int)(N-f)) || (b0==(int)(N-f) && b1==(int)f));
    if (!ok){ xil_printf("  ^ top two bins are not 16 and 1008\r\n"); errors++; }

    xil_printf("[tone] %s\r\n", errors ? "FAIL":"PASS");
    return errors ? 1 : 0;
}

/* Raw memory addressing test: write mem[a]=a, read it back, NO FFT.
 * Isolates write/read addressing from the FFT datapath. Uses raw
 * addresses (no bit-reversal) so mem[a] should read back exactly a. */
static int test_memory(void){
    int errors = 0;
    xil_printf("\r\n[mem] ramp write/read (no FFT)...\r\n");

    for (uint32_t a = 0; a < N; a++){
        wr(R_ADDR, a);
        wr(R_DATA, pack((int16_t)a, 0));
        wr(R_CMD,  CMD_WRITE);
    }

    for (uint32_t a = 0; a < N; a++){
        int16_t re, im;
        if (mem_read(a, &re, &im)){ xil_printf("  read timeout a=%d\r\n", a); return 1; }
        if ((uint16_t)re != (uint16_t)a){
            if (errors < 12)
                xil_printf("  mem[%d] = %d (expected %d)\r\n", a, re, a);
            errors++;
        }
    }
    xil_printf("[mem] %s (%d errors)\r\n", errors ? "FAIL":"PASS", errors);
    return errors ? 1 : 0;
}

int main(void){
    xil_printf("\r\n=== FFT accelerator hardware test (N=%d) ===\r\n", N);
    xil_printf("base=0x%08x\r\n", FFT_BASE);

    /* Register sanity: ADDR readback and status snapshot */
    wr(R_ADDR, 0x2A5);
    uint32_t rb = rd(R_ADDR);
    xil_printf("addr readback: wrote 0x2A5 read 0x%03x -> %s\r\n",
               rb, (rb == 0x2A5) ? "OK" : "MISMATCH");
    xil_printf("status=0x%x\r\n", rd(R_STATUS));

    int failed = 0;
    failed += test_memory();
    failed += test_impulse();
    failed += test_dc();
    failed += test_tone();

    if (failed == 0)
        xil_printf("\r\n=== ALL TESTS PASSED ===\r\n");
    else
        xil_printf("\r\n=== %d TEST(S) FAILED ===\r\n", failed);

    while (1) { }
    return 0;
}
