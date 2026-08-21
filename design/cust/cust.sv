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
// Last Modified : 2026-08-21 13:02:28
// Description   : Custom execution units
// ----------------------------------------------------------------------

module CUST (
`ifdef SOPHON_EEI
     input logic                                    clk_i
    ,input logic                                    clk_neg_i
    ,input logic                                    rst_ni
    ,input  logic                                   eei_req_i
    ,input  logic                                   eei_ext_i
    ,input  logic [2:0]                             eei_funct3_i
    ,input  logic [6:0]                             eei_funct7_i
    ,input  logic [31:0]                            eei_rs_val_i[SOPHON_PKG::REGFILE_LEN-1:0]
    ,output logic                                   eei_ack_o
    ,output logic                                   eei_error_o
    ,output logic [SOPHON_PKG::REGFILE_LEN-1:0]     eei_rd_idx_onehot_o
    ,output logic [31:0]                            eei_rd_val_o[SOPHON_PKG::REGFILE_LEN-1:0]
`ifdef SOPHON_EEI_GPIO
    ,output logic [`FGPIO_NUM-1:0]                  gpio_dir_o
    ,input  logic [`FGPIO_NUM-1:0]                  gpio_in_val_i
    ,output logic [`FGPIO_NUM-1:0]                  gpio_out_val_o
`endif
`ifdef SOPHON_EEI_VSM
    ,output logic                                   clic_irq_req_o
    ,output logic                                   clic_irq_shv_o
    ,output logic [4:0]                             clic_irq_id_o
    ,output logic [7:0]                             clic_irq_level_o
    ,input  logic                                   clic_irq_ack_i
    ,input  logic [7:0]                             clic_irq_intthresh_i
    ,input  logic                                   clic_mnxti_clr_i
    ,input  logic [4:0]                             clic_mnxti_id_i
`endif
`endif
);



    // ----------------------------------------------------------------------
    //  fast gpio control instruction extention
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EEI_GPIO

        logic               fgpio_req;
        logic               fgpio_ack;
        logic               fgpio_error;
        logic [31:0]        fgpio_rd_val;

        // fgpio uses regular EEI instruction
        assign fgpio_req = eei_req_i & ~eei_ext_i & ( eei_funct3_i==3'b000 ) ;

        FGPIO U_FGPIO (
            .clk_i           ( clk_i          ) ,
            .clk_neg_i       ( clk_neg_i      ) ,
            .rst_ni          ( rst_ni         ) ,
            .fgpio_req       ( fgpio_req      ) ,
            .fgpio_funct7    ( eei_funct7_i   ) ,
            .fgpio_rs_val    ( eei_rs_val_i   ) ,
            .fgpio_ack       ( fgpio_ack      ) ,
            .fgpio_error     ( fgpio_error    ) ,
            .fgpio_rd_val    ( fgpio_rd_val   ) ,
            .gpio_dir        ( gpio_dir_o     ) ,
            .gpio_in_val     ( gpio_in_val_i  ) ,
            .gpio_out_val    ( gpio_out_val_o ) 
        );

    `endif


    // ----------------------------------------------------------------------
    //  virtual state machine instruction extention
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EEI_VSM

        logic               vsm_req;
        logic               vsm_ack;
        logic               vsm_error;
        logic [31:0]        vsm_rd_val;

        assign vsm_req = eei_req_i & ~eei_ext_i & ( eei_funct3_i==3'b001 ) ;

        VSM U_VSM (
             .clk_i                ( clk_i                ) 
            ,.rst_ni               ( rst_ni               ) 
            ,.vsm_req              ( vsm_req              ) 
            ,.vsm_funct7           ( eei_funct7_i         ) 
            ,.vsm_rs_val           ( eei_rs_val_i         ) 
            ,.vsm_ack              ( vsm_ack              ) 
            ,.vsm_error            ( vsm_error            ) 
            ,.vsm_rd_val           ( vsm_rd_val           ) 
            ,.clic_irq_req_o       ( clic_irq_req_o       ) 
            ,.clic_irq_shv_o       ( clic_irq_shv_o       ) 
            ,.clic_irq_id_o        ( clic_irq_id_o        ) 
            ,.clic_irq_level_o     ( clic_irq_level_o     ) 
            ,.clic_irq_ack_i       ( clic_irq_ack_i       ) 
            ,.clic_irq_intthresh_i ( clic_irq_intthresh_i ) 
            ,.clic_mnxti_clr_i     ( clic_mnxti_clr_i     ) 
            ,.clic_mnxti_id_i      ( clic_mnxti_id_i      )
        );

    `endif


    // ----------------------------------------------------------------------
    //  snapshot instruction extention
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EEI_SREG

        logic                               sreg_req;
        logic                               sreg_ack;
        logic                               sreg_error;
        logic [SOPHON_PKG::REGFILE_LEN-1:0] sreg_rd_idx_onehot;
        logic [31:0]                        sreg_rd_val[SOPHON_PKG::REGFILE_LEN-1:0];

        assign sreg_req  = eei_req_i &  eei_ext_i & ( eei_funct3_i==3'b000 ) ;

        SNAPREG U_SNAPREG (
            .clk_i              ( clk_i              ) ,
            .rst_ni             ( rst_ni             ) ,
            .sreg_req           ( sreg_req           ) ,
            .sreg_funct7        ( eei_funct7_i       ) ,
            .sreg_rs_val        ( eei_rs_val_i       ) ,
            .sreg_ack           ( sreg_ack           ) ,
            .sreg_error         ( sreg_error         ) ,
            .sreg_rd_val        ( sreg_rd_val        ) ,
            .sreg_rd_idx_onehot ( sreg_rd_idx_onehot ) 
        );

    `endif


    // ----------------------------------------------------------------------
    //  EEI response
    // ----------------------------------------------------------------------

	`ifdef SOPHON_EEI
		
		always_comb begin
			eei_ack_o   = eei_req_i;
			eei_error_o = 1'b0;
	    `ifdef SOPHON_EEI_GPIO
	    	if ( fgpio_req ) begin
	    		eei_ack_o   = fgpio_ack;
	    		eei_error_o = fgpio_error;
	    	end
	    `endif
	    `ifdef SOPHON_EEI_SREG
	    	if ( sreg_req ) begin
	    		eei_ack_o   = sreg_ack;
	    		eei_error_o = sreg_error;
	    	end
	    `endif
		end

        always_comb begin
        `ifdef SOPHON_EEI_GPIO
        	eei_rd_val_o[0] = fgpio_rd_val;
        `else
        	eei_rd_val_o[0] = 32'd0;
        `endif
        `ifdef SOPHON_EEI_SREG
        	if ( sreg_req )
        		eei_rd_val_o[0] = sreg_rd_val[0];
        `endif
        end

		for (genvar i=1; i<SOPHON_PKG::REGFILE_LEN; i++) begin : gen_cust_rd_val
		    always_comb begin
        	`ifdef SOPHON_EEI_SREG
		    	eei_rd_val_o[i] =  sreg_rd_val[i];
            `else
		    	eei_rd_val_o[i] =  32'd0;
            `endif 
		    `ifdef SOPHON_EEI_YOUR_CUST
		    	if ( your_cust_req & your_cust_rd_idx_onehot[i] )
		    		eei_rd_val_o[i] = your_cust_rd_val[i];
		    `endif
		    end
		end

		always_comb begin
			//eei_rd_idx_onehot_o = sreg_rd_idx_onehot;
			eei_rd_idx_onehot_o = `ifdef SOPHON_EEI_SREG sreg_rd_idx_onehot `else '0 `endif;
		`ifdef SOPHON_EEI_YOUR_CUST
		    if ( your_cust_req )
		    	eei_rd_val_o[i] = your_cust_rd_val[i];
		`endif
		end

	`endif

endmodule
