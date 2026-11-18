// hw-proj: GENERATE HEADER BEGIN
module tex (
    input  wire clk,
    input  wire rst_n,

    // master ppu0.tex (ppu)
    input  wire [31:0] m_ppu0_tex_haddr,
    input  wire m_ppu0_tex_hwrite,
    input  wire [1:0] m_ppu0_tex_htrans,
    input  wire [2:0] m_ppu0_tex_hsize,
    input  wire [31:0] m_ppu0_tex_hwdata,
    output wire [31:0] m_ppu0_tex_hrdata,
    output wire m_ppu0_tex_hready,
    output wire m_ppu0_tex_hresp,

    // master texld0.tex (texld)
    input  wire [31:0] m_texld0_tex_haddr,
    input  wire m_texld0_tex_hwrite,
    input  wire [1:0] m_texld0_tex_htrans,
    input  wire [2:0] m_texld0_tex_hsize,
    input  wire [31:0] m_texld0_tex_hwdata,
    output wire [31:0] m_texld0_tex_hrdata,
    output wire m_texld0_tex_hready,
    output wire m_texld0_tex_hresp,

    // slave tex0 (tex_bank) 0x0 + 0x10000
    output wire [31:0] s_tex0_haddr,
    output wire s_tex0_hwrite,
    output wire [1:0] s_tex0_htrans,
    output wire [2:0] s_tex0_hsize,
    output wire [31:0] s_tex0_hwdata,
    input  wire [31:0] s_tex0_hrdata,
    input  wire s_tex0_hready,
    input  wire s_tex0_hresp
);
// hw-proj: GENERATE HEADER END

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    wire [0:0][31:0] dec_ppu0_tex_haddr;     // decoder of ppu0.tex: slave side, one entry per reachable slave
    wire [0:0]       dec_ppu0_tex_hwrite;
    wire [0:0][1:0]  dec_ppu0_tex_htrans;
    wire [0:0][2:0]  dec_ppu0_tex_hsize;
    wire [0:0][31:0] dec_ppu0_tex_hwdata;
    wire [0:0][31:0] dec_ppu0_tex_hrdata;
    wire [0:0]       dec_ppu0_tex_hready;
    wire [0:0]       dec_ppu0_tex_hresp;
    wire [0:0]       dec_ppu0_tex_gnt;
    wire [0:0][31:0] dec_texld0_tex_haddr;   // decoder of texld0.tex: slave side, one entry per reachable slave
    wire [0:0]       dec_texld0_tex_hwrite;
    wire [0:0][1:0]  dec_texld0_tex_htrans;
    wire [0:0][2:0]  dec_texld0_tex_hsize;
    wire [0:0][31:0] dec_texld0_tex_hwdata;
    wire [0:0][31:0] dec_texld0_tex_hrdata;
    wire [0:0]       dec_texld0_tex_hready;
    wire [0:0]       dec_texld0_tex_hresp;
    wire [0:0]       dec_texld0_tex_gnt;
    wire [1:0][31:0] mux_tex0_haddr;         // mux of tex0: master side, one entry per master, priority order
    wire [1:0]       mux_tex0_hwrite;
    wire [1:0][1:0]  mux_tex0_htrans;
    wire [1:0][2:0]  mux_tex0_hsize;
    wire [1:0][31:0] mux_tex0_hwdata;
    wire [1:0][31:0] mux_tex0_hrdata;
    wire [1:0]       mux_tex0_hready;
    wire [1:0]       mux_tex0_hresp;
    wire [1:0]       mux_tex0_gnt;

    // Module instances
    // Decoders: one per master port
    tex_ppu0_tex_decoder u_dec_ppu0_tex (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(m_ppu0_tex_haddr),
        .m_hwrite(m_ppu0_tex_hwrite),
        .m_htrans(m_ppu0_tex_htrans),
        .m_hsize(m_ppu0_tex_hsize),
        .m_hwdata(m_ppu0_tex_hwdata),
        .m_hrdata(m_ppu0_tex_hrdata),
        .m_hready(m_ppu0_tex_hready),
        .m_hresp(m_ppu0_tex_hresp),
        .s_haddr(dec_ppu0_tex_haddr),
        .s_hwrite(dec_ppu0_tex_hwrite),
        .s_htrans(dec_ppu0_tex_htrans),
        .s_hsize(dec_ppu0_tex_hsize),
        .s_hwdata(dec_ppu0_tex_hwdata),
        .s_hrdata(dec_ppu0_tex_hrdata),
        .s_hready(dec_ppu0_tex_hready),
        .s_hresp(dec_ppu0_tex_hresp),
        .s_gnt(dec_ppu0_tex_gnt)
    );
    tex_texld0_tex_decoder u_dec_texld0_tex (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(m_texld0_tex_haddr),
        .m_hwrite(m_texld0_tex_hwrite),
        .m_htrans(m_texld0_tex_htrans),
        .m_hsize(m_texld0_tex_hsize),
        .m_hwdata(m_texld0_tex_hwdata),
        .m_hrdata(m_texld0_tex_hrdata),
        .m_hready(m_texld0_tex_hready),
        .m_hresp(m_texld0_tex_hresp),
        .s_haddr(dec_texld0_tex_haddr),
        .s_hwrite(dec_texld0_tex_hwrite),
        .s_htrans(dec_texld0_tex_htrans),
        .s_hsize(dec_texld0_tex_hsize),
        .s_hwdata(dec_texld0_tex_hwdata),
        .s_hrdata(dec_texld0_tex_hrdata),
        .s_hready(dec_texld0_tex_hready),
        .s_hresp(dec_texld0_tex_hresp),
        .s_gnt(dec_texld0_tex_gnt)
    );

    // Muxes: one per reachable slave
    tex_tex0_mux u_mux_tex0 (
        .clk(clk),
        .rst_n(rst_n),
        .m_haddr(mux_tex0_haddr),
        .m_hwrite(mux_tex0_hwrite),
        .m_htrans(mux_tex0_htrans),
        .m_hsize(mux_tex0_hsize),
        .m_hwdata(mux_tex0_hwdata),
        .m_hrdata(mux_tex0_hrdata),
        .m_hready(mux_tex0_hready),
        .m_hresp(mux_tex0_hresp),
        .m_gnt(mux_tex0_gnt),
        .s_haddr(s_tex0_haddr),
        .s_hwrite(s_tex0_hwrite),
        .s_htrans(s_tex0_htrans),
        .s_hsize(s_tex0_hsize),
        .s_hwdata(s_tex0_hwdata),
        .s_hrdata(s_tex0_hrdata),
        .s_hready(s_tex0_hready),
        .s_hresp(s_tex0_hresp)
    );

    // Links: decoder slave index to mux master index
    // ppu0.tex -> tex0   (decoder slave 0, mux master 0)
    assign mux_tex0_haddr[0]  = dec_ppu0_tex_haddr[0];
    assign mux_tex0_hwrite[0] = dec_ppu0_tex_hwrite[0];
    assign mux_tex0_htrans[0] = dec_ppu0_tex_htrans[0];
    assign mux_tex0_hsize[0]  = dec_ppu0_tex_hsize[0];
    assign mux_tex0_hwdata[0] = dec_ppu0_tex_hwdata[0];
    assign dec_ppu0_tex_hrdata[0] = mux_tex0_hrdata[0];
    assign dec_ppu0_tex_hready[0] = mux_tex0_hready[0];
    assign dec_ppu0_tex_hresp[0]  = mux_tex0_hresp[0];
    assign dec_ppu0_tex_gnt[0]    = mux_tex0_gnt[0];

    // texld0.tex -> tex0   (decoder slave 0, mux master 1)
    assign mux_tex0_haddr[1]  = dec_texld0_tex_haddr[0];
    assign mux_tex0_hwrite[1] = dec_texld0_tex_hwrite[0];
    assign mux_tex0_htrans[1] = dec_texld0_tex_htrans[0];
    assign mux_tex0_hsize[1]  = dec_texld0_tex_hsize[0];
    assign mux_tex0_hwdata[1] = dec_texld0_tex_hwdata[0];
    assign dec_texld0_tex_hrdata[0] = mux_tex0_hrdata[1];
    assign dec_texld0_tex_hready[0] = mux_tex0_hready[1];
    assign dec_texld0_tex_hresp[0]  = mux_tex0_hresp[1];
    assign dec_texld0_tex_gnt[0]    = mux_tex0_gnt[1];

    // hw-proj: GENERATE END

endmodule
