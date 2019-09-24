`timescale 1ns/100ps


module clock_comp_rx
#(
        parameter NB_DATA          = 66,
        parameter AM_BLOCK_PERIOD  = 16383, //[CHECK]
        parameter N_LANES          = 20
 )
 (
        input  wire                     i_clock,
        input  wire                     i_reset,
        input  wire                     i_enable,
        input  wire                     i_valid,
        input  wire                     i_fsm_control,
        input  wire                     i_sol_tag,
        input  wire [NB_DATA-1 : 0]     i_data,
        output wire [NB_DATA-1 : 0]     o_data

 );


localparam                      NB_PERIOD_CNT = $clog2(AM_BLOCK_PERIOD*N_LANES);
localparam                      NB_IDLE_CNT   = $clog2(N_LANES); //se insertaran tantos idle como lineas se tengan
localparam [NB_DATA-1 : 0]      PCS_IDLE      = 'h1_e0_00_00_00_00_00_00_00;

//------------ Internal Signals -----------------//

reg [NB_PERIOD_CNT-1 : 0]       period_counter;
reg [NB_IDLE_CNT-1 : 0]         idle_counter;

wire                            period_done;
wire                            insert_idle;
wire                            fifo_read_enable;
wire                            fifo_write_enable;



//----------- Algorithm ------------------------//


always @ (posedge i_clock)
begin
        if (i_reset || period_done)
                period_counter = {NB_PERIOD_CNT{1'b0}};
        else if (i_enable && i_valid)
                period_counter <= period_counter + 1'b1;
end

assign period_done = (period_counter == (AM_BLOCK_PERIOD-1)) ? 1'b1 : 1'b0;


always @ (posedge i_clock)
begin
        if (i_reset || period_done)
                idle_counter = {NB_IDLE_CNT{1'b0}};
        else if (i_enable && i_valid && i_fsm_control && insert_idle)
                idle_counter <= idle_counter + 1'b1;
end

assign idle_insert = ((idle_counter < N_LANES) && i_fsm_control) ? 1'b1 : 1'b0; //si fsm del receptor esta en el estado de
                                                                                //control puedo insertar los idles necesarios


//Fifo enables

assign fifo_read_enable  = ~idle_insert; // si estoy insertando idles no debo sacar datos de la fifo
assign fifo_write_enable = ~i_sol_tag  ; // elimino los idle con los cuales se "pisaron" los aligner markers


//-------- Ports -------------------------------//

assign o_data = (idle_insert) ? PCS_IDLE : fifo_output_data;


//------- Instances ---------------------------//

sync_fifo
        #(
                .NB_DATA(NB_DATA),
                .NB_ADDR(NB_ADDR)
         )
         u_sync_fifo
         (
                .i_clock        (i_clock),
                .i_reset        (i_reset),
                .i_enable       (i_enable),
                .i_write_enb    (i_valid),
                .i_read_enb     (fifo_read_enable),
                .i_data         (i_data),
                
                .o_empty        (fifo_empty),
                .o_data         (fifo_output_data)
         );

endmodule
