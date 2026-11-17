// ppu_bench firmware: one frame per reset (spec/sprite-spec.md section 8).
// crt0.s (generated) sets the stack and calls main(); soc.h (generated) has the addresses and register macros of the chip.
//
// The core never touches pixels: it writes the palette and textures through the loader (TEXLD0_BASE mirrors bus tex one to one;
// TEX0_BASE in soc.h is the address on bus tex, which the core cannot reach), the sprite table into OAM0, then starts the engine.
#include "soc.h"

#define TEX(off)  (*(volatile uint32_t *)(TEXLD0_BASE + (off)))   // a word of the texture SRAM, through the loader
#define OAM(i, w) (*(volatile uint32_t *)(OAM0_BASE + 8u * (i) + 4u * (w)))

int main(void)
{
    // the VGA pins are a function of racer0, not software gpio: select it (FUNCSEL resets to 0 and no pin drives out of reset)
    for (int n = RACER0_0_RGB_PIN_FIRST; n <= RACER0_0_VSYNC_PIN; n++)
        GPIO_CTRL(n) = RACER0_0_FUNCSEL;

    // palette entry 0 is the backdrop (rgb444 in bits [11:0]); entries are 16 bits, two to a word
    TEX(0) = 0x0000u | (0x0FFFu << 16);   // entry 0 black, entry 1 white

    // no sprite: every OAM entry disabled (word 0 bit 28 = 0)
    for (unsigned i = 0; i < 128; i++) {
        OAM(i, 0) = 0;
        OAM(i, 1) = 0;
    }

    // one frame, from the next frame start; textures are locked from here on
    PPU0_CTRL = 1u;
    while (!(PPU0_STATUS & 1u))
        ;

    for (;;)
        ;
}
