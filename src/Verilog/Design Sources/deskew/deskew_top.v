

module deskew_top
#(
	parameter N_LANES          = 20,
	parameter NB_DATA          = 66,
	parameter FIFO_DEPTH       = 20,
	parameter MAX_SKEW         = 16,	
	parameter NB_DELAY_COUNT   = $clog2(FIFO_DEPTH),
	parameter NB_DELAY_BUS     = NB_DELAY_COUNT*N_LANES,
	parameter NB_DATA_BUS      = NB_DATA*N_LANES
 )
 (
 	input wire 					i_clock,
 	input wire 					i_reset,
 	input wire 					i_enable,
 	input wire 					i_valid,
 	input wire 	[N_LANES-1 : 0]		        i_resync,
 	input wire 	[N_LANES-1 : 0]		        i_start_of_lane,
 	input wire      [NB_DATA_BUS-1 : 0]             i_data,

 	output wire 					o_set_fifo_delay,
 	output wire     [NB_DELAY_BUS-1 : 0]            o_lane_delay,
 	output wire     [NB_DATA_BUS-1 : 0]             o_data
 //	output wire 							o_valid_skew,
 //	output wire 							o_align_status
 );


 //LOCALPARAMS
 localparam test = { 6'd19,6'd18,6'd17,6'd16,6'd15,6'd14,6'd13,6'd12,6'd11,6'd10,6'd9,6'd8,6'd7,6'd6,6'd5,6'd4,6'd3,6'd2,6'd1,6'd0};
 //INTERNAL SIGNALS
 wire [N_LANES-1 : 0]			stop_lane_counters;
 wire [NB_DELAY_BUS-1 : 0]              lane_counters_value;
 wire                                   enable_counter;
 wire [NB_DELAY_COUNT-1 : 0]            common_counter_value;
 wire 					stop_common_counter;
 wire 					set_fifo_delay;
 wire                                   write_prog_fifo_enb;
 wire                                   read_prog_fifo_enb;
 wire 				        invalid_skew;



 //PORTS
 assign o_set_fifo_delay = set_fifo_delay;
 assign o_lane_delay = lane_counters_value;
 /*

 Salidas de la FSM , pero probablemente align_status deberia ser seteada por las
 fifos programables y valid skew deberia ser solo una variable intrna, quizas agregar una 
 senial que indique que el skew fue calculado.

 assign o_valid_skew = valid_skew;
 assign o_align_status = align_status;
*/

 //MODULES
 prog_fifo_top
 #(
    .FIFO_DEPTH(FIFO_DEPTH)
 )
 u_prog_fifo_top
 (
    .i_clock            (i_clock),
    .i_reset            (i_reset),
    .i_valid            (i_valid),
    .i_set_fifo_delay   (set_fifo_delay),
    .i_write_enb        (write_prog_fifo_enb),
    .i_read_enb         (read_prog_fifo_enb),
    .i_delay_vector     (lane_counters_value),
    .i_data             (i_data),
    .o_data             (o_data)
 );
 
 deskew_fsm
 #(
 	.N_LANES 	(N_LANES),
 	.NB_DELAY_COUNT(NB_DELAY_COUNT),
 	.MAX_SKEW	(MAX_SKEW)
  )
 u_deskew_fsm
  (
  	//INPUT
  	.i_clock		(i_clock),
  	.i_reset		(i_reset),
  	.i_enable		(i_enable),
  	.i_valid                (i_valid),
  	//.i_am_lock				(i_am_lock),
  	.i_resync		(|i_resync),
  	.i_start_of_lane	(i_start_of_lane),
  	.i_common_counter	(common_counter_value),
  	//OUTPUT
  	.o_enable_counters	(enable_counter),
  	.o_stop_common_counter	(stop_common_counter),
  	.o_set_fifo_delay	(set_fifo_delay),
  	.o_write_prog_fifo_enb  (write_prog_fifo_enb),
  	.o_read_prog_fifo_enb   (read_prog_fifo_enb),
  	.o_stop_lane_counters	(stop_lane_counters),
  	.o_invalid_skew         (invalid_skew)
  );

  ss_counter
  #(
  	.NB_DELAY_COUNT(NB_DELAY_COUNT)
  	)
  u_common_counter
   (
   	//INPUT
  	.i_clock		(i_clock),
  	.i_reset		(i_reset),
  	.i_enable		(i_enable),
  	.i_resync		(|i_resync),            //[CAREFUL]reduction OR of all lanes resync signal
  	.i_enable_counter	(enable_counter),
  	.i_stop_counter 	(&stop_lane_counters),  //[CAREFUL]reduction AND of all lanes resync signal
  	//OUTPUT
  	.o_count 		(common_counter_value)
   );



 genvar i;
 //generate

 for (i=0; i<N_LANES; i=i+1)
 begin :ger_block
	   ss_counter
	  #(
        .NB_DELAY_COUNT(NB_DELAY_COUNT)
	   )
	  u_ss_counter
	   (
	   	//INPUT
	  	.i_clock		(i_clock),
	  	.i_reset		(i_reset),
	  	.i_enable		(i_enable),
	  	.i_resync		(|i_resync ), //reduction OR of all lanes resync signal
	  	.i_enable_counter	(enable_counter),
	  	.i_stop_counter 	(stop_lane_counters[i]),
	  	//OUTPUT
	  	//.o_count 				(lane_counters_value[i*NB_DELAY_COUNT +: NB_DELAY_COUNT])
	  	.o_count                (lane_counters_value[NB_DELAY_BUS-(i*NB_DELAY_COUNT)-1 -: NB_DELAY_COUNT])
	  	
	   );
 	
 end

 //endgenerate
 


  endmodule