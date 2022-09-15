// Example APB Slave for testing APB Driver module
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/* verilator lint_off UNUSED */
module apbSlave
#(parameter int AWIDTH = 12
, parameter int DWIDTH = 32
, parameter int SWIDTH = DWIDTH/8
)(input  var logic              i_ck
, input  var logic              i_rst_n
, input  var logic              i_sel
, input  var logic              i_enable
, input  var logic [AWIDTH-1:0] i_addr
, input  var logic              i_write
, input  var logic [DWIDTH-1:0] i_wdata
, input  var logic [SWIDTH-1:0] i_strb
, input  var logic        [2:0] i_prot
, output var logic [DWIDTH-1:0] o_rdata
, output var logic              o_ready
, output var logic              o_slverr
);

  logic [DWIDTH-1:0] mem [4096];
  logic [DWIDTH-1:0] wdata;
  for (genvar i = 0; i < SWIDTH; i++) begin
    assign wdata[8*i+7:8*i] = i_strb[i] ? i_wdata[8*i+7:8*i] : mem[i_addr][8*i+7:8*i];
  end

  enum bit [1:0]
  { SETUP
  , WRITE
  , READ
  } STATE;

  always_comb
    case (STATE)
      SETUP: begin
        o_rdata  = '0;
        o_ready  = '0;
        o_slverr = '0;
      end
      WRITE: begin
        o_rdata  = '0;
        o_ready  = '1;
        o_slverr = '0;
      end
      READ: begin
        o_rdata  = mem[i_addr];
        o_ready  = '1;
        o_slverr = '0;
      end
      default: begin end
    endcase

  always_ff @(posedge i_ck)
    if (i_rst_n == 0)
      STATE <= SETUP;
    else if (i_sel == 0)
      STATE <= SETUP;
    else
      if (i_write == 0)
        STATE <= READ;
      else
        STATE <= WRITE;

  always_ff @(negedge i_ck)
    if (STATE == WRITE) mem[i_addr] <= wdata;
    else                mem[i_addr] <= mem[i_addr];
endmodule
/* verilator lint_on UNUSED */

`resetall
