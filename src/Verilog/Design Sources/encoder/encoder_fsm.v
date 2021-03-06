

module encoder_fsm
#(
   parameter                           LEN_CODED_BLOCK = 66
 )
 (
  input  wire                          i_clock,
  input  wire                          i_reset,
  input  wire                          i_enable,
  input  wire [3:0]                    i_tx_type,
  input  wire [LEN_CODED_BLOCK-1 : 0]  i_tx_coded, //recibida desde el bloque comparador/codificador
  output wire [LEN_CODED_BLOCK-1 : 0]  o_tx_coded // solo difiere de lo recibido del comparador si la secuencia es incorrecta
 );

// T_TYPE
localparam [3:0] TYPE_D  = 4'b1000;
localparam [3:0] TYPE_S  = 4'b0100;
localparam [3:0] TYPE_C  = 4'b0010;
localparam [3:0] TYPE_T  = 4'b0001;
localparam [3:0] TYPE_E  = 4'b0000;
// STATES
localparam [4:0] TX_INIT = 5'b10000;
localparam [4:0] TX_C    = 5'b01000;
localparam [4:0] TX_D    = 5'b00100;
localparam [4:0] TX_T    = 5'b00010;
localparam [4:0] TX_E    = 5'b00001;
localparam PCS_ERROR = 7'h1E;
localparam [LEN_CODED_BLOCK-1 : 0] LBLOCK_T = 66'h24B000001F0000000; // !!!!FIX!!!!bloque signal ordered set
localparam [LEN_CODED_BLOCK-1 : 0] EBLOCK_T = 66'h21E1E1E1E1E1E1E1E; // !!!!FIX!!!! error block

//INTERNAL SIGNALS
reg [4:0] state;
reg [4:0] state_next;
reg [LEN_CODED_BLOCK-1 : 0] tx_coded ; 
reg [LEN_CODED_BLOCK-1 : 0] tx_coded_next;

//PORTS
assign o_tx_coded = tx_coded;

//Update state
always @ (posedge i_clock)
begin

    if(i_reset)
    begin
        tx_coded <= LBLOCK_T;
        state    <= TX_INIT;
    end

    else if (i_enable)
    begin
        tx_coded <= tx_coded_next;
        state    <= state_next;
    end

end

always @ * 
begin
    state_next = state;
    tx_coded_next = {LEN_CODED_BLOCK{1'b1}};
    //tx_coded_next = tx_coded;
    

    case(state)
        TX_INIT :
        begin
            if(i_tx_type == TYPE_C)
            begin
                state_next = TX_C;
                tx_coded_next = i_tx_coded;
            end
            else if (i_tx_type == TYPE_S)
            begin
                state_next = TX_D;
                tx_coded_next = i_tx_coded;
            end
            else
            begin
                state_next = TX_E;
                tx_coded_next = EBLOCK_T;
            end
        end
        TX_C :
        begin
            if(i_tx_type == TYPE_C)
            begin
                state_next = TX_C;
                tx_coded_next = i_tx_coded;
            end
            else if(i_tx_type == TYPE_S)
            begin
                state_next = TX_D ;
                tx_coded_next = i_tx_coded;
            end
            else
            begin 
                state_next = TX_E ;
                tx_coded_next = EBLOCK_T ;
            end
        end
        TX_D :
        begin
            if(i_tx_type == TYPE_D)
            begin
                state_next = TX_D ;
                tx_coded_next = i_tx_coded;
            end
            else if (i_tx_type == TYPE_T)
            begin
                state_next = TX_T ;
                tx_coded_next = i_tx_coded ;
            end
            else
            begin
                state_next = TX_E ;
                tx_coded_next = EBLOCK_T ;
            end
        end
        TX_T :
        begin
            if(i_tx_type == TYPE_C)
            begin
                state_next = TX_C;
                tx_coded_next = i_tx_coded;
            end
            else if(i_tx_type == TYPE_S)
            begin
                state_next = TX_D;
                tx_coded_next = i_tx_coded;
            end
            else
            begin
                state_next = TX_E ;
                tx_coded_next = EBLOCK_T ;
            end
        end
        TX_E :
        begin
            if(i_tx_type == TYPE_T)
            begin
                state_next = TX_T;
                tx_coded_next = i_tx_coded;
            end
            else if (i_tx_type == TYPE_D)
            begin
                state_next =TX_D ;
                tx_coded_next = i_tx_coded;
            end
            else if (i_tx_type == TYPE_C)
            begin
                state_next =TX_C ;
                tx_coded_next = i_tx_coded;
            end
            else
            begin
                state_next = TX_E ;
                tx_coded_next = EBLOCK_T ;
            end
        end

    endcase

end


endmodule
