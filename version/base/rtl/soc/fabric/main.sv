// hw-proj: GENERATE HEADER BEGIN
module main (
    input  wire clk,
    input  wire rst_n,

    // master ppu0.oam (ppu)
    input  wire [31:0] m_ppu0_oam_haddr,
    input  wire m_ppu0_oam_hwrite,
    input  wire [1:0] m_ppu0_oam_htrans,
    input  wire [2:0] m_ppu0_oam_hsize,
    input  wire [31:0] m_ppu0_oam_hwdata,
    output wire [31:0] m_ppu0_oam_hrdata,
    output wire m_ppu0_oam_hready,
    output wire m_ppu0_oam_hresp,

    // master core0.data (hazard3_cpu_2port)
    input  wire [31:0] m_core0_data_haddr,
    input  wire m_core0_data_hwrite,
    input  wire [1:0] m_core0_data_htrans,
    input  wire [2:0] m_core0_data_hsize,
    input  wire [31:0] m_core0_data_hwdata,
    output wire [31:0] m_core0_data_hrdata,
    output wire m_core0_data_hready,
    output wire m_core0_data_hresp,

    // master core0.instruction (hazard3_cpu_2port)
    input  wire [31:0] m_core0_instruction_haddr,
    input  wire m_core0_instruction_hwrite,
    input  wire [1:0] m_core0_instruction_htrans,
    input  wire [2:0] m_core0_instruction_hsize,
    input  wire [31:0] m_core0_instruction_hwdata,
    output wire [31:0] m_core0_instruction_hrdata,
    output wire m_core0_instruction_hready,
    output wire m_core0_instruction_hresp,

    // slave sram0 (sram_bank) 0x0 + 0x10000
    output wire [31:0] s_sram0_haddr,
    output wire s_sram0_hwrite,
    output wire [1:0] s_sram0_htrans,
    output wire [2:0] s_sram0_hsize,
    output wire [31:0] s_sram0_hwdata,
    input  wire [31:0] s_sram0_hrdata,
    input  wire s_sram0_hready,
    input  wire s_sram0_hresp,

    // slave oam0 (buf_bank) 0x20000000 + 0x800
    output wire [31:0] s_oam0_haddr,
    output wire s_oam0_hwrite,
    output wire [1:0] s_oam0_htrans,
    output wire [2:0] s_oam0_hsize,
    output wire [31:0] s_oam0_hwdata,
    input  wire [31:0] s_oam0_hrdata,
    input  wire s_oam0_hready,
    input  wire s_oam0_hresp,

    // slave lst0 (buf_bank) 0x20010000 + 0x1000
    output wire [31:0] s_lst0_haddr,
    output wire s_lst0_hwrite,
    output wire [1:0] s_lst0_htrans,
    output wire [2:0] s_lst0_hsize,
    output wire [31:0] s_lst0_hwdata,
    input  wire [31:0] s_lst0_hrdata,
    input  wire s_lst0_hready,
    input  wire s_lst0_hresp,

    // slave ppu0 (ppu) 0x30000000 + 0x1000
    output wire [31:0] s_ppu0_haddr,
    output wire s_ppu0_hwrite,
    output wire [1:0] s_ppu0_htrans,
    output wire [2:0] s_ppu0_hsize,
    output wire [31:0] s_ppu0_hwdata,
    input  wire [31:0] s_ppu0_hrdata,
    input  wire s_ppu0_hready,
    input  wire s_ppu0_hresp,

    // slave texld0 (texld) 0x31000000 + 0x10000
    output wire [31:0] s_texld0_haddr,
    output wire s_texld0_hwrite,
    output wire [1:0] s_texld0_htrans,
    output wire [2:0] s_texld0_hsize,
    output wire [31:0] s_texld0_hwdata,
    input  wire [31:0] s_texld0_hrdata,
    input  wire s_texld0_hready,
    input  wire s_texld0_hresp,

    // slave gpio0 (gpio) 0x40000000 + 0x1000
    output wire [31:0] s_gpio0_haddr,
    output wire s_gpio0_hwrite,
    output wire [1:0] s_gpio0_htrans,
    output wire [2:0] s_gpio0_hsize,
    output wire [31:0] s_gpio0_hwdata,
    input  wire [31:0] s_gpio0_hrdata,
    input  wire s_gpio0_hready,
    input  wire s_gpio0_hresp
);
// hw-proj: GENERATE HEADER END

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    wire [5:0][31:0] dec_ppu0_oam_haddr;            // decoder of ppu0.oam: slave side, one entry per reachable slave
    wire [5:0]       dec_ppu0_oam_hwrite;
    wire [5:0][1:0]  dec_ppu0_oam_htrans;
    wire [5:0][2:0]  dec_ppu0_oam_hsize;
    wire [5:0][31:0] dec_ppu0_oam_hwdata;
    wire [5:0][31:0] dec_ppu0_oam_hrdata;
    wire [5:0]       dec_ppu0_oam_hready;
    wire [5:0]       dec_ppu0_oam_hresp;
    wire [5:0]       dec_ppu0_oam_gnt;
    wire [5:0][31:0] dec_core0_data_haddr;          // decoder of core0.data: slave side, one entry per reachable slave
    wire [5:0]       dec_core0_data_hwrite;
    wire [5:0][1:0]  dec_core0_data_htrans;
    wire [5:0][2:0]  dec_core0_data_hsize;
    wire [5:0][31:0] dec_core0_data_hwdata;
    wire [5:0][31:0] dec_core0_data_hrdata;
    wire [5:0]       dec_core0_data_hready;
    wire [5:0]       dec_core0_data_hresp;
    wire [5:0]       dec_core0_data_gnt;
    wire [5:0][31:0] dec_core0_instruction_haddr;   // decoder of core0.instruction: slave side, one entry per reachable slave
    wire [5:0]       dec_core0_instruction_hwrite;
    wire [5:0][1:0]  dec_core0_instruction_htrans;
    wire [5:0][2:0]  dec_core0_instruction_hsize;
    wire [5:0][31:0] dec_core0_instruction_hwdata;
    wire [5:0][31:0] dec_core0_instruction_hrdata;
    wire [5:0]       dec_core0_instruction_hready;
    wire [5:0]       dec_core0_instruction_hresp;
    wire [5:0]       dec_core0_instruction_gnt;
    wire [2:0][31:0] mux_sram0_haddr;               // mux of sram0: master side, one entry per master, priority order
    wire [2:0]       mux_sram0_hwrite;
    wire [2:0][1:0]  mux_sram0_htrans;
    wire [2:0][2:0]  mux_sram0_hsize;
    wire [2:0][31:0] mux_sram0_hwdata;
    wire [2:0][31:0] mux_sram0_hrdata;
    wire [2:0]       mux_sram0_hready;
    wire [2:0]       mux_sram0_hresp;
    wire [2:0]       mux_sram0_gnt;
    wire [2:0][31:0] mux_oam0_haddr;                // mux of oam0: master side, one entry per master, priority order
    wire [2:0]       mux_oam0_hwrite;
    wire [2:0][1:0]  mux_oam0_htrans;
    wire [2:0][2:0]  mux_oam0_hsize;
    wire [2:0][31:0] mux_oam0_hwdata;
    wire [2:0][31:0] mux_oam0_hrdata;
    wire [2:0]       mux_oam0_hready;
    wire [2:0]       mux_oam0_hresp;
    wire [2:0]       mux_oam0_gnt;
    wire [2:0][31:0] mux_lst0_haddr;                // mux of lst0: master side, one entry per master, priority order
    wire [2:0]       mux_lst0_hwrite;
    wire [2:0][1:0]  mux_lst0_htrans;
    wire [2:0][2:0]  mux_lst0_hsize;
    wire [2:0][31:0] mux_lst0_hwdata;
    wire [2:0][31:0] mux_lst0_hrdata;
    wire [2:0]       mux_lst0_hready;
    wire [2:0]       mux_lst0_hresp;
    wire [2:0]       mux_lst0_gnt;
    wire [2:0][31:0] mux_ppu0_haddr;                // mux of ppu0: master side, one entry per master, priority order
    wire [2:0]       mux_ppu0_hwrite;
    wire [2:0][1:0]  mux_ppu0_htrans;
    wire [2:0][2:0]  mux_ppu0_hsize;
    wire [2:0][31:0] mux_ppu0_hwdata;
    wire [2:0][31:0] mux_ppu0_hrdata;
    wire [2:0]       mux_ppu0_hready;
    wire [2:0]       mux_ppu0_hresp;
    wire [2:0]       mux_ppu0_gnt;
    wire [2:0][31:0] mux_texld0_haddr;              // mux of texld0: master side, one entry per master, priority order
    wire [2:0]       mux_texld0_hwrite;
    wire [2:0][1:0]  mux_texld0_htrans;
    wire [2:0][2:0]  mux_texld0_hsize;
    wire [2:0][31:0] mux_texld0_hwdata;
    wire [2:0][31:0] mux_texld0_hrdata;
    wire [2:0]       mux_texld0_hready;
    wire [2:0]       mux_texld0_hresp;
    wire [2:0]       mux_texld0_gnt;
    wire [2:0][31:0] mux_gpio0_haddr;               // mux of gpio0: master side, one entry per master, priority order
    wire [2:0]       mux_gpio0_hwrite;
    wire [2:0][1:0]  mux_gpio0_htrans;
    wire [2:0][2:0]  mux_gpio0_hsize;
    wire [2:0][31:0] mux_gpio0_hwdata;
    wire [2:0][31:0] mux_gpio0_hrdata;
    wire [2:0]       mux_gpio0_hready;
    wire [2:0]       mux_gpio0_hresp;
    wire [2:0]       mux_gpio0_gnt;

    // Module instances
    // Decoders: one per master port
    main_ppu0_oam_decoder u_dec_ppu0_oam (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(m_ppu0_oam_haddr),
        .m_hwrite(m_ppu0_oam_hwrite),
        .m_htrans(m_ppu0_oam_htrans),
        .m_hsize(m_ppu0_oam_hsize),
        .m_hwdata(m_ppu0_oam_hwdata),
        .m_hrdata(m_ppu0_oam_hrdata),
        .m_hready(m_ppu0_oam_hready),
        .m_hresp(m_ppu0_oam_hresp),
        .s_haddr(dec_ppu0_oam_haddr),
        .s_hwrite(dec_ppu0_oam_hwrite),
        .s_htrans(dec_ppu0_oam_htrans),
        .s_hsize(dec_ppu0_oam_hsize),
        .s_hwdata(dec_ppu0_oam_hwdata),
        .s_hrdata(dec_ppu0_oam_hrdata),
        .s_hready(dec_ppu0_oam_hready),
        .s_hresp(dec_ppu0_oam_hresp),
        .s_gnt(dec_ppu0_oam_gnt)
    );
    main_core0_data_decoder u_dec_core0_data (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(m_core0_data_haddr),
        .m_hwrite(m_core0_data_hwrite),
        .m_htrans(m_core0_data_htrans),
        .m_hsize(m_core0_data_hsize),
        .m_hwdata(m_core0_data_hwdata),
        .m_hrdata(m_core0_data_hrdata),
        .m_hready(m_core0_data_hready),
        .m_hresp(m_core0_data_hresp),
        .s_haddr(dec_core0_data_haddr),
        .s_hwrite(dec_core0_data_hwrite),
        .s_htrans(dec_core0_data_htrans),
        .s_hsize(dec_core0_data_hsize),
        .s_hwdata(dec_core0_data_hwdata),
        .s_hrdata(dec_core0_data_hrdata),
        .s_hready(dec_core0_data_hready),
        .s_hresp(dec_core0_data_hresp),
        .s_gnt(dec_core0_data_gnt)
    );
    main_core0_instruction_decoder u_dec_core0_instruction (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(m_core0_instruction_haddr),
        .m_hwrite(m_core0_instruction_hwrite),
        .m_htrans(m_core0_instruction_htrans),
        .m_hsize(m_core0_instruction_hsize),
        .m_hwdata(m_core0_instruction_hwdata),
        .m_hrdata(m_core0_instruction_hrdata),
        .m_hready(m_core0_instruction_hready),
        .m_hresp(m_core0_instruction_hresp),
        .s_haddr(dec_core0_instruction_haddr),
        .s_hwrite(dec_core0_instruction_hwrite),
        .s_htrans(dec_core0_instruction_htrans),
        .s_hsize(dec_core0_instruction_hsize),
        .s_hwdata(dec_core0_instruction_hwdata),
        .s_hrdata(dec_core0_instruction_hrdata),
        .s_hready(dec_core0_instruction_hready),
        .s_hresp(dec_core0_instruction_hresp),
        .s_gnt(dec_core0_instruction_gnt)
    );

    // Muxes: one per reachable slave
    main_sram0_mux u_mux_sram0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_sram0_haddr),
        .m_hwrite(mux_sram0_hwrite),
        .m_htrans(mux_sram0_htrans),
        .m_hsize(mux_sram0_hsize),
        .m_hwdata(mux_sram0_hwdata),
        .m_hrdata(mux_sram0_hrdata),
        .m_hready(mux_sram0_hready),
        .m_hresp(mux_sram0_hresp),
        .m_gnt(mux_sram0_gnt),
        .s_haddr(s_sram0_haddr),
        .s_hwrite(s_sram0_hwrite),
        .s_htrans(s_sram0_htrans),
        .s_hsize(s_sram0_hsize),
        .s_hwdata(s_sram0_hwdata),
        .s_hrdata(s_sram0_hrdata),
        .s_hready(s_sram0_hready),
        .s_hresp(s_sram0_hresp)
    );
    main_oam0_mux u_mux_oam0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_oam0_haddr),
        .m_hwrite(mux_oam0_hwrite),
        .m_htrans(mux_oam0_htrans),
        .m_hsize(mux_oam0_hsize),
        .m_hwdata(mux_oam0_hwdata),
        .m_hrdata(mux_oam0_hrdata),
        .m_hready(mux_oam0_hready),
        .m_hresp(mux_oam0_hresp),
        .m_gnt(mux_oam0_gnt),
        .s_haddr(s_oam0_haddr),
        .s_hwrite(s_oam0_hwrite),
        .s_htrans(s_oam0_htrans),
        .s_hsize(s_oam0_hsize),
        .s_hwdata(s_oam0_hwdata),
        .s_hrdata(s_oam0_hrdata),
        .s_hready(s_oam0_hready),
        .s_hresp(s_oam0_hresp)
    );
    main_lst0_mux u_mux_lst0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_lst0_haddr),
        .m_hwrite(mux_lst0_hwrite),
        .m_htrans(mux_lst0_htrans),
        .m_hsize(mux_lst0_hsize),
        .m_hwdata(mux_lst0_hwdata),
        .m_hrdata(mux_lst0_hrdata),
        .m_hready(mux_lst0_hready),
        .m_hresp(mux_lst0_hresp),
        .m_gnt(mux_lst0_gnt),
        .s_haddr(s_lst0_haddr),
        .s_hwrite(s_lst0_hwrite),
        .s_htrans(s_lst0_htrans),
        .s_hsize(s_lst0_hsize),
        .s_hwdata(s_lst0_hwdata),
        .s_hrdata(s_lst0_hrdata),
        .s_hready(s_lst0_hready),
        .s_hresp(s_lst0_hresp)
    );
    main_ppu0_mux u_mux_ppu0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_ppu0_haddr),
        .m_hwrite(mux_ppu0_hwrite),
        .m_htrans(mux_ppu0_htrans),
        .m_hsize(mux_ppu0_hsize),
        .m_hwdata(mux_ppu0_hwdata),
        .m_hrdata(mux_ppu0_hrdata),
        .m_hready(mux_ppu0_hready),
        .m_hresp(mux_ppu0_hresp),
        .m_gnt(mux_ppu0_gnt),
        .s_haddr(s_ppu0_haddr),
        .s_hwrite(s_ppu0_hwrite),
        .s_htrans(s_ppu0_htrans),
        .s_hsize(s_ppu0_hsize),
        .s_hwdata(s_ppu0_hwdata),
        .s_hrdata(s_ppu0_hrdata),
        .s_hready(s_ppu0_hready),
        .s_hresp(s_ppu0_hresp)
    );
    main_texld0_mux u_mux_texld0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_texld0_haddr),
        .m_hwrite(mux_texld0_hwrite),
        .m_htrans(mux_texld0_htrans),
        .m_hsize(mux_texld0_hsize),
        .m_hwdata(mux_texld0_hwdata),
        .m_hrdata(mux_texld0_hrdata),
        .m_hready(mux_texld0_hready),
        .m_hresp(mux_texld0_hresp),
        .m_gnt(mux_texld0_gnt),
        .s_haddr(s_texld0_haddr),
        .s_hwrite(s_texld0_hwrite),
        .s_htrans(s_texld0_htrans),
        .s_hsize(s_texld0_hsize),
        .s_hwdata(s_texld0_hwdata),
        .s_hrdata(s_texld0_hrdata),
        .s_hready(s_texld0_hready),
        .s_hresp(s_texld0_hresp)
    );
    main_gpio0_mux u_mux_gpio0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_gpio0_haddr),
        .m_hwrite(mux_gpio0_hwrite),
        .m_htrans(mux_gpio0_htrans),
        .m_hsize(mux_gpio0_hsize),
        .m_hwdata(mux_gpio0_hwdata),
        .m_hrdata(mux_gpio0_hrdata),
        .m_hready(mux_gpio0_hready),
        .m_hresp(mux_gpio0_hresp),
        .m_gnt(mux_gpio0_gnt),
        .s_haddr(s_gpio0_haddr),
        .s_hwrite(s_gpio0_hwrite),
        .s_htrans(s_gpio0_htrans),
        .s_hsize(s_gpio0_hsize),
        .s_hwdata(s_gpio0_hwdata),
        .s_hrdata(s_gpio0_hrdata),
        .s_hready(s_gpio0_hready),
        .s_hresp(s_gpio0_hresp)
    );

    // Links: decoder slave index to mux master index
    // ppu0.oam -> sram0   (decoder slave 0, mux master 0)
    assign mux_sram0_haddr[0]  = dec_ppu0_oam_haddr[0];
    assign mux_sram0_hwrite[0] = dec_ppu0_oam_hwrite[0];
    assign mux_sram0_htrans[0] = dec_ppu0_oam_htrans[0];
    assign mux_sram0_hsize[0]  = dec_ppu0_oam_hsize[0];
    assign mux_sram0_hwdata[0] = dec_ppu0_oam_hwdata[0];
    assign dec_ppu0_oam_hrdata[0] = mux_sram0_hrdata[0];
    assign dec_ppu0_oam_hready[0] = mux_sram0_hready[0];
    assign dec_ppu0_oam_hresp[0]  = mux_sram0_hresp[0];
    assign dec_ppu0_oam_gnt[0]    = mux_sram0_gnt[0];

    // ppu0.oam -> oam0   (decoder slave 1, mux master 0)
    assign mux_oam0_haddr[0]  = dec_ppu0_oam_haddr[1];
    assign mux_oam0_hwrite[0] = dec_ppu0_oam_hwrite[1];
    assign mux_oam0_htrans[0] = dec_ppu0_oam_htrans[1];
    assign mux_oam0_hsize[0]  = dec_ppu0_oam_hsize[1];
    assign mux_oam0_hwdata[0] = dec_ppu0_oam_hwdata[1];
    assign dec_ppu0_oam_hrdata[1] = mux_oam0_hrdata[0];
    assign dec_ppu0_oam_hready[1] = mux_oam0_hready[0];
    assign dec_ppu0_oam_hresp[1]  = mux_oam0_hresp[0];
    assign dec_ppu0_oam_gnt[1]    = mux_oam0_gnt[0];

    // ppu0.oam -> lst0   (decoder slave 2, mux master 0)
    assign mux_lst0_haddr[0]  = dec_ppu0_oam_haddr[2];
    assign mux_lst0_hwrite[0] = dec_ppu0_oam_hwrite[2];
    assign mux_lst0_htrans[0] = dec_ppu0_oam_htrans[2];
    assign mux_lst0_hsize[0]  = dec_ppu0_oam_hsize[2];
    assign mux_lst0_hwdata[0] = dec_ppu0_oam_hwdata[2];
    assign dec_ppu0_oam_hrdata[2] = mux_lst0_hrdata[0];
    assign dec_ppu0_oam_hready[2] = mux_lst0_hready[0];
    assign dec_ppu0_oam_hresp[2]  = mux_lst0_hresp[0];
    assign dec_ppu0_oam_gnt[2]    = mux_lst0_gnt[0];

    // ppu0.oam -> ppu0   (decoder slave 3, mux master 0)
    assign mux_ppu0_haddr[0]  = dec_ppu0_oam_haddr[3];
    assign mux_ppu0_hwrite[0] = dec_ppu0_oam_hwrite[3];
    assign mux_ppu0_htrans[0] = dec_ppu0_oam_htrans[3];
    assign mux_ppu0_hsize[0]  = dec_ppu0_oam_hsize[3];
    assign mux_ppu0_hwdata[0] = dec_ppu0_oam_hwdata[3];
    assign dec_ppu0_oam_hrdata[3] = mux_ppu0_hrdata[0];
    assign dec_ppu0_oam_hready[3] = mux_ppu0_hready[0];
    assign dec_ppu0_oam_hresp[3]  = mux_ppu0_hresp[0];
    assign dec_ppu0_oam_gnt[3]    = mux_ppu0_gnt[0];

    // ppu0.oam -> texld0   (decoder slave 4, mux master 0)
    assign mux_texld0_haddr[0]  = dec_ppu0_oam_haddr[4];
    assign mux_texld0_hwrite[0] = dec_ppu0_oam_hwrite[4];
    assign mux_texld0_htrans[0] = dec_ppu0_oam_htrans[4];
    assign mux_texld0_hsize[0]  = dec_ppu0_oam_hsize[4];
    assign mux_texld0_hwdata[0] = dec_ppu0_oam_hwdata[4];
    assign dec_ppu0_oam_hrdata[4] = mux_texld0_hrdata[0];
    assign dec_ppu0_oam_hready[4] = mux_texld0_hready[0];
    assign dec_ppu0_oam_hresp[4]  = mux_texld0_hresp[0];
    assign dec_ppu0_oam_gnt[4]    = mux_texld0_gnt[0];

    // ppu0.oam -> gpio0   (decoder slave 5, mux master 0)
    assign mux_gpio0_haddr[0]  = dec_ppu0_oam_haddr[5];
    assign mux_gpio0_hwrite[0] = dec_ppu0_oam_hwrite[5];
    assign mux_gpio0_htrans[0] = dec_ppu0_oam_htrans[5];
    assign mux_gpio0_hsize[0]  = dec_ppu0_oam_hsize[5];
    assign mux_gpio0_hwdata[0] = dec_ppu0_oam_hwdata[5];
    assign dec_ppu0_oam_hrdata[5] = mux_gpio0_hrdata[0];
    assign dec_ppu0_oam_hready[5] = mux_gpio0_hready[0];
    assign dec_ppu0_oam_hresp[5]  = mux_gpio0_hresp[0];
    assign dec_ppu0_oam_gnt[5]    = mux_gpio0_gnt[0];

    // core0.data -> sram0   (decoder slave 0, mux master 1)
    assign mux_sram0_haddr[1]  = dec_core0_data_haddr[0];
    assign mux_sram0_hwrite[1] = dec_core0_data_hwrite[0];
    assign mux_sram0_htrans[1] = dec_core0_data_htrans[0];
    assign mux_sram0_hsize[1]  = dec_core0_data_hsize[0];
    assign mux_sram0_hwdata[1] = dec_core0_data_hwdata[0];
    assign dec_core0_data_hrdata[0] = mux_sram0_hrdata[1];
    assign dec_core0_data_hready[0] = mux_sram0_hready[1];
    assign dec_core0_data_hresp[0]  = mux_sram0_hresp[1];
    assign dec_core0_data_gnt[0]    = mux_sram0_gnt[1];

    // core0.data -> oam0   (decoder slave 1, mux master 1)
    assign mux_oam0_haddr[1]  = dec_core0_data_haddr[1];
    assign mux_oam0_hwrite[1] = dec_core0_data_hwrite[1];
    assign mux_oam0_htrans[1] = dec_core0_data_htrans[1];
    assign mux_oam0_hsize[1]  = dec_core0_data_hsize[1];
    assign mux_oam0_hwdata[1] = dec_core0_data_hwdata[1];
    assign dec_core0_data_hrdata[1] = mux_oam0_hrdata[1];
    assign dec_core0_data_hready[1] = mux_oam0_hready[1];
    assign dec_core0_data_hresp[1]  = mux_oam0_hresp[1];
    assign dec_core0_data_gnt[1]    = mux_oam0_gnt[1];

    // core0.data -> lst0   (decoder slave 2, mux master 1)
    assign mux_lst0_haddr[1]  = dec_core0_data_haddr[2];
    assign mux_lst0_hwrite[1] = dec_core0_data_hwrite[2];
    assign mux_lst0_htrans[1] = dec_core0_data_htrans[2];
    assign mux_lst0_hsize[1]  = dec_core0_data_hsize[2];
    assign mux_lst0_hwdata[1] = dec_core0_data_hwdata[2];
    assign dec_core0_data_hrdata[2] = mux_lst0_hrdata[1];
    assign dec_core0_data_hready[2] = mux_lst0_hready[1];
    assign dec_core0_data_hresp[2]  = mux_lst0_hresp[1];
    assign dec_core0_data_gnt[2]    = mux_lst0_gnt[1];

    // core0.data -> ppu0   (decoder slave 3, mux master 1)
    assign mux_ppu0_haddr[1]  = dec_core0_data_haddr[3];
    assign mux_ppu0_hwrite[1] = dec_core0_data_hwrite[3];
    assign mux_ppu0_htrans[1] = dec_core0_data_htrans[3];
    assign mux_ppu0_hsize[1]  = dec_core0_data_hsize[3];
    assign mux_ppu0_hwdata[1] = dec_core0_data_hwdata[3];
    assign dec_core0_data_hrdata[3] = mux_ppu0_hrdata[1];
    assign dec_core0_data_hready[3] = mux_ppu0_hready[1];
    assign dec_core0_data_hresp[3]  = mux_ppu0_hresp[1];
    assign dec_core0_data_gnt[3]    = mux_ppu0_gnt[1];

    // core0.data -> texld0   (decoder slave 4, mux master 1)
    assign mux_texld0_haddr[1]  = dec_core0_data_haddr[4];
    assign mux_texld0_hwrite[1] = dec_core0_data_hwrite[4];
    assign mux_texld0_htrans[1] = dec_core0_data_htrans[4];
    assign mux_texld0_hsize[1]  = dec_core0_data_hsize[4];
    assign mux_texld0_hwdata[1] = dec_core0_data_hwdata[4];
    assign dec_core0_data_hrdata[4] = mux_texld0_hrdata[1];
    assign dec_core0_data_hready[4] = mux_texld0_hready[1];
    assign dec_core0_data_hresp[4]  = mux_texld0_hresp[1];
    assign dec_core0_data_gnt[4]    = mux_texld0_gnt[1];

    // core0.data -> gpio0   (decoder slave 5, mux master 1)
    assign mux_gpio0_haddr[1]  = dec_core0_data_haddr[5];
    assign mux_gpio0_hwrite[1] = dec_core0_data_hwrite[5];
    assign mux_gpio0_htrans[1] = dec_core0_data_htrans[5];
    assign mux_gpio0_hsize[1]  = dec_core0_data_hsize[5];
    assign mux_gpio0_hwdata[1] = dec_core0_data_hwdata[5];
    assign dec_core0_data_hrdata[5] = mux_gpio0_hrdata[1];
    assign dec_core0_data_hready[5] = mux_gpio0_hready[1];
    assign dec_core0_data_hresp[5]  = mux_gpio0_hresp[1];
    assign dec_core0_data_gnt[5]    = mux_gpio0_gnt[1];

    // core0.instruction -> sram0   (decoder slave 0, mux master 2)
    assign mux_sram0_haddr[2]  = dec_core0_instruction_haddr[0];
    assign mux_sram0_hwrite[2] = dec_core0_instruction_hwrite[0];
    assign mux_sram0_htrans[2] = dec_core0_instruction_htrans[0];
    assign mux_sram0_hsize[2]  = dec_core0_instruction_hsize[0];
    assign mux_sram0_hwdata[2] = dec_core0_instruction_hwdata[0];
    assign dec_core0_instruction_hrdata[0] = mux_sram0_hrdata[2];
    assign dec_core0_instruction_hready[0] = mux_sram0_hready[2];
    assign dec_core0_instruction_hresp[0]  = mux_sram0_hresp[2];
    assign dec_core0_instruction_gnt[0]    = mux_sram0_gnt[2];

    // core0.instruction -> oam0   (decoder slave 1, mux master 2)
    assign mux_oam0_haddr[2]  = dec_core0_instruction_haddr[1];
    assign mux_oam0_hwrite[2] = dec_core0_instruction_hwrite[1];
    assign mux_oam0_htrans[2] = dec_core0_instruction_htrans[1];
    assign mux_oam0_hsize[2]  = dec_core0_instruction_hsize[1];
    assign mux_oam0_hwdata[2] = dec_core0_instruction_hwdata[1];
    assign dec_core0_instruction_hrdata[1] = mux_oam0_hrdata[2];
    assign dec_core0_instruction_hready[1] = mux_oam0_hready[2];
    assign dec_core0_instruction_hresp[1]  = mux_oam0_hresp[2];
    assign dec_core0_instruction_gnt[1]    = mux_oam0_gnt[2];

    // core0.instruction -> lst0   (decoder slave 2, mux master 2)
    assign mux_lst0_haddr[2]  = dec_core0_instruction_haddr[2];
    assign mux_lst0_hwrite[2] = dec_core0_instruction_hwrite[2];
    assign mux_lst0_htrans[2] = dec_core0_instruction_htrans[2];
    assign mux_lst0_hsize[2]  = dec_core0_instruction_hsize[2];
    assign mux_lst0_hwdata[2] = dec_core0_instruction_hwdata[2];
    assign dec_core0_instruction_hrdata[2] = mux_lst0_hrdata[2];
    assign dec_core0_instruction_hready[2] = mux_lst0_hready[2];
    assign dec_core0_instruction_hresp[2]  = mux_lst0_hresp[2];
    assign dec_core0_instruction_gnt[2]    = mux_lst0_gnt[2];

    // core0.instruction -> ppu0   (decoder slave 3, mux master 2)
    assign mux_ppu0_haddr[2]  = dec_core0_instruction_haddr[3];
    assign mux_ppu0_hwrite[2] = dec_core0_instruction_hwrite[3];
    assign mux_ppu0_htrans[2] = dec_core0_instruction_htrans[3];
    assign mux_ppu0_hsize[2]  = dec_core0_instruction_hsize[3];
    assign mux_ppu0_hwdata[2] = dec_core0_instruction_hwdata[3];
    assign dec_core0_instruction_hrdata[3] = mux_ppu0_hrdata[2];
    assign dec_core0_instruction_hready[3] = mux_ppu0_hready[2];
    assign dec_core0_instruction_hresp[3]  = mux_ppu0_hresp[2];
    assign dec_core0_instruction_gnt[3]    = mux_ppu0_gnt[2];

    // core0.instruction -> texld0   (decoder slave 4, mux master 2)
    assign mux_texld0_haddr[2]  = dec_core0_instruction_haddr[4];
    assign mux_texld0_hwrite[2] = dec_core0_instruction_hwrite[4];
    assign mux_texld0_htrans[2] = dec_core0_instruction_htrans[4];
    assign mux_texld0_hsize[2]  = dec_core0_instruction_hsize[4];
    assign mux_texld0_hwdata[2] = dec_core0_instruction_hwdata[4];
    assign dec_core0_instruction_hrdata[4] = mux_texld0_hrdata[2];
    assign dec_core0_instruction_hready[4] = mux_texld0_hready[2];
    assign dec_core0_instruction_hresp[4]  = mux_texld0_hresp[2];
    assign dec_core0_instruction_gnt[4]    = mux_texld0_gnt[2];

    // core0.instruction -> gpio0   (decoder slave 5, mux master 2)
    assign mux_gpio0_haddr[2]  = dec_core0_instruction_haddr[5];
    assign mux_gpio0_hwrite[2] = dec_core0_instruction_hwrite[5];
    assign mux_gpio0_htrans[2] = dec_core0_instruction_htrans[5];
    assign mux_gpio0_hsize[2]  = dec_core0_instruction_hsize[5];
    assign mux_gpio0_hwdata[2] = dec_core0_instruction_hwdata[5];
    assign dec_core0_instruction_hrdata[5] = mux_gpio0_hrdata[2];
    assign dec_core0_instruction_hready[5] = mux_gpio0_hready[2];
    assign dec_core0_instruction_hresp[5]  = mux_gpio0_hresp[2];
    assign dec_core0_instruction_gnt[5]    = mux_gpio0_gnt[2];

    // hw-proj: GENERATE END

endmodule
