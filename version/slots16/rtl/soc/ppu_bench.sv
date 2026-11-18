// hw-proj: GENERATE HEADER BEGIN
module ppu_bench (
    // named pins of the clock and reset sources, from clocks: and reset: of system.yaml
    input  wire clk,
    input  wire porb,

    // pad bundle of the frame (adr/pins/pad-bundle-decoded-flag-vectors.md), from gpio: the frame adapter reads it
    output wire [61:0] pad_out,
    output wire [61:0] pad_oe,
    input  wire [61:0] pad_in
);
// hw-proj: GENERATE HEADER END

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    // Clock domains: outputs of rcc0
    wire clk_clk;  // clock of domain clk, the controller's own: its clk input takes it

    // Reset clock controller rcc0: resets
    wire rst_n_system;  // reset of group system, released in step with its clock

    // Bus: master ppu0.oam (ppu)
    wire [31:0] m_ppu0_oam_haddr;
    wire        m_ppu0_oam_hwrite;
    wire [1:0]  m_ppu0_oam_htrans;
    wire [2:0]  m_ppu0_oam_hsize;
    wire [31:0] m_ppu0_oam_hwdata;
    wire [31:0] m_ppu0_oam_hrdata;
    wire        m_ppu0_oam_hready;
    wire        m_ppu0_oam_hresp;

    // Bus: master core0.data (hazard3_cpu_2port)
    wire [31:0] m_core0_data_haddr;
    wire        m_core0_data_hwrite;
    wire [1:0]  m_core0_data_htrans;
    wire [2:0]  m_core0_data_hsize;
    wire [31:0] m_core0_data_hwdata;
    wire [31:0] m_core0_data_hrdata;
    wire        m_core0_data_hready;
    wire        m_core0_data_hresp;

    // Bus: master core0.instruction (hazard3_cpu_2port)
    wire [31:0] m_core0_instruction_haddr;
    wire        m_core0_instruction_hwrite;
    wire [1:0]  m_core0_instruction_htrans;
    wire [2:0]  m_core0_instruction_hsize;
    wire [31:0] m_core0_instruction_hwdata;
    wire [31:0] m_core0_instruction_hrdata;
    wire        m_core0_instruction_hready;
    wire        m_core0_instruction_hresp;

    // Bus: master ppu0.tex (ppu)
    wire [31:0] m_ppu0_tex_haddr;
    wire        m_ppu0_tex_hwrite;
    wire [1:0]  m_ppu0_tex_htrans;
    wire [2:0]  m_ppu0_tex_hsize;
    wire [31:0] m_ppu0_tex_hwdata;
    wire [31:0] m_ppu0_tex_hrdata;
    wire        m_ppu0_tex_hready;
    wire        m_ppu0_tex_hresp;

    // Bus: master texld0.tex (texld)
    wire [31:0] m_texld0_tex_haddr;
    wire        m_texld0_tex_hwrite;
    wire [1:0]  m_texld0_tex_htrans;
    wire [2:0]  m_texld0_tex_hsize;
    wire [31:0] m_texld0_tex_hwdata;
    wire [31:0] m_texld0_tex_hrdata;
    wire        m_texld0_tex_hready;
    wire        m_texld0_tex_hresp;

    // Bus: slave sram0 (sram_bank)
    wire [31:0] s_sram0_haddr;
    wire        s_sram0_hwrite;
    wire [1:0]  s_sram0_htrans;
    wire [2:0]  s_sram0_hsize;
    wire [31:0] s_sram0_hwdata;
    wire [31:0] s_sram0_hrdata;
    wire        s_sram0_hready;
    wire        s_sram0_hresp;

    // Bus: slave oam0 (buf_bank)
    wire [31:0] s_oam0_haddr;
    wire        s_oam0_hwrite;
    wire [1:0]  s_oam0_htrans;
    wire [2:0]  s_oam0_hsize;
    wire [31:0] s_oam0_hwdata;
    wire [31:0] s_oam0_hrdata;
    wire        s_oam0_hready;
    wire        s_oam0_hresp;

    // Bus: slave lst0 (buf_bank)
    wire [31:0] s_lst0_haddr;
    wire        s_lst0_hwrite;
    wire [1:0]  s_lst0_htrans;
    wire [2:0]  s_lst0_hsize;
    wire [31:0] s_lst0_hwdata;
    wire [31:0] s_lst0_hrdata;
    wire        s_lst0_hready;
    wire        s_lst0_hresp;

    // Bus: slave ppu0 (ppu)
    wire [31:0] s_ppu0_haddr;
    wire        s_ppu0_hwrite;
    wire [1:0]  s_ppu0_htrans;
    wire [2:0]  s_ppu0_hsize;
    wire [31:0] s_ppu0_hwdata;
    wire [31:0] s_ppu0_hrdata;
    wire        s_ppu0_hready;
    wire        s_ppu0_hresp;

    // Bus: slave texld0 (texld)
    wire [31:0] s_texld0_haddr;
    wire        s_texld0_hwrite;
    wire [1:0]  s_texld0_htrans;
    wire [2:0]  s_texld0_hsize;
    wire [31:0] s_texld0_hwdata;
    wire [31:0] s_texld0_hrdata;
    wire        s_texld0_hready;
    wire        s_texld0_hresp;

    // Bus: slave gpio0 (gpio)
    wire [31:0] s_gpio0_haddr;
    wire        s_gpio0_hwrite;
    wire [1:0]  s_gpio0_htrans;
    wire [2:0]  s_gpio0_hsize;
    wire [31:0] s_gpio0_hwdata;
    wire [31:0] s_gpio0_hrdata;
    wire        s_gpio0_hready;
    wire        s_gpio0_hresp;

    // Bus: slave tex0 (tex_bank)
    wire [31:0] s_tex0_haddr;
    wire        s_tex0_hwrite;
    wire [1:0]  s_tex0_htrans;
    wire [2:0]  s_tex0_hsize;
    wire [31:0] s_tex0_hwdata;
    wire [31:0] s_tex0_hrdata;
    wire        s_tex0_hready;
    wire        s_tex0_hresp;

    // Connections: vga_stream
    wire [9:0]  racer0_x;            // output of racer0: the connections read it
    wire [9:0]  ppu0_x;              // input of ppu0: the connections drive it
    wire [8:0]  racer0_y;            // output of racer0: the connections read it
    wire [8:0]  ppu0_y;              // input of ppu0: the connections drive it
    wire        racer0_active;       // output of racer0: the connections read it
    wire        ppu0_active;         // input of ppu0: the connections drive it
    wire        racer0_vblank;       // output of racer0: the connections read it
    wire        ppu0_vblank;         // input of ppu0: the connections drive it
    wire        racer0_frame_start;  // output of racer0: the connections read it
    wire        ppu0_frame_start;    // input of ppu0: the connections drive it
    wire        racer0_pix_stb;      // output of racer0: the connections read it
    wire        ppu0_pix_stb;        // input of ppu0: the connections drive it
    wire [11:0] ppu0_pixel;          // output of ppu0: the connections read it
    wire [11:0] racer0_pixel;        // input of racer0: the connections drive it
    wire        ppu0_engine_on;      // output of ppu0: the connections read it
    wire        racer0_use_ppu;      // input of racer0: the connections drive it

    // Connections: texture_lock
    wire texld0_lock;  // input of texld0: the connections drive it

    // gpio0 (gpio): functions
    wire        racer0_hsync;  // output of racer0: the function wiring of gpio reads it
    wire [13:0] gpio0_fn_out;  // input of gpio0: the function wiring of gpio drives it
    wire [13:0] gpio0_fn_oe;   // input of gpio0: the function wiring of gpio drives it
    wire        racer0_vsync;  // output of racer0: the function wiring of gpio reads it
    wire [11:0] racer0_rgb;    // output of racer0: the function wiring of gpio reads it

    // core0 (hazard3_cpu_2port): ports for you to wire
    wire        core0_pwrup_req;                   // output of core0: nothing in the zone uses it
    wire        core0_clk_en;                      // output of core0: nothing in the zone uses it
    wire        core0_unblock_out;                 // output of core0: nothing in the zone uses it
    wire [2:0]  core0_i_hburst;                    // output of core0: nothing in the zone uses it
    wire [3:0]  core0_i_hprot;                     // output of core0: nothing in the zone uses it
    wire        core0_i_hmastlock;                 // output of core0: nothing in the zone uses it
    wire [7:0]  core0_i_hmaster;                   // output of core0: nothing in the zone uses it
    wire [2:0]  core0_d_hburst;                    // output of core0: nothing in the zone uses it
    wire [3:0]  core0_d_hprot;                     // output of core0: nothing in the zone uses it
    wire        core0_d_hmastlock;                 // output of core0: nothing in the zone uses it
    wire [7:0]  core0_d_hmaster;                   // output of core0: nothing in the zone uses it
    wire        core0_d_hexcl;                     // output of core0: nothing in the zone uses it
    wire        core0_d_hexokay;                   // input of core0: you drive it
    wire        core0_fence_i_vld;                 // output of core0: nothing in the zone uses it
    wire        core0_fence_d_vld;                 // output of core0: nothing in the zone uses it
    wire        core0_dbg_halted;                  // output of core0: nothing in the zone uses it
    wire        core0_dbg_running;                 // output of core0: nothing in the zone uses it
    wire [31:0] core0_dbg_data0_wdata;             // output of core0: nothing in the zone uses it
    wire        core0_dbg_data0_wen;               // output of core0: nothing in the zone uses it
    wire        core0_dbg_instr_data_rdy;          // output of core0: nothing in the zone uses it
    wire        core0_dbg_instr_caught_exception;  // output of core0: nothing in the zone uses it
    wire        core0_dbg_instr_caught_ebreak;     // output of core0: nothing in the zone uses it
    wire        core0_dbg_sbus_rdy;                // output of core0: nothing in the zone uses it
    wire        core0_dbg_sbus_err;                // output of core0: nothing in the zone uses it
    wire [31:0] core0_dbg_sbus_rdata;              // output of core0: nothing in the zone uses it

    // core0 (hazard3_cpu_2port): inputs at their default
    wire        core0_clk_always_on;          // input of core0: its default drives it
    wire        core0_pwrup_ack;              // input of core0: its default drives it
    wire        core0_unblock_in;             // input of core0: its default drives it
    wire        core0_fence_rdy;              // input of core0: its default drives it
    wire        core0_dbg_req_halt;           // input of core0: its default drives it
    wire        core0_dbg_req_halt_on_reset;  // input of core0: its default drives it
    wire        core0_dbg_req_resume;         // input of core0: its default drives it
    wire [31:0] core0_dbg_data0_rdata;        // input of core0: its default drives it
    wire [31:0] core0_dbg_instr_data;         // input of core0: its default drives it
    wire        core0_dbg_instr_data_vld;     // input of core0: its default drives it
    wire [31:0] core0_dbg_sbus_addr;          // input of core0: its default drives it
    wire        core0_dbg_sbus_write;         // input of core0: its default drives it
    wire [1:0]  core0_dbg_sbus_size;          // input of core0: its default drives it
    wire        core0_dbg_sbus_vld;           // input of core0: its default drives it
    wire [31:0] core0_dbg_sbus_wdata;         // input of core0: its default drives it
    wire [31:0] core0_mhartid_val;            // input of core0: its default drives it
    wire [3:0]  core0_eco_version;            // input of core0: its default drives it
    wire        core0_irq;                    // input of core0: its default drives it
    wire        core0_soft_irq;               // input of core0: its default drives it
    wire        core0_timer_irq;              // input of core0: its default drives it

    // oam0 (buf_bank): ports for you to wire
    wire oam0_hexokay;  // output of oam0: nothing in the zone uses it

    // lst0 (buf_bank): ports for you to wire
    wire lst0_hexokay;  // output of lst0: nothing in the zone uses it

    // sram0 (sram_bank): ports for you to wire
    wire sram0_hexokay;  // output of sram0: nothing in the zone uses it

    // The connections of system.yaml, group by group
    // vga_stream
    assign ppu0_x = racer0_x;                      // racer0_x
    assign ppu0_y = racer0_y;                      // racer0_y
    assign ppu0_active = racer0_active;            // racer0_active
    assign ppu0_vblank = racer0_vblank;            // racer0_vblank
    assign ppu0_frame_start = racer0_frame_start;  // racer0_frame_start
    assign ppu0_pix_stb = racer0_pix_stb;          // racer0_pix_stb
    assign racer0_pixel = ppu0_pixel;              // ppu0_pixel
    assign racer0_use_ppu = ppu0_engine_on;        // ppu0_engine_on

    // texture_lock
    assign texld0_lock = ppu0_engine_on;  // ppu0_engine_on: textures are read-only once the render unit has started

    // gpio0 (gpio): functions
    assign gpio0_fn_out[0] = racer0_hsync;   // FN_RACER0_HSYNC
    assign gpio0_fn_oe[0] = 1'h0;            // FN_RACER0_HSYNC (fn_oe bit unused)
    assign gpio0_fn_out[1] = racer0_vsync;   // FN_RACER0_VSYNC
    assign gpio0_fn_oe[1] = 1'h0;            // FN_RACER0_VSYNC (fn_oe bit unused)
    assign gpio0_fn_out[13:2] = racer0_rgb;  // FN_RACER0_RGB
    assign gpio0_fn_oe[13:2] = 12'h0;        // FN_RACER0_RGB (fn_oe bit unused)

    // Port defaults: the inputs nothing else drives
    assign core0_clk_always_on = clk_clk;  // clock_in
    assign core0_pwrup_ack = 1'h1;  // default
    assign core0_unblock_in = 1'h0;  // default
    assign core0_fence_rdy = 1'h1;  // default
    assign core0_dbg_req_halt = 1'h0;  // default
    assign core0_dbg_req_halt_on_reset = 1'h0;  // default
    assign core0_dbg_req_resume = 1'h0;  // default
    assign core0_dbg_data0_rdata = 32'h0;  // default
    assign core0_dbg_instr_data = 32'h0;  // default
    assign core0_dbg_instr_data_vld = 1'h0;  // default
    assign core0_dbg_sbus_addr = 32'h0;  // default
    assign core0_dbg_sbus_write = 1'h0;  // default
    assign core0_dbg_sbus_size = 2'h0;  // default
    assign core0_dbg_sbus_vld = 1'h0;  // default
    assign core0_dbg_sbus_wdata = 32'h0;  // default
    assign core0_mhartid_val = 32'h0;  // hart_id
    assign core0_eco_version = 4'h0;  // default
    assign core0_irq = 1'h0;  // default
    assign core0_soft_irq = 1'h0;  // default
    assign core0_timer_irq = 1'h0;  // default

    // Module instances
    // Clock and reset
    reset_clock_controller rcc0 (
        .clk(clk_clk),
        .clk_pin(clk),
        .clk_clk(clk_clk),
        .por_n(porb),
        .rst_n_system(rst_n_system)
    );

    // Cores
    hazard3_cpu_2port #(.EXTENSION_A(0)) core0 (
        .clk(clk_clk),
        .clk_always_on(core0_clk_always_on),
        .rst_n(rst_n_system),
        .pwrup_req(core0_pwrup_req),
        .pwrup_ack(core0_pwrup_ack),
        .clk_en(core0_clk_en),
        .unblock_out(core0_unblock_out),
        .unblock_in(core0_unblock_in),
        .i_haddr(m_core0_instruction_haddr),
        .i_hwrite(m_core0_instruction_hwrite),
        .i_htrans(m_core0_instruction_htrans),
        .i_hsize(m_core0_instruction_hsize),
        .i_hburst(core0_i_hburst),
        .i_hprot(core0_i_hprot),
        .i_hmastlock(core0_i_hmastlock),
        .i_hmaster(core0_i_hmaster),
        .i_hready(m_core0_instruction_hready),
        .i_hresp(m_core0_instruction_hresp),
        .i_hwdata(m_core0_instruction_hwdata),
        .i_hrdata(m_core0_instruction_hrdata),
        .d_haddr(m_core0_data_haddr),
        .d_hwrite(m_core0_data_hwrite),
        .d_htrans(m_core0_data_htrans),
        .d_hsize(m_core0_data_hsize),
        .d_hburst(core0_d_hburst),
        .d_hprot(core0_d_hprot),
        .d_hmastlock(core0_d_hmastlock),
        .d_hmaster(core0_d_hmaster),
        .d_hexcl(core0_d_hexcl),
        .d_hready(m_core0_data_hready),
        .d_hresp(m_core0_data_hresp),
        .d_hexokay(core0_d_hexokay),
        .d_hwdata(m_core0_data_hwdata),
        .d_hrdata(m_core0_data_hrdata),
        .fence_i_vld(core0_fence_i_vld),
        .fence_d_vld(core0_fence_d_vld),
        .fence_rdy(core0_fence_rdy),
        .dbg_req_halt(core0_dbg_req_halt),
        .dbg_req_halt_on_reset(core0_dbg_req_halt_on_reset),
        .dbg_req_resume(core0_dbg_req_resume),
        .dbg_halted(core0_dbg_halted),
        .dbg_running(core0_dbg_running),
        .dbg_data0_rdata(core0_dbg_data0_rdata),
        .dbg_data0_wdata(core0_dbg_data0_wdata),
        .dbg_data0_wen(core0_dbg_data0_wen),
        .dbg_instr_data(core0_dbg_instr_data),
        .dbg_instr_data_vld(core0_dbg_instr_data_vld),
        .dbg_instr_data_rdy(core0_dbg_instr_data_rdy),
        .dbg_instr_caught_exception(core0_dbg_instr_caught_exception),
        .dbg_instr_caught_ebreak(core0_dbg_instr_caught_ebreak),
        .dbg_sbus_addr(core0_dbg_sbus_addr),
        .dbg_sbus_write(core0_dbg_sbus_write),
        .dbg_sbus_size(core0_dbg_sbus_size),
        .dbg_sbus_vld(core0_dbg_sbus_vld),
        .dbg_sbus_rdy(core0_dbg_sbus_rdy),
        .dbg_sbus_err(core0_dbg_sbus_err),
        .dbg_sbus_wdata(core0_dbg_sbus_wdata),
        .dbg_sbus_rdata(core0_dbg_sbus_rdata),
        .mhartid_val(core0_mhartid_val),
        .eco_version(core0_eco_version),
        .irq(core0_irq),
        .soft_irq(core0_soft_irq),
        .timer_irq(core0_timer_irq)
    );

    // Memory
    sram_bank #(
        .DEPTH(16384),
        .INIT_FILE(`ifdef FW_SRAM0 `FW_SRAM0 `else "" `endif)
    ) sram0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .haddr(s_sram0_haddr),
        .hwrite(s_sram0_hwrite),
        .htrans(s_sram0_htrans),
        .hsize(s_sram0_hsize),
        .hwdata(s_sram0_hwdata),
        .hrdata(s_sram0_hrdata),
        .hready(s_sram0_hready),
        .hresp(s_sram0_hresp),
        .hexokay(sram0_hexokay)
    );
    tex_bank #(
        .DEPTH(16384),
        .WIDTH(32)
    ) tex0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .haddr(s_tex0_haddr),
        .hwrite(s_tex0_hwrite),
        .htrans(s_tex0_htrans),
        .hsize(s_tex0_hsize),
        .hwdata(s_tex0_hwdata),
        .hrdata(s_tex0_hrdata),
        .hready(s_tex0_hready),
        .hresp(s_tex0_hresp)
    );

    // Peripherals
    buf_bank #(.DEPTH(256)) oam0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .haddr(s_oam0_haddr),
        .hwrite(s_oam0_hwrite),
        .htrans(s_oam0_htrans),
        .hsize(s_oam0_hsize),
        .hwdata(s_oam0_hwdata),
        .hrdata(s_oam0_hrdata),
        .hready(s_oam0_hready),
        .hresp(s_oam0_hresp),
        .hexokay(oam0_hexokay)
    );
    buf_bank #(.DEPTH(1024)) lst0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .haddr(s_lst0_haddr),
        .hwrite(s_lst0_hwrite),
        .htrans(s_lst0_htrans),
        .hsize(s_lst0_hsize),
        .hwdata(s_lst0_hwdata),
        .hrdata(s_lst0_hrdata),
        .hready(s_lst0_hready),
        .hresp(s_lst0_hresp),
        .hexokay(lst0_hexokay)
    );
    gpio gpio0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .haddr(s_gpio0_haddr),
        .hwrite(s_gpio0_hwrite),
        .htrans(s_gpio0_htrans),
        .hsize(s_gpio0_hsize),
        .hwdata(s_gpio0_hwdata),
        .hrdata(s_gpio0_hrdata),
        .hready(s_gpio0_hready),
        .hresp(s_gpio0_hresp),
        .pad_out(pad_out),
        .pad_oe(pad_oe),
        .pad_in(pad_in),
        .fn_out(gpio0_fn_out),
        .fn_oe(gpio0_fn_oe)
    );
    ppu #(.SLOTS(16)) ppu0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .s_haddr(s_ppu0_haddr),
        .s_hwrite(s_ppu0_hwrite),
        .s_htrans(s_ppu0_htrans),
        .s_hsize(s_ppu0_hsize),
        .s_hwdata(s_ppu0_hwdata),
        .s_hrdata(s_ppu0_hrdata),
        .s_hready(s_ppu0_hready),
        .s_hresp(s_ppu0_hresp),
        .a_haddr(m_ppu0_oam_haddr),
        .a_hwrite(m_ppu0_oam_hwrite),
        .a_htrans(m_ppu0_oam_htrans),
        .a_hsize(m_ppu0_oam_hsize),
        .a_hwdata(m_ppu0_oam_hwdata),
        .a_hrdata(m_ppu0_oam_hrdata),
        .a_hready(m_ppu0_oam_hready),
        .a_hresp(m_ppu0_oam_hresp),
        .b_haddr(m_ppu0_tex_haddr),
        .b_hwrite(m_ppu0_tex_hwrite),
        .b_htrans(m_ppu0_tex_htrans),
        .b_hsize(m_ppu0_tex_hsize),
        .b_hwdata(m_ppu0_tex_hwdata),
        .b_hrdata(m_ppu0_tex_hrdata),
        .b_hready(m_ppu0_tex_hready),
        .b_hresp(m_ppu0_tex_hresp),
        .x(ppu0_x),
        .y(ppu0_y),
        .active(ppu0_active),
        .vblank(ppu0_vblank),
        .frame_start(ppu0_frame_start),
        .pix_stb(ppu0_pix_stb),
        .pixel(ppu0_pixel),
        .engine_on(ppu0_engine_on)
    );
    texld #(.TEX_W(32)) texld0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .s_haddr(s_texld0_haddr),
        .s_hwrite(s_texld0_hwrite),
        .s_htrans(s_texld0_htrans),
        .s_hsize(s_texld0_hsize),
        .s_hwdata(s_texld0_hwdata),
        .s_hrdata(s_texld0_hrdata),
        .s_hready(s_texld0_hready),
        .s_hresp(s_texld0_hresp),
        .m_haddr(m_texld0_tex_haddr),
        .m_hwrite(m_texld0_tex_hwrite),
        .m_htrans(m_texld0_tex_htrans),
        .m_hsize(m_texld0_tex_hsize),
        .m_hwdata(m_texld0_tex_hwdata),
        .m_hrdata(m_texld0_tex_hrdata),
        .m_hready(m_texld0_tex_hready),
        .m_hresp(m_texld0_tex_hresp),
        .lock(texld0_lock)
    );
    racer racer0 (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .x(racer0_x),
        .y(racer0_y),
        .active(racer0_active),
        .vblank(racer0_vblank),
        .frame_start(racer0_frame_start),
        .pixel(racer0_pixel),
        .use_ppu(racer0_use_ppu),
        .hsync(racer0_hsync),
        .vsync(racer0_vsync),
        .rgb(racer0_rgb),
        .pix_stb(racer0_pix_stb)
    );

    // Fabric
    crossbar_central xbar (
        .clk(clk_clk),
        .rst_n(rst_n_system),
        .m_ppu0_oam_haddr(m_ppu0_oam_haddr),
        .m_ppu0_oam_hwrite(m_ppu0_oam_hwrite),
        .m_ppu0_oam_htrans(m_ppu0_oam_htrans),
        .m_ppu0_oam_hsize(m_ppu0_oam_hsize),
        .m_ppu0_oam_hwdata(m_ppu0_oam_hwdata),
        .m_ppu0_oam_hrdata(m_ppu0_oam_hrdata),
        .m_ppu0_oam_hready(m_ppu0_oam_hready),
        .m_ppu0_oam_hresp(m_ppu0_oam_hresp),
        .m_core0_data_haddr(m_core0_data_haddr),
        .m_core0_data_hwrite(m_core0_data_hwrite),
        .m_core0_data_htrans(m_core0_data_htrans),
        .m_core0_data_hsize(m_core0_data_hsize),
        .m_core0_data_hwdata(m_core0_data_hwdata),
        .m_core0_data_hrdata(m_core0_data_hrdata),
        .m_core0_data_hready(m_core0_data_hready),
        .m_core0_data_hresp(m_core0_data_hresp),
        .m_core0_instruction_haddr(m_core0_instruction_haddr),
        .m_core0_instruction_hwrite(m_core0_instruction_hwrite),
        .m_core0_instruction_htrans(m_core0_instruction_htrans),
        .m_core0_instruction_hsize(m_core0_instruction_hsize),
        .m_core0_instruction_hwdata(m_core0_instruction_hwdata),
        .m_core0_instruction_hrdata(m_core0_instruction_hrdata),
        .m_core0_instruction_hready(m_core0_instruction_hready),
        .m_core0_instruction_hresp(m_core0_instruction_hresp),
        .m_ppu0_tex_haddr(m_ppu0_tex_haddr),
        .m_ppu0_tex_hwrite(m_ppu0_tex_hwrite),
        .m_ppu0_tex_htrans(m_ppu0_tex_htrans),
        .m_ppu0_tex_hsize(m_ppu0_tex_hsize),
        .m_ppu0_tex_hwdata(m_ppu0_tex_hwdata),
        .m_ppu0_tex_hrdata(m_ppu0_tex_hrdata),
        .m_ppu0_tex_hready(m_ppu0_tex_hready),
        .m_ppu0_tex_hresp(m_ppu0_tex_hresp),
        .m_texld0_tex_haddr(m_texld0_tex_haddr),
        .m_texld0_tex_hwrite(m_texld0_tex_hwrite),
        .m_texld0_tex_htrans(m_texld0_tex_htrans),
        .m_texld0_tex_hsize(m_texld0_tex_hsize),
        .m_texld0_tex_hwdata(m_texld0_tex_hwdata),
        .m_texld0_tex_hrdata(m_texld0_tex_hrdata),
        .m_texld0_tex_hready(m_texld0_tex_hready),
        .m_texld0_tex_hresp(m_texld0_tex_hresp),
        .s_sram0_haddr(s_sram0_haddr),
        .s_sram0_hwrite(s_sram0_hwrite),
        .s_sram0_htrans(s_sram0_htrans),
        .s_sram0_hsize(s_sram0_hsize),
        .s_sram0_hwdata(s_sram0_hwdata),
        .s_sram0_hrdata(s_sram0_hrdata),
        .s_sram0_hready(s_sram0_hready),
        .s_sram0_hresp(s_sram0_hresp),
        .s_oam0_haddr(s_oam0_haddr),
        .s_oam0_hwrite(s_oam0_hwrite),
        .s_oam0_htrans(s_oam0_htrans),
        .s_oam0_hsize(s_oam0_hsize),
        .s_oam0_hwdata(s_oam0_hwdata),
        .s_oam0_hrdata(s_oam0_hrdata),
        .s_oam0_hready(s_oam0_hready),
        .s_oam0_hresp(s_oam0_hresp),
        .s_lst0_haddr(s_lst0_haddr),
        .s_lst0_hwrite(s_lst0_hwrite),
        .s_lst0_htrans(s_lst0_htrans),
        .s_lst0_hsize(s_lst0_hsize),
        .s_lst0_hwdata(s_lst0_hwdata),
        .s_lst0_hrdata(s_lst0_hrdata),
        .s_lst0_hready(s_lst0_hready),
        .s_lst0_hresp(s_lst0_hresp),
        .s_ppu0_haddr(s_ppu0_haddr),
        .s_ppu0_hwrite(s_ppu0_hwrite),
        .s_ppu0_htrans(s_ppu0_htrans),
        .s_ppu0_hsize(s_ppu0_hsize),
        .s_ppu0_hwdata(s_ppu0_hwdata),
        .s_ppu0_hrdata(s_ppu0_hrdata),
        .s_ppu0_hready(s_ppu0_hready),
        .s_ppu0_hresp(s_ppu0_hresp),
        .s_texld0_haddr(s_texld0_haddr),
        .s_texld0_hwrite(s_texld0_hwrite),
        .s_texld0_htrans(s_texld0_htrans),
        .s_texld0_hsize(s_texld0_hsize),
        .s_texld0_hwdata(s_texld0_hwdata),
        .s_texld0_hrdata(s_texld0_hrdata),
        .s_texld0_hready(s_texld0_hready),
        .s_texld0_hresp(s_texld0_hresp),
        .s_gpio0_haddr(s_gpio0_haddr),
        .s_gpio0_hwrite(s_gpio0_hwrite),
        .s_gpio0_htrans(s_gpio0_htrans),
        .s_gpio0_hsize(s_gpio0_hsize),
        .s_gpio0_hwdata(s_gpio0_hwdata),
        .s_gpio0_hrdata(s_gpio0_hrdata),
        .s_gpio0_hready(s_gpio0_hready),
        .s_gpio0_hresp(s_gpio0_hresp),
        .s_tex0_haddr(s_tex0_haddr),
        .s_tex0_hwrite(s_tex0_hwrite),
        .s_tex0_htrans(s_tex0_htrans),
        .s_tex0_hsize(s_tex0_hsize),
        .s_tex0_hwdata(s_tex0_hwdata),
        .s_tex0_hrdata(s_tex0_hrdata),
        .s_tex0_hready(s_tex0_hready),
        .s_tex0_hresp(s_tex0_hresp)
    );

    // hw-proj: GENERATE END

endmodule
