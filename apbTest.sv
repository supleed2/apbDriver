// SystemVerilog testbench to instantiate Driver and Slave modules
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/* verilator lint_off UNUSED */
module apbTest
( input var logic i_clk
, input var logic i_rst
, input var logic i_arst
);

  localparam int unsigned AddrWidth = 12;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned StrbWidth =  4;

  logic i_rst_n;
  assign i_rst_n = !i_rst;

  logic o_ck;
  assign apbBus.ckApb = o_ck;

  apbSlave
  #(.AWIDTH   (AddrWidth        )
  , .DWIDTH   (DataWidth        )
  , .SWIDTH   (StrbWidth        )
  ) u_apbSlave
  ( .i_ck     (apbBus.ckApb     )
  , .i_rst_n  (i_rst_n          )
  , .i_sel    (apbBus.apbPSel   )
  , .i_enable (apbBus.apbPEnable)
  , .i_addr   (apbBus.apbPAddr  )
  , .i_write  (apbBus.apbPWrite )
  , .i_wdata  (apbBus.apbPWData )
  , .i_strb   (apbBus.apbPStrb  )
  , .i_prot   (apbBus.apbPProt  )
  , .o_rdata  (apbBus.apbPRData )
  , .o_ready  (apbBus.apbPReady )
  , .o_slverr (apbBus.apbPSlvErr)
  );

  generateClock u_generateClock
  ( .o_clk           (o_ck ) // Generated clock for testbench
  , .i_rootClk       (i_clk) // V_erilator clock input
  , .i_periodHi      (0    ) // Number of rootClk cycles-1 to stay high
  , .i_periodLo      (0    ) // Number of rootClk cycles-1 to stay low
  , .i_jitterControl (0    ) // Random jitter control (0: none --> higher number: more jitter)
  );

  in_ApbBus
  #(.APB_DW (DataWidth)
  , .APB_AW (AddrWidth)
  ) apbBus ();

  ApbDriver
  #(.APB_AW     (AddrWidth        )
  , .APB_DW     (DataWidth        )
  , .APB_SW     (StrbWidth        )
  ) u_apbDriver
  ( .ckApb      (apbBus.ckApb     )
  , .apbPRData  (apbBus.apbPRData )
  , .apbPReady  (apbBus.apbPReady )
  , .apbPSlvErr (apbBus.apbPSlvErr)
  , .apbPSel    (apbBus.apbPSel   )
  , .apbPEnable (apbBus.apbPEnable)
  , .apbPAddr   (apbBus.apbPAddr  )
  , .apbPWrite  (apbBus.apbPWrite )
  , .apbPWData  (apbBus.apbPWData )
  , .apbPStrb   (apbBus.apbPStrb  )
  , .apbPProt   (apbBus.apbPProt  )
  );
endmodule
/* verilator lint_on UNUSED */

`resetall
