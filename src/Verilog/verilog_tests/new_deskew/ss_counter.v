module ss_counter
#(
	parameter MAX_SKEW = 16,
	parameter NB_COUNT = $clog2(MAX_SKEW), //AGREGAR MAS BITS !!!!!
	parameter tt = 6'd0 //test param
 )
 (
 	input wire 					 i_clock,
 	input wire 					 i_reset,
 	input wire 					 i_resync,
 	input wire 					 i_enable,
 	input wire					 i_enable_counter,
 	input wire 					 i_stop_counter,
 	
 	output wire [NB_COUNT-1 : 0] o_count
 );

 //INTERNAL SIGNALS
 reg [NB_COUNT-1 : 0] counter;

 //PORTS
 assign o_count = counter;

 always @ (posedge  i_clock)
 begin
 	
 	if(i_reset || i_resync)
 	begin
 		counter <= {NB_COUNT{1'b0}};
 	end
 	else if (i_enable)
 	begin

 		if(i_stop_counter)
 			counter <= counter;
 		else if (i_enable_counter)
 			counter <= counter + 1;
 	end

 end
 
 endmodule