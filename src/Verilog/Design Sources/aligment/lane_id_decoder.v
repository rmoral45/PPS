

module lane_id_decoder
#(
        parameter NB_ONEHOT_ID = 20, //same as number of lanes
        parameter NB_LANE_ID = $clog2(NB_ONEHOT_ID)
 )
 (
        input  wire [NB_ONEHOT_ID-1 : 0] i_match_mask,

        output wire [NB_LANE_ID-1 : 0] o_lane_id
 );


reg [NB_LANE_ID-1 : 0] decimal_id;

assign o_lane_id = decimal_id;
always @(*)
begin
decimal_id = 0;
        casez(i_match_mask)
                20'b????_????_????_????_???1 :
                        decimal_id = 0;
                20'b????_????_????_????_??1? :
                        decimal_id = 1;
                20'b????_????_????_????_?1?? :
                        decimal_id = 2;
                20'b????_????_????_????_1??? :
                        decimal_id = 3;
                20'b????_????_????_???1_???? :
                        decimal_id = 4;
                20'b????_????_????_??1?_???? :
                        decimal_id = 5;
                20'b????_????_????_?1??_???? :
                        decimal_id = 6;
                20'b????_????_????_1???_???? :
                        decimal_id = 7;
                20'b????_????_???1_????_???? :
                        decimal_id = 8;
                20'b????_????_??1?_????_???? :
                        decimal_id = 9;
                20'b????_????_?1??_????_???? :
                        decimal_id = 10;
                20'b????_????_1???_????_???? :
                        decimal_id = 11;
                20'b????_???1_????_????_???? :
                        decimal_id = 12;
                20'b????_??1?_????_????_???? :
                        decimal_id = 13;
                20'b????_?1??_????_????_???? :
                        decimal_id = 14;
                20'b????_1???_????_????_???? :
                        decimal_id = 15;
                20'b???1_????_????_????_???? :
                        decimal_id = 16;
                20'b??1?_????_????_????_???? :
                        decimal_id = 17;
                20'b?1??_????_????_????_???? :
                        decimal_id = 18;
                20'b1???_????_????_????_???? :
                        decimal_id = 19;
        endcase
end

endmodule