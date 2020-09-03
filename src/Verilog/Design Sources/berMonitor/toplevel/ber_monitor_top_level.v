`timescale 1ns/100ps

module ber_monitor_top_level
#(
    parameter                           N_LANES             = 20,
    parameter                           NB_SH_BUS           = N_LANES,
    parameter                           HI_BER_VALUE        = 97,
    parameter                           XUS_TIMER_WINDOW    = 1024
)
(
    input  wire                         i_clock,
    input  wire                         i_reset,
    input  wire                         i_test_mode,
    input  wire                         i_valid,
    input  wire [NB_SH_BUS-1    : 0]    i_sh_bus,

    output  wire [N_LANES-1      : 0]   o_hi_ber_bus    
);

genvar i;

generate
        for (i = 0; i < N_LANES; i = i + 1)
        begin: BER_MONITORS
        ber_monitor
            u_ber_monitor
            (
                .i_clock(i_clock),
                .i_reset(i_reset),
                .i_valid_sh(i_sh_bus[i]),
                .i_test_mode(i_test_mode),
                .i_valid(i_valid),

                .o_hi_ber(o_hi_ber_bus[i])
            );
        end
endgenerate

endmodule