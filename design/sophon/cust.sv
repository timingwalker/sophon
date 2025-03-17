// ----------------------------------------------------------------------
// Copyright 2023 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
// Create Date   : 2023-01-11 16:52:34
// Last Modified : 2025-03-14 14:56:10
// Description   : Custom execution units
// ----------------------------------------------------------------------

module CUST(
     input logic                            clk_i
    ,input logic                            clk_neg_i
    ,input logic                            rst_ni
`ifdef SOPHON_EEI
    // eei interface
    ,input  logic                           eei_req
    ,input  logic                           eei_ext
    ,input  logic [2:0]                     eei_funct3
    ,input  logic [6:0]                     eei_funct7
    ,input  logic [4:0]                     eei_batch_start
    ,input  logic [4:0]                     eei_batch_len
    ,output logic [4:0]                     eei_rd_len  // if eei_rd_op=2, indicate write back rd number
    ,input  logic [31:0]                    eei_rs_val[`EEI_RS_MAX-1:0]
    ,output logic                           eei_ack  
    ,output logic [1:0]                     eei_rd_op   // 0: don't write rd
                                                        // 1: write single rd
                                                        // 2: batch write rd
                                                        // TBD: merge this signal with eei_rd_len
    ,output logic                           eei_error
    ,output logic [31:0]                    eei_rd_val[`EEI_RD_MAX-1:0]
`endif
`ifdef SOPHON_EEI_GPIO
    // gpio interface 
    ,output logic [`FGPIO_NUM-1:0]          gpio_dir
    ,input  logic [`FGPIO_NUM-1:0]          gpio_in_val
    ,output logic [`FGPIO_NUM-1:0]          gpio_out_val
`endif

);



    // ----------------------------------------------------------------------
    //  fast gpio control instruction extention
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EEI_GPIO

        logic               fgpio_req;
        logic               fgpio_ack;
        logic               fgpio_error;
        logic [31:0]        fgpio_rd_val[`EEI_RD_MAX-1:0];

        // fgpio uses both regular EEI and enhanced EEI instructions
        assign fgpio_req = eei_req & ( eei_funct3==3'b000 ) ;

        FGPIO U_FGPIO (
            .clk_i           ( clk_i         ) ,
            .clk_neg_i       ( clk_neg_i     ) ,
            .rst_ni          ( rst_ni        ) ,
            .eei_ext         ( eei_ext       ) ,
            .fgpio_req       ( fgpio_req     ) ,
            .fgpio_funct7    ( eei_funct7    ) ,
            .fgpio_batch_len ( eei_batch_len ) ,
            .fgpio_rs_val    ( eei_rs_val    ) ,
            .fgpio_ack       ( fgpio_ack     ) ,
            .fgpio_error     ( fgpio_error   ) ,
            .fgpio_rd_val    ( fgpio_rd_val  ) ,
            .gpio_dir        ( gpio_dir      ) ,
            .gpio_in_val     ( gpio_in_val   ) ,
            .gpio_out_val    ( gpio_out_val  ) 
        );

    `endif


    // ----------------------------------------------------------------------
    //  snapshot instruction extention
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EEI_SREG

        logic               sreg_req;
        logic               sreg_ack;
        logic               sreg_error;
        logic [31:0]        sreg_rd_val[`EEI_RD_MAX-1:0];

        assign sreg_req  = eei_req &  eei_ext & ( eei_funct3==3'b001 ) ;
        //assign sreg_req  = eei_req &  eei_ext & ( eei_funct3==3'b000 ) ;

        SNAPREG U_SNAPREG (
            .clk_i              ( clk_i           ) ,
            .rst_ni             ( rst_ni          ) ,
            .sreg_req           ( sreg_req        ) ,
            .sreg_funct7        ( eei_funct7      ) ,
            .sreg_batch_start   ( eei_batch_start ) ,
            .sreg_batch_len     ( eei_batch_len   ) ,
            .sreg_rs_val        ( eei_rs_val      ) ,
            .sreg_ack           ( sreg_ack        ) ,
            .sreg_error         ( sreg_error      ) ,
            .sreg_rd_val        ( sreg_rd_val     ) 
        );

    `endif


    // ----------------------------------------------------------------------
    //  EEI response
    // ----------------------------------------------------------------------

	`ifdef SOPHON_EEI
		
		always_comb begin
			eei_ack   = eei_req;
			eei_error = 1'b0;
			`ifdef SOPHON_EEI_GPIO
				if ( fgpio_req ) begin
					eei_ack   = fgpio_ack;
					eei_error = fgpio_error;
				end
			`endif
			`ifdef SOPHON_EEI_SREG
				if ( sreg_req ) begin
					eei_ack   = sreg_ack;
					eei_error = sreg_error;
				end
			`endif
		end

		for (genvar i=0; i<`EEI_RD_MAX; i++) begin : gen_cust_rd_val
            // TODO: 
			`ifdef SOPHON_EEI_GPIO
                assign eei_rd_val[i]=fgpio_rd_val[i];
            `else
                assign eei_rd_val[i]='0;
            `endif
			// if ( i==0 ) begin: gen_cust_rd0
			// 	always_comb begin
			// 		eei_rd_val[i] = 32'd0;
			// 		`ifdef SOPHON_EEI_GPIO
			// 			if ( fgpio_req )
			// 				eei_rd_val[i] = fgpio_rd_val[i];
			// 		`endif
			// 		`ifdef SOPHON_EEI_SREG
			// 			if ( sreg_req )
			// 				eei_rd_val[i] = sreg_rd_val[i];
			// 		`endif
			// 	end
			// end
			// else begin: gen_cust_rd_extend
			// 	always_comb begin
			// 		eei_rd_val[i] = 32'd0;
			// 		`ifdef SOPHON_EEI_GPIO
			// 			if ( fgpio_req )
			// 				eei_rd_val[i] = fgpio_rd_val[i];
			// 		`endif
			// 		`ifdef SOPHON_EEI_SREG
			// 			if ( sreg_req )
			// 				eei_rd_val[i] = sreg_rd_val[i];
			// 		`endif
			// 	end
			// end
		end

		always_comb begin
			eei_rd_op  = 2'd0;
			eei_rd_len = 5'd0;
			`ifdef SOPHON_EEI_GPIO
				if (fgpio_req & ~eei_ext) 
					eei_rd_op = 2'd1;
				else if (fgpio_req & eei_ext) begin
					eei_rd_op = 2'd3;
					eei_rd_len = eei_batch_len;
				end
			`endif
			`ifdef SOPHON_EEI_SREG
				if (sreg_req ) begin
					if (eei_funct7[6]==1'b1) begin
						eei_rd_op = 2'd2;
						eei_rd_len = eei_batch_len;
					end
					else
						eei_rd_op = 2'd0;
				end
			`endif
		end

	`endif

endmodule
