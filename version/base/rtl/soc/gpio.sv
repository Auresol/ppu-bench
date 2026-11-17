// hw-proj: GENERATE HEADER BEGIN
module gpio #(
    parameter int PINS = 62,
    parameter int FN_OUT = 14
) (
    // Port list: hw-proj rewrites it on every run from the YAML (edit the spec, not this list)
    // AHB-Lite slave (no hsel — crossbar handles selection via htrans) bus interface
    input  wire clk,
    input  wire rst_n,
    input  wire [31:0] haddr,
    input  wire hwrite,
    input  wire [1:0] htrans,
    input  wire [2:0] hsize,
    input  wire [31:0] hwdata,
    output wire [31:0] hrdata,
    output wire hready,
    output wire hresp,

    // Pad bundle (adr/pins/pad-bundle-decoded-flag-vectors.md): one bit per pin, 0 is the default; the frame adapter reads it
    output wire [PINS-1:0] pad_out,
    output wire [PINS-1:0] pad_oe,
    input  wire [PINS-1:0] pad_in,

    // Function ports (C40): the slots are named by the FN_* localparams below
    input  wire [FN_OUT-1:0] fn_out,  // output of each OUT slot, from the function
    input  wire [FN_OUT-1:0] fn_oe  // output enable of each OUT slot, from the function
);
// hw-proj: GENERATE HEADER END

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    // Bus stage
    reg         bus_sel_r;    // a transfer was selected in the address phase
    reg         bus_write_r;  // that transfer is a write
    reg  [11:0] bus_addr_r;   // its address
    wire        bus_wr;       // write strobe, valid with bus_wdata
    wire        bus_rd;       // read strobe
    wire [11:0] bus_addr;     // register address of the data phase
    wire [31:0] bus_wdata;    // write data
    reg  [31:0] bus_rdata;    // read data, driven by the read mux

    // Strobes: which register the bus writes or reads
    wire wen_ctrl0;     // write enable of CTRL0
    wire wen_ctrl1;     // write enable of CTRL1
    wire wen_ctrl2;     // write enable of CTRL2
    wire wen_ctrl3;     // write enable of CTRL3
    wire wen_ctrl4;     // write enable of CTRL4
    wire wen_ctrl5;     // write enable of CTRL5
    wire wen_ctrl6;     // write enable of CTRL6
    wire wen_ctrl7;     // write enable of CTRL7
    wire wen_ctrl8;     // write enable of CTRL8
    wire wen_ctrl9;     // write enable of CTRL9
    wire wen_ctrl10;    // write enable of CTRL10
    wire wen_ctrl11;    // write enable of CTRL11
    wire wen_ctrl12;    // write enable of CTRL12
    wire wen_ctrl13;    // write enable of CTRL13
    wire wen_ctrl14;    // write enable of CTRL14
    wire wen_ctrl15;    // write enable of CTRL15
    wire wen_ctrl16;    // write enable of CTRL16
    wire wen_ctrl17;    // write enable of CTRL17
    wire wen_ctrl18;    // write enable of CTRL18
    wire wen_ctrl19;    // write enable of CTRL19
    wire wen_ctrl20;    // write enable of CTRL20
    wire wen_ctrl21;    // write enable of CTRL21
    wire wen_ctrl22;    // write enable of CTRL22
    wire wen_ctrl23;    // write enable of CTRL23
    wire wen_ctrl24;    // write enable of CTRL24
    wire wen_ctrl25;    // write enable of CTRL25
    wire wen_ctrl26;    // write enable of CTRL26
    wire wen_ctrl27;    // write enable of CTRL27
    wire wen_ctrl28;    // write enable of CTRL28
    wire wen_ctrl29;    // write enable of CTRL29
    wire wen_ctrl30;    // write enable of CTRL30
    wire wen_ctrl31;    // write enable of CTRL31
    wire wen_ctrl32;    // write enable of CTRL32
    wire wen_ctrl33;    // write enable of CTRL33
    wire wen_ctrl34;    // write enable of CTRL34
    wire wen_ctrl35;    // write enable of CTRL35
    wire wen_ctrl36;    // write enable of CTRL36
    wire wen_ctrl37;    // write enable of CTRL37
    wire wen_ctrl38;    // write enable of CTRL38
    wire wen_ctrl39;    // write enable of CTRL39
    wire wen_ctrl40;    // write enable of CTRL40
    wire wen_ctrl41;    // write enable of CTRL41
    wire wen_ctrl42;    // write enable of CTRL42
    wire wen_ctrl43;    // write enable of CTRL43
    wire wen_ctrl44;    // write enable of CTRL44
    wire wen_ctrl45;    // write enable of CTRL45
    wire wen_ctrl46;    // write enable of CTRL46
    wire wen_ctrl47;    // write enable of CTRL47
    wire wen_ctrl48;    // write enable of CTRL48
    wire wen_ctrl49;    // write enable of CTRL49
    wire wen_ctrl50;    // write enable of CTRL50
    wire wen_ctrl51;    // write enable of CTRL51
    wire wen_ctrl52;    // write enable of CTRL52
    wire wen_ctrl53;    // write enable of CTRL53
    wire wen_ctrl54;    // write enable of CTRL54
    wire wen_ctrl55;    // write enable of CTRL55
    wire wen_ctrl56;    // write enable of CTRL56
    wire wen_ctrl57;    // write enable of CTRL57
    wire wen_ctrl58;    // write enable of CTRL58
    wire wen_ctrl59;    // write enable of CTRL59
    wire wen_ctrl60;    // write enable of CTRL60
    wire wen_ctrl61;    // write enable of CTRL61
    wire wen_out0;      // write enable of OUT0
    wire wen_out1;      // write enable of OUT1
    wire wen_oe0;       // write enable of OE0
    wire wen_oe1;       // write enable of OE1
    wire wen_out0_set;  // write enable of OUT0_SET: the set effect on OUT0
    wire wen_out1_set;  // write enable of OUT1_SET: the set effect on OUT1
    wire wen_out0_clr;  // write enable of OUT0_CLR: the clear effect on OUT0
    wire wen_out1_clr;  // write enable of OUT1_CLR: the clear effect on OUT1
    wire wen_out0_xor;  // write enable of OUT0_XOR: the toggle effect on OUT0
    wire wen_out1_xor;  // write enable of OUT1_XOR: the toggle effect on OUT1
    wire wen_oe0_set;   // write enable of OE0_SET: the set effect on OE0
    wire wen_oe1_set;   // write enable of OE1_SET: the set effect on OE1
    wire wen_oe0_clr;   // write enable of OE0_CLR: the clear effect on OE0
    wire wen_oe1_clr;   // write enable of OE1_CLR: the clear effect on OE1
    wire wen_oe0_xor;   // write enable of OE0_XOR: the toggle effect on OE0
    wire wen_oe1_xor;   // write enable of OE1_XOR: the toggle effect on OE1

    // Register field wires: read them in your logic, drive the ones marked
    wire ctrl0_funcsel;   // CTRL0.FUNCSEL [0:0] rw
    wire ctrl1_funcsel;   // CTRL1.FUNCSEL [0:0] rw
    wire ctrl2_funcsel;   // CTRL2.FUNCSEL [0:0] rw
    wire ctrl3_funcsel;   // CTRL3.FUNCSEL [0:0] rw
    wire ctrl4_funcsel;   // CTRL4.FUNCSEL [0:0] rw
    wire ctrl5_funcsel;   // CTRL5.FUNCSEL [0:0] rw
    wire ctrl6_funcsel;   // CTRL6.FUNCSEL [0:0] rw
    wire ctrl7_funcsel;   // CTRL7.FUNCSEL [0:0] rw
    wire ctrl8_funcsel;   // CTRL8.FUNCSEL [0:0] rw
    wire ctrl9_funcsel;   // CTRL9.FUNCSEL [0:0] rw
    wire ctrl10_funcsel;  // CTRL10.FUNCSEL [0:0] rw
    wire ctrl11_funcsel;  // CTRL11.FUNCSEL [0:0] rw
    wire ctrl12_funcsel;  // CTRL12.FUNCSEL [0:0] rw
    wire ctrl13_funcsel;  // CTRL13.FUNCSEL [0:0] rw
    wire ctrl14_funcsel;  // CTRL14.FUNCSEL [0:0] rw
    wire ctrl15_funcsel;  // CTRL15.FUNCSEL [0:0] rw
    wire ctrl16_funcsel;  // CTRL16.FUNCSEL [0:0] rw
    wire ctrl17_funcsel;  // CTRL17.FUNCSEL [0:0] rw
    wire ctrl18_funcsel;  // CTRL18.FUNCSEL [0:0] rw
    wire ctrl19_funcsel;  // CTRL19.FUNCSEL [0:0] rw
    wire ctrl20_funcsel;  // CTRL20.FUNCSEL [0:0] rw
    wire ctrl21_funcsel;  // CTRL21.FUNCSEL [0:0] rw
    wire ctrl22_funcsel;  // CTRL22.FUNCSEL [0:0] rw
    wire ctrl23_funcsel;  // CTRL23.FUNCSEL [0:0] rw
    wire ctrl24_funcsel;  // CTRL24.FUNCSEL [0:0] rw
    wire ctrl25_funcsel;  // CTRL25.FUNCSEL [0:0] rw
    wire ctrl26_funcsel;  // CTRL26.FUNCSEL [0:0] rw
    wire ctrl27_funcsel;  // CTRL27.FUNCSEL [0:0] rw
    wire ctrl28_funcsel;  // CTRL28.FUNCSEL [0:0] rw
    wire ctrl29_funcsel;  // CTRL29.FUNCSEL [0:0] rw
    wire ctrl30_funcsel;  // CTRL30.FUNCSEL [0:0] rw
    wire ctrl31_funcsel;  // CTRL31.FUNCSEL [0:0] rw
    wire ctrl32_funcsel;  // CTRL32.FUNCSEL [0:0] rw
    wire ctrl33_funcsel;  // CTRL33.FUNCSEL [0:0] rw
    wire ctrl34_funcsel;  // CTRL34.FUNCSEL [0:0] rw
    wire ctrl35_funcsel;  // CTRL35.FUNCSEL [0:0] rw
    wire ctrl36_funcsel;  // CTRL36.FUNCSEL [0:0] rw
    wire ctrl37_funcsel;  // CTRL37.FUNCSEL [0:0] rw
    wire ctrl38_funcsel;  // CTRL38.FUNCSEL [0:0] rw
    wire ctrl39_funcsel;  // CTRL39.FUNCSEL [0:0] rw
    wire ctrl40_funcsel;  // CTRL40.FUNCSEL [0:0] rw
    wire ctrl41_funcsel;  // CTRL41.FUNCSEL [0:0] rw
    wire ctrl42_funcsel;  // CTRL42.FUNCSEL [0:0] rw
    wire ctrl43_funcsel;  // CTRL43.FUNCSEL [0:0] rw
    wire ctrl44_funcsel;  // CTRL44.FUNCSEL [0:0] rw
    wire ctrl45_funcsel;  // CTRL45.FUNCSEL [0:0] rw
    wire ctrl46_funcsel;  // CTRL46.FUNCSEL [0:0] rw
    wire ctrl47_funcsel;  // CTRL47.FUNCSEL [0:0] rw
    wire ctrl48_funcsel;  // CTRL48.FUNCSEL [0:0] rw
    wire ctrl49_funcsel;  // CTRL49.FUNCSEL [0:0] rw
    wire ctrl50_funcsel;  // CTRL50.FUNCSEL [0:0] rw
    wire ctrl51_funcsel;  // CTRL51.FUNCSEL [0:0] rw
    wire ctrl52_funcsel;  // CTRL52.FUNCSEL [0:0] rw
    wire ctrl53_funcsel;  // CTRL53.FUNCSEL [0:0] rw
    wire ctrl54_funcsel;  // CTRL54.FUNCSEL [0:0] rw
    wire ctrl55_funcsel;  // CTRL55.FUNCSEL [0:0] rw
    wire ctrl56_funcsel;  // CTRL56.FUNCSEL [0:0] rw
    wire ctrl57_funcsel;  // CTRL57.FUNCSEL [0:0] rw
    wire ctrl58_funcsel;  // CTRL58.FUNCSEL [0:0] rw
    wire ctrl59_funcsel;  // CTRL59.FUNCSEL [0:0] rw
    wire ctrl60_funcsel;  // CTRL60.FUNCSEL [0:0] rw
    wire ctrl61_funcsel;  // CTRL61.FUNCSEL [0:0] rw
    wire out0_p0;         // OUT0.P0 [0:0] rw
    wire out0_p1;         // OUT0.P1 [1:1] rw
    wire out0_p2;         // OUT0.P2 [2:2] rw
    wire out0_p3;         // OUT0.P3 [3:3] rw
    wire out0_p4;         // OUT0.P4 [4:4] rw
    wire out0_p5;         // OUT0.P5 [5:5] rw
    wire out0_p6;         // OUT0.P6 [6:6] rw
    wire out0_p7;         // OUT0.P7 [7:7] rw
    wire out0_p8;         // OUT0.P8 [8:8] rw
    wire out0_p9;         // OUT0.P9 [9:9] rw
    wire out0_p10;        // OUT0.P10 [10:10] rw
    wire out0_p11;        // OUT0.P11 [11:11] rw
    wire out0_p12;        // OUT0.P12 [12:12] rw
    wire out0_p13;        // OUT0.P13 [13:13] rw
    wire out0_p14;        // OUT0.P14 [14:14] rw
    wire out0_p15;        // OUT0.P15 [15:15] rw
    wire out0_p16;        // OUT0.P16 [16:16] rw
    wire out0_p17;        // OUT0.P17 [17:17] rw
    wire out0_p18;        // OUT0.P18 [18:18] rw
    wire out0_p19;        // OUT0.P19 [19:19] rw
    wire out0_p20;        // OUT0.P20 [20:20] rw
    wire out0_p21;        // OUT0.P21 [21:21] rw
    wire out0_p22;        // OUT0.P22 [22:22] rw
    wire out0_p23;        // OUT0.P23 [23:23] rw
    wire out0_p24;        // OUT0.P24 [24:24] rw
    wire out0_p25;        // OUT0.P25 [25:25] rw
    wire out0_p26;        // OUT0.P26 [26:26] rw
    wire out0_p27;        // OUT0.P27 [27:27] rw
    wire out0_p28;        // OUT0.P28 [28:28] rw
    wire out0_p29;        // OUT0.P29 [29:29] rw
    wire out0_p30;        // OUT0.P30 [30:30] rw
    wire out0_p31;        // OUT0.P31 [31:31] rw
    wire out1_p32;        // OUT1.P32 [0:0] rw
    wire out1_p33;        // OUT1.P33 [1:1] rw
    wire out1_p34;        // OUT1.P34 [2:2] rw
    wire out1_p35;        // OUT1.P35 [3:3] rw
    wire out1_p36;        // OUT1.P36 [4:4] rw
    wire out1_p37;        // OUT1.P37 [5:5] rw
    wire out1_p38;        // OUT1.P38 [6:6] rw
    wire out1_p39;        // OUT1.P39 [7:7] rw
    wire out1_p40;        // OUT1.P40 [8:8] rw
    wire out1_p41;        // OUT1.P41 [9:9] rw
    wire out1_p42;        // OUT1.P42 [10:10] rw
    wire out1_p43;        // OUT1.P43 [11:11] rw
    wire out1_p44;        // OUT1.P44 [12:12] rw
    wire out1_p45;        // OUT1.P45 [13:13] rw
    wire out1_p46;        // OUT1.P46 [14:14] rw
    wire out1_p47;        // OUT1.P47 [15:15] rw
    wire out1_p48;        // OUT1.P48 [16:16] rw
    wire out1_p49;        // OUT1.P49 [17:17] rw
    wire out1_p50;        // OUT1.P50 [18:18] rw
    wire out1_p51;        // OUT1.P51 [19:19] rw
    wire out1_p52;        // OUT1.P52 [20:20] rw
    wire out1_p53;        // OUT1.P53 [21:21] rw
    wire out1_p54;        // OUT1.P54 [22:22] rw
    wire out1_p55;        // OUT1.P55 [23:23] rw
    wire out1_p56;        // OUT1.P56 [24:24] rw
    wire out1_p57;        // OUT1.P57 [25:25] rw
    wire out1_p58;        // OUT1.P58 [26:26] rw
    wire out1_p59;        // OUT1.P59 [27:27] rw
    wire out1_p60;        // OUT1.P60 [28:28] rw
    wire out1_p61;        // OUT1.P61 [29:29] rw
    wire oe0_p0;          // OE0.P0 [0:0] rw
    wire oe0_p1;          // OE0.P1 [1:1] rw
    wire oe0_p2;          // OE0.P2 [2:2] rw
    wire oe0_p3;          // OE0.P3 [3:3] rw
    wire oe0_p4;          // OE0.P4 [4:4] rw
    wire oe0_p5;          // OE0.P5 [5:5] rw
    wire oe0_p6;          // OE0.P6 [6:6] rw
    wire oe0_p7;          // OE0.P7 [7:7] rw
    wire oe0_p8;          // OE0.P8 [8:8] rw
    wire oe0_p9;          // OE0.P9 [9:9] rw
    wire oe0_p10;         // OE0.P10 [10:10] rw
    wire oe0_p11;         // OE0.P11 [11:11] rw
    wire oe0_p12;         // OE0.P12 [12:12] rw
    wire oe0_p13;         // OE0.P13 [13:13] rw
    wire oe0_p14;         // OE0.P14 [14:14] rw
    wire oe0_p15;         // OE0.P15 [15:15] rw
    wire oe0_p16;         // OE0.P16 [16:16] rw
    wire oe0_p17;         // OE0.P17 [17:17] rw
    wire oe0_p18;         // OE0.P18 [18:18] rw
    wire oe0_p19;         // OE0.P19 [19:19] rw
    wire oe0_p20;         // OE0.P20 [20:20] rw
    wire oe0_p21;         // OE0.P21 [21:21] rw
    wire oe0_p22;         // OE0.P22 [22:22] rw
    wire oe0_p23;         // OE0.P23 [23:23] rw
    wire oe0_p24;         // OE0.P24 [24:24] rw
    wire oe0_p25;         // OE0.P25 [25:25] rw
    wire oe0_p26;         // OE0.P26 [26:26] rw
    wire oe0_p27;         // OE0.P27 [27:27] rw
    wire oe0_p28;         // OE0.P28 [28:28] rw
    wire oe0_p29;         // OE0.P29 [29:29] rw
    wire oe0_p30;         // OE0.P30 [30:30] rw
    wire oe0_p31;         // OE0.P31 [31:31] rw
    wire oe1_p32;         // OE1.P32 [0:0] rw
    wire oe1_p33;         // OE1.P33 [1:1] rw
    wire oe1_p34;         // OE1.P34 [2:2] rw
    wire oe1_p35;         // OE1.P35 [3:3] rw
    wire oe1_p36;         // OE1.P36 [4:4] rw
    wire oe1_p37;         // OE1.P37 [5:5] rw
    wire oe1_p38;         // OE1.P38 [6:6] rw
    wire oe1_p39;         // OE1.P39 [7:7] rw
    wire oe1_p40;         // OE1.P40 [8:8] rw
    wire oe1_p41;         // OE1.P41 [9:9] rw
    wire oe1_p42;         // OE1.P42 [10:10] rw
    wire oe1_p43;         // OE1.P43 [11:11] rw
    wire oe1_p44;         // OE1.P44 [12:12] rw
    wire oe1_p45;         // OE1.P45 [13:13] rw
    wire oe1_p46;         // OE1.P46 [14:14] rw
    wire oe1_p47;         // OE1.P47 [15:15] rw
    wire oe1_p48;         // OE1.P48 [16:16] rw
    wire oe1_p49;         // OE1.P49 [17:17] rw
    wire oe1_p50;         // OE1.P50 [18:18] rw
    wire oe1_p51;         // OE1.P51 [19:19] rw
    wire oe1_p52;         // OE1.P52 [20:20] rw
    wire oe1_p53;         // OE1.P53 [21:21] rw
    wire oe1_p54;         // OE1.P54 [22:22] rw
    wire oe1_p55;         // OE1.P55 [23:23] rw
    wire oe1_p56;         // OE1.P56 [24:24] rw
    wire oe1_p57;         // OE1.P57 [25:25] rw
    wire oe1_p58;         // OE1.P58 [26:26] rw
    wire oe1_p59;         // OE1.P59 [27:27] rw
    wire oe1_p60;         // OE1.P60 [28:28] rw
    wire oe1_p61;         // OE1.P61 [29:29] rw
    wire in0_p0;          // IN0.P0 [0:0] ro, drive it in your logic
    wire in0_p1;          // IN0.P1 [1:1] ro, drive it in your logic
    wire in0_p2;          // IN0.P2 [2:2] ro, drive it in your logic
    wire in0_p3;          // IN0.P3 [3:3] ro, drive it in your logic
    wire in0_p4;          // IN0.P4 [4:4] ro, drive it in your logic
    wire in0_p5;          // IN0.P5 [5:5] ro, drive it in your logic
    wire in0_p6;          // IN0.P6 [6:6] ro, drive it in your logic
    wire in0_p7;          // IN0.P7 [7:7] ro, drive it in your logic
    wire in0_p8;          // IN0.P8 [8:8] ro, drive it in your logic
    wire in0_p9;          // IN0.P9 [9:9] ro, drive it in your logic
    wire in0_p10;         // IN0.P10 [10:10] ro, drive it in your logic
    wire in0_p11;         // IN0.P11 [11:11] ro, drive it in your logic
    wire in0_p12;         // IN0.P12 [12:12] ro, drive it in your logic
    wire in0_p13;         // IN0.P13 [13:13] ro, drive it in your logic
    wire in0_p14;         // IN0.P14 [14:14] ro, drive it in your logic
    wire in0_p15;         // IN0.P15 [15:15] ro, drive it in your logic
    wire in0_p16;         // IN0.P16 [16:16] ro, drive it in your logic
    wire in0_p17;         // IN0.P17 [17:17] ro, drive it in your logic
    wire in0_p18;         // IN0.P18 [18:18] ro, drive it in your logic
    wire in0_p19;         // IN0.P19 [19:19] ro, drive it in your logic
    wire in0_p20;         // IN0.P20 [20:20] ro, drive it in your logic
    wire in0_p21;         // IN0.P21 [21:21] ro, drive it in your logic
    wire in0_p22;         // IN0.P22 [22:22] ro, drive it in your logic
    wire in0_p23;         // IN0.P23 [23:23] ro, drive it in your logic
    wire in0_p24;         // IN0.P24 [24:24] ro, drive it in your logic
    wire in0_p25;         // IN0.P25 [25:25] ro, drive it in your logic
    wire in0_p26;         // IN0.P26 [26:26] ro, drive it in your logic
    wire in0_p27;         // IN0.P27 [27:27] ro, drive it in your logic
    wire in0_p28;         // IN0.P28 [28:28] ro, drive it in your logic
    wire in0_p29;         // IN0.P29 [29:29] ro, drive it in your logic
    wire in0_p30;         // IN0.P30 [30:30] ro, drive it in your logic
    wire in0_p31;         // IN0.P31 [31:31] ro, drive it in your logic
    wire in1_p32;         // IN1.P32 [0:0] ro, drive it in your logic
    wire in1_p33;         // IN1.P33 [1:1] ro, drive it in your logic
    wire in1_p34;         // IN1.P34 [2:2] ro, drive it in your logic
    wire in1_p35;         // IN1.P35 [3:3] ro, drive it in your logic
    wire in1_p36;         // IN1.P36 [4:4] ro, drive it in your logic
    wire in1_p37;         // IN1.P37 [5:5] ro, drive it in your logic
    wire in1_p38;         // IN1.P38 [6:6] ro, drive it in your logic
    wire in1_p39;         // IN1.P39 [7:7] ro, drive it in your logic
    wire in1_p40;         // IN1.P40 [8:8] ro, drive it in your logic
    wire in1_p41;         // IN1.P41 [9:9] ro, drive it in your logic
    wire in1_p42;         // IN1.P42 [10:10] ro, drive it in your logic
    wire in1_p43;         // IN1.P43 [11:11] ro, drive it in your logic
    wire in1_p44;         // IN1.P44 [12:12] ro, drive it in your logic
    wire in1_p45;         // IN1.P45 [13:13] ro, drive it in your logic
    wire in1_p46;         // IN1.P46 [14:14] ro, drive it in your logic
    wire in1_p47;         // IN1.P47 [15:15] ro, drive it in your logic
    wire in1_p48;         // IN1.P48 [16:16] ro, drive it in your logic
    wire in1_p49;         // IN1.P49 [17:17] ro, drive it in your logic
    wire in1_p50;         // IN1.P50 [18:18] ro, drive it in your logic
    wire in1_p51;         // IN1.P51 [19:19] ro, drive it in your logic
    wire in1_p52;         // IN1.P52 [20:20] ro, drive it in your logic
    wire in1_p53;         // IN1.P53 [21:21] ro, drive it in your logic
    wire in1_p54;         // IN1.P54 [22:22] ro, drive it in your logic
    wire in1_p55;         // IN1.P55 [23:23] ro, drive it in your logic
    wire in1_p56;         // IN1.P56 [24:24] ro, drive it in your logic
    wire in1_p57;         // IN1.P57 [25:25] ro, drive it in your logic
    wire in1_p58;         // IN1.P58 [26:26] ro, drive it in your logic
    wire in1_p59;         // IN1.P59 [27:27] ro, drive it in your logic
    wire in1_p60;         // IN1.P60 [28:28] ro, drive it in your logic
    wire in1_p61;         // IN1.P61 [29:29] ro, drive it in your logic

    // Field flops
    reg  reg_ctrl0_funcsel;
    reg  reg_ctrl1_funcsel;
    reg  reg_ctrl2_funcsel;
    reg  reg_ctrl3_funcsel;
    reg  reg_ctrl4_funcsel;
    reg  reg_ctrl5_funcsel;
    reg  reg_ctrl6_funcsel;
    reg  reg_ctrl7_funcsel;
    reg  reg_ctrl8_funcsel;
    reg  reg_ctrl9_funcsel;
    reg  reg_ctrl10_funcsel;
    reg  reg_ctrl11_funcsel;
    reg  reg_ctrl12_funcsel;
    reg  reg_ctrl13_funcsel;
    reg  reg_ctrl14_funcsel;
    reg  reg_ctrl15_funcsel;
    reg  reg_ctrl16_funcsel;
    reg  reg_ctrl17_funcsel;
    reg  reg_ctrl18_funcsel;
    reg  reg_ctrl19_funcsel;
    reg  reg_ctrl20_funcsel;
    reg  reg_ctrl21_funcsel;
    reg  reg_ctrl22_funcsel;
    reg  reg_ctrl23_funcsel;
    reg  reg_ctrl24_funcsel;
    reg  reg_ctrl25_funcsel;
    reg  reg_ctrl26_funcsel;
    reg  reg_ctrl27_funcsel;
    reg  reg_ctrl28_funcsel;
    reg  reg_ctrl29_funcsel;
    reg  reg_ctrl30_funcsel;
    reg  reg_ctrl31_funcsel;
    reg  reg_ctrl32_funcsel;
    reg  reg_ctrl33_funcsel;
    reg  reg_ctrl34_funcsel;
    reg  reg_ctrl35_funcsel;
    reg  reg_ctrl36_funcsel;
    reg  reg_ctrl37_funcsel;
    reg  reg_ctrl38_funcsel;
    reg  reg_ctrl39_funcsel;
    reg  reg_ctrl40_funcsel;
    reg  reg_ctrl41_funcsel;
    reg  reg_ctrl42_funcsel;
    reg  reg_ctrl43_funcsel;
    reg  reg_ctrl44_funcsel;
    reg  reg_ctrl45_funcsel;
    reg  reg_ctrl46_funcsel;
    reg  reg_ctrl47_funcsel;
    reg  reg_ctrl48_funcsel;
    reg  reg_ctrl49_funcsel;
    reg  reg_ctrl50_funcsel;
    reg  reg_ctrl51_funcsel;
    reg  reg_ctrl52_funcsel;
    reg  reg_ctrl53_funcsel;
    reg  reg_ctrl54_funcsel;
    reg  reg_ctrl55_funcsel;
    reg  reg_ctrl56_funcsel;
    reg  reg_ctrl57_funcsel;
    reg  reg_ctrl58_funcsel;
    reg  reg_ctrl59_funcsel;
    reg  reg_ctrl60_funcsel;
    reg  reg_ctrl61_funcsel;
    reg  reg_out0_p0;
    reg  reg_out0_p1;
    reg  reg_out0_p2;
    reg  reg_out0_p3;
    reg  reg_out0_p4;
    reg  reg_out0_p5;
    reg  reg_out0_p6;
    reg  reg_out0_p7;
    reg  reg_out0_p8;
    reg  reg_out0_p9;
    reg  reg_out0_p10;
    reg  reg_out0_p11;
    reg  reg_out0_p12;
    reg  reg_out0_p13;
    reg  reg_out0_p14;
    reg  reg_out0_p15;
    reg  reg_out0_p16;
    reg  reg_out0_p17;
    reg  reg_out0_p18;
    reg  reg_out0_p19;
    reg  reg_out0_p20;
    reg  reg_out0_p21;
    reg  reg_out0_p22;
    reg  reg_out0_p23;
    reg  reg_out0_p24;
    reg  reg_out0_p25;
    reg  reg_out0_p26;
    reg  reg_out0_p27;
    reg  reg_out0_p28;
    reg  reg_out0_p29;
    reg  reg_out0_p30;
    reg  reg_out0_p31;
    reg  reg_out1_p32;
    reg  reg_out1_p33;
    reg  reg_out1_p34;
    reg  reg_out1_p35;
    reg  reg_out1_p36;
    reg  reg_out1_p37;
    reg  reg_out1_p38;
    reg  reg_out1_p39;
    reg  reg_out1_p40;
    reg  reg_out1_p41;
    reg  reg_out1_p42;
    reg  reg_out1_p43;
    reg  reg_out1_p44;
    reg  reg_out1_p45;
    reg  reg_out1_p46;
    reg  reg_out1_p47;
    reg  reg_out1_p48;
    reg  reg_out1_p49;
    reg  reg_out1_p50;
    reg  reg_out1_p51;
    reg  reg_out1_p52;
    reg  reg_out1_p53;
    reg  reg_out1_p54;
    reg  reg_out1_p55;
    reg  reg_out1_p56;
    reg  reg_out1_p57;
    reg  reg_out1_p58;
    reg  reg_out1_p59;
    reg  reg_out1_p60;
    reg  reg_out1_p61;
    reg  reg_oe0_p0;
    reg  reg_oe0_p1;
    reg  reg_oe0_p2;
    reg  reg_oe0_p3;
    reg  reg_oe0_p4;
    reg  reg_oe0_p5;
    reg  reg_oe0_p6;
    reg  reg_oe0_p7;
    reg  reg_oe0_p8;
    reg  reg_oe0_p9;
    reg  reg_oe0_p10;
    reg  reg_oe0_p11;
    reg  reg_oe0_p12;
    reg  reg_oe0_p13;
    reg  reg_oe0_p14;
    reg  reg_oe0_p15;
    reg  reg_oe0_p16;
    reg  reg_oe0_p17;
    reg  reg_oe0_p18;
    reg  reg_oe0_p19;
    reg  reg_oe0_p20;
    reg  reg_oe0_p21;
    reg  reg_oe0_p22;
    reg  reg_oe0_p23;
    reg  reg_oe0_p24;
    reg  reg_oe0_p25;
    reg  reg_oe0_p26;
    reg  reg_oe0_p27;
    reg  reg_oe0_p28;
    reg  reg_oe0_p29;
    reg  reg_oe0_p30;
    reg  reg_oe0_p31;
    reg  reg_oe1_p32;
    reg  reg_oe1_p33;
    reg  reg_oe1_p34;
    reg  reg_oe1_p35;
    reg  reg_oe1_p36;
    reg  reg_oe1_p37;
    reg  reg_oe1_p38;
    reg  reg_oe1_p39;
    reg  reg_oe1_p40;
    reg  reg_oe1_p41;
    reg  reg_oe1_p42;
    reg  reg_oe1_p43;
    reg  reg_oe1_p44;
    reg  reg_oe1_p45;
    reg  reg_oe1_p46;
    reg  reg_oe1_p47;
    reg  reg_oe1_p48;
    reg  reg_oe1_p49;
    reg  reg_oe1_p50;
    reg  reg_oe1_p51;
    reg  reg_oe1_p52;
    reg  reg_oe1_p53;
    reg  reg_oe1_p54;
    reg  reg_oe1_p55;
    reg  reg_oe1_p56;
    reg  reg_oe1_p57;
    reg  reg_oe1_p58;
    reg  reg_oe1_p59;
    reg  reg_oe1_p60;
    reg  reg_oe1_p61;

    reg  [PINS-1:0] pad_in_meta;  // pad_in, first flop
    reg  [PINS-1:0] pad_in_sync;  // pad_in, second flop: what IN reads

    // Function slots
    localparam int FN_RACER0_HSYNC = 0;  // racer0.hsync, bit of fn_out/fn_oe
    localparam int FN_RACER0_VSYNC = 1;  // racer0.vsync, bit of fn_out/fn_oe
    localparam int FN_RACER0_RGB_BASE = 2;  // racer0.rgb, first bit of fn_out/fn_oe
    localparam int FN_RACER0_RGB_W = 12;  // racer0.rgb, number of bits

    // A wire per function slot
    wire racer0_hsync = fn_out[FN_RACER0_HSYNC];
    wire racer0_vsync = fn_out[FN_RACER0_VSYNC];
    wire [FN_RACER0_RGB_W-1:0] racer0_rgb = fn_out[FN_RACER0_RGB_BASE +: FN_RACER0_RGB_W];

    // Address phase captured for the data phase
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_sel_r   <= 1'b0;
            bus_write_r <= 1'b0;
            bus_addr_r  <= 12'h0;
        end else begin
            bus_sel_r <= htrans[1];
            if (htrans[1]) begin
                bus_write_r <= hwrite;
                bus_addr_r  <= haddr[11:0];
            end
        end
    end

    // Data-phase strobes, address and write data; the answer on the bus
    assign bus_wr    = bus_sel_r &  bus_write_r;
    assign bus_rd    = bus_sel_r & ~bus_write_r;
    assign bus_addr  = bus_addr_r;
    assign bus_wdata = hwdata;
    assign hrdata = bus_rdata;
    assign hready = 1'b1;   // no wait states
    assign hresp  = 1'b0;   // never an error

    // Which register is being written or read
    // write enable per register
    assign wen_ctrl0 = bus_wr && (bus_addr == 12'h000);
    assign wen_ctrl1 = bus_wr && (bus_addr == 12'h004);
    assign wen_ctrl2 = bus_wr && (bus_addr == 12'h008);
    assign wen_ctrl3 = bus_wr && (bus_addr == 12'h00C);
    assign wen_ctrl4 = bus_wr && (bus_addr == 12'h010);
    assign wen_ctrl5 = bus_wr && (bus_addr == 12'h014);
    assign wen_ctrl6 = bus_wr && (bus_addr == 12'h018);
    assign wen_ctrl7 = bus_wr && (bus_addr == 12'h01C);
    assign wen_ctrl8 = bus_wr && (bus_addr == 12'h020);
    assign wen_ctrl9 = bus_wr && (bus_addr == 12'h024);
    assign wen_ctrl10 = bus_wr && (bus_addr == 12'h028);
    assign wen_ctrl11 = bus_wr && (bus_addr == 12'h02C);
    assign wen_ctrl12 = bus_wr && (bus_addr == 12'h030);
    assign wen_ctrl13 = bus_wr && (bus_addr == 12'h034);
    assign wen_ctrl14 = bus_wr && (bus_addr == 12'h038);
    assign wen_ctrl15 = bus_wr && (bus_addr == 12'h03C);
    assign wen_ctrl16 = bus_wr && (bus_addr == 12'h040);
    assign wen_ctrl17 = bus_wr && (bus_addr == 12'h044);
    assign wen_ctrl18 = bus_wr && (bus_addr == 12'h048);
    assign wen_ctrl19 = bus_wr && (bus_addr == 12'h04C);
    assign wen_ctrl20 = bus_wr && (bus_addr == 12'h050);
    assign wen_ctrl21 = bus_wr && (bus_addr == 12'h054);
    assign wen_ctrl22 = bus_wr && (bus_addr == 12'h058);
    assign wen_ctrl23 = bus_wr && (bus_addr == 12'h05C);
    assign wen_ctrl24 = bus_wr && (bus_addr == 12'h060);
    assign wen_ctrl25 = bus_wr && (bus_addr == 12'h064);
    assign wen_ctrl26 = bus_wr && (bus_addr == 12'h068);
    assign wen_ctrl27 = bus_wr && (bus_addr == 12'h06C);
    assign wen_ctrl28 = bus_wr && (bus_addr == 12'h070);
    assign wen_ctrl29 = bus_wr && (bus_addr == 12'h074);
    assign wen_ctrl30 = bus_wr && (bus_addr == 12'h078);
    assign wen_ctrl31 = bus_wr && (bus_addr == 12'h07C);
    assign wen_ctrl32 = bus_wr && (bus_addr == 12'h080);
    assign wen_ctrl33 = bus_wr && (bus_addr == 12'h084);
    assign wen_ctrl34 = bus_wr && (bus_addr == 12'h088);
    assign wen_ctrl35 = bus_wr && (bus_addr == 12'h08C);
    assign wen_ctrl36 = bus_wr && (bus_addr == 12'h090);
    assign wen_ctrl37 = bus_wr && (bus_addr == 12'h094);
    assign wen_ctrl38 = bus_wr && (bus_addr == 12'h098);
    assign wen_ctrl39 = bus_wr && (bus_addr == 12'h09C);
    assign wen_ctrl40 = bus_wr && (bus_addr == 12'h0A0);
    assign wen_ctrl41 = bus_wr && (bus_addr == 12'h0A4);
    assign wen_ctrl42 = bus_wr && (bus_addr == 12'h0A8);
    assign wen_ctrl43 = bus_wr && (bus_addr == 12'h0AC);
    assign wen_ctrl44 = bus_wr && (bus_addr == 12'h0B0);
    assign wen_ctrl45 = bus_wr && (bus_addr == 12'h0B4);
    assign wen_ctrl46 = bus_wr && (bus_addr == 12'h0B8);
    assign wen_ctrl47 = bus_wr && (bus_addr == 12'h0BC);
    assign wen_ctrl48 = bus_wr && (bus_addr == 12'h0C0);
    assign wen_ctrl49 = bus_wr && (bus_addr == 12'h0C4);
    assign wen_ctrl50 = bus_wr && (bus_addr == 12'h0C8);
    assign wen_ctrl51 = bus_wr && (bus_addr == 12'h0CC);
    assign wen_ctrl52 = bus_wr && (bus_addr == 12'h0D0);
    assign wen_ctrl53 = bus_wr && (bus_addr == 12'h0D4);
    assign wen_ctrl54 = bus_wr && (bus_addr == 12'h0D8);
    assign wen_ctrl55 = bus_wr && (bus_addr == 12'h0DC);
    assign wen_ctrl56 = bus_wr && (bus_addr == 12'h0E0);
    assign wen_ctrl57 = bus_wr && (bus_addr == 12'h0E4);
    assign wen_ctrl58 = bus_wr && (bus_addr == 12'h0E8);
    assign wen_ctrl59 = bus_wr && (bus_addr == 12'h0EC);
    assign wen_ctrl60 = bus_wr && (bus_addr == 12'h0F0);
    assign wen_ctrl61 = bus_wr && (bus_addr == 12'h0F4);
    assign wen_out0 = bus_wr && (bus_addr == 12'h100);
    assign wen_out1 = bus_wr && (bus_addr == 12'h104);
    assign wen_oe0 = bus_wr && (bus_addr == 12'h120);
    assign wen_oe1 = bus_wr && (bus_addr == 12'h124);

    // write enable per set/clear/toggle alias
    assign wen_out0_set = bus_wr && (bus_addr == 12'h108);
    assign wen_out1_set = bus_wr && (bus_addr == 12'h10C);
    assign wen_out0_clr = bus_wr && (bus_addr == 12'h110);
    assign wen_out1_clr = bus_wr && (bus_addr == 12'h114);
    assign wen_out0_xor = bus_wr && (bus_addr == 12'h118);
    assign wen_out1_xor = bus_wr && (bus_addr == 12'h11C);
    assign wen_oe0_set = bus_wr && (bus_addr == 12'h128);
    assign wen_oe1_set = bus_wr && (bus_addr == 12'h12C);
    assign wen_oe0_clr = bus_wr && (bus_addr == 12'h130);
    assign wen_oe1_clr = bus_wr && (bus_addr == 12'h134);
    assign wen_oe0_xor = bus_wr && (bus_addr == 12'h138);
    assign wen_oe1_xor = bus_wr && (bus_addr == 12'h13C);

    // Field flops: reset, hardware, bus writes
    // rw, rwh and wo fields: reset, hardware load, writes from the bus, alias effects
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl0_funcsel <= 1'b0;
            reg_ctrl1_funcsel <= 1'b0;
            reg_ctrl2_funcsel <= 1'b0;
            reg_ctrl3_funcsel <= 1'b0;
            reg_ctrl4_funcsel <= 1'b0;
            reg_ctrl5_funcsel <= 1'b0;
            reg_ctrl6_funcsel <= 1'b0;
            reg_ctrl7_funcsel <= 1'b0;
            reg_ctrl8_funcsel <= 1'b0;
            reg_ctrl9_funcsel <= 1'b0;
            reg_ctrl10_funcsel <= 1'b0;
            reg_ctrl11_funcsel <= 1'b0;
            reg_ctrl12_funcsel <= 1'b0;
            reg_ctrl13_funcsel <= 1'b0;
            reg_ctrl14_funcsel <= 1'b0;
            reg_ctrl15_funcsel <= 1'b0;
            reg_ctrl16_funcsel <= 1'b0;
            reg_ctrl17_funcsel <= 1'b0;
            reg_ctrl18_funcsel <= 1'b0;
            reg_ctrl19_funcsel <= 1'b0;
            reg_ctrl20_funcsel <= 1'b0;
            reg_ctrl21_funcsel <= 1'b0;
            reg_ctrl22_funcsel <= 1'b0;
            reg_ctrl23_funcsel <= 1'b0;
            reg_ctrl24_funcsel <= 1'b0;
            reg_ctrl25_funcsel <= 1'b0;
            reg_ctrl26_funcsel <= 1'b0;
            reg_ctrl27_funcsel <= 1'b0;
            reg_ctrl28_funcsel <= 1'b0;
            reg_ctrl29_funcsel <= 1'b0;
            reg_ctrl30_funcsel <= 1'b0;
            reg_ctrl31_funcsel <= 1'b0;
            reg_ctrl32_funcsel <= 1'b0;
            reg_ctrl33_funcsel <= 1'b0;
            reg_ctrl34_funcsel <= 1'b0;
            reg_ctrl35_funcsel <= 1'b0;
            reg_ctrl36_funcsel <= 1'b0;
            reg_ctrl37_funcsel <= 1'b0;
            reg_ctrl38_funcsel <= 1'b0;
            reg_ctrl39_funcsel <= 1'b0;
            reg_ctrl40_funcsel <= 1'b0;
            reg_ctrl41_funcsel <= 1'b0;
            reg_ctrl42_funcsel <= 1'b0;
            reg_ctrl43_funcsel <= 1'b0;
            reg_ctrl44_funcsel <= 1'b0;
            reg_ctrl45_funcsel <= 1'b0;
            reg_ctrl46_funcsel <= 1'b0;
            reg_ctrl47_funcsel <= 1'b0;
            reg_ctrl48_funcsel <= 1'b0;
            reg_ctrl49_funcsel <= 1'b0;
            reg_ctrl50_funcsel <= 1'b0;
            reg_ctrl51_funcsel <= 1'b0;
            reg_ctrl52_funcsel <= 1'b0;
            reg_ctrl53_funcsel <= 1'b0;
            reg_ctrl54_funcsel <= 1'b0;
            reg_ctrl55_funcsel <= 1'b0;
            reg_ctrl56_funcsel <= 1'b0;
            reg_ctrl57_funcsel <= 1'b0;
            reg_ctrl58_funcsel <= 1'b0;
            reg_ctrl59_funcsel <= 1'b0;
            reg_ctrl60_funcsel <= 1'b0;
            reg_ctrl61_funcsel <= 1'b0;
            reg_out0_p0 <= 1'b0;
            reg_out0_p1 <= 1'b0;
            reg_out0_p2 <= 1'b0;
            reg_out0_p3 <= 1'b0;
            reg_out0_p4 <= 1'b0;
            reg_out0_p5 <= 1'b0;
            reg_out0_p6 <= 1'b0;
            reg_out0_p7 <= 1'b0;
            reg_out0_p8 <= 1'b0;
            reg_out0_p9 <= 1'b0;
            reg_out0_p10 <= 1'b0;
            reg_out0_p11 <= 1'b0;
            reg_out0_p12 <= 1'b0;
            reg_out0_p13 <= 1'b0;
            reg_out0_p14 <= 1'b0;
            reg_out0_p15 <= 1'b0;
            reg_out0_p16 <= 1'b0;
            reg_out0_p17 <= 1'b0;
            reg_out0_p18 <= 1'b0;
            reg_out0_p19 <= 1'b0;
            reg_out0_p20 <= 1'b0;
            reg_out0_p21 <= 1'b0;
            reg_out0_p22 <= 1'b0;
            reg_out0_p23 <= 1'b0;
            reg_out0_p24 <= 1'b0;
            reg_out0_p25 <= 1'b0;
            reg_out0_p26 <= 1'b0;
            reg_out0_p27 <= 1'b0;
            reg_out0_p28 <= 1'b0;
            reg_out0_p29 <= 1'b0;
            reg_out0_p30 <= 1'b0;
            reg_out0_p31 <= 1'b0;
            reg_out1_p32 <= 1'b0;
            reg_out1_p33 <= 1'b0;
            reg_out1_p34 <= 1'b0;
            reg_out1_p35 <= 1'b0;
            reg_out1_p36 <= 1'b0;
            reg_out1_p37 <= 1'b0;
            reg_out1_p38 <= 1'b0;
            reg_out1_p39 <= 1'b0;
            reg_out1_p40 <= 1'b0;
            reg_out1_p41 <= 1'b0;
            reg_out1_p42 <= 1'b0;
            reg_out1_p43 <= 1'b0;
            reg_out1_p44 <= 1'b0;
            reg_out1_p45 <= 1'b0;
            reg_out1_p46 <= 1'b0;
            reg_out1_p47 <= 1'b0;
            reg_out1_p48 <= 1'b0;
            reg_out1_p49 <= 1'b0;
            reg_out1_p50 <= 1'b0;
            reg_out1_p51 <= 1'b0;
            reg_out1_p52 <= 1'b0;
            reg_out1_p53 <= 1'b0;
            reg_out1_p54 <= 1'b0;
            reg_out1_p55 <= 1'b0;
            reg_out1_p56 <= 1'b0;
            reg_out1_p57 <= 1'b0;
            reg_out1_p58 <= 1'b0;
            reg_out1_p59 <= 1'b0;
            reg_out1_p60 <= 1'b0;
            reg_out1_p61 <= 1'b0;
            reg_oe0_p0 <= 1'b0;
            reg_oe0_p1 <= 1'b0;
            reg_oe0_p2 <= 1'b0;
            reg_oe0_p3 <= 1'b0;
            reg_oe0_p4 <= 1'b0;
            reg_oe0_p5 <= 1'b0;
            reg_oe0_p6 <= 1'b0;
            reg_oe0_p7 <= 1'b0;
            reg_oe0_p8 <= 1'b0;
            reg_oe0_p9 <= 1'b0;
            reg_oe0_p10 <= 1'b0;
            reg_oe0_p11 <= 1'b0;
            reg_oe0_p12 <= 1'b0;
            reg_oe0_p13 <= 1'b0;
            reg_oe0_p14 <= 1'b0;
            reg_oe0_p15 <= 1'b0;
            reg_oe0_p16 <= 1'b0;
            reg_oe0_p17 <= 1'b0;
            reg_oe0_p18 <= 1'b0;
            reg_oe0_p19 <= 1'b0;
            reg_oe0_p20 <= 1'b0;
            reg_oe0_p21 <= 1'b0;
            reg_oe0_p22 <= 1'b0;
            reg_oe0_p23 <= 1'b0;
            reg_oe0_p24 <= 1'b0;
            reg_oe0_p25 <= 1'b0;
            reg_oe0_p26 <= 1'b0;
            reg_oe0_p27 <= 1'b0;
            reg_oe0_p28 <= 1'b0;
            reg_oe0_p29 <= 1'b0;
            reg_oe0_p30 <= 1'b0;
            reg_oe0_p31 <= 1'b0;
            reg_oe1_p32 <= 1'b0;
            reg_oe1_p33 <= 1'b0;
            reg_oe1_p34 <= 1'b0;
            reg_oe1_p35 <= 1'b0;
            reg_oe1_p36 <= 1'b0;
            reg_oe1_p37 <= 1'b0;
            reg_oe1_p38 <= 1'b0;
            reg_oe1_p39 <= 1'b0;
            reg_oe1_p40 <= 1'b0;
            reg_oe1_p41 <= 1'b0;
            reg_oe1_p42 <= 1'b0;
            reg_oe1_p43 <= 1'b0;
            reg_oe1_p44 <= 1'b0;
            reg_oe1_p45 <= 1'b0;
            reg_oe1_p46 <= 1'b0;
            reg_oe1_p47 <= 1'b0;
            reg_oe1_p48 <= 1'b0;
            reg_oe1_p49 <= 1'b0;
            reg_oe1_p50 <= 1'b0;
            reg_oe1_p51 <= 1'b0;
            reg_oe1_p52 <= 1'b0;
            reg_oe1_p53 <= 1'b0;
            reg_oe1_p54 <= 1'b0;
            reg_oe1_p55 <= 1'b0;
            reg_oe1_p56 <= 1'b0;
            reg_oe1_p57 <= 1'b0;
            reg_oe1_p58 <= 1'b0;
            reg_oe1_p59 <= 1'b0;
            reg_oe1_p60 <= 1'b0;
            reg_oe1_p61 <= 1'b0;
        end else begin
            if (wen_ctrl0) reg_ctrl0_funcsel <= bus_wdata[0:0];
            if (wen_ctrl1) reg_ctrl1_funcsel <= bus_wdata[0:0];
            if (wen_ctrl2) reg_ctrl2_funcsel <= bus_wdata[0:0];
            if (wen_ctrl3) reg_ctrl3_funcsel <= bus_wdata[0:0];
            if (wen_ctrl4) reg_ctrl4_funcsel <= bus_wdata[0:0];
            if (wen_ctrl5) reg_ctrl5_funcsel <= bus_wdata[0:0];
            if (wen_ctrl6) reg_ctrl6_funcsel <= bus_wdata[0:0];
            if (wen_ctrl7) reg_ctrl7_funcsel <= bus_wdata[0:0];
            if (wen_ctrl8) reg_ctrl8_funcsel <= bus_wdata[0:0];
            if (wen_ctrl9) reg_ctrl9_funcsel <= bus_wdata[0:0];
            if (wen_ctrl10) reg_ctrl10_funcsel <= bus_wdata[0:0];
            if (wen_ctrl11) reg_ctrl11_funcsel <= bus_wdata[0:0];
            if (wen_ctrl12) reg_ctrl12_funcsel <= bus_wdata[0:0];
            if (wen_ctrl13) reg_ctrl13_funcsel <= bus_wdata[0:0];
            if (wen_ctrl14) reg_ctrl14_funcsel <= bus_wdata[0:0];
            if (wen_ctrl15) reg_ctrl15_funcsel <= bus_wdata[0:0];
            if (wen_ctrl16) reg_ctrl16_funcsel <= bus_wdata[0:0];
            if (wen_ctrl17) reg_ctrl17_funcsel <= bus_wdata[0:0];
            if (wen_ctrl18) reg_ctrl18_funcsel <= bus_wdata[0:0];
            if (wen_ctrl19) reg_ctrl19_funcsel <= bus_wdata[0:0];
            if (wen_ctrl20) reg_ctrl20_funcsel <= bus_wdata[0:0];
            if (wen_ctrl21) reg_ctrl21_funcsel <= bus_wdata[0:0];
            if (wen_ctrl22) reg_ctrl22_funcsel <= bus_wdata[0:0];
            if (wen_ctrl23) reg_ctrl23_funcsel <= bus_wdata[0:0];
            if (wen_ctrl24) reg_ctrl24_funcsel <= bus_wdata[0:0];
            if (wen_ctrl25) reg_ctrl25_funcsel <= bus_wdata[0:0];
            if (wen_ctrl26) reg_ctrl26_funcsel <= bus_wdata[0:0];
            if (wen_ctrl27) reg_ctrl27_funcsel <= bus_wdata[0:0];
            if (wen_ctrl28) reg_ctrl28_funcsel <= bus_wdata[0:0];
            if (wen_ctrl29) reg_ctrl29_funcsel <= bus_wdata[0:0];
            if (wen_ctrl30) reg_ctrl30_funcsel <= bus_wdata[0:0];
            if (wen_ctrl31) reg_ctrl31_funcsel <= bus_wdata[0:0];
            if (wen_ctrl32) reg_ctrl32_funcsel <= bus_wdata[0:0];
            if (wen_ctrl33) reg_ctrl33_funcsel <= bus_wdata[0:0];
            if (wen_ctrl34) reg_ctrl34_funcsel <= bus_wdata[0:0];
            if (wen_ctrl35) reg_ctrl35_funcsel <= bus_wdata[0:0];
            if (wen_ctrl36) reg_ctrl36_funcsel <= bus_wdata[0:0];
            if (wen_ctrl37) reg_ctrl37_funcsel <= bus_wdata[0:0];
            if (wen_ctrl38) reg_ctrl38_funcsel <= bus_wdata[0:0];
            if (wen_ctrl39) reg_ctrl39_funcsel <= bus_wdata[0:0];
            if (wen_ctrl40) reg_ctrl40_funcsel <= bus_wdata[0:0];
            if (wen_ctrl41) reg_ctrl41_funcsel <= bus_wdata[0:0];
            if (wen_ctrl42) reg_ctrl42_funcsel <= bus_wdata[0:0];
            if (wen_ctrl43) reg_ctrl43_funcsel <= bus_wdata[0:0];
            if (wen_ctrl44) reg_ctrl44_funcsel <= bus_wdata[0:0];
            if (wen_ctrl45) reg_ctrl45_funcsel <= bus_wdata[0:0];
            if (wen_ctrl46) reg_ctrl46_funcsel <= bus_wdata[0:0];
            if (wen_ctrl47) reg_ctrl47_funcsel <= bus_wdata[0:0];
            if (wen_ctrl48) reg_ctrl48_funcsel <= bus_wdata[0:0];
            if (wen_ctrl49) reg_ctrl49_funcsel <= bus_wdata[0:0];
            if (wen_ctrl50) reg_ctrl50_funcsel <= bus_wdata[0:0];
            if (wen_ctrl51) reg_ctrl51_funcsel <= bus_wdata[0:0];
            if (wen_ctrl52) reg_ctrl52_funcsel <= bus_wdata[0:0];
            if (wen_ctrl53) reg_ctrl53_funcsel <= bus_wdata[0:0];
            if (wen_ctrl54) reg_ctrl54_funcsel <= bus_wdata[0:0];
            if (wen_ctrl55) reg_ctrl55_funcsel <= bus_wdata[0:0];
            if (wen_ctrl56) reg_ctrl56_funcsel <= bus_wdata[0:0];
            if (wen_ctrl57) reg_ctrl57_funcsel <= bus_wdata[0:0];
            if (wen_ctrl58) reg_ctrl58_funcsel <= bus_wdata[0:0];
            if (wen_ctrl59) reg_ctrl59_funcsel <= bus_wdata[0:0];
            if (wen_ctrl60) reg_ctrl60_funcsel <= bus_wdata[0:0];
            if (wen_ctrl61) reg_ctrl61_funcsel <= bus_wdata[0:0];
            if (wen_out0) reg_out0_p0 <= bus_wdata[0:0];
            if (wen_out0) reg_out0_p1 <= bus_wdata[1:1];
            if (wen_out0) reg_out0_p2 <= bus_wdata[2:2];
            if (wen_out0) reg_out0_p3 <= bus_wdata[3:3];
            if (wen_out0) reg_out0_p4 <= bus_wdata[4:4];
            if (wen_out0) reg_out0_p5 <= bus_wdata[5:5];
            if (wen_out0) reg_out0_p6 <= bus_wdata[6:6];
            if (wen_out0) reg_out0_p7 <= bus_wdata[7:7];
            if (wen_out0) reg_out0_p8 <= bus_wdata[8:8];
            if (wen_out0) reg_out0_p9 <= bus_wdata[9:9];
            if (wen_out0) reg_out0_p10 <= bus_wdata[10:10];
            if (wen_out0) reg_out0_p11 <= bus_wdata[11:11];
            if (wen_out0) reg_out0_p12 <= bus_wdata[12:12];
            if (wen_out0) reg_out0_p13 <= bus_wdata[13:13];
            if (wen_out0) reg_out0_p14 <= bus_wdata[14:14];
            if (wen_out0) reg_out0_p15 <= bus_wdata[15:15];
            if (wen_out0) reg_out0_p16 <= bus_wdata[16:16];
            if (wen_out0) reg_out0_p17 <= bus_wdata[17:17];
            if (wen_out0) reg_out0_p18 <= bus_wdata[18:18];
            if (wen_out0) reg_out0_p19 <= bus_wdata[19:19];
            if (wen_out0) reg_out0_p20 <= bus_wdata[20:20];
            if (wen_out0) reg_out0_p21 <= bus_wdata[21:21];
            if (wen_out0) reg_out0_p22 <= bus_wdata[22:22];
            if (wen_out0) reg_out0_p23 <= bus_wdata[23:23];
            if (wen_out0) reg_out0_p24 <= bus_wdata[24:24];
            if (wen_out0) reg_out0_p25 <= bus_wdata[25:25];
            if (wen_out0) reg_out0_p26 <= bus_wdata[26:26];
            if (wen_out0) reg_out0_p27 <= bus_wdata[27:27];
            if (wen_out0) reg_out0_p28 <= bus_wdata[28:28];
            if (wen_out0) reg_out0_p29 <= bus_wdata[29:29];
            if (wen_out0) reg_out0_p30 <= bus_wdata[30:30];
            if (wen_out0) reg_out0_p31 <= bus_wdata[31:31];
            if (wen_out1) reg_out1_p32 <= bus_wdata[0:0];
            if (wen_out1) reg_out1_p33 <= bus_wdata[1:1];
            if (wen_out1) reg_out1_p34 <= bus_wdata[2:2];
            if (wen_out1) reg_out1_p35 <= bus_wdata[3:3];
            if (wen_out1) reg_out1_p36 <= bus_wdata[4:4];
            if (wen_out1) reg_out1_p37 <= bus_wdata[5:5];
            if (wen_out1) reg_out1_p38 <= bus_wdata[6:6];
            if (wen_out1) reg_out1_p39 <= bus_wdata[7:7];
            if (wen_out1) reg_out1_p40 <= bus_wdata[8:8];
            if (wen_out1) reg_out1_p41 <= bus_wdata[9:9];
            if (wen_out1) reg_out1_p42 <= bus_wdata[10:10];
            if (wen_out1) reg_out1_p43 <= bus_wdata[11:11];
            if (wen_out1) reg_out1_p44 <= bus_wdata[12:12];
            if (wen_out1) reg_out1_p45 <= bus_wdata[13:13];
            if (wen_out1) reg_out1_p46 <= bus_wdata[14:14];
            if (wen_out1) reg_out1_p47 <= bus_wdata[15:15];
            if (wen_out1) reg_out1_p48 <= bus_wdata[16:16];
            if (wen_out1) reg_out1_p49 <= bus_wdata[17:17];
            if (wen_out1) reg_out1_p50 <= bus_wdata[18:18];
            if (wen_out1) reg_out1_p51 <= bus_wdata[19:19];
            if (wen_out1) reg_out1_p52 <= bus_wdata[20:20];
            if (wen_out1) reg_out1_p53 <= bus_wdata[21:21];
            if (wen_out1) reg_out1_p54 <= bus_wdata[22:22];
            if (wen_out1) reg_out1_p55 <= bus_wdata[23:23];
            if (wen_out1) reg_out1_p56 <= bus_wdata[24:24];
            if (wen_out1) reg_out1_p57 <= bus_wdata[25:25];
            if (wen_out1) reg_out1_p58 <= bus_wdata[26:26];
            if (wen_out1) reg_out1_p59 <= bus_wdata[27:27];
            if (wen_out1) reg_out1_p60 <= bus_wdata[28:28];
            if (wen_out1) reg_out1_p61 <= bus_wdata[29:29];
            if (wen_oe0) reg_oe0_p0 <= bus_wdata[0:0];
            if (wen_oe0) reg_oe0_p1 <= bus_wdata[1:1];
            if (wen_oe0) reg_oe0_p2 <= bus_wdata[2:2];
            if (wen_oe0) reg_oe0_p3 <= bus_wdata[3:3];
            if (wen_oe0) reg_oe0_p4 <= bus_wdata[4:4];
            if (wen_oe0) reg_oe0_p5 <= bus_wdata[5:5];
            if (wen_oe0) reg_oe0_p6 <= bus_wdata[6:6];
            if (wen_oe0) reg_oe0_p7 <= bus_wdata[7:7];
            if (wen_oe0) reg_oe0_p8 <= bus_wdata[8:8];
            if (wen_oe0) reg_oe0_p9 <= bus_wdata[9:9];
            if (wen_oe0) reg_oe0_p10 <= bus_wdata[10:10];
            if (wen_oe0) reg_oe0_p11 <= bus_wdata[11:11];
            if (wen_oe0) reg_oe0_p12 <= bus_wdata[12:12];
            if (wen_oe0) reg_oe0_p13 <= bus_wdata[13:13];
            if (wen_oe0) reg_oe0_p14 <= bus_wdata[14:14];
            if (wen_oe0) reg_oe0_p15 <= bus_wdata[15:15];
            if (wen_oe0) reg_oe0_p16 <= bus_wdata[16:16];
            if (wen_oe0) reg_oe0_p17 <= bus_wdata[17:17];
            if (wen_oe0) reg_oe0_p18 <= bus_wdata[18:18];
            if (wen_oe0) reg_oe0_p19 <= bus_wdata[19:19];
            if (wen_oe0) reg_oe0_p20 <= bus_wdata[20:20];
            if (wen_oe0) reg_oe0_p21 <= bus_wdata[21:21];
            if (wen_oe0) reg_oe0_p22 <= bus_wdata[22:22];
            if (wen_oe0) reg_oe0_p23 <= bus_wdata[23:23];
            if (wen_oe0) reg_oe0_p24 <= bus_wdata[24:24];
            if (wen_oe0) reg_oe0_p25 <= bus_wdata[25:25];
            if (wen_oe0) reg_oe0_p26 <= bus_wdata[26:26];
            if (wen_oe0) reg_oe0_p27 <= bus_wdata[27:27];
            if (wen_oe0) reg_oe0_p28 <= bus_wdata[28:28];
            if (wen_oe0) reg_oe0_p29 <= bus_wdata[29:29];
            if (wen_oe0) reg_oe0_p30 <= bus_wdata[30:30];
            if (wen_oe0) reg_oe0_p31 <= bus_wdata[31:31];
            if (wen_oe1) reg_oe1_p32 <= bus_wdata[0:0];
            if (wen_oe1) reg_oe1_p33 <= bus_wdata[1:1];
            if (wen_oe1) reg_oe1_p34 <= bus_wdata[2:2];
            if (wen_oe1) reg_oe1_p35 <= bus_wdata[3:3];
            if (wen_oe1) reg_oe1_p36 <= bus_wdata[4:4];
            if (wen_oe1) reg_oe1_p37 <= bus_wdata[5:5];
            if (wen_oe1) reg_oe1_p38 <= bus_wdata[6:6];
            if (wen_oe1) reg_oe1_p39 <= bus_wdata[7:7];
            if (wen_oe1) reg_oe1_p40 <= bus_wdata[8:8];
            if (wen_oe1) reg_oe1_p41 <= bus_wdata[9:9];
            if (wen_oe1) reg_oe1_p42 <= bus_wdata[10:10];
            if (wen_oe1) reg_oe1_p43 <= bus_wdata[11:11];
            if (wen_oe1) reg_oe1_p44 <= bus_wdata[12:12];
            if (wen_oe1) reg_oe1_p45 <= bus_wdata[13:13];
            if (wen_oe1) reg_oe1_p46 <= bus_wdata[14:14];
            if (wen_oe1) reg_oe1_p47 <= bus_wdata[15:15];
            if (wen_oe1) reg_oe1_p48 <= bus_wdata[16:16];
            if (wen_oe1) reg_oe1_p49 <= bus_wdata[17:17];
            if (wen_oe1) reg_oe1_p50 <= bus_wdata[18:18];
            if (wen_oe1) reg_oe1_p51 <= bus_wdata[19:19];
            if (wen_oe1) reg_oe1_p52 <= bus_wdata[20:20];
            if (wen_oe1) reg_oe1_p53 <= bus_wdata[21:21];
            if (wen_oe1) reg_oe1_p54 <= bus_wdata[22:22];
            if (wen_oe1) reg_oe1_p55 <= bus_wdata[23:23];
            if (wen_oe1) reg_oe1_p56 <= bus_wdata[24:24];
            if (wen_oe1) reg_oe1_p57 <= bus_wdata[25:25];
            if (wen_oe1) reg_oe1_p58 <= bus_wdata[26:26];
            if (wen_oe1) reg_oe1_p59 <= bus_wdata[27:27];
            if (wen_oe1) reg_oe1_p60 <= bus_wdata[28:28];
            if (wen_oe1) reg_oe1_p61 <= bus_wdata[29:29];
            if (wen_out0_set) reg_out0_p0 <= reg_out0_p0 | bus_wdata[0:0];
            if (wen_out0_set) reg_out0_p1 <= reg_out0_p1 | bus_wdata[1:1];
            if (wen_out0_set) reg_out0_p2 <= reg_out0_p2 | bus_wdata[2:2];
            if (wen_out0_set) reg_out0_p3 <= reg_out0_p3 | bus_wdata[3:3];
            if (wen_out0_set) reg_out0_p4 <= reg_out0_p4 | bus_wdata[4:4];
            if (wen_out0_set) reg_out0_p5 <= reg_out0_p5 | bus_wdata[5:5];
            if (wen_out0_set) reg_out0_p6 <= reg_out0_p6 | bus_wdata[6:6];
            if (wen_out0_set) reg_out0_p7 <= reg_out0_p7 | bus_wdata[7:7];
            if (wen_out0_set) reg_out0_p8 <= reg_out0_p8 | bus_wdata[8:8];
            if (wen_out0_set) reg_out0_p9 <= reg_out0_p9 | bus_wdata[9:9];
            if (wen_out0_set) reg_out0_p10 <= reg_out0_p10 | bus_wdata[10:10];
            if (wen_out0_set) reg_out0_p11 <= reg_out0_p11 | bus_wdata[11:11];
            if (wen_out0_set) reg_out0_p12 <= reg_out0_p12 | bus_wdata[12:12];
            if (wen_out0_set) reg_out0_p13 <= reg_out0_p13 | bus_wdata[13:13];
            if (wen_out0_set) reg_out0_p14 <= reg_out0_p14 | bus_wdata[14:14];
            if (wen_out0_set) reg_out0_p15 <= reg_out0_p15 | bus_wdata[15:15];
            if (wen_out0_set) reg_out0_p16 <= reg_out0_p16 | bus_wdata[16:16];
            if (wen_out0_set) reg_out0_p17 <= reg_out0_p17 | bus_wdata[17:17];
            if (wen_out0_set) reg_out0_p18 <= reg_out0_p18 | bus_wdata[18:18];
            if (wen_out0_set) reg_out0_p19 <= reg_out0_p19 | bus_wdata[19:19];
            if (wen_out0_set) reg_out0_p20 <= reg_out0_p20 | bus_wdata[20:20];
            if (wen_out0_set) reg_out0_p21 <= reg_out0_p21 | bus_wdata[21:21];
            if (wen_out0_set) reg_out0_p22 <= reg_out0_p22 | bus_wdata[22:22];
            if (wen_out0_set) reg_out0_p23 <= reg_out0_p23 | bus_wdata[23:23];
            if (wen_out0_set) reg_out0_p24 <= reg_out0_p24 | bus_wdata[24:24];
            if (wen_out0_set) reg_out0_p25 <= reg_out0_p25 | bus_wdata[25:25];
            if (wen_out0_set) reg_out0_p26 <= reg_out0_p26 | bus_wdata[26:26];
            if (wen_out0_set) reg_out0_p27 <= reg_out0_p27 | bus_wdata[27:27];
            if (wen_out0_set) reg_out0_p28 <= reg_out0_p28 | bus_wdata[28:28];
            if (wen_out0_set) reg_out0_p29 <= reg_out0_p29 | bus_wdata[29:29];
            if (wen_out0_set) reg_out0_p30 <= reg_out0_p30 | bus_wdata[30:30];
            if (wen_out0_set) reg_out0_p31 <= reg_out0_p31 | bus_wdata[31:31];
            if (wen_out1_set) reg_out1_p32 <= reg_out1_p32 | bus_wdata[0:0];
            if (wen_out1_set) reg_out1_p33 <= reg_out1_p33 | bus_wdata[1:1];
            if (wen_out1_set) reg_out1_p34 <= reg_out1_p34 | bus_wdata[2:2];
            if (wen_out1_set) reg_out1_p35 <= reg_out1_p35 | bus_wdata[3:3];
            if (wen_out1_set) reg_out1_p36 <= reg_out1_p36 | bus_wdata[4:4];
            if (wen_out1_set) reg_out1_p37 <= reg_out1_p37 | bus_wdata[5:5];
            if (wen_out1_set) reg_out1_p38 <= reg_out1_p38 | bus_wdata[6:6];
            if (wen_out1_set) reg_out1_p39 <= reg_out1_p39 | bus_wdata[7:7];
            if (wen_out1_set) reg_out1_p40 <= reg_out1_p40 | bus_wdata[8:8];
            if (wen_out1_set) reg_out1_p41 <= reg_out1_p41 | bus_wdata[9:9];
            if (wen_out1_set) reg_out1_p42 <= reg_out1_p42 | bus_wdata[10:10];
            if (wen_out1_set) reg_out1_p43 <= reg_out1_p43 | bus_wdata[11:11];
            if (wen_out1_set) reg_out1_p44 <= reg_out1_p44 | bus_wdata[12:12];
            if (wen_out1_set) reg_out1_p45 <= reg_out1_p45 | bus_wdata[13:13];
            if (wen_out1_set) reg_out1_p46 <= reg_out1_p46 | bus_wdata[14:14];
            if (wen_out1_set) reg_out1_p47 <= reg_out1_p47 | bus_wdata[15:15];
            if (wen_out1_set) reg_out1_p48 <= reg_out1_p48 | bus_wdata[16:16];
            if (wen_out1_set) reg_out1_p49 <= reg_out1_p49 | bus_wdata[17:17];
            if (wen_out1_set) reg_out1_p50 <= reg_out1_p50 | bus_wdata[18:18];
            if (wen_out1_set) reg_out1_p51 <= reg_out1_p51 | bus_wdata[19:19];
            if (wen_out1_set) reg_out1_p52 <= reg_out1_p52 | bus_wdata[20:20];
            if (wen_out1_set) reg_out1_p53 <= reg_out1_p53 | bus_wdata[21:21];
            if (wen_out1_set) reg_out1_p54 <= reg_out1_p54 | bus_wdata[22:22];
            if (wen_out1_set) reg_out1_p55 <= reg_out1_p55 | bus_wdata[23:23];
            if (wen_out1_set) reg_out1_p56 <= reg_out1_p56 | bus_wdata[24:24];
            if (wen_out1_set) reg_out1_p57 <= reg_out1_p57 | bus_wdata[25:25];
            if (wen_out1_set) reg_out1_p58 <= reg_out1_p58 | bus_wdata[26:26];
            if (wen_out1_set) reg_out1_p59 <= reg_out1_p59 | bus_wdata[27:27];
            if (wen_out1_set) reg_out1_p60 <= reg_out1_p60 | bus_wdata[28:28];
            if (wen_out1_set) reg_out1_p61 <= reg_out1_p61 | bus_wdata[29:29];
            if (wen_out0_clr) reg_out0_p0 <= reg_out0_p0 & ~bus_wdata[0:0];
            if (wen_out0_clr) reg_out0_p1 <= reg_out0_p1 & ~bus_wdata[1:1];
            if (wen_out0_clr) reg_out0_p2 <= reg_out0_p2 & ~bus_wdata[2:2];
            if (wen_out0_clr) reg_out0_p3 <= reg_out0_p3 & ~bus_wdata[3:3];
            if (wen_out0_clr) reg_out0_p4 <= reg_out0_p4 & ~bus_wdata[4:4];
            if (wen_out0_clr) reg_out0_p5 <= reg_out0_p5 & ~bus_wdata[5:5];
            if (wen_out0_clr) reg_out0_p6 <= reg_out0_p6 & ~bus_wdata[6:6];
            if (wen_out0_clr) reg_out0_p7 <= reg_out0_p7 & ~bus_wdata[7:7];
            if (wen_out0_clr) reg_out0_p8 <= reg_out0_p8 & ~bus_wdata[8:8];
            if (wen_out0_clr) reg_out0_p9 <= reg_out0_p9 & ~bus_wdata[9:9];
            if (wen_out0_clr) reg_out0_p10 <= reg_out0_p10 & ~bus_wdata[10:10];
            if (wen_out0_clr) reg_out0_p11 <= reg_out0_p11 & ~bus_wdata[11:11];
            if (wen_out0_clr) reg_out0_p12 <= reg_out0_p12 & ~bus_wdata[12:12];
            if (wen_out0_clr) reg_out0_p13 <= reg_out0_p13 & ~bus_wdata[13:13];
            if (wen_out0_clr) reg_out0_p14 <= reg_out0_p14 & ~bus_wdata[14:14];
            if (wen_out0_clr) reg_out0_p15 <= reg_out0_p15 & ~bus_wdata[15:15];
            if (wen_out0_clr) reg_out0_p16 <= reg_out0_p16 & ~bus_wdata[16:16];
            if (wen_out0_clr) reg_out0_p17 <= reg_out0_p17 & ~bus_wdata[17:17];
            if (wen_out0_clr) reg_out0_p18 <= reg_out0_p18 & ~bus_wdata[18:18];
            if (wen_out0_clr) reg_out0_p19 <= reg_out0_p19 & ~bus_wdata[19:19];
            if (wen_out0_clr) reg_out0_p20 <= reg_out0_p20 & ~bus_wdata[20:20];
            if (wen_out0_clr) reg_out0_p21 <= reg_out0_p21 & ~bus_wdata[21:21];
            if (wen_out0_clr) reg_out0_p22 <= reg_out0_p22 & ~bus_wdata[22:22];
            if (wen_out0_clr) reg_out0_p23 <= reg_out0_p23 & ~bus_wdata[23:23];
            if (wen_out0_clr) reg_out0_p24 <= reg_out0_p24 & ~bus_wdata[24:24];
            if (wen_out0_clr) reg_out0_p25 <= reg_out0_p25 & ~bus_wdata[25:25];
            if (wen_out0_clr) reg_out0_p26 <= reg_out0_p26 & ~bus_wdata[26:26];
            if (wen_out0_clr) reg_out0_p27 <= reg_out0_p27 & ~bus_wdata[27:27];
            if (wen_out0_clr) reg_out0_p28 <= reg_out0_p28 & ~bus_wdata[28:28];
            if (wen_out0_clr) reg_out0_p29 <= reg_out0_p29 & ~bus_wdata[29:29];
            if (wen_out0_clr) reg_out0_p30 <= reg_out0_p30 & ~bus_wdata[30:30];
            if (wen_out0_clr) reg_out0_p31 <= reg_out0_p31 & ~bus_wdata[31:31];
            if (wen_out1_clr) reg_out1_p32 <= reg_out1_p32 & ~bus_wdata[0:0];
            if (wen_out1_clr) reg_out1_p33 <= reg_out1_p33 & ~bus_wdata[1:1];
            if (wen_out1_clr) reg_out1_p34 <= reg_out1_p34 & ~bus_wdata[2:2];
            if (wen_out1_clr) reg_out1_p35 <= reg_out1_p35 & ~bus_wdata[3:3];
            if (wen_out1_clr) reg_out1_p36 <= reg_out1_p36 & ~bus_wdata[4:4];
            if (wen_out1_clr) reg_out1_p37 <= reg_out1_p37 & ~bus_wdata[5:5];
            if (wen_out1_clr) reg_out1_p38 <= reg_out1_p38 & ~bus_wdata[6:6];
            if (wen_out1_clr) reg_out1_p39 <= reg_out1_p39 & ~bus_wdata[7:7];
            if (wen_out1_clr) reg_out1_p40 <= reg_out1_p40 & ~bus_wdata[8:8];
            if (wen_out1_clr) reg_out1_p41 <= reg_out1_p41 & ~bus_wdata[9:9];
            if (wen_out1_clr) reg_out1_p42 <= reg_out1_p42 & ~bus_wdata[10:10];
            if (wen_out1_clr) reg_out1_p43 <= reg_out1_p43 & ~bus_wdata[11:11];
            if (wen_out1_clr) reg_out1_p44 <= reg_out1_p44 & ~bus_wdata[12:12];
            if (wen_out1_clr) reg_out1_p45 <= reg_out1_p45 & ~bus_wdata[13:13];
            if (wen_out1_clr) reg_out1_p46 <= reg_out1_p46 & ~bus_wdata[14:14];
            if (wen_out1_clr) reg_out1_p47 <= reg_out1_p47 & ~bus_wdata[15:15];
            if (wen_out1_clr) reg_out1_p48 <= reg_out1_p48 & ~bus_wdata[16:16];
            if (wen_out1_clr) reg_out1_p49 <= reg_out1_p49 & ~bus_wdata[17:17];
            if (wen_out1_clr) reg_out1_p50 <= reg_out1_p50 & ~bus_wdata[18:18];
            if (wen_out1_clr) reg_out1_p51 <= reg_out1_p51 & ~bus_wdata[19:19];
            if (wen_out1_clr) reg_out1_p52 <= reg_out1_p52 & ~bus_wdata[20:20];
            if (wen_out1_clr) reg_out1_p53 <= reg_out1_p53 & ~bus_wdata[21:21];
            if (wen_out1_clr) reg_out1_p54 <= reg_out1_p54 & ~bus_wdata[22:22];
            if (wen_out1_clr) reg_out1_p55 <= reg_out1_p55 & ~bus_wdata[23:23];
            if (wen_out1_clr) reg_out1_p56 <= reg_out1_p56 & ~bus_wdata[24:24];
            if (wen_out1_clr) reg_out1_p57 <= reg_out1_p57 & ~bus_wdata[25:25];
            if (wen_out1_clr) reg_out1_p58 <= reg_out1_p58 & ~bus_wdata[26:26];
            if (wen_out1_clr) reg_out1_p59 <= reg_out1_p59 & ~bus_wdata[27:27];
            if (wen_out1_clr) reg_out1_p60 <= reg_out1_p60 & ~bus_wdata[28:28];
            if (wen_out1_clr) reg_out1_p61 <= reg_out1_p61 & ~bus_wdata[29:29];
            if (wen_out0_xor) reg_out0_p0 <= reg_out0_p0 ^ bus_wdata[0:0];
            if (wen_out0_xor) reg_out0_p1 <= reg_out0_p1 ^ bus_wdata[1:1];
            if (wen_out0_xor) reg_out0_p2 <= reg_out0_p2 ^ bus_wdata[2:2];
            if (wen_out0_xor) reg_out0_p3 <= reg_out0_p3 ^ bus_wdata[3:3];
            if (wen_out0_xor) reg_out0_p4 <= reg_out0_p4 ^ bus_wdata[4:4];
            if (wen_out0_xor) reg_out0_p5 <= reg_out0_p5 ^ bus_wdata[5:5];
            if (wen_out0_xor) reg_out0_p6 <= reg_out0_p6 ^ bus_wdata[6:6];
            if (wen_out0_xor) reg_out0_p7 <= reg_out0_p7 ^ bus_wdata[7:7];
            if (wen_out0_xor) reg_out0_p8 <= reg_out0_p8 ^ bus_wdata[8:8];
            if (wen_out0_xor) reg_out0_p9 <= reg_out0_p9 ^ bus_wdata[9:9];
            if (wen_out0_xor) reg_out0_p10 <= reg_out0_p10 ^ bus_wdata[10:10];
            if (wen_out0_xor) reg_out0_p11 <= reg_out0_p11 ^ bus_wdata[11:11];
            if (wen_out0_xor) reg_out0_p12 <= reg_out0_p12 ^ bus_wdata[12:12];
            if (wen_out0_xor) reg_out0_p13 <= reg_out0_p13 ^ bus_wdata[13:13];
            if (wen_out0_xor) reg_out0_p14 <= reg_out0_p14 ^ bus_wdata[14:14];
            if (wen_out0_xor) reg_out0_p15 <= reg_out0_p15 ^ bus_wdata[15:15];
            if (wen_out0_xor) reg_out0_p16 <= reg_out0_p16 ^ bus_wdata[16:16];
            if (wen_out0_xor) reg_out0_p17 <= reg_out0_p17 ^ bus_wdata[17:17];
            if (wen_out0_xor) reg_out0_p18 <= reg_out0_p18 ^ bus_wdata[18:18];
            if (wen_out0_xor) reg_out0_p19 <= reg_out0_p19 ^ bus_wdata[19:19];
            if (wen_out0_xor) reg_out0_p20 <= reg_out0_p20 ^ bus_wdata[20:20];
            if (wen_out0_xor) reg_out0_p21 <= reg_out0_p21 ^ bus_wdata[21:21];
            if (wen_out0_xor) reg_out0_p22 <= reg_out0_p22 ^ bus_wdata[22:22];
            if (wen_out0_xor) reg_out0_p23 <= reg_out0_p23 ^ bus_wdata[23:23];
            if (wen_out0_xor) reg_out0_p24 <= reg_out0_p24 ^ bus_wdata[24:24];
            if (wen_out0_xor) reg_out0_p25 <= reg_out0_p25 ^ bus_wdata[25:25];
            if (wen_out0_xor) reg_out0_p26 <= reg_out0_p26 ^ bus_wdata[26:26];
            if (wen_out0_xor) reg_out0_p27 <= reg_out0_p27 ^ bus_wdata[27:27];
            if (wen_out0_xor) reg_out0_p28 <= reg_out0_p28 ^ bus_wdata[28:28];
            if (wen_out0_xor) reg_out0_p29 <= reg_out0_p29 ^ bus_wdata[29:29];
            if (wen_out0_xor) reg_out0_p30 <= reg_out0_p30 ^ bus_wdata[30:30];
            if (wen_out0_xor) reg_out0_p31 <= reg_out0_p31 ^ bus_wdata[31:31];
            if (wen_out1_xor) reg_out1_p32 <= reg_out1_p32 ^ bus_wdata[0:0];
            if (wen_out1_xor) reg_out1_p33 <= reg_out1_p33 ^ bus_wdata[1:1];
            if (wen_out1_xor) reg_out1_p34 <= reg_out1_p34 ^ bus_wdata[2:2];
            if (wen_out1_xor) reg_out1_p35 <= reg_out1_p35 ^ bus_wdata[3:3];
            if (wen_out1_xor) reg_out1_p36 <= reg_out1_p36 ^ bus_wdata[4:4];
            if (wen_out1_xor) reg_out1_p37 <= reg_out1_p37 ^ bus_wdata[5:5];
            if (wen_out1_xor) reg_out1_p38 <= reg_out1_p38 ^ bus_wdata[6:6];
            if (wen_out1_xor) reg_out1_p39 <= reg_out1_p39 ^ bus_wdata[7:7];
            if (wen_out1_xor) reg_out1_p40 <= reg_out1_p40 ^ bus_wdata[8:8];
            if (wen_out1_xor) reg_out1_p41 <= reg_out1_p41 ^ bus_wdata[9:9];
            if (wen_out1_xor) reg_out1_p42 <= reg_out1_p42 ^ bus_wdata[10:10];
            if (wen_out1_xor) reg_out1_p43 <= reg_out1_p43 ^ bus_wdata[11:11];
            if (wen_out1_xor) reg_out1_p44 <= reg_out1_p44 ^ bus_wdata[12:12];
            if (wen_out1_xor) reg_out1_p45 <= reg_out1_p45 ^ bus_wdata[13:13];
            if (wen_out1_xor) reg_out1_p46 <= reg_out1_p46 ^ bus_wdata[14:14];
            if (wen_out1_xor) reg_out1_p47 <= reg_out1_p47 ^ bus_wdata[15:15];
            if (wen_out1_xor) reg_out1_p48 <= reg_out1_p48 ^ bus_wdata[16:16];
            if (wen_out1_xor) reg_out1_p49 <= reg_out1_p49 ^ bus_wdata[17:17];
            if (wen_out1_xor) reg_out1_p50 <= reg_out1_p50 ^ bus_wdata[18:18];
            if (wen_out1_xor) reg_out1_p51 <= reg_out1_p51 ^ bus_wdata[19:19];
            if (wen_out1_xor) reg_out1_p52 <= reg_out1_p52 ^ bus_wdata[20:20];
            if (wen_out1_xor) reg_out1_p53 <= reg_out1_p53 ^ bus_wdata[21:21];
            if (wen_out1_xor) reg_out1_p54 <= reg_out1_p54 ^ bus_wdata[22:22];
            if (wen_out1_xor) reg_out1_p55 <= reg_out1_p55 ^ bus_wdata[23:23];
            if (wen_out1_xor) reg_out1_p56 <= reg_out1_p56 ^ bus_wdata[24:24];
            if (wen_out1_xor) reg_out1_p57 <= reg_out1_p57 ^ bus_wdata[25:25];
            if (wen_out1_xor) reg_out1_p58 <= reg_out1_p58 ^ bus_wdata[26:26];
            if (wen_out1_xor) reg_out1_p59 <= reg_out1_p59 ^ bus_wdata[27:27];
            if (wen_out1_xor) reg_out1_p60 <= reg_out1_p60 ^ bus_wdata[28:28];
            if (wen_out1_xor) reg_out1_p61 <= reg_out1_p61 ^ bus_wdata[29:29];
            if (wen_oe0_set) reg_oe0_p0 <= reg_oe0_p0 | bus_wdata[0:0];
            if (wen_oe0_set) reg_oe0_p1 <= reg_oe0_p1 | bus_wdata[1:1];
            if (wen_oe0_set) reg_oe0_p2 <= reg_oe0_p2 | bus_wdata[2:2];
            if (wen_oe0_set) reg_oe0_p3 <= reg_oe0_p3 | bus_wdata[3:3];
            if (wen_oe0_set) reg_oe0_p4 <= reg_oe0_p4 | bus_wdata[4:4];
            if (wen_oe0_set) reg_oe0_p5 <= reg_oe0_p5 | bus_wdata[5:5];
            if (wen_oe0_set) reg_oe0_p6 <= reg_oe0_p6 | bus_wdata[6:6];
            if (wen_oe0_set) reg_oe0_p7 <= reg_oe0_p7 | bus_wdata[7:7];
            if (wen_oe0_set) reg_oe0_p8 <= reg_oe0_p8 | bus_wdata[8:8];
            if (wen_oe0_set) reg_oe0_p9 <= reg_oe0_p9 | bus_wdata[9:9];
            if (wen_oe0_set) reg_oe0_p10 <= reg_oe0_p10 | bus_wdata[10:10];
            if (wen_oe0_set) reg_oe0_p11 <= reg_oe0_p11 | bus_wdata[11:11];
            if (wen_oe0_set) reg_oe0_p12 <= reg_oe0_p12 | bus_wdata[12:12];
            if (wen_oe0_set) reg_oe0_p13 <= reg_oe0_p13 | bus_wdata[13:13];
            if (wen_oe0_set) reg_oe0_p14 <= reg_oe0_p14 | bus_wdata[14:14];
            if (wen_oe0_set) reg_oe0_p15 <= reg_oe0_p15 | bus_wdata[15:15];
            if (wen_oe0_set) reg_oe0_p16 <= reg_oe0_p16 | bus_wdata[16:16];
            if (wen_oe0_set) reg_oe0_p17 <= reg_oe0_p17 | bus_wdata[17:17];
            if (wen_oe0_set) reg_oe0_p18 <= reg_oe0_p18 | bus_wdata[18:18];
            if (wen_oe0_set) reg_oe0_p19 <= reg_oe0_p19 | bus_wdata[19:19];
            if (wen_oe0_set) reg_oe0_p20 <= reg_oe0_p20 | bus_wdata[20:20];
            if (wen_oe0_set) reg_oe0_p21 <= reg_oe0_p21 | bus_wdata[21:21];
            if (wen_oe0_set) reg_oe0_p22 <= reg_oe0_p22 | bus_wdata[22:22];
            if (wen_oe0_set) reg_oe0_p23 <= reg_oe0_p23 | bus_wdata[23:23];
            if (wen_oe0_set) reg_oe0_p24 <= reg_oe0_p24 | bus_wdata[24:24];
            if (wen_oe0_set) reg_oe0_p25 <= reg_oe0_p25 | bus_wdata[25:25];
            if (wen_oe0_set) reg_oe0_p26 <= reg_oe0_p26 | bus_wdata[26:26];
            if (wen_oe0_set) reg_oe0_p27 <= reg_oe0_p27 | bus_wdata[27:27];
            if (wen_oe0_set) reg_oe0_p28 <= reg_oe0_p28 | bus_wdata[28:28];
            if (wen_oe0_set) reg_oe0_p29 <= reg_oe0_p29 | bus_wdata[29:29];
            if (wen_oe0_set) reg_oe0_p30 <= reg_oe0_p30 | bus_wdata[30:30];
            if (wen_oe0_set) reg_oe0_p31 <= reg_oe0_p31 | bus_wdata[31:31];
            if (wen_oe1_set) reg_oe1_p32 <= reg_oe1_p32 | bus_wdata[0:0];
            if (wen_oe1_set) reg_oe1_p33 <= reg_oe1_p33 | bus_wdata[1:1];
            if (wen_oe1_set) reg_oe1_p34 <= reg_oe1_p34 | bus_wdata[2:2];
            if (wen_oe1_set) reg_oe1_p35 <= reg_oe1_p35 | bus_wdata[3:3];
            if (wen_oe1_set) reg_oe1_p36 <= reg_oe1_p36 | bus_wdata[4:4];
            if (wen_oe1_set) reg_oe1_p37 <= reg_oe1_p37 | bus_wdata[5:5];
            if (wen_oe1_set) reg_oe1_p38 <= reg_oe1_p38 | bus_wdata[6:6];
            if (wen_oe1_set) reg_oe1_p39 <= reg_oe1_p39 | bus_wdata[7:7];
            if (wen_oe1_set) reg_oe1_p40 <= reg_oe1_p40 | bus_wdata[8:8];
            if (wen_oe1_set) reg_oe1_p41 <= reg_oe1_p41 | bus_wdata[9:9];
            if (wen_oe1_set) reg_oe1_p42 <= reg_oe1_p42 | bus_wdata[10:10];
            if (wen_oe1_set) reg_oe1_p43 <= reg_oe1_p43 | bus_wdata[11:11];
            if (wen_oe1_set) reg_oe1_p44 <= reg_oe1_p44 | bus_wdata[12:12];
            if (wen_oe1_set) reg_oe1_p45 <= reg_oe1_p45 | bus_wdata[13:13];
            if (wen_oe1_set) reg_oe1_p46 <= reg_oe1_p46 | bus_wdata[14:14];
            if (wen_oe1_set) reg_oe1_p47 <= reg_oe1_p47 | bus_wdata[15:15];
            if (wen_oe1_set) reg_oe1_p48 <= reg_oe1_p48 | bus_wdata[16:16];
            if (wen_oe1_set) reg_oe1_p49 <= reg_oe1_p49 | bus_wdata[17:17];
            if (wen_oe1_set) reg_oe1_p50 <= reg_oe1_p50 | bus_wdata[18:18];
            if (wen_oe1_set) reg_oe1_p51 <= reg_oe1_p51 | bus_wdata[19:19];
            if (wen_oe1_set) reg_oe1_p52 <= reg_oe1_p52 | bus_wdata[20:20];
            if (wen_oe1_set) reg_oe1_p53 <= reg_oe1_p53 | bus_wdata[21:21];
            if (wen_oe1_set) reg_oe1_p54 <= reg_oe1_p54 | bus_wdata[22:22];
            if (wen_oe1_set) reg_oe1_p55 <= reg_oe1_p55 | bus_wdata[23:23];
            if (wen_oe1_set) reg_oe1_p56 <= reg_oe1_p56 | bus_wdata[24:24];
            if (wen_oe1_set) reg_oe1_p57 <= reg_oe1_p57 | bus_wdata[25:25];
            if (wen_oe1_set) reg_oe1_p58 <= reg_oe1_p58 | bus_wdata[26:26];
            if (wen_oe1_set) reg_oe1_p59 <= reg_oe1_p59 | bus_wdata[27:27];
            if (wen_oe1_set) reg_oe1_p60 <= reg_oe1_p60 | bus_wdata[28:28];
            if (wen_oe1_set) reg_oe1_p61 <= reg_oe1_p61 | bus_wdata[29:29];
            if (wen_oe0_clr) reg_oe0_p0 <= reg_oe0_p0 & ~bus_wdata[0:0];
            if (wen_oe0_clr) reg_oe0_p1 <= reg_oe0_p1 & ~bus_wdata[1:1];
            if (wen_oe0_clr) reg_oe0_p2 <= reg_oe0_p2 & ~bus_wdata[2:2];
            if (wen_oe0_clr) reg_oe0_p3 <= reg_oe0_p3 & ~bus_wdata[3:3];
            if (wen_oe0_clr) reg_oe0_p4 <= reg_oe0_p4 & ~bus_wdata[4:4];
            if (wen_oe0_clr) reg_oe0_p5 <= reg_oe0_p5 & ~bus_wdata[5:5];
            if (wen_oe0_clr) reg_oe0_p6 <= reg_oe0_p6 & ~bus_wdata[6:6];
            if (wen_oe0_clr) reg_oe0_p7 <= reg_oe0_p7 & ~bus_wdata[7:7];
            if (wen_oe0_clr) reg_oe0_p8 <= reg_oe0_p8 & ~bus_wdata[8:8];
            if (wen_oe0_clr) reg_oe0_p9 <= reg_oe0_p9 & ~bus_wdata[9:9];
            if (wen_oe0_clr) reg_oe0_p10 <= reg_oe0_p10 & ~bus_wdata[10:10];
            if (wen_oe0_clr) reg_oe0_p11 <= reg_oe0_p11 & ~bus_wdata[11:11];
            if (wen_oe0_clr) reg_oe0_p12 <= reg_oe0_p12 & ~bus_wdata[12:12];
            if (wen_oe0_clr) reg_oe0_p13 <= reg_oe0_p13 & ~bus_wdata[13:13];
            if (wen_oe0_clr) reg_oe0_p14 <= reg_oe0_p14 & ~bus_wdata[14:14];
            if (wen_oe0_clr) reg_oe0_p15 <= reg_oe0_p15 & ~bus_wdata[15:15];
            if (wen_oe0_clr) reg_oe0_p16 <= reg_oe0_p16 & ~bus_wdata[16:16];
            if (wen_oe0_clr) reg_oe0_p17 <= reg_oe0_p17 & ~bus_wdata[17:17];
            if (wen_oe0_clr) reg_oe0_p18 <= reg_oe0_p18 & ~bus_wdata[18:18];
            if (wen_oe0_clr) reg_oe0_p19 <= reg_oe0_p19 & ~bus_wdata[19:19];
            if (wen_oe0_clr) reg_oe0_p20 <= reg_oe0_p20 & ~bus_wdata[20:20];
            if (wen_oe0_clr) reg_oe0_p21 <= reg_oe0_p21 & ~bus_wdata[21:21];
            if (wen_oe0_clr) reg_oe0_p22 <= reg_oe0_p22 & ~bus_wdata[22:22];
            if (wen_oe0_clr) reg_oe0_p23 <= reg_oe0_p23 & ~bus_wdata[23:23];
            if (wen_oe0_clr) reg_oe0_p24 <= reg_oe0_p24 & ~bus_wdata[24:24];
            if (wen_oe0_clr) reg_oe0_p25 <= reg_oe0_p25 & ~bus_wdata[25:25];
            if (wen_oe0_clr) reg_oe0_p26 <= reg_oe0_p26 & ~bus_wdata[26:26];
            if (wen_oe0_clr) reg_oe0_p27 <= reg_oe0_p27 & ~bus_wdata[27:27];
            if (wen_oe0_clr) reg_oe0_p28 <= reg_oe0_p28 & ~bus_wdata[28:28];
            if (wen_oe0_clr) reg_oe0_p29 <= reg_oe0_p29 & ~bus_wdata[29:29];
            if (wen_oe0_clr) reg_oe0_p30 <= reg_oe0_p30 & ~bus_wdata[30:30];
            if (wen_oe0_clr) reg_oe0_p31 <= reg_oe0_p31 & ~bus_wdata[31:31];
            if (wen_oe1_clr) reg_oe1_p32 <= reg_oe1_p32 & ~bus_wdata[0:0];
            if (wen_oe1_clr) reg_oe1_p33 <= reg_oe1_p33 & ~bus_wdata[1:1];
            if (wen_oe1_clr) reg_oe1_p34 <= reg_oe1_p34 & ~bus_wdata[2:2];
            if (wen_oe1_clr) reg_oe1_p35 <= reg_oe1_p35 & ~bus_wdata[3:3];
            if (wen_oe1_clr) reg_oe1_p36 <= reg_oe1_p36 & ~bus_wdata[4:4];
            if (wen_oe1_clr) reg_oe1_p37 <= reg_oe1_p37 & ~bus_wdata[5:5];
            if (wen_oe1_clr) reg_oe1_p38 <= reg_oe1_p38 & ~bus_wdata[6:6];
            if (wen_oe1_clr) reg_oe1_p39 <= reg_oe1_p39 & ~bus_wdata[7:7];
            if (wen_oe1_clr) reg_oe1_p40 <= reg_oe1_p40 & ~bus_wdata[8:8];
            if (wen_oe1_clr) reg_oe1_p41 <= reg_oe1_p41 & ~bus_wdata[9:9];
            if (wen_oe1_clr) reg_oe1_p42 <= reg_oe1_p42 & ~bus_wdata[10:10];
            if (wen_oe1_clr) reg_oe1_p43 <= reg_oe1_p43 & ~bus_wdata[11:11];
            if (wen_oe1_clr) reg_oe1_p44 <= reg_oe1_p44 & ~bus_wdata[12:12];
            if (wen_oe1_clr) reg_oe1_p45 <= reg_oe1_p45 & ~bus_wdata[13:13];
            if (wen_oe1_clr) reg_oe1_p46 <= reg_oe1_p46 & ~bus_wdata[14:14];
            if (wen_oe1_clr) reg_oe1_p47 <= reg_oe1_p47 & ~bus_wdata[15:15];
            if (wen_oe1_clr) reg_oe1_p48 <= reg_oe1_p48 & ~bus_wdata[16:16];
            if (wen_oe1_clr) reg_oe1_p49 <= reg_oe1_p49 & ~bus_wdata[17:17];
            if (wen_oe1_clr) reg_oe1_p50 <= reg_oe1_p50 & ~bus_wdata[18:18];
            if (wen_oe1_clr) reg_oe1_p51 <= reg_oe1_p51 & ~bus_wdata[19:19];
            if (wen_oe1_clr) reg_oe1_p52 <= reg_oe1_p52 & ~bus_wdata[20:20];
            if (wen_oe1_clr) reg_oe1_p53 <= reg_oe1_p53 & ~bus_wdata[21:21];
            if (wen_oe1_clr) reg_oe1_p54 <= reg_oe1_p54 & ~bus_wdata[22:22];
            if (wen_oe1_clr) reg_oe1_p55 <= reg_oe1_p55 & ~bus_wdata[23:23];
            if (wen_oe1_clr) reg_oe1_p56 <= reg_oe1_p56 & ~bus_wdata[24:24];
            if (wen_oe1_clr) reg_oe1_p57 <= reg_oe1_p57 & ~bus_wdata[25:25];
            if (wen_oe1_clr) reg_oe1_p58 <= reg_oe1_p58 & ~bus_wdata[26:26];
            if (wen_oe1_clr) reg_oe1_p59 <= reg_oe1_p59 & ~bus_wdata[27:27];
            if (wen_oe1_clr) reg_oe1_p60 <= reg_oe1_p60 & ~bus_wdata[28:28];
            if (wen_oe1_clr) reg_oe1_p61 <= reg_oe1_p61 & ~bus_wdata[29:29];
            if (wen_oe0_xor) reg_oe0_p0 <= reg_oe0_p0 ^ bus_wdata[0:0];
            if (wen_oe0_xor) reg_oe0_p1 <= reg_oe0_p1 ^ bus_wdata[1:1];
            if (wen_oe0_xor) reg_oe0_p2 <= reg_oe0_p2 ^ bus_wdata[2:2];
            if (wen_oe0_xor) reg_oe0_p3 <= reg_oe0_p3 ^ bus_wdata[3:3];
            if (wen_oe0_xor) reg_oe0_p4 <= reg_oe0_p4 ^ bus_wdata[4:4];
            if (wen_oe0_xor) reg_oe0_p5 <= reg_oe0_p5 ^ bus_wdata[5:5];
            if (wen_oe0_xor) reg_oe0_p6 <= reg_oe0_p6 ^ bus_wdata[6:6];
            if (wen_oe0_xor) reg_oe0_p7 <= reg_oe0_p7 ^ bus_wdata[7:7];
            if (wen_oe0_xor) reg_oe0_p8 <= reg_oe0_p8 ^ bus_wdata[8:8];
            if (wen_oe0_xor) reg_oe0_p9 <= reg_oe0_p9 ^ bus_wdata[9:9];
            if (wen_oe0_xor) reg_oe0_p10 <= reg_oe0_p10 ^ bus_wdata[10:10];
            if (wen_oe0_xor) reg_oe0_p11 <= reg_oe0_p11 ^ bus_wdata[11:11];
            if (wen_oe0_xor) reg_oe0_p12 <= reg_oe0_p12 ^ bus_wdata[12:12];
            if (wen_oe0_xor) reg_oe0_p13 <= reg_oe0_p13 ^ bus_wdata[13:13];
            if (wen_oe0_xor) reg_oe0_p14 <= reg_oe0_p14 ^ bus_wdata[14:14];
            if (wen_oe0_xor) reg_oe0_p15 <= reg_oe0_p15 ^ bus_wdata[15:15];
            if (wen_oe0_xor) reg_oe0_p16 <= reg_oe0_p16 ^ bus_wdata[16:16];
            if (wen_oe0_xor) reg_oe0_p17 <= reg_oe0_p17 ^ bus_wdata[17:17];
            if (wen_oe0_xor) reg_oe0_p18 <= reg_oe0_p18 ^ bus_wdata[18:18];
            if (wen_oe0_xor) reg_oe0_p19 <= reg_oe0_p19 ^ bus_wdata[19:19];
            if (wen_oe0_xor) reg_oe0_p20 <= reg_oe0_p20 ^ bus_wdata[20:20];
            if (wen_oe0_xor) reg_oe0_p21 <= reg_oe0_p21 ^ bus_wdata[21:21];
            if (wen_oe0_xor) reg_oe0_p22 <= reg_oe0_p22 ^ bus_wdata[22:22];
            if (wen_oe0_xor) reg_oe0_p23 <= reg_oe0_p23 ^ bus_wdata[23:23];
            if (wen_oe0_xor) reg_oe0_p24 <= reg_oe0_p24 ^ bus_wdata[24:24];
            if (wen_oe0_xor) reg_oe0_p25 <= reg_oe0_p25 ^ bus_wdata[25:25];
            if (wen_oe0_xor) reg_oe0_p26 <= reg_oe0_p26 ^ bus_wdata[26:26];
            if (wen_oe0_xor) reg_oe0_p27 <= reg_oe0_p27 ^ bus_wdata[27:27];
            if (wen_oe0_xor) reg_oe0_p28 <= reg_oe0_p28 ^ bus_wdata[28:28];
            if (wen_oe0_xor) reg_oe0_p29 <= reg_oe0_p29 ^ bus_wdata[29:29];
            if (wen_oe0_xor) reg_oe0_p30 <= reg_oe0_p30 ^ bus_wdata[30:30];
            if (wen_oe0_xor) reg_oe0_p31 <= reg_oe0_p31 ^ bus_wdata[31:31];
            if (wen_oe1_xor) reg_oe1_p32 <= reg_oe1_p32 ^ bus_wdata[0:0];
            if (wen_oe1_xor) reg_oe1_p33 <= reg_oe1_p33 ^ bus_wdata[1:1];
            if (wen_oe1_xor) reg_oe1_p34 <= reg_oe1_p34 ^ bus_wdata[2:2];
            if (wen_oe1_xor) reg_oe1_p35 <= reg_oe1_p35 ^ bus_wdata[3:3];
            if (wen_oe1_xor) reg_oe1_p36 <= reg_oe1_p36 ^ bus_wdata[4:4];
            if (wen_oe1_xor) reg_oe1_p37 <= reg_oe1_p37 ^ bus_wdata[5:5];
            if (wen_oe1_xor) reg_oe1_p38 <= reg_oe1_p38 ^ bus_wdata[6:6];
            if (wen_oe1_xor) reg_oe1_p39 <= reg_oe1_p39 ^ bus_wdata[7:7];
            if (wen_oe1_xor) reg_oe1_p40 <= reg_oe1_p40 ^ bus_wdata[8:8];
            if (wen_oe1_xor) reg_oe1_p41 <= reg_oe1_p41 ^ bus_wdata[9:9];
            if (wen_oe1_xor) reg_oe1_p42 <= reg_oe1_p42 ^ bus_wdata[10:10];
            if (wen_oe1_xor) reg_oe1_p43 <= reg_oe1_p43 ^ bus_wdata[11:11];
            if (wen_oe1_xor) reg_oe1_p44 <= reg_oe1_p44 ^ bus_wdata[12:12];
            if (wen_oe1_xor) reg_oe1_p45 <= reg_oe1_p45 ^ bus_wdata[13:13];
            if (wen_oe1_xor) reg_oe1_p46 <= reg_oe1_p46 ^ bus_wdata[14:14];
            if (wen_oe1_xor) reg_oe1_p47 <= reg_oe1_p47 ^ bus_wdata[15:15];
            if (wen_oe1_xor) reg_oe1_p48 <= reg_oe1_p48 ^ bus_wdata[16:16];
            if (wen_oe1_xor) reg_oe1_p49 <= reg_oe1_p49 ^ bus_wdata[17:17];
            if (wen_oe1_xor) reg_oe1_p50 <= reg_oe1_p50 ^ bus_wdata[18:18];
            if (wen_oe1_xor) reg_oe1_p51 <= reg_oe1_p51 ^ bus_wdata[19:19];
            if (wen_oe1_xor) reg_oe1_p52 <= reg_oe1_p52 ^ bus_wdata[20:20];
            if (wen_oe1_xor) reg_oe1_p53 <= reg_oe1_p53 ^ bus_wdata[21:21];
            if (wen_oe1_xor) reg_oe1_p54 <= reg_oe1_p54 ^ bus_wdata[22:22];
            if (wen_oe1_xor) reg_oe1_p55 <= reg_oe1_p55 ^ bus_wdata[23:23];
            if (wen_oe1_xor) reg_oe1_p56 <= reg_oe1_p56 ^ bus_wdata[24:24];
            if (wen_oe1_xor) reg_oe1_p57 <= reg_oe1_p57 ^ bus_wdata[25:25];
            if (wen_oe1_xor) reg_oe1_p58 <= reg_oe1_p58 ^ bus_wdata[26:26];
            if (wen_oe1_xor) reg_oe1_p59 <= reg_oe1_p59 ^ bus_wdata[27:27];
            if (wen_oe1_xor) reg_oe1_p60 <= reg_oe1_p60 ^ bus_wdata[28:28];
            if (wen_oe1_xor) reg_oe1_p61 <= reg_oe1_p61 ^ bus_wdata[29:29];
        end
    end

    // Fields connected to their flops, the write data and the module ports
    assign ctrl0_funcsel = reg_ctrl0_funcsel;
    assign ctrl1_funcsel = reg_ctrl1_funcsel;
    assign ctrl2_funcsel = reg_ctrl2_funcsel;
    assign ctrl3_funcsel = reg_ctrl3_funcsel;
    assign ctrl4_funcsel = reg_ctrl4_funcsel;
    assign ctrl5_funcsel = reg_ctrl5_funcsel;
    assign ctrl6_funcsel = reg_ctrl6_funcsel;
    assign ctrl7_funcsel = reg_ctrl7_funcsel;
    assign ctrl8_funcsel = reg_ctrl8_funcsel;
    assign ctrl9_funcsel = reg_ctrl9_funcsel;
    assign ctrl10_funcsel = reg_ctrl10_funcsel;
    assign ctrl11_funcsel = reg_ctrl11_funcsel;
    assign ctrl12_funcsel = reg_ctrl12_funcsel;
    assign ctrl13_funcsel = reg_ctrl13_funcsel;
    assign ctrl14_funcsel = reg_ctrl14_funcsel;
    assign ctrl15_funcsel = reg_ctrl15_funcsel;
    assign ctrl16_funcsel = reg_ctrl16_funcsel;
    assign ctrl17_funcsel = reg_ctrl17_funcsel;
    assign ctrl18_funcsel = reg_ctrl18_funcsel;
    assign ctrl19_funcsel = reg_ctrl19_funcsel;
    assign ctrl20_funcsel = reg_ctrl20_funcsel;
    assign ctrl21_funcsel = reg_ctrl21_funcsel;
    assign ctrl22_funcsel = reg_ctrl22_funcsel;
    assign ctrl23_funcsel = reg_ctrl23_funcsel;
    assign ctrl24_funcsel = reg_ctrl24_funcsel;
    assign ctrl25_funcsel = reg_ctrl25_funcsel;
    assign ctrl26_funcsel = reg_ctrl26_funcsel;
    assign ctrl27_funcsel = reg_ctrl27_funcsel;
    assign ctrl28_funcsel = reg_ctrl28_funcsel;
    assign ctrl29_funcsel = reg_ctrl29_funcsel;
    assign ctrl30_funcsel = reg_ctrl30_funcsel;
    assign ctrl31_funcsel = reg_ctrl31_funcsel;
    assign ctrl32_funcsel = reg_ctrl32_funcsel;
    assign ctrl33_funcsel = reg_ctrl33_funcsel;
    assign ctrl34_funcsel = reg_ctrl34_funcsel;
    assign ctrl35_funcsel = reg_ctrl35_funcsel;
    assign ctrl36_funcsel = reg_ctrl36_funcsel;
    assign ctrl37_funcsel = reg_ctrl37_funcsel;
    assign ctrl38_funcsel = reg_ctrl38_funcsel;
    assign ctrl39_funcsel = reg_ctrl39_funcsel;
    assign ctrl40_funcsel = reg_ctrl40_funcsel;
    assign ctrl41_funcsel = reg_ctrl41_funcsel;
    assign ctrl42_funcsel = reg_ctrl42_funcsel;
    assign ctrl43_funcsel = reg_ctrl43_funcsel;
    assign ctrl44_funcsel = reg_ctrl44_funcsel;
    assign ctrl45_funcsel = reg_ctrl45_funcsel;
    assign ctrl46_funcsel = reg_ctrl46_funcsel;
    assign ctrl47_funcsel = reg_ctrl47_funcsel;
    assign ctrl48_funcsel = reg_ctrl48_funcsel;
    assign ctrl49_funcsel = reg_ctrl49_funcsel;
    assign ctrl50_funcsel = reg_ctrl50_funcsel;
    assign ctrl51_funcsel = reg_ctrl51_funcsel;
    assign ctrl52_funcsel = reg_ctrl52_funcsel;
    assign ctrl53_funcsel = reg_ctrl53_funcsel;
    assign ctrl54_funcsel = reg_ctrl54_funcsel;
    assign ctrl55_funcsel = reg_ctrl55_funcsel;
    assign ctrl56_funcsel = reg_ctrl56_funcsel;
    assign ctrl57_funcsel = reg_ctrl57_funcsel;
    assign ctrl58_funcsel = reg_ctrl58_funcsel;
    assign ctrl59_funcsel = reg_ctrl59_funcsel;
    assign ctrl60_funcsel = reg_ctrl60_funcsel;
    assign ctrl61_funcsel = reg_ctrl61_funcsel;
    assign out0_p0 = reg_out0_p0;
    assign out0_p1 = reg_out0_p1;
    assign out0_p2 = reg_out0_p2;
    assign out0_p3 = reg_out0_p3;
    assign out0_p4 = reg_out0_p4;
    assign out0_p5 = reg_out0_p5;
    assign out0_p6 = reg_out0_p6;
    assign out0_p7 = reg_out0_p7;
    assign out0_p8 = reg_out0_p8;
    assign out0_p9 = reg_out0_p9;
    assign out0_p10 = reg_out0_p10;
    assign out0_p11 = reg_out0_p11;
    assign out0_p12 = reg_out0_p12;
    assign out0_p13 = reg_out0_p13;
    assign out0_p14 = reg_out0_p14;
    assign out0_p15 = reg_out0_p15;
    assign out0_p16 = reg_out0_p16;
    assign out0_p17 = reg_out0_p17;
    assign out0_p18 = reg_out0_p18;
    assign out0_p19 = reg_out0_p19;
    assign out0_p20 = reg_out0_p20;
    assign out0_p21 = reg_out0_p21;
    assign out0_p22 = reg_out0_p22;
    assign out0_p23 = reg_out0_p23;
    assign out0_p24 = reg_out0_p24;
    assign out0_p25 = reg_out0_p25;
    assign out0_p26 = reg_out0_p26;
    assign out0_p27 = reg_out0_p27;
    assign out0_p28 = reg_out0_p28;
    assign out0_p29 = reg_out0_p29;
    assign out0_p30 = reg_out0_p30;
    assign out0_p31 = reg_out0_p31;
    assign out1_p32 = reg_out1_p32;
    assign out1_p33 = reg_out1_p33;
    assign out1_p34 = reg_out1_p34;
    assign out1_p35 = reg_out1_p35;
    assign out1_p36 = reg_out1_p36;
    assign out1_p37 = reg_out1_p37;
    assign out1_p38 = reg_out1_p38;
    assign out1_p39 = reg_out1_p39;
    assign out1_p40 = reg_out1_p40;
    assign out1_p41 = reg_out1_p41;
    assign out1_p42 = reg_out1_p42;
    assign out1_p43 = reg_out1_p43;
    assign out1_p44 = reg_out1_p44;
    assign out1_p45 = reg_out1_p45;
    assign out1_p46 = reg_out1_p46;
    assign out1_p47 = reg_out1_p47;
    assign out1_p48 = reg_out1_p48;
    assign out1_p49 = reg_out1_p49;
    assign out1_p50 = reg_out1_p50;
    assign out1_p51 = reg_out1_p51;
    assign out1_p52 = reg_out1_p52;
    assign out1_p53 = reg_out1_p53;
    assign out1_p54 = reg_out1_p54;
    assign out1_p55 = reg_out1_p55;
    assign out1_p56 = reg_out1_p56;
    assign out1_p57 = reg_out1_p57;
    assign out1_p58 = reg_out1_p58;
    assign out1_p59 = reg_out1_p59;
    assign out1_p60 = reg_out1_p60;
    assign out1_p61 = reg_out1_p61;
    assign oe0_p0 = reg_oe0_p0;
    assign oe0_p1 = reg_oe0_p1;
    assign oe0_p2 = reg_oe0_p2;
    assign oe0_p3 = reg_oe0_p3;
    assign oe0_p4 = reg_oe0_p4;
    assign oe0_p5 = reg_oe0_p5;
    assign oe0_p6 = reg_oe0_p6;
    assign oe0_p7 = reg_oe0_p7;
    assign oe0_p8 = reg_oe0_p8;
    assign oe0_p9 = reg_oe0_p9;
    assign oe0_p10 = reg_oe0_p10;
    assign oe0_p11 = reg_oe0_p11;
    assign oe0_p12 = reg_oe0_p12;
    assign oe0_p13 = reg_oe0_p13;
    assign oe0_p14 = reg_oe0_p14;
    assign oe0_p15 = reg_oe0_p15;
    assign oe0_p16 = reg_oe0_p16;
    assign oe0_p17 = reg_oe0_p17;
    assign oe0_p18 = reg_oe0_p18;
    assign oe0_p19 = reg_oe0_p19;
    assign oe0_p20 = reg_oe0_p20;
    assign oe0_p21 = reg_oe0_p21;
    assign oe0_p22 = reg_oe0_p22;
    assign oe0_p23 = reg_oe0_p23;
    assign oe0_p24 = reg_oe0_p24;
    assign oe0_p25 = reg_oe0_p25;
    assign oe0_p26 = reg_oe0_p26;
    assign oe0_p27 = reg_oe0_p27;
    assign oe0_p28 = reg_oe0_p28;
    assign oe0_p29 = reg_oe0_p29;
    assign oe0_p30 = reg_oe0_p30;
    assign oe0_p31 = reg_oe0_p31;
    assign oe1_p32 = reg_oe1_p32;
    assign oe1_p33 = reg_oe1_p33;
    assign oe1_p34 = reg_oe1_p34;
    assign oe1_p35 = reg_oe1_p35;
    assign oe1_p36 = reg_oe1_p36;
    assign oe1_p37 = reg_oe1_p37;
    assign oe1_p38 = reg_oe1_p38;
    assign oe1_p39 = reg_oe1_p39;
    assign oe1_p40 = reg_oe1_p40;
    assign oe1_p41 = reg_oe1_p41;
    assign oe1_p42 = reg_oe1_p42;
    assign oe1_p43 = reg_oe1_p43;
    assign oe1_p44 = reg_oe1_p44;
    assign oe1_p45 = reg_oe1_p45;
    assign oe1_p46 = reg_oe1_p46;
    assign oe1_p47 = reg_oe1_p47;
    assign oe1_p48 = reg_oe1_p48;
    assign oe1_p49 = reg_oe1_p49;
    assign oe1_p50 = reg_oe1_p50;
    assign oe1_p51 = reg_oe1_p51;
    assign oe1_p52 = reg_oe1_p52;
    assign oe1_p53 = reg_oe1_p53;
    assign oe1_p54 = reg_oe1_p54;
    assign oe1_p55 = reg_oe1_p55;
    assign oe1_p56 = reg_oe1_p56;
    assign oe1_p57 = reg_oe1_p57;
    assign oe1_p58 = reg_oe1_p58;
    assign oe1_p59 = reg_oe1_p59;
    assign oe1_p60 = reg_oe1_p60;
    assign oe1_p61 = reg_oe1_p61;

    // Read mux: bus_rdata by register address
    always_comb begin
        bus_rdata = 32'h0;
        if (bus_rd) begin
            case (bus_addr)
                12'h000: begin
                    bus_rdata[0:0] = ctrl0_funcsel;
                end
                12'h004: begin
                    bus_rdata[0:0] = ctrl1_funcsel;
                end
                12'h008: begin
                    bus_rdata[0:0] = ctrl2_funcsel;
                end
                12'h00C: begin
                    bus_rdata[0:0] = ctrl3_funcsel;
                end
                12'h010: begin
                    bus_rdata[0:0] = ctrl4_funcsel;
                end
                12'h014: begin
                    bus_rdata[0:0] = ctrl5_funcsel;
                end
                12'h018: begin
                    bus_rdata[0:0] = ctrl6_funcsel;
                end
                12'h01C: begin
                    bus_rdata[0:0] = ctrl7_funcsel;
                end
                12'h020: begin
                    bus_rdata[0:0] = ctrl8_funcsel;
                end
                12'h024: begin
                    bus_rdata[0:0] = ctrl9_funcsel;
                end
                12'h028: begin
                    bus_rdata[0:0] = ctrl10_funcsel;
                end
                12'h02C: begin
                    bus_rdata[0:0] = ctrl11_funcsel;
                end
                12'h030: begin
                    bus_rdata[0:0] = ctrl12_funcsel;
                end
                12'h034: begin
                    bus_rdata[0:0] = ctrl13_funcsel;
                end
                12'h038: begin
                    bus_rdata[0:0] = ctrl14_funcsel;
                end
                12'h03C: begin
                    bus_rdata[0:0] = ctrl15_funcsel;
                end
                12'h040: begin
                    bus_rdata[0:0] = ctrl16_funcsel;
                end
                12'h044: begin
                    bus_rdata[0:0] = ctrl17_funcsel;
                end
                12'h048: begin
                    bus_rdata[0:0] = ctrl18_funcsel;
                end
                12'h04C: begin
                    bus_rdata[0:0] = ctrl19_funcsel;
                end
                12'h050: begin
                    bus_rdata[0:0] = ctrl20_funcsel;
                end
                12'h054: begin
                    bus_rdata[0:0] = ctrl21_funcsel;
                end
                12'h058: begin
                    bus_rdata[0:0] = ctrl22_funcsel;
                end
                12'h05C: begin
                    bus_rdata[0:0] = ctrl23_funcsel;
                end
                12'h060: begin
                    bus_rdata[0:0] = ctrl24_funcsel;
                end
                12'h064: begin
                    bus_rdata[0:0] = ctrl25_funcsel;
                end
                12'h068: begin
                    bus_rdata[0:0] = ctrl26_funcsel;
                end
                12'h06C: begin
                    bus_rdata[0:0] = ctrl27_funcsel;
                end
                12'h070: begin
                    bus_rdata[0:0] = ctrl28_funcsel;
                end
                12'h074: begin
                    bus_rdata[0:0] = ctrl29_funcsel;
                end
                12'h078: begin
                    bus_rdata[0:0] = ctrl30_funcsel;
                end
                12'h07C: begin
                    bus_rdata[0:0] = ctrl31_funcsel;
                end
                12'h080: begin
                    bus_rdata[0:0] = ctrl32_funcsel;
                end
                12'h084: begin
                    bus_rdata[0:0] = ctrl33_funcsel;
                end
                12'h088: begin
                    bus_rdata[0:0] = ctrl34_funcsel;
                end
                12'h08C: begin
                    bus_rdata[0:0] = ctrl35_funcsel;
                end
                12'h090: begin
                    bus_rdata[0:0] = ctrl36_funcsel;
                end
                12'h094: begin
                    bus_rdata[0:0] = ctrl37_funcsel;
                end
                12'h098: begin
                    bus_rdata[0:0] = ctrl38_funcsel;
                end
                12'h09C: begin
                    bus_rdata[0:0] = ctrl39_funcsel;
                end
                12'h0A0: begin
                    bus_rdata[0:0] = ctrl40_funcsel;
                end
                12'h0A4: begin
                    bus_rdata[0:0] = ctrl41_funcsel;
                end
                12'h0A8: begin
                    bus_rdata[0:0] = ctrl42_funcsel;
                end
                12'h0AC: begin
                    bus_rdata[0:0] = ctrl43_funcsel;
                end
                12'h0B0: begin
                    bus_rdata[0:0] = ctrl44_funcsel;
                end
                12'h0B4: begin
                    bus_rdata[0:0] = ctrl45_funcsel;
                end
                12'h0B8: begin
                    bus_rdata[0:0] = ctrl46_funcsel;
                end
                12'h0BC: begin
                    bus_rdata[0:0] = ctrl47_funcsel;
                end
                12'h0C0: begin
                    bus_rdata[0:0] = ctrl48_funcsel;
                end
                12'h0C4: begin
                    bus_rdata[0:0] = ctrl49_funcsel;
                end
                12'h0C8: begin
                    bus_rdata[0:0] = ctrl50_funcsel;
                end
                12'h0CC: begin
                    bus_rdata[0:0] = ctrl51_funcsel;
                end
                12'h0D0: begin
                    bus_rdata[0:0] = ctrl52_funcsel;
                end
                12'h0D4: begin
                    bus_rdata[0:0] = ctrl53_funcsel;
                end
                12'h0D8: begin
                    bus_rdata[0:0] = ctrl54_funcsel;
                end
                12'h0DC: begin
                    bus_rdata[0:0] = ctrl55_funcsel;
                end
                12'h0E0: begin
                    bus_rdata[0:0] = ctrl56_funcsel;
                end
                12'h0E4: begin
                    bus_rdata[0:0] = ctrl57_funcsel;
                end
                12'h0E8: begin
                    bus_rdata[0:0] = ctrl58_funcsel;
                end
                12'h0EC: begin
                    bus_rdata[0:0] = ctrl59_funcsel;
                end
                12'h0F0: begin
                    bus_rdata[0:0] = ctrl60_funcsel;
                end
                12'h0F4: begin
                    bus_rdata[0:0] = ctrl61_funcsel;
                end
                12'h100: begin
                    bus_rdata[0:0] = out0_p0;
                    bus_rdata[1:1] = out0_p1;
                    bus_rdata[2:2] = out0_p2;
                    bus_rdata[3:3] = out0_p3;
                    bus_rdata[4:4] = out0_p4;
                    bus_rdata[5:5] = out0_p5;
                    bus_rdata[6:6] = out0_p6;
                    bus_rdata[7:7] = out0_p7;
                    bus_rdata[8:8] = out0_p8;
                    bus_rdata[9:9] = out0_p9;
                    bus_rdata[10:10] = out0_p10;
                    bus_rdata[11:11] = out0_p11;
                    bus_rdata[12:12] = out0_p12;
                    bus_rdata[13:13] = out0_p13;
                    bus_rdata[14:14] = out0_p14;
                    bus_rdata[15:15] = out0_p15;
                    bus_rdata[16:16] = out0_p16;
                    bus_rdata[17:17] = out0_p17;
                    bus_rdata[18:18] = out0_p18;
                    bus_rdata[19:19] = out0_p19;
                    bus_rdata[20:20] = out0_p20;
                    bus_rdata[21:21] = out0_p21;
                    bus_rdata[22:22] = out0_p22;
                    bus_rdata[23:23] = out0_p23;
                    bus_rdata[24:24] = out0_p24;
                    bus_rdata[25:25] = out0_p25;
                    bus_rdata[26:26] = out0_p26;
                    bus_rdata[27:27] = out0_p27;
                    bus_rdata[28:28] = out0_p28;
                    bus_rdata[29:29] = out0_p29;
                    bus_rdata[30:30] = out0_p30;
                    bus_rdata[31:31] = out0_p31;
                end
                12'h104: begin
                    bus_rdata[0:0] = out1_p32;
                    bus_rdata[1:1] = out1_p33;
                    bus_rdata[2:2] = out1_p34;
                    bus_rdata[3:3] = out1_p35;
                    bus_rdata[4:4] = out1_p36;
                    bus_rdata[5:5] = out1_p37;
                    bus_rdata[6:6] = out1_p38;
                    bus_rdata[7:7] = out1_p39;
                    bus_rdata[8:8] = out1_p40;
                    bus_rdata[9:9] = out1_p41;
                    bus_rdata[10:10] = out1_p42;
                    bus_rdata[11:11] = out1_p43;
                    bus_rdata[12:12] = out1_p44;
                    bus_rdata[13:13] = out1_p45;
                    bus_rdata[14:14] = out1_p46;
                    bus_rdata[15:15] = out1_p47;
                    bus_rdata[16:16] = out1_p48;
                    bus_rdata[17:17] = out1_p49;
                    bus_rdata[18:18] = out1_p50;
                    bus_rdata[19:19] = out1_p51;
                    bus_rdata[20:20] = out1_p52;
                    bus_rdata[21:21] = out1_p53;
                    bus_rdata[22:22] = out1_p54;
                    bus_rdata[23:23] = out1_p55;
                    bus_rdata[24:24] = out1_p56;
                    bus_rdata[25:25] = out1_p57;
                    bus_rdata[26:26] = out1_p58;
                    bus_rdata[27:27] = out1_p59;
                    bus_rdata[28:28] = out1_p60;
                    bus_rdata[29:29] = out1_p61;
                end
                12'h108: begin
                    bus_rdata[0:0] = out0_p0;
                    bus_rdata[1:1] = out0_p1;
                    bus_rdata[2:2] = out0_p2;
                    bus_rdata[3:3] = out0_p3;
                    bus_rdata[4:4] = out0_p4;
                    bus_rdata[5:5] = out0_p5;
                    bus_rdata[6:6] = out0_p6;
                    bus_rdata[7:7] = out0_p7;
                    bus_rdata[8:8] = out0_p8;
                    bus_rdata[9:9] = out0_p9;
                    bus_rdata[10:10] = out0_p10;
                    bus_rdata[11:11] = out0_p11;
                    bus_rdata[12:12] = out0_p12;
                    bus_rdata[13:13] = out0_p13;
                    bus_rdata[14:14] = out0_p14;
                    bus_rdata[15:15] = out0_p15;
                    bus_rdata[16:16] = out0_p16;
                    bus_rdata[17:17] = out0_p17;
                    bus_rdata[18:18] = out0_p18;
                    bus_rdata[19:19] = out0_p19;
                    bus_rdata[20:20] = out0_p20;
                    bus_rdata[21:21] = out0_p21;
                    bus_rdata[22:22] = out0_p22;
                    bus_rdata[23:23] = out0_p23;
                    bus_rdata[24:24] = out0_p24;
                    bus_rdata[25:25] = out0_p25;
                    bus_rdata[26:26] = out0_p26;
                    bus_rdata[27:27] = out0_p27;
                    bus_rdata[28:28] = out0_p28;
                    bus_rdata[29:29] = out0_p29;
                    bus_rdata[30:30] = out0_p30;
                    bus_rdata[31:31] = out0_p31;
                end
                12'h10C: begin
                    bus_rdata[0:0] = out1_p32;
                    bus_rdata[1:1] = out1_p33;
                    bus_rdata[2:2] = out1_p34;
                    bus_rdata[3:3] = out1_p35;
                    bus_rdata[4:4] = out1_p36;
                    bus_rdata[5:5] = out1_p37;
                    bus_rdata[6:6] = out1_p38;
                    bus_rdata[7:7] = out1_p39;
                    bus_rdata[8:8] = out1_p40;
                    bus_rdata[9:9] = out1_p41;
                    bus_rdata[10:10] = out1_p42;
                    bus_rdata[11:11] = out1_p43;
                    bus_rdata[12:12] = out1_p44;
                    bus_rdata[13:13] = out1_p45;
                    bus_rdata[14:14] = out1_p46;
                    bus_rdata[15:15] = out1_p47;
                    bus_rdata[16:16] = out1_p48;
                    bus_rdata[17:17] = out1_p49;
                    bus_rdata[18:18] = out1_p50;
                    bus_rdata[19:19] = out1_p51;
                    bus_rdata[20:20] = out1_p52;
                    bus_rdata[21:21] = out1_p53;
                    bus_rdata[22:22] = out1_p54;
                    bus_rdata[23:23] = out1_p55;
                    bus_rdata[24:24] = out1_p56;
                    bus_rdata[25:25] = out1_p57;
                    bus_rdata[26:26] = out1_p58;
                    bus_rdata[27:27] = out1_p59;
                    bus_rdata[28:28] = out1_p60;
                    bus_rdata[29:29] = out1_p61;
                end
                12'h110: begin
                    bus_rdata[0:0] = out0_p0;
                    bus_rdata[1:1] = out0_p1;
                    bus_rdata[2:2] = out0_p2;
                    bus_rdata[3:3] = out0_p3;
                    bus_rdata[4:4] = out0_p4;
                    bus_rdata[5:5] = out0_p5;
                    bus_rdata[6:6] = out0_p6;
                    bus_rdata[7:7] = out0_p7;
                    bus_rdata[8:8] = out0_p8;
                    bus_rdata[9:9] = out0_p9;
                    bus_rdata[10:10] = out0_p10;
                    bus_rdata[11:11] = out0_p11;
                    bus_rdata[12:12] = out0_p12;
                    bus_rdata[13:13] = out0_p13;
                    bus_rdata[14:14] = out0_p14;
                    bus_rdata[15:15] = out0_p15;
                    bus_rdata[16:16] = out0_p16;
                    bus_rdata[17:17] = out0_p17;
                    bus_rdata[18:18] = out0_p18;
                    bus_rdata[19:19] = out0_p19;
                    bus_rdata[20:20] = out0_p20;
                    bus_rdata[21:21] = out0_p21;
                    bus_rdata[22:22] = out0_p22;
                    bus_rdata[23:23] = out0_p23;
                    bus_rdata[24:24] = out0_p24;
                    bus_rdata[25:25] = out0_p25;
                    bus_rdata[26:26] = out0_p26;
                    bus_rdata[27:27] = out0_p27;
                    bus_rdata[28:28] = out0_p28;
                    bus_rdata[29:29] = out0_p29;
                    bus_rdata[30:30] = out0_p30;
                    bus_rdata[31:31] = out0_p31;
                end
                12'h114: begin
                    bus_rdata[0:0] = out1_p32;
                    bus_rdata[1:1] = out1_p33;
                    bus_rdata[2:2] = out1_p34;
                    bus_rdata[3:3] = out1_p35;
                    bus_rdata[4:4] = out1_p36;
                    bus_rdata[5:5] = out1_p37;
                    bus_rdata[6:6] = out1_p38;
                    bus_rdata[7:7] = out1_p39;
                    bus_rdata[8:8] = out1_p40;
                    bus_rdata[9:9] = out1_p41;
                    bus_rdata[10:10] = out1_p42;
                    bus_rdata[11:11] = out1_p43;
                    bus_rdata[12:12] = out1_p44;
                    bus_rdata[13:13] = out1_p45;
                    bus_rdata[14:14] = out1_p46;
                    bus_rdata[15:15] = out1_p47;
                    bus_rdata[16:16] = out1_p48;
                    bus_rdata[17:17] = out1_p49;
                    bus_rdata[18:18] = out1_p50;
                    bus_rdata[19:19] = out1_p51;
                    bus_rdata[20:20] = out1_p52;
                    bus_rdata[21:21] = out1_p53;
                    bus_rdata[22:22] = out1_p54;
                    bus_rdata[23:23] = out1_p55;
                    bus_rdata[24:24] = out1_p56;
                    bus_rdata[25:25] = out1_p57;
                    bus_rdata[26:26] = out1_p58;
                    bus_rdata[27:27] = out1_p59;
                    bus_rdata[28:28] = out1_p60;
                    bus_rdata[29:29] = out1_p61;
                end
                12'h118: begin
                    bus_rdata[0:0] = out0_p0;
                    bus_rdata[1:1] = out0_p1;
                    bus_rdata[2:2] = out0_p2;
                    bus_rdata[3:3] = out0_p3;
                    bus_rdata[4:4] = out0_p4;
                    bus_rdata[5:5] = out0_p5;
                    bus_rdata[6:6] = out0_p6;
                    bus_rdata[7:7] = out0_p7;
                    bus_rdata[8:8] = out0_p8;
                    bus_rdata[9:9] = out0_p9;
                    bus_rdata[10:10] = out0_p10;
                    bus_rdata[11:11] = out0_p11;
                    bus_rdata[12:12] = out0_p12;
                    bus_rdata[13:13] = out0_p13;
                    bus_rdata[14:14] = out0_p14;
                    bus_rdata[15:15] = out0_p15;
                    bus_rdata[16:16] = out0_p16;
                    bus_rdata[17:17] = out0_p17;
                    bus_rdata[18:18] = out0_p18;
                    bus_rdata[19:19] = out0_p19;
                    bus_rdata[20:20] = out0_p20;
                    bus_rdata[21:21] = out0_p21;
                    bus_rdata[22:22] = out0_p22;
                    bus_rdata[23:23] = out0_p23;
                    bus_rdata[24:24] = out0_p24;
                    bus_rdata[25:25] = out0_p25;
                    bus_rdata[26:26] = out0_p26;
                    bus_rdata[27:27] = out0_p27;
                    bus_rdata[28:28] = out0_p28;
                    bus_rdata[29:29] = out0_p29;
                    bus_rdata[30:30] = out0_p30;
                    bus_rdata[31:31] = out0_p31;
                end
                12'h11C: begin
                    bus_rdata[0:0] = out1_p32;
                    bus_rdata[1:1] = out1_p33;
                    bus_rdata[2:2] = out1_p34;
                    bus_rdata[3:3] = out1_p35;
                    bus_rdata[4:4] = out1_p36;
                    bus_rdata[5:5] = out1_p37;
                    bus_rdata[6:6] = out1_p38;
                    bus_rdata[7:7] = out1_p39;
                    bus_rdata[8:8] = out1_p40;
                    bus_rdata[9:9] = out1_p41;
                    bus_rdata[10:10] = out1_p42;
                    bus_rdata[11:11] = out1_p43;
                    bus_rdata[12:12] = out1_p44;
                    bus_rdata[13:13] = out1_p45;
                    bus_rdata[14:14] = out1_p46;
                    bus_rdata[15:15] = out1_p47;
                    bus_rdata[16:16] = out1_p48;
                    bus_rdata[17:17] = out1_p49;
                    bus_rdata[18:18] = out1_p50;
                    bus_rdata[19:19] = out1_p51;
                    bus_rdata[20:20] = out1_p52;
                    bus_rdata[21:21] = out1_p53;
                    bus_rdata[22:22] = out1_p54;
                    bus_rdata[23:23] = out1_p55;
                    bus_rdata[24:24] = out1_p56;
                    bus_rdata[25:25] = out1_p57;
                    bus_rdata[26:26] = out1_p58;
                    bus_rdata[27:27] = out1_p59;
                    bus_rdata[28:28] = out1_p60;
                    bus_rdata[29:29] = out1_p61;
                end
                12'h120: begin
                    bus_rdata[0:0] = oe0_p0;
                    bus_rdata[1:1] = oe0_p1;
                    bus_rdata[2:2] = oe0_p2;
                    bus_rdata[3:3] = oe0_p3;
                    bus_rdata[4:4] = oe0_p4;
                    bus_rdata[5:5] = oe0_p5;
                    bus_rdata[6:6] = oe0_p6;
                    bus_rdata[7:7] = oe0_p7;
                    bus_rdata[8:8] = oe0_p8;
                    bus_rdata[9:9] = oe0_p9;
                    bus_rdata[10:10] = oe0_p10;
                    bus_rdata[11:11] = oe0_p11;
                    bus_rdata[12:12] = oe0_p12;
                    bus_rdata[13:13] = oe0_p13;
                    bus_rdata[14:14] = oe0_p14;
                    bus_rdata[15:15] = oe0_p15;
                    bus_rdata[16:16] = oe0_p16;
                    bus_rdata[17:17] = oe0_p17;
                    bus_rdata[18:18] = oe0_p18;
                    bus_rdata[19:19] = oe0_p19;
                    bus_rdata[20:20] = oe0_p20;
                    bus_rdata[21:21] = oe0_p21;
                    bus_rdata[22:22] = oe0_p22;
                    bus_rdata[23:23] = oe0_p23;
                    bus_rdata[24:24] = oe0_p24;
                    bus_rdata[25:25] = oe0_p25;
                    bus_rdata[26:26] = oe0_p26;
                    bus_rdata[27:27] = oe0_p27;
                    bus_rdata[28:28] = oe0_p28;
                    bus_rdata[29:29] = oe0_p29;
                    bus_rdata[30:30] = oe0_p30;
                    bus_rdata[31:31] = oe0_p31;
                end
                12'h124: begin
                    bus_rdata[0:0] = oe1_p32;
                    bus_rdata[1:1] = oe1_p33;
                    bus_rdata[2:2] = oe1_p34;
                    bus_rdata[3:3] = oe1_p35;
                    bus_rdata[4:4] = oe1_p36;
                    bus_rdata[5:5] = oe1_p37;
                    bus_rdata[6:6] = oe1_p38;
                    bus_rdata[7:7] = oe1_p39;
                    bus_rdata[8:8] = oe1_p40;
                    bus_rdata[9:9] = oe1_p41;
                    bus_rdata[10:10] = oe1_p42;
                    bus_rdata[11:11] = oe1_p43;
                    bus_rdata[12:12] = oe1_p44;
                    bus_rdata[13:13] = oe1_p45;
                    bus_rdata[14:14] = oe1_p46;
                    bus_rdata[15:15] = oe1_p47;
                    bus_rdata[16:16] = oe1_p48;
                    bus_rdata[17:17] = oe1_p49;
                    bus_rdata[18:18] = oe1_p50;
                    bus_rdata[19:19] = oe1_p51;
                    bus_rdata[20:20] = oe1_p52;
                    bus_rdata[21:21] = oe1_p53;
                    bus_rdata[22:22] = oe1_p54;
                    bus_rdata[23:23] = oe1_p55;
                    bus_rdata[24:24] = oe1_p56;
                    bus_rdata[25:25] = oe1_p57;
                    bus_rdata[26:26] = oe1_p58;
                    bus_rdata[27:27] = oe1_p59;
                    bus_rdata[28:28] = oe1_p60;
                    bus_rdata[29:29] = oe1_p61;
                end
                12'h128: begin
                    bus_rdata[0:0] = oe0_p0;
                    bus_rdata[1:1] = oe0_p1;
                    bus_rdata[2:2] = oe0_p2;
                    bus_rdata[3:3] = oe0_p3;
                    bus_rdata[4:4] = oe0_p4;
                    bus_rdata[5:5] = oe0_p5;
                    bus_rdata[6:6] = oe0_p6;
                    bus_rdata[7:7] = oe0_p7;
                    bus_rdata[8:8] = oe0_p8;
                    bus_rdata[9:9] = oe0_p9;
                    bus_rdata[10:10] = oe0_p10;
                    bus_rdata[11:11] = oe0_p11;
                    bus_rdata[12:12] = oe0_p12;
                    bus_rdata[13:13] = oe0_p13;
                    bus_rdata[14:14] = oe0_p14;
                    bus_rdata[15:15] = oe0_p15;
                    bus_rdata[16:16] = oe0_p16;
                    bus_rdata[17:17] = oe0_p17;
                    bus_rdata[18:18] = oe0_p18;
                    bus_rdata[19:19] = oe0_p19;
                    bus_rdata[20:20] = oe0_p20;
                    bus_rdata[21:21] = oe0_p21;
                    bus_rdata[22:22] = oe0_p22;
                    bus_rdata[23:23] = oe0_p23;
                    bus_rdata[24:24] = oe0_p24;
                    bus_rdata[25:25] = oe0_p25;
                    bus_rdata[26:26] = oe0_p26;
                    bus_rdata[27:27] = oe0_p27;
                    bus_rdata[28:28] = oe0_p28;
                    bus_rdata[29:29] = oe0_p29;
                    bus_rdata[30:30] = oe0_p30;
                    bus_rdata[31:31] = oe0_p31;
                end
                12'h12C: begin
                    bus_rdata[0:0] = oe1_p32;
                    bus_rdata[1:1] = oe1_p33;
                    bus_rdata[2:2] = oe1_p34;
                    bus_rdata[3:3] = oe1_p35;
                    bus_rdata[4:4] = oe1_p36;
                    bus_rdata[5:5] = oe1_p37;
                    bus_rdata[6:6] = oe1_p38;
                    bus_rdata[7:7] = oe1_p39;
                    bus_rdata[8:8] = oe1_p40;
                    bus_rdata[9:9] = oe1_p41;
                    bus_rdata[10:10] = oe1_p42;
                    bus_rdata[11:11] = oe1_p43;
                    bus_rdata[12:12] = oe1_p44;
                    bus_rdata[13:13] = oe1_p45;
                    bus_rdata[14:14] = oe1_p46;
                    bus_rdata[15:15] = oe1_p47;
                    bus_rdata[16:16] = oe1_p48;
                    bus_rdata[17:17] = oe1_p49;
                    bus_rdata[18:18] = oe1_p50;
                    bus_rdata[19:19] = oe1_p51;
                    bus_rdata[20:20] = oe1_p52;
                    bus_rdata[21:21] = oe1_p53;
                    bus_rdata[22:22] = oe1_p54;
                    bus_rdata[23:23] = oe1_p55;
                    bus_rdata[24:24] = oe1_p56;
                    bus_rdata[25:25] = oe1_p57;
                    bus_rdata[26:26] = oe1_p58;
                    bus_rdata[27:27] = oe1_p59;
                    bus_rdata[28:28] = oe1_p60;
                    bus_rdata[29:29] = oe1_p61;
                end
                12'h130: begin
                    bus_rdata[0:0] = oe0_p0;
                    bus_rdata[1:1] = oe0_p1;
                    bus_rdata[2:2] = oe0_p2;
                    bus_rdata[3:3] = oe0_p3;
                    bus_rdata[4:4] = oe0_p4;
                    bus_rdata[5:5] = oe0_p5;
                    bus_rdata[6:6] = oe0_p6;
                    bus_rdata[7:7] = oe0_p7;
                    bus_rdata[8:8] = oe0_p8;
                    bus_rdata[9:9] = oe0_p9;
                    bus_rdata[10:10] = oe0_p10;
                    bus_rdata[11:11] = oe0_p11;
                    bus_rdata[12:12] = oe0_p12;
                    bus_rdata[13:13] = oe0_p13;
                    bus_rdata[14:14] = oe0_p14;
                    bus_rdata[15:15] = oe0_p15;
                    bus_rdata[16:16] = oe0_p16;
                    bus_rdata[17:17] = oe0_p17;
                    bus_rdata[18:18] = oe0_p18;
                    bus_rdata[19:19] = oe0_p19;
                    bus_rdata[20:20] = oe0_p20;
                    bus_rdata[21:21] = oe0_p21;
                    bus_rdata[22:22] = oe0_p22;
                    bus_rdata[23:23] = oe0_p23;
                    bus_rdata[24:24] = oe0_p24;
                    bus_rdata[25:25] = oe0_p25;
                    bus_rdata[26:26] = oe0_p26;
                    bus_rdata[27:27] = oe0_p27;
                    bus_rdata[28:28] = oe0_p28;
                    bus_rdata[29:29] = oe0_p29;
                    bus_rdata[30:30] = oe0_p30;
                    bus_rdata[31:31] = oe0_p31;
                end
                12'h134: begin
                    bus_rdata[0:0] = oe1_p32;
                    bus_rdata[1:1] = oe1_p33;
                    bus_rdata[2:2] = oe1_p34;
                    bus_rdata[3:3] = oe1_p35;
                    bus_rdata[4:4] = oe1_p36;
                    bus_rdata[5:5] = oe1_p37;
                    bus_rdata[6:6] = oe1_p38;
                    bus_rdata[7:7] = oe1_p39;
                    bus_rdata[8:8] = oe1_p40;
                    bus_rdata[9:9] = oe1_p41;
                    bus_rdata[10:10] = oe1_p42;
                    bus_rdata[11:11] = oe1_p43;
                    bus_rdata[12:12] = oe1_p44;
                    bus_rdata[13:13] = oe1_p45;
                    bus_rdata[14:14] = oe1_p46;
                    bus_rdata[15:15] = oe1_p47;
                    bus_rdata[16:16] = oe1_p48;
                    bus_rdata[17:17] = oe1_p49;
                    bus_rdata[18:18] = oe1_p50;
                    bus_rdata[19:19] = oe1_p51;
                    bus_rdata[20:20] = oe1_p52;
                    bus_rdata[21:21] = oe1_p53;
                    bus_rdata[22:22] = oe1_p54;
                    bus_rdata[23:23] = oe1_p55;
                    bus_rdata[24:24] = oe1_p56;
                    bus_rdata[25:25] = oe1_p57;
                    bus_rdata[26:26] = oe1_p58;
                    bus_rdata[27:27] = oe1_p59;
                    bus_rdata[28:28] = oe1_p60;
                    bus_rdata[29:29] = oe1_p61;
                end
                12'h138: begin
                    bus_rdata[0:0] = oe0_p0;
                    bus_rdata[1:1] = oe0_p1;
                    bus_rdata[2:2] = oe0_p2;
                    bus_rdata[3:3] = oe0_p3;
                    bus_rdata[4:4] = oe0_p4;
                    bus_rdata[5:5] = oe0_p5;
                    bus_rdata[6:6] = oe0_p6;
                    bus_rdata[7:7] = oe0_p7;
                    bus_rdata[8:8] = oe0_p8;
                    bus_rdata[9:9] = oe0_p9;
                    bus_rdata[10:10] = oe0_p10;
                    bus_rdata[11:11] = oe0_p11;
                    bus_rdata[12:12] = oe0_p12;
                    bus_rdata[13:13] = oe0_p13;
                    bus_rdata[14:14] = oe0_p14;
                    bus_rdata[15:15] = oe0_p15;
                    bus_rdata[16:16] = oe0_p16;
                    bus_rdata[17:17] = oe0_p17;
                    bus_rdata[18:18] = oe0_p18;
                    bus_rdata[19:19] = oe0_p19;
                    bus_rdata[20:20] = oe0_p20;
                    bus_rdata[21:21] = oe0_p21;
                    bus_rdata[22:22] = oe0_p22;
                    bus_rdata[23:23] = oe0_p23;
                    bus_rdata[24:24] = oe0_p24;
                    bus_rdata[25:25] = oe0_p25;
                    bus_rdata[26:26] = oe0_p26;
                    bus_rdata[27:27] = oe0_p27;
                    bus_rdata[28:28] = oe0_p28;
                    bus_rdata[29:29] = oe0_p29;
                    bus_rdata[30:30] = oe0_p30;
                    bus_rdata[31:31] = oe0_p31;
                end
                12'h13C: begin
                    bus_rdata[0:0] = oe1_p32;
                    bus_rdata[1:1] = oe1_p33;
                    bus_rdata[2:2] = oe1_p34;
                    bus_rdata[3:3] = oe1_p35;
                    bus_rdata[4:4] = oe1_p36;
                    bus_rdata[5:5] = oe1_p37;
                    bus_rdata[6:6] = oe1_p38;
                    bus_rdata[7:7] = oe1_p39;
                    bus_rdata[8:8] = oe1_p40;
                    bus_rdata[9:9] = oe1_p41;
                    bus_rdata[10:10] = oe1_p42;
                    bus_rdata[11:11] = oe1_p43;
                    bus_rdata[12:12] = oe1_p44;
                    bus_rdata[13:13] = oe1_p45;
                    bus_rdata[14:14] = oe1_p46;
                    bus_rdata[15:15] = oe1_p47;
                    bus_rdata[16:16] = oe1_p48;
                    bus_rdata[17:17] = oe1_p49;
                    bus_rdata[18:18] = oe1_p50;
                    bus_rdata[19:19] = oe1_p51;
                    bus_rdata[20:20] = oe1_p52;
                    bus_rdata[21:21] = oe1_p53;
                    bus_rdata[22:22] = oe1_p54;
                    bus_rdata[23:23] = oe1_p55;
                    bus_rdata[24:24] = oe1_p56;
                    bus_rdata[25:25] = oe1_p57;
                    bus_rdata[26:26] = oe1_p58;
                    bus_rdata[27:27] = oe1_p59;
                    bus_rdata[28:28] = oe1_p60;
                    bus_rdata[29:29] = oe1_p61;
                end
                12'h140: begin
                    bus_rdata[0:0] = in0_p0;
                    bus_rdata[1:1] = in0_p1;
                    bus_rdata[2:2] = in0_p2;
                    bus_rdata[3:3] = in0_p3;
                    bus_rdata[4:4] = in0_p4;
                    bus_rdata[5:5] = in0_p5;
                    bus_rdata[6:6] = in0_p6;
                    bus_rdata[7:7] = in0_p7;
                    bus_rdata[8:8] = in0_p8;
                    bus_rdata[9:9] = in0_p9;
                    bus_rdata[10:10] = in0_p10;
                    bus_rdata[11:11] = in0_p11;
                    bus_rdata[12:12] = in0_p12;
                    bus_rdata[13:13] = in0_p13;
                    bus_rdata[14:14] = in0_p14;
                    bus_rdata[15:15] = in0_p15;
                    bus_rdata[16:16] = in0_p16;
                    bus_rdata[17:17] = in0_p17;
                    bus_rdata[18:18] = in0_p18;
                    bus_rdata[19:19] = in0_p19;
                    bus_rdata[20:20] = in0_p20;
                    bus_rdata[21:21] = in0_p21;
                    bus_rdata[22:22] = in0_p22;
                    bus_rdata[23:23] = in0_p23;
                    bus_rdata[24:24] = in0_p24;
                    bus_rdata[25:25] = in0_p25;
                    bus_rdata[26:26] = in0_p26;
                    bus_rdata[27:27] = in0_p27;
                    bus_rdata[28:28] = in0_p28;
                    bus_rdata[29:29] = in0_p29;
                    bus_rdata[30:30] = in0_p30;
                    bus_rdata[31:31] = in0_p31;
                end
                12'h144: begin
                    bus_rdata[0:0] = in1_p32;
                    bus_rdata[1:1] = in1_p33;
                    bus_rdata[2:2] = in1_p34;
                    bus_rdata[3:3] = in1_p35;
                    bus_rdata[4:4] = in1_p36;
                    bus_rdata[5:5] = in1_p37;
                    bus_rdata[6:6] = in1_p38;
                    bus_rdata[7:7] = in1_p39;
                    bus_rdata[8:8] = in1_p40;
                    bus_rdata[9:9] = in1_p41;
                    bus_rdata[10:10] = in1_p42;
                    bus_rdata[11:11] = in1_p43;
                    bus_rdata[12:12] = in1_p44;
                    bus_rdata[13:13] = in1_p45;
                    bus_rdata[14:14] = in1_p46;
                    bus_rdata[15:15] = in1_p47;
                    bus_rdata[16:16] = in1_p48;
                    bus_rdata[17:17] = in1_p49;
                    bus_rdata[18:18] = in1_p50;
                    bus_rdata[19:19] = in1_p51;
                    bus_rdata[20:20] = in1_p52;
                    bus_rdata[21:21] = in1_p53;
                    bus_rdata[22:22] = in1_p54;
                    bus_rdata[23:23] = in1_p55;
                    bus_rdata[24:24] = in1_p56;
                    bus_rdata[25:25] = in1_p57;
                    bus_rdata[26:26] = in1_p58;
                    bus_rdata[27:27] = in1_p59;
                    bus_rdata[28:28] = in1_p60;
                    bus_rdata[29:29] = in1_p61;
                end
                default: ;
            endcase
        end
    end

    // Bus signals nothing in this zone reads, read here on purpose
    wire _unused = &{1'b0, haddr[31:12], htrans[0], hsize};

    // pad_in seen on clk through two flops
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pad_in_meta <= {PINS{1'b0}};
            pad_in_sync <= {PINS{1'b0}};
        end else begin
            pad_in_meta <= pad_in;
            pad_in_sync <= pad_in_meta;
        end
    end

    // IN: the synchronized level of each pad
    assign in0_p0 = pad_in_sync[0];
    assign in0_p1 = pad_in_sync[1];
    assign in0_p2 = pad_in_sync[2];
    assign in0_p3 = pad_in_sync[3];
    assign in0_p4 = pad_in_sync[4];
    assign in0_p5 = pad_in_sync[5];
    assign in0_p6 = pad_in_sync[6];
    assign in0_p7 = pad_in_sync[7];
    assign in0_p8 = pad_in_sync[8];
    assign in0_p9 = pad_in_sync[9];
    assign in0_p10 = pad_in_sync[10];
    assign in0_p11 = pad_in_sync[11];
    assign in0_p12 = pad_in_sync[12];
    assign in0_p13 = pad_in_sync[13];
    assign in0_p14 = pad_in_sync[14];
    assign in0_p15 = pad_in_sync[15];
    assign in0_p16 = pad_in_sync[16];
    assign in0_p17 = pad_in_sync[17];
    assign in0_p18 = pad_in_sync[18];
    assign in0_p19 = pad_in_sync[19];
    assign in0_p20 = pad_in_sync[20];
    assign in0_p21 = pad_in_sync[21];
    assign in0_p22 = pad_in_sync[22];
    assign in0_p23 = pad_in_sync[23];
    assign in0_p24 = pad_in_sync[24];
    assign in0_p25 = pad_in_sync[25];
    assign in0_p26 = pad_in_sync[26];
    assign in0_p27 = pad_in_sync[27];
    assign in0_p28 = pad_in_sync[28];
    assign in0_p29 = pad_in_sync[29];
    assign in0_p30 = pad_in_sync[30];
    assign in0_p31 = pad_in_sync[31];
    assign in1_p32 = pad_in_sync[32];
    assign in1_p33 = pad_in_sync[33];
    assign in1_p34 = pad_in_sync[34];
    assign in1_p35 = pad_in_sync[35];
    assign in1_p36 = pad_in_sync[36];
    assign in1_p37 = pad_in_sync[37];
    assign in1_p38 = pad_in_sync[38];
    assign in1_p39 = pad_in_sync[39];
    assign in1_p40 = pad_in_sync[40];
    assign in1_p41 = pad_in_sync[41];
    assign in1_p42 = pad_in_sync[42];
    assign in1_p43 = pad_in_sync[43];
    assign in1_p44 = pad_in_sync[44];
    assign in1_p45 = pad_in_sync[45];
    assign in1_p46 = pad_in_sync[46];
    assign in1_p47 = pad_in_sync[47];
    assign in1_p48 = pad_in_sync[48];
    assign in1_p49 = pad_in_sync[49];
    assign in1_p50 = pad_in_sync[50];
    assign in1_p51 = pad_in_sync[51];
    assign in1_p52 = pad_in_sync[52];
    assign in1_p53 = pad_in_sync[53];
    assign in1_p54 = pad_in_sync[54];
    assign in1_p55 = pad_in_sync[55];
    assign in1_p56 = pad_in_sync[56];
    assign in1_p57 = pad_in_sync[57];
    assign in1_p58 = pad_in_sync[58];
    assign in1_p59 = pad_in_sync[59];
    assign in1_p60 = pad_in_sync[60];
    assign in1_p61 = pad_in_sync[61];

    // pad_out and pad_oe by FUNCSEL
    assign pad_out[0] = (ctrl0_funcsel == 1'd0) ? out0_p0 :
                        1'b0;
    assign pad_oe[0] = (ctrl0_funcsel == 1'd0) ? oe0_p0 :
                       1'b0;
    assign pad_out[1] = (ctrl1_funcsel == 1'd0) ? out0_p1 :
                        1'b0;
    assign pad_oe[1] = (ctrl1_funcsel == 1'd0) ? oe0_p1 :
                       1'b0;
    assign pad_out[2] = (ctrl2_funcsel == 1'd0) ? out0_p2 :
                        1'b0;
    assign pad_oe[2] = (ctrl2_funcsel == 1'd0) ? oe0_p2 :
                       1'b0;
    assign pad_out[3] = (ctrl3_funcsel == 1'd0) ? out0_p3 :
                        1'b0;
    assign pad_oe[3] = (ctrl3_funcsel == 1'd0) ? oe0_p3 :
                       1'b0;
    assign pad_out[4] = (ctrl4_funcsel == 1'd0) ? out0_p4 :
                        1'b0;
    assign pad_oe[4] = (ctrl4_funcsel == 1'd0) ? oe0_p4 :
                       1'b0;
    assign pad_out[5] = (ctrl5_funcsel == 1'd0) ? out0_p5 :
                        1'b0;
    assign pad_oe[5] = (ctrl5_funcsel == 1'd0) ? oe0_p5 :
                       1'b0;
    assign pad_out[6] = (ctrl6_funcsel == 1'd0) ? out0_p6 :
                        1'b0;
    assign pad_oe[6] = (ctrl6_funcsel == 1'd0) ? oe0_p6 :
                       1'b0;
    assign pad_out[7] = (ctrl7_funcsel == 1'd0) ? out0_p7 :
                        1'b0;
    assign pad_oe[7] = (ctrl7_funcsel == 1'd0) ? oe0_p7 :
                       1'b0;
    assign pad_out[8] = (ctrl8_funcsel == 1'd0) ? out0_p8 :
                        1'b0;
    assign pad_oe[8] = (ctrl8_funcsel == 1'd0) ? oe0_p8 :
                       1'b0;
    assign pad_out[9] = (ctrl9_funcsel == 1'd0) ? out0_p9 :
                        1'b0;
    assign pad_oe[9] = (ctrl9_funcsel == 1'd0) ? oe0_p9 :
                       1'b0;
    assign pad_out[10] = (ctrl10_funcsel == 1'd0) ? out0_p10 :
                         1'b0;
    assign pad_oe[10] = (ctrl10_funcsel == 1'd0) ? oe0_p10 :
                        1'b0;
    assign pad_out[11] = (ctrl11_funcsel == 1'd0) ? out0_p11 :
                         1'b0;
    assign pad_oe[11] = (ctrl11_funcsel == 1'd0) ? oe0_p11 :
                        1'b0;
    assign pad_out[12] = (ctrl12_funcsel == 1'd0) ? out0_p12 :
                         1'b0;
    assign pad_oe[12] = (ctrl12_funcsel == 1'd0) ? oe0_p12 :
                        1'b0;
    assign pad_out[13] = (ctrl13_funcsel == 1'd0) ? out0_p13 :
                         1'b0;
    assign pad_oe[13] = (ctrl13_funcsel == 1'd0) ? oe0_p13 :
                        1'b0;
    assign pad_out[14] = (ctrl14_funcsel == 1'd0) ? out0_p14 :
                         1'b0;
    assign pad_oe[14] = (ctrl14_funcsel == 1'd0) ? oe0_p14 :
                        1'b0;
    assign pad_out[15] = (ctrl15_funcsel == 1'd0) ? out0_p15 :
                         1'b0;
    assign pad_oe[15] = (ctrl15_funcsel == 1'd0) ? oe0_p15 :
                        1'b0;
    assign pad_out[16] = (ctrl16_funcsel == 1'd0) ? out0_p16 :
                         1'b0;
    assign pad_oe[16] = (ctrl16_funcsel == 1'd0) ? oe0_p16 :
                        1'b0;
    assign pad_out[17] = (ctrl17_funcsel == 1'd0) ? out0_p17 :
                         1'b0;
    assign pad_oe[17] = (ctrl17_funcsel == 1'd0) ? oe0_p17 :
                        1'b0;
    assign pad_out[18] = (ctrl18_funcsel == 1'd0) ? out0_p18 :
                         1'b0;
    assign pad_oe[18] = (ctrl18_funcsel == 1'd0) ? oe0_p18 :
                        1'b0;
    assign pad_out[19] = (ctrl19_funcsel == 1'd0) ? out0_p19 :
                         1'b0;
    assign pad_oe[19] = (ctrl19_funcsel == 1'd0) ? oe0_p19 :
                        1'b0;
    assign pad_out[20] = (ctrl20_funcsel == 1'd0) ? out0_p20 :
                         1'b0;
    assign pad_oe[20] = (ctrl20_funcsel == 1'd0) ? oe0_p20 :
                        1'b0;
    assign pad_out[21] = (ctrl21_funcsel == 1'd0) ? out0_p21 :
                         1'b0;
    assign pad_oe[21] = (ctrl21_funcsel == 1'd0) ? oe0_p21 :
                        1'b0;
    assign pad_out[22] = (ctrl22_funcsel == 1'd0) ? out0_p22 :
                         1'b0;
    assign pad_oe[22] = (ctrl22_funcsel == 1'd0) ? oe0_p22 :
                        1'b0;
    assign pad_out[23] = (ctrl23_funcsel == 1'd0) ? out0_p23 :
                         1'b0;
    assign pad_oe[23] = (ctrl23_funcsel == 1'd0) ? oe0_p23 :
                        1'b0;
    assign pad_out[24] = (ctrl24_funcsel == 1'd0) ? out0_p24 :
                         1'b0;
    assign pad_oe[24] = (ctrl24_funcsel == 1'd0) ? oe0_p24 :
                        1'b0;
    assign pad_out[25] = (ctrl25_funcsel == 1'd0) ? out0_p25 :
                         1'b0;
    assign pad_oe[25] = (ctrl25_funcsel == 1'd0) ? oe0_p25 :
                        1'b0;
    assign pad_out[26] = (ctrl26_funcsel == 1'd0) ? out0_p26 :
                         1'b0;
    assign pad_oe[26] = (ctrl26_funcsel == 1'd0) ? oe0_p26 :
                        1'b0;
    assign pad_out[27] = (ctrl27_funcsel == 1'd0) ? out0_p27 :
                         1'b0;
    assign pad_oe[27] = (ctrl27_funcsel == 1'd0) ? oe0_p27 :
                        1'b0;
    assign pad_out[28] = (ctrl28_funcsel == 1'd0) ? out0_p28 :
                         1'b0;
    assign pad_oe[28] = (ctrl28_funcsel == 1'd0) ? oe0_p28 :
                        1'b0;
    assign pad_out[29] = (ctrl29_funcsel == 1'd0) ? out0_p29 :
                         1'b0;
    assign pad_oe[29] = (ctrl29_funcsel == 1'd0) ? oe0_p29 :
                        1'b0;
    assign pad_out[30] = (ctrl30_funcsel == 1'd0) ? out0_p30 :
                         1'b0;
    assign pad_oe[30] = (ctrl30_funcsel == 1'd0) ? oe0_p30 :
                        1'b0;
    assign pad_out[31] = (ctrl31_funcsel == 1'd0) ? out0_p31 :
                         1'b0;
    assign pad_oe[31] = (ctrl31_funcsel == 1'd0) ? oe0_p31 :
                        1'b0;
    assign pad_out[32] = (ctrl32_funcsel == 1'd0) ? out1_p32 :
                         1'b0;
    assign pad_oe[32] = (ctrl32_funcsel == 1'd0) ? oe1_p32 :
                        1'b0;
    assign pad_out[33] = (ctrl33_funcsel == 1'd0) ? out1_p33 :
                         1'b0;
    assign pad_oe[33] = (ctrl33_funcsel == 1'd0) ? oe1_p33 :
                        1'b0;
    assign pad_out[34] = (ctrl34_funcsel == 1'd0) ? out1_p34 :
                         1'b0;
    assign pad_oe[34] = (ctrl34_funcsel == 1'd0) ? oe1_p34 :
                        1'b0;
    assign pad_out[35] = (ctrl35_funcsel == 1'd0) ? out1_p35 :
                         1'b0;
    assign pad_oe[35] = (ctrl35_funcsel == 1'd0) ? oe1_p35 :
                        1'b0;
    assign pad_out[36] = (ctrl36_funcsel == 1'd0) ? out1_p36 :
                         1'b0;
    assign pad_oe[36] = (ctrl36_funcsel == 1'd0) ? oe1_p36 :
                        1'b0;
    assign pad_out[37] = (ctrl37_funcsel == 1'd0) ? out1_p37 :
                         1'b0;
    assign pad_oe[37] = (ctrl37_funcsel == 1'd0) ? oe1_p37 :
                        1'b0;
    assign pad_out[38] = (ctrl38_funcsel == 1'd0) ? out1_p38 :
                         1'b0;
    assign pad_oe[38] = (ctrl38_funcsel == 1'd0) ? oe1_p38 :
                        1'b0;
    assign pad_out[39] = (ctrl39_funcsel == 1'd0) ? out1_p39 :
                         1'b0;
    assign pad_oe[39] = (ctrl39_funcsel == 1'd0) ? oe1_p39 :
                        1'b0;
    assign pad_out[40] = (ctrl40_funcsel == 1'd0) ? out1_p40 :
                         1'b0;
    assign pad_oe[40] = (ctrl40_funcsel == 1'd0) ? oe1_p40 :
                        1'b0;
    assign pad_out[41] = (ctrl41_funcsel == 1'd0) ? out1_p41 :
                         1'b0;
    assign pad_oe[41] = (ctrl41_funcsel == 1'd0) ? oe1_p41 :
                        1'b0;
    assign pad_out[42] = (ctrl42_funcsel == 1'd0) ? out1_p42 :
                         1'b0;
    assign pad_oe[42] = (ctrl42_funcsel == 1'd0) ? oe1_p42 :
                        1'b0;
    assign pad_out[43] = (ctrl43_funcsel == 1'd0) ? out1_p43 :
                         1'b0;
    assign pad_oe[43] = (ctrl43_funcsel == 1'd0) ? oe1_p43 :
                        1'b0;
    assign pad_out[44] = (ctrl44_funcsel == 1'd0) ? out1_p44 :
                         1'b0;
    assign pad_oe[44] = (ctrl44_funcsel == 1'd0) ? oe1_p44 :
                        1'b0;
    assign pad_out[45] = (ctrl45_funcsel == 1'd0) ? out1_p45 :
                         1'b0;
    assign pad_oe[45] = (ctrl45_funcsel == 1'd0) ? oe1_p45 :
                        1'b0;
    assign pad_out[46] = (ctrl46_funcsel == 1'd0) ? out1_p46 :
                         1'b0;
    assign pad_oe[46] = (ctrl46_funcsel == 1'd0) ? oe1_p46 :
                        1'b0;
    assign pad_out[47] = (ctrl47_funcsel == 1'd0) ? out1_p47 :
                         1'b0;
    assign pad_oe[47] = (ctrl47_funcsel == 1'd0) ? oe1_p47 :
                        1'b0;
    assign pad_out[48] = (ctrl48_funcsel == 1'd0) ? out1_p48 :
                         (ctrl48_funcsel == 1'd1) ? racer0_rgb[0] :
                         1'b0;
    assign pad_oe[48] = (ctrl48_funcsel == 1'd0) ? oe1_p48 :
                        (ctrl48_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[49] = (ctrl49_funcsel == 1'd0) ? out1_p49 :
                         (ctrl49_funcsel == 1'd1) ? racer0_rgb[1] :
                         1'b0;
    assign pad_oe[49] = (ctrl49_funcsel == 1'd0) ? oe1_p49 :
                        (ctrl49_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[50] = (ctrl50_funcsel == 1'd0) ? out1_p50 :
                         (ctrl50_funcsel == 1'd1) ? racer0_rgb[2] :
                         1'b0;
    assign pad_oe[50] = (ctrl50_funcsel == 1'd0) ? oe1_p50 :
                        (ctrl50_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[51] = (ctrl51_funcsel == 1'd0) ? out1_p51 :
                         (ctrl51_funcsel == 1'd1) ? racer0_rgb[3] :
                         1'b0;
    assign pad_oe[51] = (ctrl51_funcsel == 1'd0) ? oe1_p51 :
                        (ctrl51_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[52] = (ctrl52_funcsel == 1'd0) ? out1_p52 :
                         (ctrl52_funcsel == 1'd1) ? racer0_rgb[4] :
                         1'b0;
    assign pad_oe[52] = (ctrl52_funcsel == 1'd0) ? oe1_p52 :
                        (ctrl52_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[53] = (ctrl53_funcsel == 1'd0) ? out1_p53 :
                         (ctrl53_funcsel == 1'd1) ? racer0_rgb[5] :
                         1'b0;
    assign pad_oe[53] = (ctrl53_funcsel == 1'd0) ? oe1_p53 :
                        (ctrl53_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[54] = (ctrl54_funcsel == 1'd0) ? out1_p54 :
                         (ctrl54_funcsel == 1'd1) ? racer0_rgb[6] :
                         1'b0;
    assign pad_oe[54] = (ctrl54_funcsel == 1'd0) ? oe1_p54 :
                        (ctrl54_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[55] = (ctrl55_funcsel == 1'd0) ? out1_p55 :
                         (ctrl55_funcsel == 1'd1) ? racer0_rgb[7] :
                         1'b0;
    assign pad_oe[55] = (ctrl55_funcsel == 1'd0) ? oe1_p55 :
                        (ctrl55_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[56] = (ctrl56_funcsel == 1'd0) ? out1_p56 :
                         (ctrl56_funcsel == 1'd1) ? racer0_rgb[8] :
                         1'b0;
    assign pad_oe[56] = (ctrl56_funcsel == 1'd0) ? oe1_p56 :
                        (ctrl56_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[57] = (ctrl57_funcsel == 1'd0) ? out1_p57 :
                         (ctrl57_funcsel == 1'd1) ? racer0_rgb[9] :
                         1'b0;
    assign pad_oe[57] = (ctrl57_funcsel == 1'd0) ? oe1_p57 :
                        (ctrl57_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[58] = (ctrl58_funcsel == 1'd0) ? out1_p58 :
                         (ctrl58_funcsel == 1'd1) ? racer0_rgb[10] :
                         1'b0;
    assign pad_oe[58] = (ctrl58_funcsel == 1'd0) ? oe1_p58 :
                        (ctrl58_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[59] = (ctrl59_funcsel == 1'd0) ? out1_p59 :
                         (ctrl59_funcsel == 1'd1) ? racer0_rgb[11] :
                         1'b0;
    assign pad_oe[59] = (ctrl59_funcsel == 1'd0) ? oe1_p59 :
                        (ctrl59_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[60] = (ctrl60_funcsel == 1'd0) ? out1_p60 :
                         (ctrl60_funcsel == 1'd1) ? racer0_hsync :
                         1'b0;
    assign pad_oe[60] = (ctrl60_funcsel == 1'd0) ? oe1_p60 :
                        (ctrl60_funcsel == 1'd1) ? 1'b1 :
                        1'b0;
    assign pad_out[61] = (ctrl61_funcsel == 1'd0) ? out1_p61 :
                         (ctrl61_funcsel == 1'd1) ? racer0_vsync :
                         1'b0;
    assign pad_oe[61] = (ctrl61_funcsel == 1'd0) ? oe1_p61 :
                        (ctrl61_funcsel == 1'd1) ? 1'b1 :
                        1'b0;

    // hw-proj: GENERATE END

endmodule
