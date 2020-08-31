`timescale 1ns/100ps

/*
 *@TODO agregar un enable diferente por modulo --> LISTO! Definir si hacer un bus de enable o seniales separadas
 *@TODO revisar los i_valid de cada modulo 
 *@TODO en el RF agregar las seniales de read de los registros COR
 */

module rx_toplevel
#(
    // common
    parameter NB_DATA           = 66,
    parameter N_LANES           = 20,
    parameter NB_DATA_BUS       = N_LANES * NB_DATA,
    // block sync
    parameter NB_SH             = 2,
    parameter NB_SH_BUS         = NB_SH * N_LANES,
    parameter MAX_WINDOW        = 4096,
    parameter NB_WINDOW_CNT     = $clog2(MAX_WINDOW),
    parameter MAX_INV_SH        = (MAX_WINDOW/2),
    parameter NB_INV_SH         = $clog2(MAX_WINDOW/2),
    
    //aligment
    parameter NB_ERROR_COUNTER  = 32,
    parameter N_ALIGNER         = 20,
    parameter NB_LANE_ID        = $clog2(N_ALIGNER),
    parameter NB_ID_BUS         = N_LANES * NB_LANE_ID,
    parameter AM_PERIOD_BLOCKS  = 16383,
    parameter MAX_INV_AM        = 8,
    parameter NB_INV_AM         = $clog2(MAX_INV_AM),
    parameter MAX_VAL_AM        = 20,
    parameter NB_VAL_AM         = $clog2(MAX_VAL_AM),
    parameter NB_AM             = 48,
    parameter NB_ERR_BUS        = N_LANES * NB_ERROR_COUNTER,
    parameter NB_AM_PERIOD      = 14,

    //deskew
    parameter FIFO_DEPTH        = 20,
    parameter NB_FIFO_DATA      = 67, //incluye tag de SOL
    parameter MAX_SKEW          = 16,
    parameter FIFO_DATA_BUS     = N_LANES * FIFO_DEPTH,

    //decoder
    parameter NB_FSM_CONTROL    = 4,
    parameter NB_DATA_RAW       = 64,
    parameter NB_CTRL_RAW       = 8,
    
    //test pattern checker
    parameter NB_MISMATCH_COUNTER = 32

)
(
    input  wire                             i_clock,
    input  wire                             i_reset,
    input  wire                             i_enable,
    input  wire                             i_valid, //esta senial viene del channel? 
    input  wire [NB_DATA_BUS - 1 : 0]       i_phy_data,
    
    //Valid generator inputs
    input  wire                             i_rf_enb_valid_gen,
    
    //Block sync inputs
    input  wire                             i_rf_enable_block_sync,
    input  wire [NB_WINDOW_CNT-1    : 0]    i_rf_unlocked_timer_limit,
    input  wire [NB_WINDOW_CNT-1    : 0]    i_rf_locked_timer_limit,
    input  wire [NB_INV_SH-1        : 0]    i_rf_sh_invalid_limit,
    input  wire [NB_DATA_BUS-1      : 0]    i_data,
    input  wire                             i_signal_ok,

    //Aligner inputs
    input  wire                             i_rf_enable_aligner,
    input  wire [NB_INV_AM-1        : 0]    i_rf_invalid_am_thr,
    input  wire [NB_VAL_AM-1        : 0]    i_rf_valid_am_thr,
    input  wire [NB_AM-1            : 0]    i_rf_compare_mask,
    input  wire [NB_AM_PERIOD-1     : 0]    i_rf_am_period,

    //Deskew inputs
    input  wire                             i_rf_enable_deskewer,

    //Lane reorder inputs
    input  wire                             i_rf_enable_lane_reorder,
    input  wire                             i_rf_reset_order,
        
    //Descrambler inputs
    input  wire                             i_rf_enable_descrambler,
    input  wire                             i_rf_descrambler_bypass,
    input  wire                             i_rf_enable_clock_comp,

    //Test pattern checker & ber_monitor signal
    input  wire                             i_rf_test_pattern_checker,
    input  wire                             i_rf_idle_pattern_mode,
    
    //Decoder signals
    input  wire                             i_rf_enable_decoder,
    
    //Read pulses to COR registers
    input  wire                             i_rf_read_hi_ber,
    input  wire                             i_rf_read_am_error_counter,
    input  wire                             i_rf_read_am_resyncs,
    input  wire                             i_rf_read_missmatch_counter,
    input  wire                             i_rf_read_lanes_block_lock,
    input  wire                             i_rf_read_lanes_id,

    output wire [N_LANES-1          : 0]    o_rf_hi_ber,
    output wire [NB_ERR_BUS  - 1    : 0]    o_rf_am_error_counter,
    output wire [NB_ERR_BUS  - 1    : 0]    o_rf_resync_counter_bus,
    output wire [N_LANES     - 1    : 0]    o_rf_am_lock,
    output wire [NB_MISMATCH_COUNTER-1  : 0] o_rf_missmatch_counter,
    output wire [N_LANES-1          : 0]    o_rf_lanes_block_lock,
    output wire [NB_ID_BUS-1        : 0]    o_rf_lanes_id
);

//-----------------  localparameters  ------------------//
// valid_generators
localparam              COUNT_SCALE             = 2;
localparam              VALID_COUNT_LIMIT_FAST  = 2;
localparam              VALID_COUNT_LIMIT_SLOW  = 40;

//-----------------  module connect wires  ------------------//
// valid_generators
wire                                fast_valid;
wire                                slow_valid;


//block sync --> aligment
wire    [NB_DATA_BUS - 1 : 0]       blksync_data_aligment;
wire                                blksync_valid_aligment;
wire    [N_LANES     - 1 : 0]       blksync_lock_aligment;
wire    [NB_SH_BUS-1     : 0]       blksync_sh_bermonitor;

//aligment   --> deskew
wire    [NB_DATA_BUS - 1 : 0]       aligment_data_deskew;
wire                                aligment_valid_deskew;
wire    [N_LANES     - 1 : 0]       aligment_resync_deskew;
wire    [N_LANES     - 1 : 0]       aligment_sol_deskew;

//aligment    --> lane reorder
wire    [NB_ID_BUS   - 1 : 0]       aligment_id_reorder;

//alignment   --> rf
wire    [NB_ERR_BUS-1       : 0]    alignment_error_bus_rf; 
wire    [N_LANES-1          : 0]    am_lanes_lock;  
wire    [NB_ERR_BUS-1       : 0]    am_resync_counter_rf;

//ber monitor --> rf
wire    [N_LANES-1          : 0]    ber_monitor_hi_ber_bus_rf;

//deskew      --> reorder
//@CAREFUL estos datos son de 67 bits xq contiene el tag
wire [FIFO_DATA_BUS  - 1 : 0]       deskew_data_reorder;
wire                                deskew_deskewdone_reorder;

//deskew      --> regfile
wire                                deskew_validskew_regfile;
//deskew      --> ber monitor
wire                                deskew_validskew_bermonitor;

// reorder    --> descrambler
wire    [NB_DATA     - 1 : 0]       reorder_data_descrambler;
wire                                reorder_tag_descrambler;

//descrambler --> clock comp rx
wire    [NB_DATA     - 1 : 0]       descrambler_data_clockcomp;
wire                                descrambler_tag;

//clock comp rx --> decoder
wire    [NB_DATA     - 1 : 0]       clockcomp_data_decoder;

//test pattern checker --> rf
wire    [NB_MISMATCH_COUNTER-1 : 0] missmatch_counter_rf;


//decoder --> clock comp rx
wire    [NB_FSM_CONTROL-1   :   0]  decoder_fsmcontrol_clockcomp;
wire    [NB_DATA_RAW-1      :   0]  decoder_data_raw;
wire    [NB_CTRL_RAW-1      :   0]  decoder_ctrl_raw;

//---------------------  COR registers --------------------------//
reg     [N_LANES-1          :   0]  hi_ber;
reg     [NB_ERR_BUS-1       :   0]  am_error_counter;
reg     [NB_ERROR_COUNTER-1 :   0]  am_resyncs;
reg     [NB_MISMATCH_COUNTER-1  : 0] patternchecker_missmatch_counter;
reg     [N_LANES-1              : 0] lanes_block_lock;
reg     [NB_ID_BUS-1            : 0] lanes_id_bus;

reg                                 read_hi_ber_d;
reg                                 read_am_error_counter_d;
reg                                 read_am_resyncs_d;
reg                                 read_missmatch_counter_d;
reg                                 read_lanes_block_lock_d;
reg                                 read_lanes_id_d;

wire                                reset_hi_ber_posedge;
wire                                reset_am_error_counter_posedge;
wire                                reset_am_resyncs_posedge;
wire                                reset_missmatch_counter;
wire                                reset_lanes_block_lock;
reg                                 reset_lanes_id;

always @(posedge i_clock)
begin
    if(i_reset)
    begin
        read_hi_ber_d           <=  1'b0;
        read_am_error_counter_d <=  1'b0;
        read_am_resyncs_d       <=  1'b0;
        read_missmatch_counter_d<=  1'b0;
        read_lanes_block_lock_d <=  1'b0;
        read_lanes_id_d         <=  1'b0;
    end
    else
    begin
        read_hi_ber_d           <=  i_rf_read_hi_ber;
        read_am_error_counter_d <=  i_rf_read_am_error_counter;
        read_am_resyncs_d       <=  i_rf_read_am_resyncs;
        read_missmatch_counter_d<=  i_rf_read_missmatch_counter;
        read_lanes_block_lock_d <=  i_rf_read_lanes_block_lock;
        read_lanes_id_d         <=  i_rf_read_lanes_id;
    end
end

assign                              reset_hi_ber_posedge             = (i_rf_read_hi_ber & ~read_hi_ber_d);
assign                              reset_am_error_counter_posedge   = (i_rf_read_am_error_counter & ~read_am_error_counter_d);
assign                              reset_am_resyncs_posedge         = (i_rf_read_am_resyncs & ~read_am_resyncs_d);
assign                              reset_missmatch_counter          = (i_rf_read_missmatch_counter & ~read_missmatch_counter_d);
assign                              reset_lanes_block_lock           = (i_rf_read_lanes_block_lock & ~read_lanes_block_lock_d);
assign                              reset_lanes_id                   = (i_rf_read_lanes_id & ~read_lanes_id_d);

always @(posedge i_clock)
begin
    if(i_reset || reset_hi_ber_posedge)
        hi_ber                  <=  1'b0;
    else
        hi_ber                  <=  ber_monitor_hi_ber_bus_rf;
end

always @(posedge i_clock)
begin
    if(i_reset || reset_am_error_counter_posedge)
        am_error_counter        <=  {NB_ERR_BUS{1'b0}};
    else
        am_error_counter        <=  alignment_error_bus_rf;
end

always @(posedge i_clock)
begin
    if(i_reset || reset_am_resyncs_posedge)
        am_resyncs              <=  {NB_ERR_BUS{1'b0}};
    else
        am_resyncs              <=  am_resync_counter_rf;
end

always @(posedge i_clock)
begin
    if(i_reset || reset_missmatch_counter)
        patternchecker_missmatch_counter  <=  {NB_MISMATCH_COUNTER{1'b0}};
    else
        patternchecker_missmatch_counter  <=  missmatch_counter_rf;
end

always @(posedge i_clock)
begin
    if(i_reset || reset_lanes_block_lock)
        lanes_block_lock  <=  {N_LANES{1'b0}};
    else
        lanes_block_lock  <=  blksync_lock_aligment;
end

always @(posedge i_clock)
begin
    if(i_reset || reset_lanes_id)
        lanes_id_bus  <=  {NB_ID_BUS{1'b0}};
    else
        lanes_id_bus  <=  aligment_id_reorder;
end

//---------------------  Outputs --------------------------//
    assign                                  o_rf_hi_ber             = hi_ber;
    assign                                  o_rf_am_error_counter   = am_error_counter;
    assign                                  o_rf_am_lock            = am_lanes_lock;
    assign                                  o_rf_missmatch_counter  = patternchecker_missmatch_counter;
    assign                                  o_rf_lanes_block_lock   = lanes_block_lock;


//---------------------  Instances --------------------------//

decoder
u_decoder
(
    .i_clock(i_clock),
    .i_reset(i_reset),
    .i_enable(i_rf_enable_decoder),
    .i_data(clockcomp_data_decoder),

    .o_data(decoder_data_raw),
    .o_ctrl(decoder_ctrl_raw),
    .o_fsm_control(decoder_fsmcontrol_clockcomp)
);

test_pattern_checker
u_test_pattern_checker
(
    .i_clock(i_clock),
    .i_reset(i_reset),
    .i_enable(i_rf_test_pattern_checker),
    .i_valid(fast_valid),
    .i_idle_pattern_mode(i_rf_idle_pattern_mode),
    .i_data(descrambler_data_clockcomp),
    
    .o_mismatch_counter(missmatch_counter_rf)
);

clock_comp_rx
u_clock_comp_rx
(
    .i_clock(i_clock),
    .i_reset(i_reset),
    .i_enable(i_rf_enable_clock_comp),
    .i_valid(fast_valid),
    .i_fsm_control(decoder_fsmcontrol_clockcomp),
    .i_sol_tag(descrambler_tag),   //CHECK!!!
    .i_data(descrambler_data_clockcomp),
    
    .o_data(clockcomp_data_decoder)
);

descrambler
#(
    .NB_DATA    (NB_DATA)
 )
    u_descrambler
    (
        .i_clock    (i_clock),
        .i_reset    (i_reset),
        .i_enable   (i_rf_enable_descrambler), 
        .i_valid    (fast_valid),
        .i_bypass   (i_rf_descrambler_bypass | reorder_tag_descrambler),
        .i_data     (reorder_data_descrambler),
        .i_tag      (reorder_tag_descrambler),

        .o_data     (descrambler_data_clockcomp),
        .o_tag      (descrambler_tag)
    );


reorder_toplevel
#(
    .NB_DATA        (NB_DATA),
    .NB_FIFO_DATA   (NB_FIFO_DATA),
    .N_LANES        (N_LANES)
 )
    u_reorder_top
    (
    .i_clock                    (i_clock),
    .i_reset                    (i_reset),
    .i_rf_reset_order           (i_rf_reset_order),
    .i_enable                   (i_rf_enable_lane_reorder),
    .i_valid                    (fast_valid),
    .i_deskew_done              (deskew_deskewdone_reorder),
    .i_logical_rx_ID            (aligment_id_reorder),
    .i_data                     (deskew_data_reorder),

    .o_data                     (reorder_data_descrambler),
    .o_tag                      (reorder_tag_descrambler)
    );

deskew_top
#(
    .N_LANES                    (N_LANES),
    .NB_DATA                    (NB_DATA),
    .NB_FIFO_DATA               (NB_FIFO_DATA),
    .FIFO_DEPTH                 (FIFO_DEPTH),
    .MAX_SKEW                   (MAX_SKEW)
)
    u_deskew_top
    (
    .i_clock                    (i_clock),
    .i_reset                    (i_reset),
    .i_enable                   (i_rf_enable_deskewer),
    .i_valid                    (aligment_valid_deskew),
    .i_resync                   (aligment_resync_deskew),
    .i_start_of_lane            (aligment_sol_deskew),
    .i_data                     (aligment_data_deskew),

    .o_data                     (deskew_data_reorder),
    .o_deskew_done              (deskew_deskewdone_reorder),
    .o_valid_skew               (deskew_validskew_bermonitor)
    );

am_top_level
#(
    .N_LANES                    (N_LANES),
    .NB_DATA                    (NB_DATA),
    .NB_ERROR_COUNTER           (NB_ERROR_COUNTER),
    .N_ALIGNER                  (N_ALIGNER),
    .N_BLOCKS                   (AM_PERIOD_BLOCKS),
    .MAX_INN_AM                 (MAX_INV_AM),
    .MAX_VAL_AM                 (MAX_VAL_AM),
    .NB_AM                      (NB_AM)
)
    u_aligner_top
    (
    .i_clock                    (i_clock),
    .i_reset                    (i_reset),
    .i_rf_enable                (i_rf_enable_aligner),
    .i_valid                    (blksync_valid_aligment),
    .i_block_lock               (blksync_lock_aligment),
    .i_data                     (blksync_data_aligment),
    .i_rf_invalid_am_thr        (i_rf_invalid_am_thr),
    .i_rf_valid_am_thr          (i_rf_valid_am_thr),
    .i_rf_compare_mask          (i_rf_compare_mask),

    .o_data                     (aligment_data_deskew),
    .o_valid                    (aligment_valid_deskew),
    .o_lane_id                  (aligment_id_reorder),
    .o_error_counter            (alignment_error_bus_rf),
    .o_am_lock                  (am_lanes_lock),
    .o_resync                   (aligment_resync_deskew),
    .o_resync_counter_bus       (am_resync_counter_rf_bus),
    .o_start_of_lane            (aligment_sol_deskew)
    );


ber_monitor_top_level
    u_ber_monitor_top_level
    (
        .i_clock                    (i_clock),
        .i_reset                    (i_reset),
        .i_valid                    (aligment_valid_deskew),
        .i_align_status             (deskew_validskew_bermonitor), //CHECK: seria valid_skew, pero la comentamos a esta salida.
        .i_test_mode                (i_rf_idle_pattern_mode),

        .o_hi_ber_bus               (ber_monitor_hi_ber_bus_rf)
    );

block_sync_toplevel
#(
    .NB_DATA                    (NB_DATA),
    .N_LANES                    (N_LANES),
    .MAX_WINDOW                 (MAX_WINDOW)
)
    u_block_sync_top
    (
    .i_clock                    (i_clock),
    .i_reset                    (i_reset),
    .i_enable                   (i_rf_enable_block_sync),
    .i_valid                    (slow_valid),
    .i_data                     (i_phy_data),
    .i_signal_ok                (i_signal_ok),
    .i_rf_unlocked_timer_limit  (i_rf_unlocked_timer_limit),
    .i_rf_locked_timer_limit    (i_rf_locked_timer_limit),
    .i_rf_sh_invalid_limit      (i_rf_sh_invalid_limit),

    .o_data                     (blksync_data_aligment),
    .o_sh_bus                   (blksync_sh_bermonitor),
    .o_valid                    (blksync_valid_aligment),
    .o_block_lock               (blksync_lock_aligment)
    );

valid_generator
#(
    .COUNT_SCALE(COUNT_SCALE),
    .VALID_COUNT_LIMIT(VALID_COUNT_LIMIT_FAST)
)
    u_fast_valid
    (
        .i_clock(i_clock),
        .i_reset(i_reset),
        .i_enable(i_rf_enb_valid_gen),
        .o_valid(fast_valid)
    
    );
    
valid_generator
#(
    .COUNT_SCALE(COUNT_SCALE),
    .VALID_COUNT_LIMIT(VALID_COUNT_LIMIT_SLOW)
)
    u_slow_valid
    (
        .i_clock(i_clock),
        .i_reset(i_reset),
        .i_enable(i_rf_enb_valid_gen),
        .o_valid(slow_valid)
    );    


endmodule