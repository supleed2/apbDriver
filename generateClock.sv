// V_erilator clock generation module, allows for the clock to be "stepped down" for use within the testbench
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module generateClock
( output var logic        o_clk            // Generated clock for testbench
, input  var logic        i_rootClk        // V_erilator clock input
, input  var logic [63:0] i_periodHi       // Number of rootClk cycles-1 to stay high
, input  var logic [63:0] i_periodLo       // Number of rootClk cycles-1 to stay low
, input  var logic [ 7:0] i_jitterControl  // Random jitter control (0: none --> higher number: more jitter)
);

  logic        intClk_d;
  logic        intClk_q;
  logic [63:0] downCounter_d;
  logic [63:0] downCounter_q;

  /* svlint off legacy_always */
  always @(posedge i_rootClk)
    intClk_q <= intClk_d;
  always @(posedge i_rootClk)
    downCounter_q <= downCounter_d;
  /* svlint on legacy_always */


  logic [7:0] rndJitter;
  always_ff @(posedge i_rootClk)
  /* verilator lint_off WIDTH */
    rndJitter <= $random;
  /* verilator lint_on  WIDTH */

  logic jitterThisCycle;
  assign jitterThisCycle = (rndJitter < i_jitterControl);

  always_comb
    if (downCounter_q == '0)
      if (jitterThisCycle)
        downCounter_d = downCounter_q;
      else if (intClk_q)
        downCounter_d = i_periodLo;
      else
        downCounter_d = i_periodHi;
    else
        downCounter_d = downCounter_q - 'd1;

  always_comb
    if ((downCounter_q == '0) && !jitterThisCycle)
      intClk_d = ~intClk_q;
    else
      intClk_d = intClk_q;

  assign o_clk = intClk_q;

endmodule

`resetall
