// Benchmark firmware: one frame per reset (spec/sprite-spec.md section 8), the same program for every workload.
//
// The workload is not compiled in: the testbench (test-suite/ppu_bench) builds it in Go, with the golden model, and writes it
// into `workload` through the SRAM backdoor before the reset. It is in .noinit, which crt0 does not clear (chip_ram.ld).
// The core never touches pixels: it copies the texture image through the loader (TEXLD0_BASE + k is texture byte k), the
// sprite table into OAM0, writes GIANT, starts the engine and waits for DONE. Then it leaves the results in bench_result,
// which the testbench reads by symbol, done last. The core has no counter CSRs: cycles are the testbench's to measure.
#include "soc.h"

#define WL_MAGIC   0x574C4F41u        // "AOLW": the testbench wrote a workload
#define WL_TEX_MAX 12800u             // words of the texture image (50 kb): the largest workload is 46 kb

struct workload {
    uint32_t magic, giant, tex_words, reserved;
    uint32_t oam[256];                // sprite i = words 2i (placement) and 2i+1 (appearance)
    uint32_t tex[WL_TEX_MAX];         // the texture SRAM image from byte 0: the palette (0..511), then the textures
};
__attribute__((section(".noinit"))) volatile struct workload workload;

struct bench_result {
    uint32_t late;                    // PPU0_LATE after the frame
    uint32_t hit[4];                  // PPU0_HIT0..3
    uint32_t done;                    // written last: 1 = the fields above are final; 0xBAD = no workload was written
    // the performance counters of the frame (doc/ppu.yaml FRAME_CYC .. TEX_WANT_PEAK), in register order
    uint32_t frame_cyc, tex_busy, main_busy, slots_peak, adm_wait, adm_slack, tex_want_peak;
};
volatile struct bench_result bench_result;

int main(void)
{
    if (workload.magic != WL_MAGIC || workload.tex_words > WL_TEX_MAX) {
        bench_result.done = 0xBADu;
        return 1;
    }
    for (int n = RACER0_0_RGB_PIN_FIRST; n <= RACER0_0_VSYNC_PIN; n++)
        GPIO_CTRL(n) = RACER0_0_FUNCSEL;

    volatile uint32_t *tex = (volatile uint32_t *)TEXLD0_BASE;
    for (uint32_t i = 0; i < workload.tex_words; i++)
        tex[i] = workload.tex[i];
    volatile uint32_t *oam = (volatile uint32_t *)OAM0_BASE;
    for (uint32_t i = 0; i < 256; i++)
        oam[i] = workload.oam[i];
    PPU0_GIANT = workload.giant;

    PPU0_CTRL = 1u;
    while (!(PPU0_STATUS & 1u))
        ;

    bench_result.late = PPU0_LATE;
    bench_result.hit[0] = PPU0_HIT0;
    bench_result.hit[1] = PPU0_HIT1;
    bench_result.hit[2] = PPU0_HIT2;
    bench_result.hit[3] = PPU0_HIT3;
    bench_result.frame_cyc     = PPU0_FRAME_CYC;
    bench_result.tex_busy      = PPU0_TEX_BUSY;
    bench_result.main_busy     = PPU0_MAIN_BUSY;
    bench_result.slots_peak    = PPU0_SLOTS_PEAK;
    bench_result.adm_wait      = PPU0_ADM_WAIT;
    bench_result.adm_slack     = PPU0_ADM_SLACK;
    bench_result.tex_want_peak = PPU0_TEX_WANT_PEAK;
    __asm__ volatile("" ::: "memory");
    bench_result.done = 1u;
    return 0;
}
