module basys3_top (
    // Board side: the ports of the master xdc that this wiring uses (basys3_pins.xdc constrains them)
    input  wire clk,
    inout  wire [15:0] sw,
    inout  wire [15:0] led,
    inout  wire [6:0] seg,
    inout  wire dp,
    inout  wire [3:0] an,
    input  wire btnC,
    inout  wire btnU,
    inout  wire btnL,
    inout  wire btnR,
    inout  wire btnD,
    inout  wire [3:0] vgaRed,
    inout  wire [3:0] vgaBlue,
    inout  wire [3:0] vgaGreen,
    inout  wire Hsync,
    inout  wire Vsync
);

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    // Pad bundle, between the chip top and the board wiring below
    wire [61:0] pad_out;
    wire [61:0] pad_oe;
    wire [61:0] pad_in;

    // Named pins and pins: of system.yaml, between the chip top and the board
    wire pin_clk;
    wire pin_porb;

    // Outputs of the shell basys3_shell (frame-spec.yaml shell:)
    wire shell_sys_clk;
    wire shell_por_n;

    // Module instances
    // The shell: FPGA-only logic with no physical pins (frame/basys3/basys3_shell.sv)
    basys3_shell u_shell (
        .clk(clk),
        .btnC(btnC),
        .sys_clk(shell_sys_clk),
        .por_n(shell_por_n)
    );

    // The chip top: it reaches the outside only through the pad bundle and its named pins; keep_hierarchy keeps its port names through Vivado synthesis, the clock checks name them
    (* keep_hierarchy = "yes" *) ppu_bench u_chip (
        .pad_out(pad_out),
        .pad_oe(pad_oe),
        .pad_in(pad_in),
        .clk(pin_clk),
        .porb(pin_porb)
    );

    // Tri-state pads on the xdc ports
    assign led[0] = pad_oe[0] ? pad_out[0] : 1'bz;
    assign pad_in[0] = led[0];
    assign led[1] = pad_oe[1] ? pad_out[1] : 1'bz;
    assign pad_in[1] = led[1];
    assign led[2] = pad_oe[2] ? pad_out[2] : 1'bz;
    assign pad_in[2] = led[2];
    assign led[3] = pad_oe[3] ? pad_out[3] : 1'bz;
    assign pad_in[3] = led[3];
    assign led[4] = pad_oe[4] ? pad_out[4] : 1'bz;
    assign pad_in[4] = led[4];
    assign led[5] = pad_oe[5] ? pad_out[5] : 1'bz;
    assign pad_in[5] = led[5];
    assign led[6] = pad_oe[6] ? pad_out[6] : 1'bz;
    assign pad_in[6] = led[6];
    assign led[7] = pad_oe[7] ? pad_out[7] : 1'bz;
    assign pad_in[7] = led[7];
    assign led[8] = pad_oe[8] ? pad_out[8] : 1'bz;
    assign pad_in[8] = led[8];
    assign led[9] = pad_oe[9] ? pad_out[9] : 1'bz;
    assign pad_in[9] = led[9];
    assign led[10] = pad_oe[10] ? pad_out[10] : 1'bz;
    assign pad_in[10] = led[10];
    assign led[11] = pad_oe[11] ? pad_out[11] : 1'bz;
    assign pad_in[11] = led[11];
    assign led[12] = pad_oe[12] ? pad_out[12] : 1'bz;
    assign pad_in[12] = led[12];
    assign led[13] = pad_oe[13] ? pad_out[13] : 1'bz;
    assign pad_in[13] = led[13];
    assign led[14] = pad_oe[14] ? pad_out[14] : 1'bz;
    assign pad_in[14] = led[14];
    assign led[15] = pad_oe[15] ? pad_out[15] : 1'bz;
    assign pad_in[15] = led[15];
    assign sw[0] = pad_oe[16] ? pad_out[16] : 1'bz;
    assign pad_in[16] = sw[0];
    assign sw[1] = pad_oe[17] ? pad_out[17] : 1'bz;
    assign pad_in[17] = sw[1];
    assign sw[2] = pad_oe[18] ? pad_out[18] : 1'bz;
    assign pad_in[18] = sw[2];
    assign sw[3] = pad_oe[19] ? pad_out[19] : 1'bz;
    assign pad_in[19] = sw[3];
    assign sw[4] = pad_oe[20] ? pad_out[20] : 1'bz;
    assign pad_in[20] = sw[4];
    assign sw[5] = pad_oe[21] ? pad_out[21] : 1'bz;
    assign pad_in[21] = sw[5];
    assign sw[6] = pad_oe[22] ? pad_out[22] : 1'bz;
    assign pad_in[22] = sw[6];
    assign sw[7] = pad_oe[23] ? pad_out[23] : 1'bz;
    assign pad_in[23] = sw[7];
    assign sw[8] = pad_oe[24] ? pad_out[24] : 1'bz;
    assign pad_in[24] = sw[8];
    assign sw[9] = pad_oe[25] ? pad_out[25] : 1'bz;
    assign pad_in[25] = sw[9];
    assign sw[10] = pad_oe[26] ? pad_out[26] : 1'bz;
    assign pad_in[26] = sw[10];
    assign sw[11] = pad_oe[27] ? pad_out[27] : 1'bz;
    assign pad_in[27] = sw[11];
    assign sw[12] = pad_oe[28] ? pad_out[28] : 1'bz;
    assign pad_in[28] = sw[12];
    assign sw[13] = pad_oe[29] ? pad_out[29] : 1'bz;
    assign pad_in[29] = sw[13];
    assign sw[14] = pad_oe[30] ? pad_out[30] : 1'bz;
    assign pad_in[30] = sw[14];
    assign sw[15] = pad_oe[31] ? pad_out[31] : 1'bz;
    assign pad_in[31] = sw[15];
    assign btnU = pad_oe[32] ? pad_out[32] : 1'bz;
    assign pad_in[32] = btnU;
    assign btnL = pad_oe[33] ? pad_out[33] : 1'bz;
    assign pad_in[33] = btnL;
    assign btnR = pad_oe[34] ? pad_out[34] : 1'bz;
    assign pad_in[34] = btnR;
    assign btnD = pad_oe[35] ? pad_out[35] : 1'bz;
    assign pad_in[35] = btnD;
    assign seg[0] = pad_oe[36] ? pad_out[36] : 1'bz;
    assign pad_in[36] = seg[0];
    assign seg[1] = pad_oe[37] ? pad_out[37] : 1'bz;
    assign pad_in[37] = seg[1];
    assign seg[2] = pad_oe[38] ? pad_out[38] : 1'bz;
    assign pad_in[38] = seg[2];
    assign seg[3] = pad_oe[39] ? pad_out[39] : 1'bz;
    assign pad_in[39] = seg[3];
    assign seg[4] = pad_oe[40] ? pad_out[40] : 1'bz;
    assign pad_in[40] = seg[4];
    assign seg[5] = pad_oe[41] ? pad_out[41] : 1'bz;
    assign pad_in[41] = seg[5];
    assign seg[6] = pad_oe[42] ? pad_out[42] : 1'bz;
    assign pad_in[42] = seg[6];
    assign dp = pad_oe[43] ? pad_out[43] : 1'bz;
    assign pad_in[43] = dp;
    assign an[0] = pad_oe[44] ? pad_out[44] : 1'bz;
    assign pad_in[44] = an[0];
    assign an[1] = pad_oe[45] ? pad_out[45] : 1'bz;
    assign pad_in[45] = an[1];
    assign an[2] = pad_oe[46] ? pad_out[46] : 1'bz;
    assign pad_in[46] = an[2];
    assign an[3] = pad_oe[47] ? pad_out[47] : 1'bz;
    assign pad_in[47] = an[3];
    assign vgaBlue[0] = pad_oe[48] ? pad_out[48] : 1'bz;
    assign pad_in[48] = vgaBlue[0];
    assign vgaBlue[1] = pad_oe[49] ? pad_out[49] : 1'bz;
    assign pad_in[49] = vgaBlue[1];
    assign vgaBlue[2] = pad_oe[50] ? pad_out[50] : 1'bz;
    assign pad_in[50] = vgaBlue[2];
    assign vgaBlue[3] = pad_oe[51] ? pad_out[51] : 1'bz;
    assign pad_in[51] = vgaBlue[3];
    assign vgaGreen[0] = pad_oe[52] ? pad_out[52] : 1'bz;
    assign pad_in[52] = vgaGreen[0];
    assign vgaGreen[1] = pad_oe[53] ? pad_out[53] : 1'bz;
    assign pad_in[53] = vgaGreen[1];
    assign vgaGreen[2] = pad_oe[54] ? pad_out[54] : 1'bz;
    assign pad_in[54] = vgaGreen[2];
    assign vgaGreen[3] = pad_oe[55] ? pad_out[55] : 1'bz;
    assign pad_in[55] = vgaGreen[3];
    assign vgaRed[0] = pad_oe[56] ? pad_out[56] : 1'bz;
    assign pad_in[56] = vgaRed[0];
    assign vgaRed[1] = pad_oe[57] ? pad_out[57] : 1'bz;
    assign pad_in[57] = vgaRed[1];
    assign vgaRed[2] = pad_oe[58] ? pad_out[58] : 1'bz;
    assign pad_in[58] = vgaRed[2];
    assign vgaRed[3] = pad_oe[59] ? pad_out[59] : 1'bz;
    assign pad_in[59] = vgaRed[3];
    assign Hsync = pad_oe[60] ? pad_out[60] : 1'bz;
    assign pad_in[60] = Hsync;
    assign Vsync = pad_oe[61] ? pad_out[61] : 1'bz;
    assign pad_in[61] = Vsync;

    // Named pins of the chip, from the xdc ports and the shell, and to the xdc ports
    assign pin_clk = shell_sys_clk;
    assign pin_porb = shell_por_n;

    // hw-proj: GENERATE END

endmodule
