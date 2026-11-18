// racer0: the VGA output unit (doc/racer.yaml). The racer of ../vga_stream (hw-proj init's "VGA stream" example), with the render
// unit as its colour source.
//
// The block (module vga, written by hw-proj gen from doc/vga.yaml) shows rgb = its pixel input inside 640x480 and black outside,
// and tells you the pixel it will need: x, y (and active: it is inside the picture) are the pixel the beam shows LEAD pixels later
// (lead: 1 in doc/vga.yaml). They go out to ppu0, which answers on pixel.
//
// Until ppu0 starts (use_ppu = ppu0.engine_on) the colour is racer's own bars. The block names x LEAD = 6 pixels ahead (doc/vga.yaml),
// so the bar goes through six registers stepped at pix_stb (the last cycle of a pixel), as ppu0's six pipeline stages do:
// both colours are the right one for the pixel on show, and the choice is a plain mux.

`default_nettype none

module racer (
    input  wire        clk,
    input  wire        rst_n,
    output wire [9:0]  x,
    output wire [8:0]  y,
    output wire        active,
    output wire        vblank,
    output wire        frame_start,
    input  wire [11:0] pixel,      // ppu0's colour
    input  wire        use_ppu,    // ppu0 has started: show its colour
    output wire        hsync,
    output wire        vsync,
    output wire [11:0] rgb,        // red in the high bits: 4 bits each of red, green, blue
    output wire        pix_stb
);

reg [11:0] bars;
reg [11:0] bars_d [5];               // with bars, six stages: lead 6, as ppu0's pipeline

// eight bars of 80 pixels: white, yellow, cyan, green, magenta, red, blue, black
function automatic [11:0] bar(input [9:0] col);
    case (col / 10'd80)
        10'd0:   bar = 12'hFFF;
        10'd1:   bar = 12'hFF0;
        10'd2:   bar = 12'h0FF;
        10'd3:   bar = 12'h0F0;
        10'd4:   bar = 12'hF0F;
        10'd5:   bar = 12'hF00;
        10'd6:   bar = 12'h00F;
        default: bar = 12'h000;
    endcase
endfunction

always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
        for (int i = 0; i < 5; i++) bars_d[i] <= 12'h000;
        bars <= 12'h000;
    end else if (pix_stb) begin
        bars_d[0] <= bar(x);
        for (int i = 1; i < 5; i++) bars_d[i] <= bars_d[i-1];
        bars <= bars_d[4];
    end

vga u_vga (
    .clk(clk), .rst_n(rst_n),
    .hsync(hsync), .vsync(vsync), .rgb(rgb), .pix_stb(pix_stb),
    .x(x), .y(y), .active(active), .pixel(use_ppu ? pixel : bars),
    .vblank(vblank), .frame_start(frame_start)
);

endmodule
