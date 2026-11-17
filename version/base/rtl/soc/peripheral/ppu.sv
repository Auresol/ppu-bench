// hw-proj: GENERATE HEADER BEGIN
module ppu #(
    parameter SLOTS = 8
) (
    // Port list: hw-proj rewrites it on every run from the YAML (edit the spec, not this list)
    // AHB-Lite slave (no hsel — crossbar handles selection via htrans) bus interface
    input  wire clk,
    input  wire rst_n,
    input  wire [31:0] s_haddr,
    input  wire s_hwrite,
    input  wire [1:0] s_htrans,
    input  wire [2:0] s_hsize,
    input  wire [31:0] s_hwdata,
    output wire [31:0] s_hrdata,
    output wire s_hready,
    output wire s_hresp,

    // oam master interface
    output wire [31:0] a_haddr,
    output wire a_hwrite,
    output wire [1:0] a_htrans,
    output wire [2:0] a_hsize,
    output wire [31:0] a_hwdata,
    input  wire [31:0] a_hrdata,
    input  wire a_hready,
    input  wire a_hresp,

    // tex master interface
    output wire [31:0] b_haddr,
    output wire b_hwrite,
    output wire [1:0] b_htrans,
    output wire [2:0] b_hsize,
    output wire [31:0] b_hwdata,
    input  wire [31:0] b_hrdata,
    input  wire b_hready,
    input  wire b_hresp,

    // Module ports
    input  wire [9:0] x,
    input  wire [8:0] y,
    input  wire active,
    input  wire vblank,
    input  wire frame_start,
    input  wire pix_stb,
    output wire [11:0] pixel,
    output wire engine_on
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
    wire wen_ctrl;   // write enable of CTRL
    wire wen_giant;  // write enable of GIANT

    // Register field wires: read them in your logic, drive the ones marked
    wire         ctrl_start;    // CTRL.START [0:0] wf, strobe wen_ctrl
    wire         status_done;   // STATUS.DONE [0:0] ro, drive it in your logic
    wire         status_busy;   // STATUS.BUSY [1:1] ro, drive it in your logic
    wire [31:0]  late_count;    // LATE.COUNT [31:0] ro, drive it in your logic
    wire [9:0]   giant_w;       // GIANT.W [9:0] rw
    wire [9:0]   giant_h;       // GIANT.H [19:10] rw
    wire         giant_scale2;  // GIANT.SCALE2 [20:20] rw
    wire [127:0] hit_bits;      // HIT%s.BITS [31:0] ro (dim=4 array), drive it in your logic

    // Field flops
    reg  [9:0] reg_giant_w;
    reg  [9:0] reg_giant_h;
    reg        reg_giant_scale2;

    // Address phase captured for the data phase
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_sel_r   <= 1'b0;
            bus_write_r <= 1'b0;
            bus_addr_r  <= 12'h0;
        end else begin
            bus_sel_r <= s_htrans[1];
            if (s_htrans[1]) begin
                bus_write_r <= s_hwrite;
                bus_addr_r  <= s_haddr[11:0];
            end
        end
    end

    // Data-phase strobes, address and write data; the answer on the bus
    assign bus_wr    = bus_sel_r &  bus_write_r;
    assign bus_rd    = bus_sel_r & ~bus_write_r;
    assign bus_addr  = bus_addr_r;
    assign bus_wdata = s_hwdata;
    assign s_hrdata = bus_rdata;
    assign s_hready = 1'b1;   // no wait states
    assign s_hresp  = 1'b0;   // never an error

    // Which register is being written or read
    // write enable per register
    assign wen_ctrl = bus_wr && (bus_addr == 12'h000);
    assign wen_giant = bus_wr && (bus_addr == 12'h00C);

    // Field flops: reset, hardware, bus writes
    // rw, rwh and wo fields: reset, hardware load, writes from the bus, alias effects
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_giant_w <= 10'h000;
            reg_giant_h <= 10'h000;
            reg_giant_scale2 <= 1'b0;
        end else begin
            if (wen_giant) reg_giant_w <= bus_wdata[9:0];
            if (wen_giant) reg_giant_h <= bus_wdata[19:10];
            if (wen_giant) reg_giant_scale2 <= bus_wdata[20:20];
        end
    end

    // Fields connected to their flops, the write data and the module ports
    assign giant_w = reg_giant_w;
    assign giant_h = reg_giant_h;
    assign giant_scale2 = reg_giant_scale2;

    assign ctrl_start = bus_wdata[0:0];

    // Read mux: bus_rdata by register address
    always_comb begin
        bus_rdata = 32'h0;
        if (bus_rd) begin
            case (bus_addr)
                12'h000: begin
                    // no readable fields
                end
                12'h004: begin
                    bus_rdata[0:0] = status_done;
                    bus_rdata[1:1] = status_busy;
                end
                12'h008: begin
                    bus_rdata[31:0] = late_count;
                end
                12'h00C: begin
                    bus_rdata[9:0] = giant_w;
                    bus_rdata[19:10] = giant_h;
                    bus_rdata[20:20] = giant_scale2;
                end
                12'h010: begin
                    bus_rdata[31:0] = hit_bits[31:0];
                end
                12'h014: begin
                    bus_rdata[31:0] = hit_bits[63:32];
                end
                12'h018: begin
                    bus_rdata[31:0] = hit_bits[95:64];
                end
                12'h01C: begin
                    bus_rdata[31:0] = hit_bits[127:96];
                end
                default: ;
            endcase
        end
    end

    // Bus signals nothing in this zone reads, read here on purpose
    wire _unused = &{1'b0, s_haddr[31:12], s_htrans[0], s_hsize, bus_wdata[31:21]};

    // hw-proj: GENERATE END

// ============================================================================================================================
// The render unit (spec/sprite-spec.md). Races the beam: no line buffer, no frame buffer. It streams into racer0
// (doc/racer.yaml), which names the pixel it needs LEAD = 3 pixels ahead of the beam (doc/vga.yaml).
//
//   line controller (bus main)   while line L-1 is on show: scan the 128 OAM entries for line L and write each visible sprite
//                                into a linked list per bin (40 bins of 16 pixels, by left edge) in lst0, two halves (L even /
//                                odd); then walk the bins left to right and load each sprite into a free slot ("admission").
//   slots (SLOTS of them)        one sprite each: its row on its line, two texture words, a prefetch pointer. A slot frees
//                                itself once the beam has passed its right edge, so the limit is sprites on one pixel, not on
//                                one line.
//   texture fetch (bus tex)      the palette once at START (into pal_mem), then the slots' words, ahead of the beam.
//   pixel pipeline (3 stages)    S0 texel of every slot, S1 priority and hitboxes, S2 palette -> pixel. A pixel whose sprite
//                                is not admitted yet, or whose texture word is not here yet, is late: black, and counted.
//
// Frame (spec section 8, as built): START loads the palette, waits for the next vertical blanking (prepares line 0 in it)
// and renders the frame that follows; DONE is set a few pixels after that frame's last line.
// ============================================================================================================================

localparam int A  = SLOTS;
localparam int AW = (SLOTS > 1) ? $clog2(SLOTS) : 1;

localparam [31:0] OAM_BASE = 32'h2000_0000;   // oam0 in system.yaml
localparam [31:0] LST_BASE = 32'h2001_0000;   // lst0: half h at +512*h, entry n at +4*n
localparam [1:0]  HT_IDLE = 2'b00, HT_NONSEQ = 2'b10;
localparam [2:0]  HSIZE_WORD = 3'b010;
localparam int    NBINS = 40;                  // 640 / 16

// ---------------------------------------------------------------------------------------------------------------------------
// Raster: (cx, cy) is the lead side, the pixel racer0 names (x, y while active). Synced at frame_start and at the start of
// the vertical blanking, stepped at every pix_stb like racer0's own counter.
// ---------------------------------------------------------------------------------------------------------------------------
logic [9:0] cx, cy;
logic       vblank_d;
wire        vb_rise = vblank && !vblank_d;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cx <= '0; cy <= '0; vblank_d <= 1'b0;
    end else begin
        vblank_d <= vblank;
        if (frame_start) begin
            cx <= '0; cy <= '0;
        end else if (vb_rise) begin
            cx <= '0; cy <= 10'd480;
        end else if (pix_stb) begin
            if (cx == 10'd799) begin
                cx <= '0;
                cy <= (cy == 10'd524) ? 10'd0 : cy + 10'd1;
            end else begin
                cx <= cx + 10'd1;
            end
        end
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Engine: one frame per reset
// ---------------------------------------------------------------------------------------------------------------------------
typedef enum logic [2:0] {E_IDLE, E_PAL, E_WAITVB, E_PREP, E_RUN, E_FIN, E_DONE} est_t;
est_t              est;
logic signed [10:0] fl;          // frame line on show (lead side): -1 in the blanking before the frame, 0..479 in it
logic [2:0]        fin_cnt;
logic [7:0]        pal_w;        // palette words loaded (128 = all 256 entries)
wire               pal_done = (pal_w == 8'd128);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        est <= E_IDLE; fl <= -11'sd1; fin_cnt <= '0;
    end else begin
        case (est)
            E_IDLE:   if (wen_ctrl && ctrl_start) est <= E_PAL;
            E_PAL:    if (pal_done) est <= E_WAITVB;
            E_WAITVB: if (vb_rise) begin est <= E_PREP; fl <= -11'sd1; end
            E_PREP:   if (frame_start) begin est <= E_RUN; fl <= 11'sd0; end
            E_RUN: begin
                if (pix_stb && cx == 10'd799) fl <= fl + 11'sd1;
                if (vb_rise) begin est <= E_FIN; fin_cnt <= '0; end
            end
            E_FIN:    if (pix_stb) begin
                          fin_cnt <= fin_cnt + 3'd1;
                          if (fin_cnt == 3'd4) est <= E_DONE;   // the pipeline has emptied: LATE and HIT are final
                      end
            default: ;
        endcase
    end
end

assign engine_on   = (est != E_IDLE);
assign status_done = (est == E_DONE);
assign status_busy = (est != E_IDLE) && (est != E_DONE);

wire frame_px = (est == E_RUN) && (cy < 10'd480) && (cx < 10'd640);   // the pixel S0 works on is in the frame

// ---------------------------------------------------------------------------------------------------------------------------
// Bus main sequencer: one access at a time for the line controller (acc_go one cycle, acc_done one cycle with acc_rd)
// ---------------------------------------------------------------------------------------------------------------------------
logic        acc_go, acc_we, acc_done;
logic [31:0] acc_addr, acc_wd, acc_rd;
logic [1:0]  aph;            // 0 idle, 1 address phase, 2 data phase
logic [31:0] a_addr_r, a_wd_r;
logic        a_we_r;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aph <= '0; a_addr_r <= '0; a_wd_r <= '0; a_we_r <= 1'b0; acc_done <= 1'b0; acc_rd <= '0;
    end else begin
        acc_done <= 1'b0;
        case (aph)
            2'd0: if (acc_go) begin aph <= 2'd1; a_addr_r <= acc_addr; a_we_r <= acc_we; a_wd_r <= acc_wd; end
            2'd1: if (a_hready) aph <= 2'd2;
            2'd2: if (a_hready) begin aph <= 2'd0; acc_done <= 1'b1; acc_rd <= a_hrdata; end
            default: aph <= 2'd0;
        endcase
    end
end

assign a_htrans = (aph == 2'd1) ? HT_NONSEQ : HT_IDLE;
assign a_haddr  = a_addr_r;
assign a_hwrite = a_we_r;
assign a_hsize  = HSIZE_WORD;
assign a_hwdata = a_wd_r;

// ---------------------------------------------------------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------------------------------------------------------
logic                sv    [A];      // holds a sprite
logic [8:0]          sline [A];      // its line
logic [6:0]          sidx  [A];
logic [1:0]          sprio [A];
logic [3:0]          spal  [A];
logic                sb8   [A], shb [A], shf [A], ssh [A];   // 8bpp, hitbox, hflip, scale 2
logic signed [12:0]  sx    [A], sxe [A];                     // screen columns [sx, sxe)
logic [9:0]          sW    [A];                              // texture width
logic [17:0]         srow  [A];                              // word address of its row in tex0
logic [7:0]          snw   [A];                              // words in the row
logic signed [8:0]   skc   [A], skf [A];                     // word the beam is at, next word to fetch
logic [31:0]         sbuf  [A][2];                           // two words, by the word number's low bit
logic [7:0]          stag  [A][2];
logic                sbv   [A][2];
logic                spend [A];                              // a fetch is on bus tex

// ---- S0: every slot's texel at (cx, cy), combinational ----
logic                c_cov [A], c_opq [A], c_late [A];
logic [7:0]          c_c   [A];
logic signed [8:0]   c_k   [A];
logic                c_free[A];      // passed by the beam: may be reused

always_comb begin
    for (int s = 0; s < A; s++) begin
        logic signed [12:0] cxs, dx;
        logic [9:0]  u0, u;
        logic [7:0]  k;
        logic        e;
        logic [31:0] w;
        cxs = $signed({3'b000, cx});
        dx  = cxs - sx[s];
        u0  = ssh[s] ? dx[10:1] : dx[9:0];
        u   = shf[s] ? (sW[s] - 10'd1 - u0) : u0;
        k   = sb8[s] ? u[9:2] : {1'b0, u[9:3]};
        e   = k[0];
        w   = sbuf[s][e];
        c_k[s]   = $signed({1'b0, k});
        c_cov[s] = sv[s] && frame_px && (sline[s] == cy[8:0]) && (dx >= 0) && (cxs < sxe[s]);
        c_c[s]   = sb8[s] ? w[8*u[1:0] +: 8] : {4'h0, w[4*u[2:0] +: 4]};
        c_late[s] = c_cov[s] && !(sbv[s][e] && stag[s][e] == k);
        c_opq[s]  = c_cov[s] && !c_late[s] && (c_c[s] != 8'h0);
        // free once its line is over, or the beam is past its right edge (or the visible picture) on its line
        c_free[s] = sv[s] && !spend[s] && (est == E_RUN) &&
                    (($signed({2'b00, sline[s]}) < fl) ||
                     ($signed({2'b00, sline[s]}) == fl && (cxs >= sxe[s] || cx >= 10'd640)));
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Line controller: evaluation (OAM -> lists in lst0) and admission (lists -> slots)
// ---------------------------------------------------------------------------------------------------------------------------
typedef enum logic [3:0] {L_IDLE, L_EVSTART, L_EVRD, L_EVCHK, L_EVWR, L_ADBIN, L_ADRDL, L_ADRD0, L_ADRD1,
                          L_ADC1, L_ADC2, L_ADLOAD, L_DONE} lst_t;
lst_t              lc;
logic              lc_pend;          // the access of this state is on the bus
logic [8:0]        L;                // the line being prepared
logic [6:0]        ev_i, ev_n;       // OAM entry, list entries written
logic [5:0]        ev_bin;
logic              hv [2][NBINS];    // bin heads of the two halves
logic [6:0]        hp [2][NBINS];
logic [5:0]        ad_b;             // bin being admitted (the frontier)
logic [6:0]        ad_p, ad_idx, ad_nx;
logic              ad_nv, adm_active;
logic signed [10:0] adm_done_line;   // every sprite of this line and the ones before is in a slot
logic [31:0]       w0r, w1r;

// evaluation of w0r for line L
logic signed [12:0] e_x, e_y, e_dy, e_Wd, e_Hd;
logic [9:0]  e_W, e_H;
logic        e_sh, e_on;
always_comb begin
    e_x  = 13'(signed'(w0r[20:10]));
    e_y  = 13'(signed'(w0r[9:0]));
    e_sh = w0r[27] && giant_scale2;
    e_W  = w0r[27] ? giant_w : {3'b000, {1'b0, w0r[23:21]} + 4'd1, 3'b000};   // (code + 1) * 8, 8..64
    e_H  = w0r[27] ? giant_h : {3'b000, {1'b0, w0r[26:24]} + 4'd1, 3'b000};
    e_Wd = $signed({3'b000, e_W}) <<< e_sh;
    e_Hd = $signed({3'b000, e_H}) <<< e_sh;
    e_dy = $signed({4'b0000, L}) - e_y;
    e_on = w0r[28] && (e_dy >= 0) && (e_dy < e_Hd) && (e_x < 13'sd640) && (e_x + e_Wd > 13'sd0);
end

// admission: decoded sprite (C1), then its row and first word (C2)
logic signed [12:0] a_x, a_xe;
logic [9:0]  a_W, a_H, a_v0, a_v;
logic        a_sh, a_hf, a_vf, a_b8, a_hb;
logic [1:0]  a_prio;
logic [3:0]  a_pal;
logic [13:0] a_tex;
logic [17:0] a_row;
logic [7:0]  a_nw;
logic signed [8:0] a_k0;

// the first free slot
logic          have_free;
logic [AW-1:0] free_s;
always_comb begin
    have_free = 1'b0; free_s = '0;
    for (int s = A - 1; s >= 0; s--)
        if (!sv[s]) begin have_free = 1'b1; free_s = AW'(s); end
end
wire adm_load = (lc == L_ADLOAD) && have_free;

wire lc_gate = (est == E_PREP || est == E_RUN) && ($signed({2'b00, L}) <= fl + 11'sd1);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lc <= L_IDLE; lc_pend <= 1'b0; L <= '0; ev_i <= '0; ev_n <= '0; ev_bin <= '0;
        ad_b <= '0; ad_p <= '0; ad_idx <= '0; ad_nx <= '0; ad_nv <= 1'b0; adm_active <= 1'b0;
        adm_done_line <= -11'sd1; w0r <= '0; w1r <= '0;
        acc_go <= 1'b0; acc_we <= 1'b0; acc_addr <= '0; acc_wd <= '0;
        for (int h = 0; h < 2; h++) for (int b = 0; b < NBINS; b++) begin hv[h][b] <= 1'b0; hp[h][b] <= '0; end
        a_x <= '0; a_xe <= '0; a_W <= '0; a_H <= '0; a_v0 <= '0; a_v <= '0; a_sh <= 1'b0; a_hf <= 1'b0; a_vf <= 1'b0;
        a_b8 <= 1'b0; a_hb <= 1'b0; a_prio <= '0; a_pal <= '0; a_tex <= '0; a_row <= '0; a_nw <= '0; a_k0 <= '0;
    end else begin
        acc_go <= 1'b0;
        case (lc)
            L_IDLE: if (est == E_PREP) begin L <= '0; lc <= L_EVSTART; end

            // ---- evaluation of line L into half L[0] ----
            L_EVSTART: if (lc_gate) begin
                for (int b = 0; b < NBINS; b++) hv[L[0]][b] <= 1'b0;
                ev_i <= '0; ev_n <= '0; lc <= L_EVRD;
            end
            L_EVRD: if (!lc_pend) begin
                acc_go <= 1'b1; acc_we <= 1'b0; acc_addr <= OAM_BASE + {22'd0, ev_i, 3'b000}; lc_pend <= 1'b1;
            end else if (acc_done) begin
                lc_pend <= 1'b0; w0r <= acc_rd; lc <= L_EVCHK;
            end
            L_EVCHK: begin
                ev_bin <= (e_x < 0) ? 6'd0 : e_x[9:4];
                if (e_on) lc <= L_EVWR;
                else if (ev_i == 7'd127) begin ad_b <= '0; adm_active <= 1'b1; lc <= L_ADBIN; end
                else begin ev_i <= ev_i + 7'd1; lc <= L_EVRD; end
            end
            L_EVWR: if (!lc_pend) begin
                // push front: the entry links to the bin's old head
                acc_go <= 1'b1; acc_we <= 1'b1; lc_pend <= 1'b1;
                acc_addr <= LST_BASE + {22'd0, L[0], ev_n, 2'b00};
                acc_wd <= {17'd0, hv[L[0]][ev_bin], hp[L[0]][ev_bin], ev_i};
            end else if (acc_done) begin
                lc_pend <= 1'b0;
                hv[L[0]][ev_bin] <= 1'b1; hp[L[0]][ev_bin] <= ev_n; ev_n <= ev_n + 7'd1;
                if (ev_i == 7'd127) begin ad_b <= '0; adm_active <= 1'b1; lc <= L_ADBIN; end
                else begin ev_i <= ev_i + 7'd1; lc <= L_EVRD; end
            end

            // ---- admission of line L, bin by bin ----
            L_ADBIN: begin
                if (ad_b == 6'(NBINS)) begin
                    adm_active <= 1'b0; adm_done_line <= $signed({2'b00, L});
                    if (L == 9'd479) lc <= L_DONE;
                    else begin L <= L + 9'd1; lc <= L_EVSTART; end
                end else if (hv[L[0]][ad_b]) begin
                    ad_p <= hp[L[0]][ad_b]; lc <= L_ADRDL;
                end else begin
                    ad_b <= ad_b + 6'd1;
                end
            end
            L_ADRDL: if (!lc_pend) begin
                acc_go <= 1'b1; acc_we <= 1'b0; acc_addr <= LST_BASE + {22'd0, L[0], ad_p, 2'b00}; lc_pend <= 1'b1;
            end else if (acc_done) begin
                lc_pend <= 1'b0; ad_idx <= acc_rd[6:0]; ad_nx <= acc_rd[13:7]; ad_nv <= acc_rd[14]; lc <= L_ADRD0;
            end
            L_ADRD0: if (!lc_pend) begin
                acc_go <= 1'b1; acc_we <= 1'b0; acc_addr <= OAM_BASE + {22'd0, ad_idx, 3'b000}; lc_pend <= 1'b1;
            end else if (acc_done) begin
                lc_pend <= 1'b0; w0r <= acc_rd; lc <= L_ADRD1;
            end
            L_ADRD1: if (!lc_pend) begin
                acc_go <= 1'b1; acc_we <= 1'b0; acc_addr <= OAM_BASE + {22'd0, ad_idx, 3'b100}; lc_pend <= 1'b1;
            end else if (acc_done) begin
                lc_pend <= 1'b0; w1r <= acc_rd; lc <= L_ADC1;
            end
            L_ADC1: begin
                /* verilator lint_off UNUSEDSIGNAL */
                logic signed [12:0] dy;   // L - y: 0..H*s-1 here, the top bits are 0
                /* verilator lint_on UNUSEDSIGNAL */
                dy = $signed({4'b0000, L}) - e_y;
                a_x  <= e_x;          a_W  <= e_W;            a_H <= e_H;          a_sh <= e_sh;
                a_hf <= w0r[29];      a_vf <= w0r[30];        a_hb <= w0r[31];
                a_tex <= w1r[13:0];   a_pal <= w1r[17:14];    a_b8 <= w1r[18];     a_prio <= w1r[20:19];
                a_v0 <= e_sh ? dy[10:1] : dy[9:0];
                a_xe <= e_x + e_Wd;
                lc <= L_ADC2;
            end
            L_ADC2: begin
                /* verilator lint_off UNUSEDSIGNAL */
                logic [9:0]  v, u0, uf;           // uf[1:0]: below the word
                logic [19:0] vw;
                logic signed [12:0] cx0, du;      // du: 0..2*W, the top bits are 0
                /* verilator lint_on UNUSEDSIGNAL */
                v   = a_vf ? (a_H - 10'd1 - a_v0) : a_v0;
                vw  = v * a_W;
                cx0 = (a_x < 0) ? 13'sd0 : a_x;
                du  = cx0 - a_x;
                u0  = a_sh ? du[10:1] : du[9:0];
                uf  = a_hf ? (a_W - 10'd1 - u0) : u0;
                a_v   <= v;
                a_row <= {1'b0, a_tex, 3'b000} + (a_b8 ? 18'(vw >> 2) : 18'(vw >> 3));
                a_nw  <= a_b8 ? a_W[9:2] : {1'b0, a_W[9:3]};
                a_k0  <= a_b8 ? $signed({1'b0, uf[9:2]}) : $signed({2'b00, uf[9:3]});
                lc <= L_ADLOAD;
            end
            L_ADLOAD: if (have_free) begin    // the slot block loads it this cycle (adm_load)
                if (ad_nv) begin ad_p <= ad_nx; lc <= L_ADRDL; end
                else begin ad_b <= ad_b + 6'd1; lc <= L_ADBIN; end
            end
            default: ;   // L_DONE
        endcase
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Bus tex: the palette at START, then the slots' words (one access at a time, lowest slot first)
// ---------------------------------------------------------------------------------------------------------------------------
logic [11:0]   pal_mem [256];
logic [1:0]    bph;
logic          b_pal;            // the access in flight loads the palette
logic [AW-1:0] b_slot;
logic          b_e;
logic [7:0]    b_k;
logic [31:0]   b_addr_r;

logic          b_want [A];
logic          any_want;
logic [AW-1:0] want_s;
always_comb begin
    any_want = 1'b0; want_s = '0;
    for (int s = A - 1; s >= 0; s--) begin
        logic signed [8:0] ahead;
        ahead = shf[s] ? (skc[s] - skf[s]) : (skf[s] - skc[s]);
        b_want[s] = sv[s] && !spend[s] && !c_free[s] && (skf[s] >= 0) && (skf[s] < $signed({1'b0, snw[s]})) && (ahead <= 9'sd1);
        if (b_want[s]) begin any_want = 1'b1; want_s = AW'(s); end
    end
end

wire b_issue_pal  = (bph == 2'd0) && (est == E_PAL) && !pal_done;
wire b_issue_slot = (bph == 2'd0) && !b_issue_pal && (est == E_PREP || est == E_RUN) && any_want;
wire b_fill       = (bph == 2'd2) && b_hready && !b_pal;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bph <= '0; b_pal <= 1'b0; b_slot <= '0; b_e <= 1'b0; b_k <= '0; b_addr_r <= '0; pal_w <= '0;
    end else begin
        case (bph)
            2'd0: if (b_issue_pal) begin
                      bph <= 2'd1; b_pal <= 1'b1; b_addr_r <= {23'd0, pal_w[6:0], 2'b00};
                  end else if (b_issue_slot) begin
                      bph <= 2'd1; b_pal <= 1'b0; b_slot <= want_s;
                      b_k <= skf[want_s][7:0]; b_e <= skf[want_s][0];
                      b_addr_r <= {12'd0, srow[want_s] + 18'(skf[want_s][7:0]), 2'b00};
                  end
            2'd1: if (b_hready) bph <= 2'd2;
            2'd2: if (b_hready) begin
                      bph <= 2'd0;
                      if (b_pal) pal_w <= pal_w + 8'd1;
                  end
            default: bph <= 2'd0;
        endcase
    end
end

// the palette: two 16-bit entries per word, rgb444 in bits [11:0] of each
always_ff @(posedge clk)
    if (bph == 2'd2 && b_hready && b_pal) begin
        pal_mem[{pal_w[6:0], 1'b0}] <= b_hrdata[11:0];
        pal_mem[{pal_w[6:0], 1'b1}] <= b_hrdata[27:16];
    end

assign b_htrans = (bph == 2'd1) ? HT_NONSEQ : HT_IDLE;   // idle before START: texld0 owns bus tex until then
assign b_haddr  = b_addr_r;
assign b_hwrite = 1'b0;
assign b_hsize  = HSIZE_WORD;
assign b_hwdata = 32'h0;

// ---------------------------------------------------------------------------------------------------------------------------
// Slot state: load (admission), fetch issue and fill (bus tex), the beam (S0), free
// ---------------------------------------------------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int s = 0; s < A; s++) begin
            sv[s] <= 1'b0; sline[s] <= '0; sidx[s] <= '0; sprio[s] <= '0; spal[s] <= '0;
            sb8[s] <= 1'b0; shb[s] <= 1'b0; shf[s] <= 1'b0; ssh[s] <= 1'b0;
            sx[s] <= '0; sxe[s] <= '0; sW[s] <= '0; srow[s] <= '0; snw[s] <= '0; skc[s] <= '0; skf[s] <= '0;
            spend[s] <= 1'b0;
            for (int e = 0; e < 2; e++) begin sbuf[s][e] <= '0; stag[s][e] <= '0; sbv[s][e] <= 1'b0; end
        end
    end else begin
        for (int s = 0; s < A; s++) begin
            if (c_free[s]) sv[s] <= 1'b0;
            if (pix_stb && c_cov[s]) skc[s] <= c_k[s];
        end
        if (adm_load) begin
            sv[free_s] <= 1'b1;      sline[free_s] <= L;        sidx[free_s] <= ad_idx;
            sprio[free_s] <= a_prio; spal[free_s] <= a_pal;      sb8[free_s] <= a_b8;   shb[free_s] <= a_hb;
            shf[free_s] <= a_hf;     ssh[free_s] <= a_sh;        sx[free_s] <= a_x;     sxe[free_s] <= a_xe;
            sW[free_s] <= a_W;       srow[free_s] <= a_row;      snw[free_s] <= a_nw;
            skc[free_s] <= a_k0;     skf[free_s] <= a_k0;
            sbv[free_s][0] <= 1'b0;  sbv[free_s][1] <= 1'b0;
        end
        if (b_issue_slot) begin
            spend[want_s] <= 1'b1;
            sbv[want_s][skf[want_s][0]] <= 1'b0;
            skf[want_s] <= shf[want_s] ? skf[want_s] - 9'sd1 : skf[want_s] + 9'sd1;
        end
        if (b_fill) begin
            spend[b_slot] <= 1'b0;
            sbuf[b_slot][b_e] <= b_hrdata; stag[b_slot][b_e] <= b_k; sbv[b_slot][b_e] <= 1'b1;
        end
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Pixel pipeline, one step per pix_stb: S0 (slot texels, registered), S1 (priority, hitboxes), S2 (palette -> pixel)
// ---------------------------------------------------------------------------------------------------------------------------
// a pixel is safe from admission when every sprite that can cover it is in a slot: all of its line, or all bins up to its own
wire adm_safe = ($signed({1'b0, cy}) <= adm_done_line) || (adm_active && (L == cy[8:0]) && ({1'b0, ad_b} > {1'b0, cx[9:4]}));

logic        s0_v, s0_late;
logic        s0_opq [A], s0_hb [A];
logic [7:0]  s0_c   [A];
logic [6:0]  s0_idx [A];
logic [1:0]  s0_prio[A];
logic [3:0]  s0_pal [A];
logic        s0_b8  [A];

logic        s1_v, s1_late;
logic [7:0]  s1_pi;
logic [31:0] late_r;
logic [127:0] hit_r;
logic [11:0] pixel_r;

// S1, combinational: the opaque slot with the smallest (prio, index) wins; hitboxes when two or more opaque ones meet
logic        w_any;
logic [8:0]  w_key;
logic [7:0]  w_pi;
logic [7:0]  hb_count;
always_comb begin
    w_any = 1'b0; w_key = 9'h1FF; w_pi = 8'h00; hb_count = '0;
    for (int s = 0; s < A; s++) begin
        if (s0_opq[s] && (!w_any || {s0_prio[s], s0_idx[s]} < w_key)) begin   // not just < the start value: prio 3, index 127 is 9'h1FF
            w_any = 1'b1;
            w_key = {s0_prio[s], s0_idx[s]};
            w_pi  = s0_b8[s] ? s0_c[s] : {s0_pal[s], s0_c[s][3:0]};
        end
        if (s0_opq[s] && s0_hb[s]) hb_count = hb_count + 8'd1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s0_v <= 1'b0; s0_late <= 1'b0; s1_v <= 1'b0; s1_late <= 1'b0; s1_pi <= '0;
        late_r <= '0; hit_r <= '0; pixel_r <= '0;
        for (int s = 0; s < A; s++) begin
            s0_opq[s] <= 1'b0; s0_hb[s] <= 1'b0; s0_c[s] <= '0; s0_idx[s] <= '0; s0_prio[s] <= '0; s0_pal[s] <= '0; s0_b8[s] <= 1'b0;
        end
    end else if (pix_stb) begin
        // S0
        s0_v <= frame_px;
        s0_late <= 1'b0;
        for (int s = 0; s < A; s++) begin
            s0_opq[s] <= c_opq[s]; s0_hb[s] <= shb[s]; s0_c[s] <= c_c[s];
            s0_idx[s] <= sidx[s];  s0_prio[s] <= sprio[s]; s0_pal[s] <= spal[s]; s0_b8[s] <= sb8[s];
            if (c_late[s]) s0_late <= 1'b1;
        end
        if (frame_px && !adm_safe) s0_late <= 1'b1;
        // S1
        s1_v    <= s0_v;
        s1_late <= s0_late;
        s1_pi   <= w_any ? w_pi : 8'h00;      // nothing opaque: the backdrop, palette[0]
        if (s0_v && s0_late && late_r != 32'hFFFF_FFFF) late_r <= late_r + 32'd1;
        if (s0_v && hb_count >= 8'd2)
            for (int s = 0; s < A; s++)
                if (s0_opq[s] && s0_hb[s]) hit_r[s0_idx[s]] <= 1'b1;
        // S2: a late pixel is black (spec section 8)
        pixel_r <= (s1_v && !s1_late) ? pal_mem[s1_pi] : 12'h000;
    end
end

assign pixel      = pixel_r;
assign late_count = late_r;
assign hit_bits   = hit_r;

// racer0 names (x, y, active) too; this unit keeps its own count of the same raster (cx, cy)
wire _unused_renderer = &{1'b0, x, y, active, a_hresp, b_hresp, a_v, w1r[31:21]};

endmodule
