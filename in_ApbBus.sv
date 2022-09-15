// Interface for APB, no modports were used
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/* verilator lint_off UNUSED */
interface in_ApbBus;
  event                   transactionReady;        //
  event                   transactionComplete;     //
  parameter  int unsigned APB_AW       = 32;       // APB Address Width
  parameter  int unsigned APB_DW       = 32;       // APB Data Width
  parameter  int unsigned APB_SW       = APB_DW/8; // APB Write Strobe Width
  parameter  int unsigned APB_AUSER    = 0;        // Address User Width, set to 0 when unused
  localparam int unsigned APB_AU_BITS  = (APB_AUSER == 0) ? 1 : APB_AUSER; // Number of bits in address user (auto-computed, do not override)
  logic                   arstApb_n;  //
  logic                   ckApb;      //
  logic      [APB_AW-1:0] apbPAddr;   //
  logic             [2:0] apbPProt;   //
  logic                   apbPSel;    //
  logic                   apbPEnable; //
  logic                   apbPWrite;  //
  logic      [APB_DW-1:0] apbPWData;  //
  logic      [APB_SW-1:0] apbPStrb;   //
  logic [APB_AU_BITS-1:0] apbPAUser;  //
  logic      [APB_DW-1:0] apbPRData;  //
  logic                   apbPSlvErr; //
  logic                   apbPReady;  //
endinterface
/* verilator lint_on UNUSED */

`resetall
