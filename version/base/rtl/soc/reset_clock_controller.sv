// hw-proj: GENERATE HEADER BEGIN
module reset_clock_controller (
    input  wire clk,
    input  wire clk_pin,
    output wire clk_clk,
    input  wire por_n,
    output wire rst_n_system
);
// hw-proj: GENERATE HEADER END

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    // Controller reset
    wire rcc_rst_n;  // the controller's own reset: asserted by a self_reset source, released on clk

    // Source activity and requests
    wire act_por_n;  // source por_n is active (active high)

    // Group holds and waits
    reg  hold_system;  // group system is held; set by any source that asserts it, cleared once the controller is out of reset and the delay is over

    // Release of the group
    reg  rcc_armed;    // the controller has been out of reset for one clk edge
    wire due_system;   // the delay of system is over
    wire hclr_system;  // clear hold_system

    // Domain clocks, straight from the sources
    assign clk_clk = clk_pin;

    // Controller reset: asserted by a self_reset source, released on clk
    wire rcc_arst_n = !(act_por_n);
    reg  rcc_ff1, rcc_ff2;
    always_ff @(posedge clk or negedge rcc_arst_n) begin
        if (!rcc_arst_n) begin
            rcc_ff1 <= 1'b0;
            rcc_ff2 <= 1'b0;
        end else begin
            rcc_ff1 <= 1'b1;
            rcc_ff2 <= rcc_ff1;
        end
    end
    assign rcc_rst_n = rcc_ff2;

    // Source activity of the level sources, polarity applied once
    assign act_por_n = !por_n;

    // Group holds: set by any active source that asserts the group, cleared by the sequencer
    wire hset_system = act_por_n || !rcc_rst_n;

    always_ff @(posedge clk or posedge hset_system) begin
        if (hset_system)      hold_system <= 1'b1;
        else if (hclr_system) hold_system <= 1'b0;
    end

    // Group resets: asserted by the hold, released two edges of the group's clock later
    wire       held_system = hold_system;
    reg  [1:0] sync_system;
    always_ff @(posedge clk or posedge held_system) begin
        if (held_system) sync_system <= 2'b00;
        else             sync_system <= {sync_system[0], 1'b1};
    end
    assign rst_n_system = sync_system[1];

    // Groups whose delay and wait are over
    assign due_system = 1'b1;

    // Release: armed one edge after the controller's reset, the delay counted from there
    always_ff @(posedge clk or negedge rcc_rst_n) begin
        if (!rcc_rst_n) rcc_armed <= 1'b0;
        else            rcc_armed <= 1'b1;
    end

    // The hold of the group is cleared once armed and the delay is over
    assign hclr_system = rcc_armed && due_system;

    // hw-proj: GENERATE END

endmodule
