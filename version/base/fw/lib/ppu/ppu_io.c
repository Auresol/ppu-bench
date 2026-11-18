// libppu, the Basys3 board (ppu.h): pinout.yaml puts the LEDs on pads 0..15, the switches on 16..31, the buttons on 32..35.
#include "ppu.h"

uint32_t ppu_buttons(void)    { return GPIO_IN(1) & 15u; }
uint32_t ppu_switches(void)   { return (GPIO_IN(0) >> 16) & 0xFFFFu; }
void     ppu_leds(uint32_t v) { GPIO_OUT(0) = v & 0xFFFFu; }
