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
    wire         ctrl_start;           // CTRL.START [0:0] wf, strobe wen_ctrl
    wire         ctrl_cont;            // CTRL.CONT [1:1] rw
    wire         ctrl_oam_sel;         // CTRL.OAM_SEL [2:2] rw
    wire         status_done;          // STATUS.DONE [0:0] ro, drive it in your logic
    wire         status_busy;          // STATUS.BUSY [1:1] ro, drive it in your logic
    wire [31:0]  late_count;           // LATE.COUNT [31:0] ro, drive it in your logic
    wire [9:0]   giant_w;              // GIANT.W [9:0] rw
    wire [9:0]   giant_h;              // GIANT.H [19:10] rw
    wire         giant_scale2;         // GIANT.SCALE2 [20:20] rw
    wire [31:0]  frame_cyc_count;      // FRAME_CYC.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  tex_busy_count;       // TEX_BUSY.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  main_busy_count;      // MAIN_BUSY.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  slots_peak_count;     // SLOTS_PEAK.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  adm_wait_count;       // ADM_WAIT.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  adm_slack_pixels;     // ADM_SLACK.PIXELS [31:0] ro, drive it in your logic
    wire [31:0]  tex_want_peak_count;  // TEX_WANT_PEAK.COUNT [31:0] ro, drive it in your logic
    wire [31:0]  frame_count;          // FRAME.COUNT [31:0] ro, drive it in your logic
    wire [127:0] hit_bits;             // HIT%s.BITS [31:0] ro (dim=4 array), drive it in your logic

    // Field flops
    reg        reg_ctrl_cont;
    reg        reg_ctrl_oam_sel;
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
            reg_ctrl_cont <= 1'b0;
            reg_ctrl_oam_sel <= 1'b0;
            reg_giant_w <= 10'h000;
            reg_giant_h <= 10'h000;
            reg_giant_scale2 <= 1'b0;
        end else begin
            if (wen_ctrl) reg_ctrl_cont <= bus_wdata[1:1];
            if (wen_ctrl) reg_ctrl_oam_sel <= bus_wdata[2:2];
            if (wen_giant) reg_giant_w <= bus_wdata[9:0];
            if (wen_giant) reg_giant_h <= bus_wdata[19:10];
            if (wen_giant) reg_giant_scale2 <= bus_wdata[20:20];
        end
    end

    // Fields connected to their flops, the write data and the module ports
    assign ctrl_cont = reg_ctrl_cont;
    assign ctrl_oam_sel = reg_ctrl_oam_sel;
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
                    bus_rdata[1:1] = ctrl_cont;
                    bus_rdata[2:2] = ctrl_oam_sel;
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
                12'h040: begin
                    bus_rdata[31:0] = frame_cyc_count;
                end
                12'h044: begin
                    bus_rdata[31:0] = tex_busy_count;
                end
                12'h048: begin
                    bus_rdata[31:0] = main_busy_count;
                end
                12'h04C: begin
                    bus_rdata[31:0] = slots_peak_count;
                end
                12'h050: begin
                    bus_rdata[31:0] = adm_wait_count;
                end
                12'h054: begin
                    bus_rdata[31:0] = adm_slack_pixels;
                end
                12'h058: begin
                    bus_rdata[31:0] = tex_want_peak_count;
                end
                12'h05C: begin
                    bus_rdata[31:0] = frame_count;
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

// bus tex is TW bits wide: its data_width in system.yaml, which hw-proj writes into this module's port list (a version with
// another width gets this same body under its own port list). A slot's texture words are TW-bit words of tex0, numbered from
// byte 0 (word k = bytes k*TB .. k*TB+TB-1); a texel is a bit offset in them, so a row need not start on a word boundary.
localparam int    TW  = $bits(b_hrdata);
localparam int    TB  = TW / 8;                  // bytes a word
localparam int    LTW = $clog2(TW);              // bit offset -> word number: >> LTW
localparam int    KW  = 16;                      // word numbers (signed: a prefetch pointer may step to -1)
localparam [2:0]  HSIZE_TEX = 3'($clog2(TB));    // a whole bus tex word

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
logic              oam_bank;     // the OAM bank this frame reads: CTRL.OAM_SEL latched as the frame starts to be prepared
logic [31:0]       frames;       // frames finished (FRAME)
logic              first_done;   // the first frame is finished (STATUS.DONE)
logic              wrap_pend;    // a frame has ended: wait for the pipeline to empty, then latch HIT and count it
logic [2:0]        wrap_cnt;
// end of a frame's last line; in continuous mode (CTRL.CONT) the next frame is prepared from here on, in the same blanking
wire               frame_end  = (est == E_RUN) && vb_rise;
wire               frame_wrap = frame_end && ctrl_cont;
wire               hit_latch  = wrap_pend && pix_stb && (wrap_cnt == 3'd4);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        est <= E_IDLE; fl <= -11'sd1; fin_cnt <= '0;
        oam_bank <= 1'b0; frames <= '0; first_done <= 1'b0; wrap_pend <= 1'b0; wrap_cnt <= '0;
    end else begin
        if (frame_end) begin wrap_pend <= 1'b1; wrap_cnt <= '0; end
        else if (wrap_pend && pix_stb) begin
            wrap_cnt <= wrap_cnt + 3'd1;
            if (hit_latch) begin wrap_pend <= 1'b0; frames <= frames + 32'd1; first_done <= 1'b1; end
        end
        case (est)
            E_IDLE:   if (wen_ctrl && ctrl_start) est <= E_PAL;
            E_PAL:    if (pal_done) est <= E_WAITVB;
            E_WAITVB: if (vb_rise) begin est <= E_PREP; fl <= -11'sd1; oam_bank <= ctrl_oam_sel; end
            E_PREP:   if (frame_start) begin est <= E_RUN; fl <= 11'sd0; end
            E_RUN: begin
                if (pix_stb && cx == 10'd799) fl <= fl + 11'sd1;
                if (frame_wrap) begin est <= E_PREP; fl <= -11'sd1; oam_bank <= ctrl_oam_sel; end
                else if (vb_rise) begin est <= E_FIN; fin_cnt <= '0; end
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
assign status_done = first_done;   // the first frame is finished (in one-frame mode: the frame)
assign status_busy = (est != E_IDLE) && (est != E_DONE);
assign frame_count = frames;

wire frame_px = (est == E_RUN) && (cy < 10'd480) && (cx < 10'd640);   // the pixel S0 works on is in the frame

// ---------------------------------------------------------------------------------------------------------------------------
// Bus main: two requesters, evaluation (ev) and admission (ad), one access at a time, round robin. A requester holds its
// request (from its state) until its done pulse; the address phase goes out in the same cycle the request is seen, the data
// phase follows: two cycles an access on a zero-wait slave.
// ---------------------------------------------------------------------------------------------------------------------------
logic        ev_req, ev_we, ad_req;
logic [31:0] ev_addr, ev_wd, ad_addr;
logic        aph_data;       // a data phase is on the bus
logic        a_own;          // its owner: 0 evaluation, 1 admission
logic        a_rr;           // who goes first when both ask: 0 evaluation, 1 admission
logic [31:0] a_wd_r;

wire a_pick_ad = ad_req && (!ev_req || a_rr);
wire a_issue   = !aph_data && (ev_req || ad_req);
wire ev_done   = aph_data && a_hready && !a_own;
wire ad_done   = aph_data && a_hready &&  a_own;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aph_data <= 1'b0; a_own <= 1'b0; a_rr <= 1'b0; a_wd_r <= '0;
    end else if (!aph_data) begin
        if (a_issue && a_hready) begin       // the address phase is taken this cycle
            aph_data <= 1'b1;
            a_own    <= a_pick_ad;
            a_rr     <= !a_pick_ad;
            a_wd_r   <= ev_wd;
        end
    end else if (a_hready) begin
        aph_data <= 1'b0;
    end
end

assign a_htrans = a_issue ? HT_NONSEQ : HT_IDLE;
assign a_haddr  = a_pick_ad ? ad_addr : ev_addr;
assign a_hwrite = a_pick_ad ? 1'b0 : ev_we;
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
logic [17:0]         srb   [A];                              // byte address of its row in tex0
logic signed [KW-1:0] skfirst [A], sklast [A];               // the words its row spans
logic signed [KW-1:0] skc   [A], skf [A];                    // word the beam is at, next word to fetch
logic [TW-1:0]       sbuf  [A][2];                           // two words, by the word number's low bit
logic [KW-1:0]       stag  [A][2];
logic                sbv   [A][2];
logic                spend [A];                              // a fetch is on bus tex

// ---- S0: every slot's texel at (cx, cy), in two pixel-rate stages ----
// Every stage of the pixel pipeline steps once a pixel (at pix_stb), whatever the clock: its logic has the whole clock cycle and
// the VGA lead covers the depth (doc/vga.yaml, lead 6: P1, P2, L1, L2, L3, the palette).
//   P1  the position: the texel's word number and bit offset, whether the slot covers the pixel, and the slot's attributes
//       (carried on, so a slot reloaded after P1 never mixes into this pixel); the admission frontier, sampled at the same edge
//   P2  the texel: the word from the slot's buffer (a pixel later: a word that lands meanwhile only helps), its tag, the colour
logic                c_cov [A], c_opq [A], c_late [A];    // P2
logic [7:0]          c_c   [A];
logic signed [KW-1:0] c_k  [A];
logic                c_free[A];      // passed by the beam: may be reused (combinational)
logic                p1_cov [A], p1_hb [A], p1_b8 [A];
logic [KW-1:0]       p1_k   [A];
logic [LTW-1:0]      p1_boff[A];
logic [6:0]          p1_idx [A], c_idx [A];
logic [1:0]          p1_prio[A], c_prio[A];
logic [3:0]          p1_pal [A], c_pal [A];
logic                c_hb   [A], c_b8 [A];

always_ff @(posedge clk) begin
    if (pix_stb) begin
        for (int s = 0; s < A; s++) begin
            logic signed [12:0] cxs, dx;
            logic [9:0]  u0, u;
            logic [21:0] bit_at;      // the texel's bit address in tex0
            logic        e;
            logic [TW-1:0] w;
            logic [7:0]  c;
            logic        late;
            // P1
            cxs = $signed({3'b000, cx});
            dx  = cxs - sx[s];
            u0  = ssh[s] ? dx[10:1] : dx[9:0];
            u   = shf[s] ? (sW[s] - 10'd1 - u0) : u0;
            bit_at = {1'b0, srb[s], 3'b000} + (sb8[s] ? {9'd0, u, 3'b000} : {10'd0, u, 2'b00});
            p1_k[s]    <= KW'(bit_at >> LTW);
            p1_boff[s] <= bit_at[LTW-1:0];
            p1_cov[s]  <= sv[s] && frame_px && (sline[s] == cy[8:0]) && (dx >= 0) && (cxs < sxe[s]);
            p1_hb[s] <= shb[s]; p1_b8[s] <= sb8[s]; p1_idx[s] <= sidx[s]; p1_prio[s] <= sprio[s]; p1_pal[s] <= spal[s];
            // P2
            e    = p1_k[s][0];
            w    = sbuf[s][e];
            c    = p1_b8[s] ? w[p1_boff[s] +: 8] : {4'h0, w[p1_boff[s] +: 4]};
            late = p1_cov[s] && !(sbv[s][e] && stag[s][e] == p1_k[s]);
            c_k[s]    <= $signed(p1_k[s]);
            c_cov[s]  <= p1_cov[s];
            c_c[s]    <= c;
            c_late[s] <= late;
            c_opq[s]  <= p1_cov[s] && !late && (c != 8'h0);
            c_hb[s] <= p1_hb[s]; c_b8[s] <= p1_b8[s]; c_idx[s] <= p1_idx[s]; c_prio[s] <= p1_prio[s]; c_pal[s] <= p1_pal[s];
        end
    end
end

always_comb begin
    for (int s = 0; s < A; s++) begin
        logic signed [12:0] cxs;
        cxs = $signed({3'b000, cx});
        // free once its line is over, or the beam is 2 pixels past its right edge (P2 reads its buffer a pixel behind P1), or
        // past the visible picture, on its line
        c_free[s] = sv[s] && !spend[s] && (est == E_RUN) &&
                    (($signed({2'b00, sline[s]}) < fl) ||
                     ($signed({2'b00, sline[s]}) == fl && (cxs >= sxe[s] + 13'sd2 || cx >= 10'd642)));
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Line control, two state machines that run at once and share bus main:
//   evaluation  line E: read the 128 OAM entries, push every sprite visible on line E onto the list of its bin (40 bins of
//               16 pixels, by left edge) in half E[0] of lst0. Starts when line E-1 is on show (or before the frame for line 0)
//               and its half is free (admission of line E-2 done).
//   admission   line L: walk the bins of half L[0] left to right, load each sprite into a free slot. Starts when line L is
//               evaluated and line L-1 is admitted; waits for slots as the beam frees them.
// So evaluating line L+1 never waits for the last sprites of line L to find a slot.
// ---------------------------------------------------------------------------------------------------------------------------
logic              hv [2][NBINS];    // bin heads of the two halves: valid, entry number
logic [6:0]        hp [2][NBINS];

// ---- evaluation ----
typedef enum logic [2:0] {EV_IDLE, EV_WAIT, EV_RD, EV_CHK, EV_WR, EV_END} evst_t;
evst_t             evs;
logic [8:0]        E;                // the line being evaluated
logic [6:0]        ev_i, ev_n;       // OAM entry, list entries written
logic [5:0]        ev_bin;
logic [31:0]       ev_w0;
logic signed [10:0] ev_done_line;    // lines up to this one have their lists
logic signed [10:0] adm_done_line;   // every sprite of this line and the ones before is in a slot

logic signed [12:0] e_x, e_y, e_dy, e_Wd, e_Hd;
logic [9:0]  e_W, e_H;
logic        e_sh, e_on;
always_comb begin
    e_x  = 13'(signed'(ev_w0[20:10]));
    e_y  = 13'(signed'(ev_w0[9:0]));
    e_sh = ev_w0[27] && giant_scale2;
    e_W  = ev_w0[27] ? giant_w : {3'b000, {1'b0, ev_w0[23:21]} + 4'd1, 3'b000};   // (code + 1) * 8, 8..64
    e_H  = ev_w0[27] ? giant_h : {3'b000, {1'b0, ev_w0[26:24]} + 4'd1, 3'b000};
    e_Wd = $signed({3'b000, e_W}) <<< e_sh;
    e_Hd = $signed({3'b000, e_H}) <<< e_sh;
    e_dy = $signed({4'b0000, E}) - e_y;
    e_on = ev_w0[28] && (e_dy >= 0) && (e_dy < e_Hd) && (e_x < 13'sd640) && (e_x + e_Wd > 13'sd0);
end

wire ev_gate = (est == E_PREP || est == E_RUN) && ($signed({2'b00, E}) <= fl + 11'sd1)
               && ($signed({2'b00, E}) <= adm_done_line + 11'sd2);

assign ev_req  = (evs == EV_RD) || (evs == EV_WR);
assign ev_we   = (evs == EV_WR);
assign ev_addr = (evs == EV_WR) ? LST_BASE + {22'd0, E[0], ev_n, 2'b00} : OAM_BASE + {21'd0, oam_bank, ev_i, 3'b000};
assign ev_wd   = {17'd0, hv[E[0]][ev_bin], hp[E[0]][ev_bin], ev_i};   // push front: the entry links to the bin's old head

// ---- admission ----
typedef enum logic [3:0] {AD_IDLE, AD_WAIT, AD_BIN, AD_RDL, AD_RD0, AD_RD1, AD_C1, AD_C2, AD_C3, AD_LOAD, AD_END} adst_t;
adst_t             ads;
logic [8:0]        L;                // the line being admitted
logic [5:0]        ad_b;             // bin being admitted (the frontier)
logic [6:0]        ad_p, ad_idx, ad_nx;
logic              ad_nv;
logic [31:0]       ad_w0, ad_w1;
// active through AD_END: there ad_b is past the last bin (every pixel of line L is safe) while adm_done_line takes L only at
// its end; leaving AD_END out made one cycle where neither said so, and a pixel strobe in it was wrongly late
wire               adm_active = (ads != AD_IDLE) && (ads != AD_WAIT);

assign ad_req  = (ads == AD_RDL) || (ads == AD_RD0) || (ads == AD_RD1);
assign ad_addr = (ads == AD_RDL) ? LST_BASE + {22'd0, L[0], ad_p, 2'b00}
               : OAM_BASE + {21'd0, oam_bank, ad_idx, (ads == AD_RD1), 2'b00};

// decoded sprite (C1), then its row and first word (C2)
logic signed [12:0] a_x, a_xe;
logic [9:0]  a_W, a_H, a_v0, a_v;
logic        a_sh, a_hf, a_vf, a_b8, a_hb;
logic [1:0]  a_prio;
logic [3:0]  a_pal;
logic [13:0] a_tex;
logic [17:0] a_rb;                 // byte address of the row
logic [9:0]  a_uf;                 // the texel of the first pixel on screen
logic signed [KW-1:0] a_k0, a_kfirst, a_klast;

// the first free slot
logic          have_free;
logic [AW-1:0] free_s;
always_comb begin
    have_free = 1'b0; free_s = '0;
    for (int s = A - 1; s >= 0; s--)
        if (!sv[s]) begin have_free = 1'b1; free_s = AW'(s); end
end
wire adm_load = (ads == AD_LOAD) && have_free;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        evs <= EV_IDLE; E <= '0; ev_i <= '0; ev_n <= '0; ev_bin <= '0; ev_w0 <= '0; ev_done_line <= -11'sd1;
        for (int h = 0; h < 2; h++) for (int b = 0; b < NBINS; b++) begin hv[h][b] <= 1'b0; hp[h][b] <= '0; end
    end else begin
        case (evs)
            EV_IDLE: if (est == E_PREP) begin E <= '0; evs <= EV_WAIT; end
            EV_WAIT: if (ev_gate) begin
                for (int b = 0; b < NBINS; b++) hv[E[0]][b] <= 1'b0;
                ev_i <= '0; ev_n <= '0; evs <= EV_RD;
            end
            EV_RD:  if (ev_done) begin ev_w0 <= a_hrdata; evs <= EV_CHK; end
            EV_CHK: begin
                ev_bin <= (e_x < 0) ? 6'd0 : e_x[9:4];
                if (e_on) evs <= EV_WR;
                else if (ev_i == 7'd127) evs <= EV_END;
                else begin ev_i <= ev_i + 7'd1; evs <= EV_RD; end
            end
            EV_WR: if (ev_done) begin
                hv[E[0]][ev_bin] <= 1'b1; hp[E[0]][ev_bin] <= ev_n; ev_n <= ev_n + 7'd1;
                if (ev_i == 7'd127) evs <= EV_END;
                else begin ev_i <= ev_i + 7'd1; evs <= EV_RD; end
            end
            EV_END: begin
                ev_done_line <= $signed({2'b00, E});
                if (E == 9'd479) evs <= EV_IDLE;    // EV_IDLE leaves again only from E_PREP: the frame is over
                else begin E <= E + 9'd1; evs <= EV_WAIT; end
            end
            default: evs <= EV_IDLE;
        endcase
        if (est == E_FIN || frame_wrap) evs <= EV_IDLE;     // a new frame starts from line 0
        if (frame_wrap) ev_done_line <= -11'sd1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ads <= AD_IDLE; L <= '0; ad_b <= '0; ad_p <= '0; ad_idx <= '0; ad_nx <= '0; ad_nv <= 1'b0;
        adm_done_line <= -11'sd1; ad_w0 <= '0; ad_w1 <= '0;
        a_x <= '0; a_xe <= '0; a_W <= '0; a_H <= '0; a_v0 <= '0; a_v <= '0; a_sh <= 1'b0; a_hf <= 1'b0; a_vf <= 1'b0;
        a_b8 <= 1'b0; a_hb <= 1'b0; a_prio <= '0; a_pal <= '0; a_tex <= '0; a_rb <= '0; a_uf <= '0;
        a_k0 <= '0; a_kfirst <= '0; a_klast <= '0;
    end else begin
        case (ads)
            AD_IDLE: if (est == E_PREP) begin L <= '0; ads <= AD_WAIT; end
            AD_WAIT: if ($signed({2'b00, L}) <= ev_done_line) begin ad_b <= '0; ads <= AD_BIN; end
            AD_BIN: begin
                if (ad_b == 6'(NBINS)) ads <= AD_END;
                else if (hv[L[0]][ad_b]) begin ad_p <= hp[L[0]][ad_b]; ads <= AD_RDL; end
                else ad_b <= ad_b + 6'd1;
            end
            AD_RDL: if (ad_done) begin
                ad_idx <= a_hrdata[6:0]; ad_nx <= a_hrdata[13:7]; ad_nv <= a_hrdata[14]; ads <= AD_RD0;
            end
            AD_RD0: if (ad_done) begin ad_w0 <= a_hrdata; ads <= AD_RD1; end
            AD_RD1: if (ad_done) begin ad_w1 <= a_hrdata; ads <= AD_C1; end
            AD_C1: begin
                /* verilator lint_off UNUSEDSIGNAL */
                logic signed [12:0] px, py, dy, Wd;   // dy: 0..H*s-1, the top bits are 0
                /* verilator lint_on UNUSEDSIGNAL */
                logic [9:0] W, H;
                logic       sh;
                px = 13'(signed'(ad_w0[20:10]));
                py = 13'(signed'(ad_w0[9:0]));
                sh = ad_w0[27] && giant_scale2;
                W  = ad_w0[27] ? giant_w : {3'b000, {1'b0, ad_w0[23:21]} + 4'd1, 3'b000};
                H  = ad_w0[27] ? giant_h : {3'b000, {1'b0, ad_w0[26:24]} + 4'd1, 3'b000};
                Wd = $signed({3'b000, W}) <<< sh;
                dy = $signed({4'b0000, L}) - py;      // 0..H*s-1: the evaluation put it on this line
                a_x  <= px;            a_W  <= W;              a_H <= H;            a_sh <= sh;
                a_hf <= ad_w0[29];    a_vf <= ad_w0[30];      a_hb <= ad_w0[31];
                a_tex <= ad_w1[13:0]; a_pal <= ad_w1[17:14];  a_b8 <= ad_w1[18];   a_prio <= ad_w1[20:19];
                a_v0 <= sh ? dy[10:1] : dy[9:0];
                a_xe <= px + Wd;
                ads <= AD_C2;
            end
            AD_C2: begin
                /* verilator lint_off UNUSEDSIGNAL */
                logic [9:0]  v, u0, uf;
                logic [19:0] vw;
                logic signed [12:0] cx0, du;      // du: 0..2*W, the top bits are 0
                /* verilator lint_on UNUSEDSIGNAL */
                v   = a_vf ? (a_H - 10'd1 - a_v0) : a_v0;
                vw  = v * a_W;
                cx0 = (a_x < 0) ? 13'sd0 : a_x;
                du  = cx0 - a_x;
                u0  = a_sh ? du[10:1] : du[9:0];
                uf  = a_hf ? (a_W - 10'd1 - u0) : u0;
                a_v  <= v;
                a_rb <= {a_tex[12:0], 5'b00000} + (a_b8 ? 18'(vw) : 18'(vw >> 1));   // tex in 32-byte units, then v rows
                a_uf <= uf;
                ads <= AD_C3;
            end
            AD_C3: begin
                // in bits: the row starts at rb*8 and is W*bpp long; the first texel on screen is at rb*8 + uf*bpp
                logic [21:0] row_bit, first_bit, last_bit;
                row_bit   = {1'b0, a_rb, 3'b000};
                first_bit = row_bit + (a_b8 ? {9'd0, a_uf, 3'b000} : {10'd0, a_uf, 2'b00});
                last_bit  = row_bit + (a_b8 ? {9'd0, a_W, 3'b000} : {10'd0, a_W, 2'b00}) - 22'd1;
                a_k0     <= $signed(KW'(first_bit >> LTW));
                a_kfirst <= $signed(KW'(row_bit >> LTW));
                a_klast  <= $signed(KW'(last_bit >> LTW));
                ads <= AD_LOAD;
            end
            AD_LOAD: if (have_free) begin    // the slot block loads it this cycle (adm_load)
                if (ad_nv) begin ad_p <= ad_nx; ads <= AD_RDL; end
                else begin ad_b <= ad_b + 6'd1; ads <= AD_BIN; end
            end
            AD_END: begin
                adm_done_line <= $signed({2'b00, L});
                if (L == 9'd479) ads <= AD_IDLE;
                else begin L <= L + 9'd1; ads <= AD_WAIT; end
            end
            default: ads <= AD_IDLE;
        endcase
        if (est == E_FIN || frame_wrap) ads <= AD_IDLE;
        if (frame_wrap) adm_done_line <= -11'sd1;
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
logic [KW-1:0] b_k;
logic [31:0]   b_addr_r;
logic [2:0]    b_size_r;

// Which slot's word goes first: by urgency, then the lowest slot. A slot in index order alone let sprites loaded early (far
// right on the line, or for the next line) take the bus from sprites the beam is about to reach: with more slots there are
// more of those, so 24 slots did worse than 8 on the bandwidth ladder (the 50 MHz sweep).
//   0  on the line on show, the beam inside it or within 16 pixels: the word it needs now (it is about to stall)
//   1  the same: its next word (prefetch, one ahead at most)
//   2  on the line on show, not reached yet: its first words
//   3  for a later line (admitted early): its first words
logic          b_want [A];
logic [1:0]    b_lvl  [A];
logic          any_want;
logic [AW-1:0] want_s;
always_comb begin
    logic [3:0]    lvl_any;
    logic [AW-1:0] lvl_s [4];
    lvl_any = '0;
    for (int l = 0; l < 4; l++) lvl_s[l] = '0;
    for (int s = A - 1; s >= 0; s--) begin
        logic signed [KW-1:0] ahead;
        logic on_show, reached;
        ahead   = shf[s] ? (skc[s] - skf[s]) : (skf[s] - skc[s]);
        on_show = (est == E_RUN) && (cy < 10'd480) && (sline[s] == cy[8:0]);
        reached = ($signed({3'b000, cx}) + 13'sd16 >= sx[s]);
        b_want[s] = sv[s] && !spend[s] && !c_free[s] && (skf[s] >= skfirst[s]) && (skf[s] <= sklast[s]) && (ahead <= 1);
        b_lvl[s]  = !on_show ? 2'd3 : !reached ? 2'd2 : (ahead <= 0) ? 2'd0 : 2'd1;
        if (b_want[s]) begin lvl_any[b_lvl[s]] = 1'b1; lvl_s[b_lvl[s]] = AW'(s); end
    end
    any_want = |lvl_any;
    want_s   = lvl_any[0] ? lvl_s[0] : lvl_any[1] ? lvl_s[1] : lvl_any[2] ? lvl_s[2] : lvl_s[3];
end

wire b_issue_pal  = (bph == 2'd0) && (est == E_PAL) && !pal_done;
wire b_issue_slot = (bph == 2'd0) && !b_issue_pal && (est == E_PREP || est == E_RUN) && any_want;
wire b_fill       = (bph == 2'd2) && b_hready && !b_pal;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bph <= '0; b_pal <= 1'b0; b_slot <= '0; b_e <= 1'b0; b_k <= '0; b_addr_r <= '0; b_size_r <= HSIZE_WORD; pal_w <= '0;
    end else begin
        case (bph)
            2'd0: if (b_issue_pal) begin
                      // the palette in 32-bit reads whatever the bus width: 128 of them, two entries each
                      bph <= 2'd1; b_pal <= 1'b1; b_addr_r <= {23'd0, pal_w[6:0], 2'b00}; b_size_r <= HSIZE_WORD;
                  end else if (b_issue_slot) begin
                      bph <= 2'd1; b_pal <= 1'b0; b_slot <= want_s;
                      b_k <= skf[want_s]; b_e <= skf[want_s][0];
                      b_addr_r <= 32'(skf[want_s]) << $clog2(TB);   // a whole word
                      b_size_r <= HSIZE_TEX;
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
localparam int PLANES = TW / 32;                       // 32-bit lanes of a bus tex word
wire [31:0] pal_word = b_hrdata[32 * ((PLANES > 1) ? int'(pal_w) % PLANES : 0) +: 32];   // the lane the read addressed
always_ff @(posedge clk)
    if (bph == 2'd2 && b_hready && b_pal) begin
        pal_mem[{pal_w[6:0], 1'b0}] <= pal_word[11:0];
        pal_mem[{pal_w[6:0], 1'b1}] <= pal_word[27:16];
    end

assign b_htrans = (bph == 2'd1) ? HT_NONSEQ : HT_IDLE;   // idle before START: texld0 owns bus tex until then
assign b_haddr  = b_addr_r;
assign b_hwrite = 1'b0;
assign b_hsize  = b_size_r;
assign b_hwdata = '0;

// ---------------------------------------------------------------------------------------------------------------------------
// Slot state: load (admission), fetch issue and fill (bus tex), the beam (S0), free
// ---------------------------------------------------------------------------------------------------------------------------
// Only the control bits are reset (sv, spend, sbv): a slot's data is read only while sv (and a buffer word only while its sbv)
// says so, and a reset of every slot register is a fan-out timing does not meet.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int s = 0; s < A; s++) begin
            sv[s] <= 1'b0; spend[s] <= 1'b0; sbv[s][0] <= 1'b0; sbv[s][1] <= 1'b0;
        end
    end else begin
        for (int s = 0; s < A; s++)
            if (c_free[s]) sv[s] <= 1'b0;
        if (adm_load) begin
            sv[free_s] <= 1'b1; sbv[free_s][0] <= 1'b0; sbv[free_s][1] <= 1'b0;
        end
        if (b_issue_slot) begin
            spend[want_s] <= 1'b1;
            sbv[want_s][skf[want_s][0]] <= 1'b0;
        end
        // a new frame: every slot is free (a fetch still in flight lands in its buffer, tagged with its absolute word number,
        // so whatever sprite takes the slot next sees correct data or a tag that does not match)
        if (frame_wrap) for (int s = 0; s < A; s++) sv[s] <= 1'b0;
        if (b_fill) begin
            spend[b_slot] <= 1'b0; sbv[b_slot][b_e] <= 1'b1;
        end
    end
end

always_ff @(posedge clk) begin
    for (int s = 0; s < A; s++)
        if (pix_stb && c_cov[s]) skc[s] <= c_k[s];
    if (adm_load) begin
        sline[free_s] <= L;        sidx[free_s] <= ad_idx;
        sprio[free_s] <= a_prio;   spal[free_s] <= a_pal;      sb8[free_s] <= a_b8;   shb[free_s] <= a_hb;
        shf[free_s] <= a_hf;       ssh[free_s] <= a_sh;        sx[free_s] <= a_x;     sxe[free_s] <= a_xe;
        sW[free_s] <= a_W;         srb[free_s] <= a_rb;        skfirst[free_s] <= a_kfirst; sklast[free_s] <= a_klast;
        skc[free_s] <= a_k0;       skf[free_s] <= a_k0;
    end
    if (b_issue_slot)
        skf[want_s] <= shf[want_s] ? skf[want_s] - 1 : skf[want_s] + 1;
    if (b_fill) begin
        sbuf[b_slot][b_e] <= b_hrdata; stag[b_slot][b_e] <= b_k;
    end
end

// ---------------------------------------------------------------------------------------------------------------------------
// Pixel pipeline, one step per pix_stb: P1, P2 (above), L1..L3 (priority, hitboxes), the palette -> pixel
// ---------------------------------------------------------------------------------------------------------------------------
// a pixel is safe from admission when every sprite that can cover it is in a slot: all of its line, or all bins up to its own.
// Sampled in P1, at the same edge as the slots.
wire adm_safe = ($signed({1'b0, cy}) <= adm_done_line) || (adm_active && (L == cy[8:0]) && ({1'b0, ad_b} > {1'b0, cx[9:4]}));

logic        p1_v, p1_unsafe, c_v, c_unsafe, l1_v, l1_late, l2_v, l2_late, l3_v, l3_late;
logic        c_lateany;      // the P2 pixel is late: the admission frontier (P1) or a texture word (P2)
logic [31:0] late_r;
logic [127:0] hit_r;          // hits of the frame being drawn
logic [127:0] hit_q;          // of the last finished frame (HIT0..3)
logic [11:0] pixel_r;

// L1..L3: the opaque slot with the smallest (prio, index) wins: a tree of 4-way picks, one level a pixel (up to 64 slots).
// A candidate is {opaque, prio, index, palette index}. The tree always has 3 levels, so the lead is the same for any SLOTS.
localparam int N1 = (A + 3) / 4, N2 = (N1 + 3) / 4, N3 = (N2 + 3) / 4;
typedef struct packed { logic v; logic [8:0] key; logic [7:0] pi; } cand_t;
function automatic cand_t pick(cand_t a, cand_t b);    // b wins only when it is opaque and a is not, or its key is smaller
    return (b.v && (!a.v || b.key < a.key)) ? b : a;
endfunction
cand_t lv0 [A];
cand_t lv1 [N1], lv2 [N2], lv3 [N3];
always_comb
    for (int s = 0; s < A; s++)
        lv0[s] = '{v: c_opq[s], key: {c_prio[s], c_idx[s]}, pi: c_b8[s] ? c_c[s] : {c_pal[s], c_c[s][3:0]}};
always_ff @(posedge clk) begin
    if (pix_stb) begin
        for (int i = 0; i < N1; i++) begin
            cand_t c; c = '0;
            for (int j = 4 * i; j < 4 * i + 4; j++) if (j < A) c = pick(c, lv0[j]);
            lv1[i] <= c;
        end
        for (int i = 0; i < N2; i++) begin
            cand_t c; c = '0;
            for (int j = 4 * i; j < 4 * i + 4; j++) if (j < N1) c = pick(c, lv1[j]);
            lv2[i] <= c;
        end
        for (int i = 0; i < N3; i++) begin
            cand_t c; c = '0;
            for (int j = 4 * i; j < 4 * i + 4; j++) if (j < N2) c = pick(c, lv2[j]);
            lv3[i] <= c;
        end
    end
end

always_comb begin
    c_lateany = c_unsafe;
    for (int s = 0; s < A; s++) c_lateany = c_lateany || c_late[s];
end

// two or more opaque hitbox sprites on the P2 pixel: every one of them is hit
logic hb_multi;
always_comb begin
    logic [7:0] n; n = '0;
    for (int s = 0; s < A; s++) n = n + 8'(c_opq[s] && c_hb[s]);
    hb_multi = (n >= 8'd2);
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p1_v <= 1'b0; p1_unsafe <= 1'b0; c_v <= 1'b0; c_unsafe <= 1'b0;
        l1_v <= 1'b0; l1_late <= 1'b0; l2_v <= 1'b0; l2_late <= 1'b0; l3_v <= 1'b0; l3_late <= 1'b0;
        late_r <= '0; hit_r <= '0; hit_q <= '0; pixel_r <= '0;
    end else if (pix_stb) begin
        // P1, P2: is the pixel in the frame, is it late (admission frontier in P1, a texture word in P2)
        p1_v      <= frame_px;
        p1_unsafe <= frame_px && !adm_safe;
        c_v       <= p1_v;
        c_unsafe  <= p1_unsafe;
        // L1: counted and hit-checked once, here
        l1_v <= c_v;  l1_late <= c_lateany;
        if (c_v && c_lateany && late_r != 32'hFFFF_FFFF) late_r <= late_r + 32'd1;
        if (hit_latch) begin hit_q <= hit_r; hit_r <= '0; end   // no pixel of a frame is in P2 then: it is the blanking
        if (c_v && hb_multi)
            for (int s = 0; s < A; s++)
                if (c_opq[s] && c_hb[s]) hit_r[c_idx[s]] <= 1'b1;
        l2_v <= l1_v; l2_late <= l1_late;
        l3_v <= l2_v; l3_late <= l2_late;
        // the palette: a late pixel is black (spec section 8); nothing opaque is the backdrop, palette[0]
        pixel_r <= (l3_v && !l3_late) ? pal_mem[lv3[0].v ? lv3[0].pi : 8'h00] : 12'h000;
    end
end

assign pixel      = pixel_r;
assign late_count = late_r;
assign hit_bits   = hit_q;

// racer0 names (x, y, active) too; this unit keeps its own count of the same raster (cx, cy)
// ---------------------------------------------------------------------------------------------------------------------------
// Performance counters (doc/ppu.yaml, FRAME_CYC .. TEX_WANT_PEAK): only while the frame renders (E_RUN)
// ---------------------------------------------------------------------------------------------------------------------------
logic [31:0] pc_frame, pc_tex, pc_main, pc_admwait;
logic [7:0]  pc_slots_peak, pc_want_peak;
logic signed [15:0] pc_slack;
// n_cover: slots covering the pixel S0 is making (the depth the picture needs there); not the slots holding a sprite, which
// admission fills ahead of the beam whenever it can, so that count says only that slots run full
logic [7:0]  n_cover, n_want;
always_comb begin
    n_cover = '0; n_want = '0;
    for (int s = 0; s < A; s++) begin
        n_cover = n_cover + 8'(c_cov[s]);
        n_want  = n_want + 8'(b_want[s]);
    end
end
// the admission frontier ahead of the pixel being made, on a line still being admitted: (first bin not done) * 16 - column
wire signed [15:0] slack_now = $signed({6'd0, ad_b, 4'b0000}) - $signed({6'd0, cx});

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_frame <= '0; pc_tex <= '0; pc_main <= '0; pc_admwait <= '0;
        pc_slots_peak <= '0; pc_want_peak <= '0; pc_slack <= 16'sh7FFF;
    end else if (est == E_RUN) begin
        pc_frame <= pc_frame + 32'd1;
        if (bph != 2'd0)               pc_tex     <= pc_tex + 32'd1;
        if (aph_data || a_issue)       pc_main    <= pc_main + 32'd1;
        if (ads == AD_LOAD && !have_free) pc_admwait <= pc_admwait + 32'd1;
        if (pix_stb && n_cover > pc_slots_peak) pc_slots_peak <= n_cover;
        if (n_want > pc_want_peak)     pc_want_peak  <= n_want;
        if (pix_stb && frame_px && adm_active && L == cy[8:0] && slack_now < pc_slack) pc_slack <= slack_now;
    end
end

assign frame_cyc_count     = pc_frame;
assign tex_busy_count      = pc_tex;
assign main_busy_count     = pc_main;
assign slots_peak_count    = {24'd0, pc_slots_peak};
assign adm_wait_count      = pc_admwait;
assign adm_slack_pixels    = 32'(pc_slack);
assign tex_want_peak_count = {24'd0, pc_want_peak};

// a_tex[13]: textures past 256 kb, beyond any tex0; pal_word[31:28, 15:12]: the unused top bits of the 16-bit entries
wire _unused_renderer = &{1'b0, x, y, active, a_hresp, b_hresp, a_v, ad_w1[31:21], ad_w0[28], ev_w0[31:29], a_tex[13],
                         pal_word[31:28], pal_word[15:12]};

endmodule
