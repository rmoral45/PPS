`timescale 1ns/100ps


module tx_tests;

localparam NB_DATA              = 66;
localparam N_LANES              = 20;
localparam AM_BLOCK_PERIOD      = 100;

localparam PATH_IN_DATA         = "/home/dabratte/PPS/src/Python/modules/idle_del/rx_test_dump/rx_input_data.txt";
localparam PATH_OUT_DATA        = "/home/dabratte/PPS/src/Python/modules/idle_del/rx_test_dump/rx_output_data.txt";
localparam PATH_IN_TAG          = "/home/dabratte/PPS/src/Python/modules/idle_del/rx_test_dump/rx_input_tag.txt";
localparam PATH_IN_CTRL         = "/home/dabratte/PPS/src/Python/modules/idle_del/rx_test_dump/rx_input_fsmctrl.txt";
localparam PATH_VERI_DATA       = "/home/dabratte/PPS/src/Python/modules/idle_del/rx_test_dump/verilog_output_data.txt";

// inputs  signals to tested module
reg                             tb_i_clock;
reg                             tb_i_reset;
reg                             tb_i_enable;
reg                             tb_i_valid;
reg                             tb_i_fsm_ctrl;
reg [NB_DATA-1 : 0]             tb_i_data;
reg                             tb_i_tag;

//outputs from tested module
wire [NB_DATA-1: 0]             tb_o_data;

//file handler signals
reg                             tb_enable_files;
reg                             py_input_tag;
reg                             py_input_fsmctrl;
reg                             temp_tag;
reg                             temp_ctrl;
reg  [0 : NB_DATA-1]            temp_data;
reg  [0 : NB_DATA-1]            py_temp_data;
reg  [NB_DATA-1 : 0]            py_output_data;


integer                         fid_input_data;
integer                         fid_input_tag;
integer                         fid_input_ctrl;
integer                         fid_output_data;
integer                         fid_verilog_data;

integer                         code_error_data;
integer                         code_error_data_py;
integer                         code_error_tag;
integer                         code_error_ctrl;
integer                         ptr_data_py;
integer                         ptr_data;


initial
begin
        //lectura de datos de entrada generadas por python
	fid_input_data = $fopen(PATH_IN_DATA, "r");
	if(fid_input_data == 0)
	begin
		$display("\n\n NO SE PUDO ABRIR ARCHIVO DE INPUT DATA PYTHON");
		$stop;
	end

        //lectura de tags de entrada generados por python
	fid_input_tag = $fopen(PATH_IN_TAG, "r");
        if (fid_input_tag == 0)
        begin
                $display("\n\n NO SE PUDO ABRIR ARCHIVO DE OUTPUT TAG PYTHON");
                $stop;
        end
        
        //lectura de senal fsm_ctrl generada por el fsm de python
	fid_input_ctrl = $fopen(PATH_IN_CTRL, "r");
        if (fid_input_ctrl == 0)
        begin
                $display("\n\n NO SE PUDO ABRIR ARCHIVO DE OUTPUT TAG PYTHON");
                $stop;
        end

        //lectura de datos de salida del simulador en python
	fid_output_data = $fopen(PATH_OUT_DATA, "r");
        if (fid_output_data == 0)
        begin
                $display("\n\n NO SE PUDO ABRIR ARCHIVO DE OUTPUT DATA PYTHON");
                $stop;
        end

        //escritura de salida de datos del modulo en verilog
	fid_verilog_data = $fopen(PATH_VERI_DATA, "w");
        if (fid_verilog_data == 0)
        begin
                $display("\n\n NO SE PUDO ABRIR ARCHIVO DE OUTPUT DATA VERILOG");
                $stop;
        end


	tb_i_clock 		= 0;
	tb_i_reset 		= 1;
	tb_i_enable 		= 0;
	tb_i_valid 		= 0;
	tb_i_data 		= 66'd0;
	tb_enable_files         =0;


	#3 	tb_i_reset  = 0;
	        tb_enable_files = 1;
		tb_i_enable = 1;
		tb_i_valid  = 1;
end

always #1 tb_i_clock= ~tb_i_clock;


always @ (posedge tb_i_clock)
begin
	if(tb_enable_files)
	begin
		//Lectura de datos de entrada generados por python
		for(ptr_data=0; ptr_data < NB_DATA; ptr_data=ptr_data+1)
		begin
			code_error_data <= $fscanf(fid_input_data, "%b\n", temp_data[ptr_data]);
			if(code_error_data != 1)
			begin
				$display("Tx-Data: El caracter leido no es valido..");
               	                $stop;
			end
		end
		
                //lectura de datos de salida del simulador 
		for(ptr_data_py=0; ptr_data_py < NB_DATA; ptr_data_py=ptr_data_py+1)
		begin
			code_error_data_py <= $fscanf(fid_output_data, "%b\n", py_temp_data[ptr_data_py]);
			if(code_error_data_py != 1)
			begin
				$display("Tx-Data: El caracter leido no es valido..");
               	                $stop;
			end
		end

                //lectura de tag de entrada generados por python
		code_error_tag <= $fscanf(fid_input_tag, "%b\n", temp_tag);
		if(code_error_tag != 1)
		begin
			$display("Tx-Tag: El caracter leido no es valido..");
                        $stop;
		end

                //lectura de senial fsm_ctrl de entrada genera por python
		code_error_ctrl <= $fscanf(fid_input_ctrl, "%b\n", temp_ctrl);
		if(code_error_ctrl != 1)
		begin
			$display("Tx-Tag: El caracter leido no es valido..");
                        $stop;
		end

                //escritura de salida del modulo de verilog
		$fwrite(fid_verilog_data, "%b\n", tb_o_data);

                py_output_data    <= py_temp_data;
		tb_i_data         <= temp_data;
		tb_i_tag          <= temp_tag;
                tb_i_fsm_ctrl     <= temp_ctrl;

	end

end
 
clock_comp_rx
        #(
                .NB_DATA        (NB_DATA),
                .AM_BLOCK_PERIOD(AM_BLOCK_PERIOD),
                .N_LANES        (N_LANES)
        )
        u_comp
        (
                .i_clock         (tb_i_clock),
                .i_reset         (tb_i_reset),
                .i_enable        (tb_i_enable),
                .i_valid         (tb_i_valid),
                .i_fsm_control   (tb_i_fsm_ctrl),
                .i_sol_tag       (tb_i_tag),
                .i_data          (tb_i_data),
      
                .o_data          (tb_o_data)
         );

endmodule