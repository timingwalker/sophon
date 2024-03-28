
module debugger#(
	parameter CC_NUM = 2
)
(
	input           tck,
	input           tms,
	input           trst_n,
	input           tdi,
	output          tdo,
	output          tdo_oe,

	output [CC_NUM-1:0] debug_req,

    output CC_ITF_PKG::xbar_slv_port_d64_req_t    axi_sba_mst_req,
    input  CC_ITF_PKG::xbar_slv_port_d64_resps_t  axi_sba_mst_resp,

    input  CC_ITF_PKG::xbar_mst_port_d64_req_t    axi_dbg_slv_req,
    output CC_ITF_PKG::xbar_mst_port_d64_resps_t  axi_dbg_slv_resp,

	input clk_i,
	input rst_ni
);


    wire          dmi_rst_n;
    dm::dmi_req_t dmi_req;
    wire          dmi_req_valid;
    wire          dmi_req_ready;
    dm::dmi_resp_t dmi_resp;
    wire           dmi_resp_ready;
    wire           dmi_resp_valid;
    
    wire            slave_req_i;
    wire            slave_we_i;
    wire [64-1:0]   slave_addr_i;
    wire [64/8-1:0] slave_be_i;
    wire [64-1:0]   slave_wdata_i;
    wire [64-1:0]   slave_rdata_o;
    
    wire            master_req_o;
    wire [64-1:0]   master_add_o;
    wire            master_we_o;
    wire [64-1:0]   master_wdata_o;
    wire [64/8-1:0] master_be_o;
    wire            master_gnt_i;
    wire            master_r_valid_i;
    wire            master_r_err_i;
    wire            master_r_other_err_i;
    wire [64-1:0]   master_r_rdata_i;


    dmi_jtag i_dtm (
        .clk_i            ( clk_i          ) ,
        .rst_ni           ( rst_ni         ) ,
        .testmode_i       ( 1'b0           ) ,
        .dmi_rst_no       ( dmi_rst_n      ) ,
        .dmi_req_o        ( dmi_req        ) ,
        .dmi_req_valid_o  ( dmi_req_valid  ) ,
        .dmi_req_ready_i  ( dmi_req_ready  ) ,
        .dmi_resp_i       ( dmi_resp       ) ,
        .dmi_resp_ready_o ( dmi_resp_ready ) ,
        .dmi_resp_valid_i ( dmi_resp_valid ) ,
        .tck_i            ( tck            ) ,
        .tms_i            ( tms            ) ,
        .trst_ni          ( trst_n         ) ,
        .td_i             ( tdi            ) ,
        .td_o             ( tdo            ) ,
        .tdo_oe_o         ( tdo_oe         ) 
    );
    
    
    dm_top #(
        .NrHarts(CC_NUM),
        .BusWidth(64),
        .DmBaseAddress('h0)
    ) i_dm(
        .clk_i                ( clk_i                ) ,
        .rst_ni               ( rst_ni               ) ,
        .testmode_i           ( 1'b0                 ) ,
        .ndmreset_o           (                      ) ,  // non-debug module reset
        .dmactive_o           (                      ) ,
        .debug_req_o          ( debug_req            ) ,
        .unavailable_i        ( '0                   ) ,
        .hartinfo_i           ( '0                   ) ,
        .slave_req_i          ( slave_req_i          ) ,
        .slave_we_i           ( slave_we_i           ) ,
        .slave_addr_i         ( slave_addr_i         ) ,
        .slave_be_i           ( slave_be_i           ) ,
        .slave_wdata_i        ( slave_wdata_i        ) ,
        .slave_rdata_o        ( slave_rdata_o        ) ,
        .master_req_o         ( master_req_o         ) ,
        .master_add_o         ( master_add_o         ) ,
        .master_we_o          ( master_we_o          ) ,
        .master_wdata_o       ( master_wdata_o       ) ,
        .master_be_o          ( master_be_o          ) ,
        .master_gnt_i         ( master_gnt_i         ) ,
        .master_r_valid_i     ( master_r_valid_i     ) ,
        .master_r_err_i       ( master_r_err_i       ) ,
        .master_r_other_err_i ( master_r_other_err_i ) ,
        .master_r_rdata_i     ( master_r_rdata_i     ) ,
        .dmi_rst_ni           ( dmi_rst_n            ) ,
        .dmi_req_valid_i      ( dmi_req_valid        ) ,
        .dmi_req_ready_o      ( dmi_req_ready        ) ,
        .dmi_req_i            ( dmi_req              ) ,
        .dmi_resp_valid_o     ( dmi_resp_valid       ) ,
        .dmi_resp_ready_i     ( dmi_resp_ready       ) ,
        .dmi_resp_o           ( dmi_resp             ) 
    );


	AXI_BUS #(
    .AXI_ADDR_WIDTH ( CC_ITF_PKG::XBAR_ADDR_WIDTH        ) ,
    .AXI_DATA_WIDTH ( CC_ITF_PKG::XBAR_DATA_WIDTH        ) ,
    .AXI_ID_WIDTH   ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH ) ,
    .AXI_USER_WIDTH ( CC_ITF_PKG::XBAR_USER_WIDTH        ) 
    ) master();



	assign master.aw_id              = axi_dbg_slv_req.aw.id;
	assign master.aw_addr            = axi_dbg_slv_req.aw.addr;
	assign master.aw_len             = axi_dbg_slv_req.aw.len;
	assign master.aw_size            = axi_dbg_slv_req.aw.size;
	assign master.aw_burst           = axi_dbg_slv_req.aw.burst;
	assign master.aw_lock            = axi_dbg_slv_req.aw.lock;
	assign master.aw_cache           = axi_dbg_slv_req.aw.cache;
	assign master.aw_prot            = axi_dbg_slv_req.aw.prot;
	assign master.aw_qos             = axi_dbg_slv_req.aw.qos;
	assign master.aw_region          = axi_dbg_slv_req.aw.region;
	assign master.aw_atop            = axi_dbg_slv_req.aw.atop;
	assign master.aw_user            = axi_dbg_slv_req.aw.user;
	assign master.aw_valid           = axi_dbg_slv_req.aw_valid;
	assign master.w_data             = axi_dbg_slv_req.w.data;
	assign master.w_strb             = axi_dbg_slv_req.w.strb;
	assign master.w_last             = axi_dbg_slv_req.w.last;
	assign master.w_user             = axi_dbg_slv_req.w.user;
	assign master.w_valid            = axi_dbg_slv_req.w_valid;
	assign master.b_ready            = axi_dbg_slv_req.b_ready;
	assign master.ar_id              = axi_dbg_slv_req.ar.id;
	assign master.ar_addr            = axi_dbg_slv_req.ar.addr;
	assign master.ar_len             = axi_dbg_slv_req.ar.len;
	assign master.ar_size            = axi_dbg_slv_req.ar.size;
	assign master.ar_burst           = axi_dbg_slv_req.ar.burst;
	assign master.ar_lock            = axi_dbg_slv_req.ar.lock;
	assign master.ar_cache           = axi_dbg_slv_req.ar.cache;
	assign master.ar_prot            = axi_dbg_slv_req.ar.prot;
	assign master.ar_qos             = axi_dbg_slv_req.ar.qos;
	assign master.ar_region          = axi_dbg_slv_req.ar.region;
	assign master.ar_user            = axi_dbg_slv_req.ar.user;
	assign master.ar_valid           = axi_dbg_slv_req.ar_valid;
	assign master.r_ready            = axi_dbg_slv_req.r_ready;

    
	assign axi_dbg_slv_resp.aw_ready = master.aw_ready;
	assign axi_dbg_slv_resp.ar_ready = master.ar_ready;
	assign axi_dbg_slv_resp.w_ready  = master.w_ready;
	assign axi_dbg_slv_resp.b_valid  = master.b_valid;
	assign axi_dbg_slv_resp.b.id     = master.b_id;
	assign axi_dbg_slv_resp.b.resp   = master.b_resp;
	assign axi_dbg_slv_resp.b.user   = master.b_user;
	assign axi_dbg_slv_resp.r_valid  = master.r_valid;
	assign axi_dbg_slv_resp.r.id     = master.r_id;
	assign axi_dbg_slv_resp.r.data   = master.r_data;
	assign axi_dbg_slv_resp.r.resp   = master.r_resp;
	assign axi_dbg_slv_resp.r.last   = master.r_last;
	assign axi_dbg_slv_resp.r.user   = master.r_user;


    axi2mem #(
        .AXI_ID_WIDTH   ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH ) ,
        .AXI_ADDR_WIDTH ( CC_ITF_PKG::XBAR_ADDR_WIDTH        ) ,
        .AXI_DATA_WIDTH ( CC_ITF_PKG::XBAR_DATA_WIDTH        ) ,
        .AXI_USER_WIDTH ( CC_ITF_PKG::XBAR_USER_WIDTH        ) 
    ) i_dm_axi2mem (
        .clk_i      ( clk_i              ) ,
        .rst_ni     ( rst_ni             ) ,
        .slave      ( master             ) ,
        .req_o      ( slave_req_i        ) ,
        .we_o       ( slave_we_i         ) ,
        .addr_o     ( slave_addr_i[31:0] ) ,
        .be_o       ( slave_be_i         ) ,
        .user_o     (                    ) ,
        .data_o     ( slave_wdata_i      ) ,
        .user_i     ( '0                 ) ,
        .data_i     ( slave_rdata_o      ) 
    );

    axi_adapter #(
        .DATA_WIDTH            ( CC_ITF_PKG::XBAR_DATA_WIDTH        ) ,
        .AXI_ID_WIDTH          ( CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH ) 
    ) i_dm_axi_master (
        .clk_i                 ( clk_i                  ) ,
        .rst_ni                ( rst_ni                 ) ,
        .req_i                 ( master_req_o           ) ,
        .type_i                ( CC_ITF_PKG::SINGLE_REQ ) ,
        .amo_i                 ( CC_ITF_PKG::AMO_NONE   ) ,
        .gnt_o                 ( master_gnt_i           ) ,
        .addr_i                ( master_add_o           ) ,
        .we_i                  ( master_we_o            ) ,
        .wdata_i               ( master_wdata_o         ) ,
        .be_i                  ( master_be_o            ) ,
        .size_i                ( 2'b11                  ) , // always do 64bit here and use byte enables to gate
        .id_i                  ( '0                     ) ,
        .valid_o               ( master_r_valid_i       ) ,
        .rdata_o               ( master_r_rdata_i       ) ,
        .id_o                  (                        ) ,
        .critical_word_o       (                        ) ,
        .critical_word_valid_o (                        ) ,
        .axi_req_o             ( axi_sba_mst_req        ) ,
        .axi_resp_i            ( axi_sba_mst_resp       ) 
    );


endmodule

