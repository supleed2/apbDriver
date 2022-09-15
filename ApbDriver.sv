// Synthesizable DPI-C driver for APB Bus Interface
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Example Usage:

// ### test_DUT.sv (Instance) ###
// ApbDriver
// #(.APB_AW (32)
// , .APB_DW (32)
// , .APB_SW ( 4)
// ) u_apbDriver
// ( .ckApb      (apbBus.ckApb     )
// , .apbPRData  (apbBus.apbPRData )
// , .apbPReady  (apbBus.apbPReady )
// , .apbPSlvErr (apbBus.apbPSlvErr)
// , .apbPSel    (apbBus.apbPSel   )
// , .apbPEnable (apbBus.apbPEnable)
// , .apbPAddr   (apbBus.apbPAddr  )
// , .apbPWrite  (apbBus.apbPWrite )
// , .apbPWData  (apbBus.apbPWData )
// , .apbPStrb   (apbBus.apbPStrb  )
// , .apbPProt   (apbBus.apbPProt  )
// );

// ### test_DUT.cpp (Setup) ###
// #include <Vtest_DUT__Dpi.h>
// EITHER: VerilatorTbFst<Vtest_DUT>* tb = new VerilatorTbFst<Vtest_DUT>();
// OR    : VerilatorTbVcd<Vtest_DUT>* tb = new VerilatorTbVcd<Vtest_DUT>();
// tb->setScope("test_DUT.u_apbDriver");

// ### test_DUT.cpp (Usage) ###
// uint32_t addr = 0x0100, data = 0x1234, strb = 0b1111, prot = 0b110;
// int err = 0;
// uint8_t SlvErr = 0;
// uint32_t readData = 0;
// err = tryStartApbWrite(&addr, &data, &strb, &prot);
// if (err != 0) { printf("tryStartApbWrite failed!\n"); }
// else {
//   tb->ticks(2);
//   err = tryFinishApbWrite(&SlvErr);
//   while (err != 0) {
//     printf("tryFinishApbWrite failed!\n");
//     tb->tick();
//     err = tryFinishApbWrite(&SlvErr);
//   }
//   if (SlvErr != 0) { printf("Apb Write failed!\n"); }
// }
// tb->tick();
// err = tryStartApbRead(&addr, &prot);
// if (err != 0) { printf("tryStartApbRead failed!\n"); }
// else {
//   tb->ticks(2);
//   err = tryFinishApbRead(&SlvErr, &readData);
//   while (err != 0) {
//     printf("tryFinishApbRead failed!\n");
//     tb->tick();
//     err = tryFinishApbRead(&SlvErr, &readData);
//   }
//   if (SlvErr != 0) { printf("Apb Read failed!\n"); }
//   else { printf("Apb Read succeeded!\nExpected Read Data: 0x%x\nReceived Read Data: 0x%x\n", data, readData); }
// }
// tb->tick();

module ApbDriver
#(parameter  int unsigned APB_AW = 32       // APB Address Width
, parameter  int unsigned APB_DW = 32       // APB Data Width
, parameter  int unsigned APB_SW = APB_DW/8 // APB Write Strobe Width
)(input  var logic              ckApb       // -- Inputs to Driver
, input  var logic [APB_DW-1:0] apbPRData
, input  var logic              apbPReady
, input  var logic              apbPSlvErr
, output var logic              apbPSel     // -- Outputs from Driver
, output var logic              apbPEnable
, output var logic [APB_AW-1:0] apbPAddr
, output var logic              apbPWrite
, output var logic [APB_DW-1:0] apbPWData
, output var logic [APB_SW-1:0] apbPStrb
, output var logic        [2:0] apbPProt
);

  // Delay-based version, does not allow for other accesses in C++ testbench
  // while task is running, synthesizable version below is preferred
  /*
  export "DPI-C" task apbRead;
  export "DPI-C" task apbWrite;

  logic trComplete;
  assign trComplete = ckApb & apbPReady;

  task automatic apbRead (input bit [APB_AW-1:0] addr, input bit [2:0] prot, output bit SlvErr, output bit [APB_DW-1:0] RData);
    @(posedge ckApb);
    apbPSel    = '1;
    apbPEnable = '0;
    apbPAddr   = addr;
    apbPWrite  = '0;
    apbPStrb   = '0;
    apbPProt   = prot;

    @(posedge ckApb);
    apbPEnable = '1;

    @(posedge trComplete);
    apbPSel = '0;
    RData   = apbPRData;
    SlvErr  = apbPSlvErr;
  endtask

  task automatic apbWrite (input bit [APB_AW-1:0] addr, input bit [APB_DW-1:0] data, input bit [APB_SW-1:0] strb, input bit [2:0] prot, output bit SlvErr);
    @(posedge ckApb);
    apbPSel    = '1;
    apbPEnable = '0;
    apbPAddr   = addr;
    apbPWrite  = '1;
    apbPWData  = data;
    apbPStrb   = strb;
    apbPProt   = prot;

    @(posedge ckApb);
    apbPEnable = '1;

    @(posedge trComplete);
    apbPSel = '0;
    SlvErr = apbPSlvErr;
  endtask
  */

  // Returns 0 if complete and -1 if bus was busy / not ready yet
  export "DPI-C" function tryStartApbRead;
  export "DPI-C" function tryStartApbWrite;
  export "DPI-C" function tryFinishApbRead;
  export "DPI-C" function tryFinishApbWrite;

  enum bit [2:0]
  { IDLE
  , R_SETUP
  , R_ACCESS
  , W_SETUP
  , W_ACCESS
  } apbState;

  enum bit [1:0]
  { n_NONE
  , n_IDLE
  , n_READ
  , n_WRITE
  } nextState;

  logic [APB_AW-1:0] nextAddr;
  logic [APB_DW-1:0] nextWData;
  logic [APB_SW-1:0] nextStrb;
  logic        [2:0] nextProt;

  always_ff @(posedge ckApb) // apbPSel
    case (apbState)
      IDLE:     apbPSel <= '0;
      R_SETUP:  apbPSel <= '1;
      R_ACCESS: apbPSel <= '1;
      W_SETUP:  apbPSel <= '1;
      W_ACCESS: apbPSel <= '1;
      default:  apbPSel <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPEnable
    case (apbState)
      IDLE:     apbPEnable <= '0;
      R_SETUP:  apbPEnable <= '0;
      R_ACCESS: apbPEnable <= '1;
      W_SETUP:  apbPEnable <= '0;
      W_ACCESS: apbPEnable <= '1;
      default:  apbPEnable <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPAddr
    case (apbState)
      IDLE:     apbPAddr <= '0;
      R_SETUP:  apbPAddr <= nextAddr;
      R_ACCESS: apbPAddr <= nextAddr;
      W_SETUP:  apbPAddr <= nextAddr;
      W_ACCESS: apbPAddr <= nextAddr;
      default:  apbPAddr <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPWrite
    case (apbState)
      IDLE:     apbPWrite <= '0;
      R_SETUP:  apbPWrite <= '0;
      R_ACCESS: apbPWrite <= '0;
      W_SETUP:  apbPWrite <= '1;
      W_ACCESS: apbPWrite <= '1;
      default:  apbPWrite <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPWData
    case (apbState)
      IDLE:     apbPWData <= '0;
      R_SETUP:  apbPWData <= '0;
      R_ACCESS: apbPWData <= '0;
      W_SETUP:  apbPWData <= nextWData;
      W_ACCESS: apbPWData <= nextWData;
      default:  apbPWData <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPStrb
    case (apbState)
      IDLE:     apbPStrb <= '0;
      R_SETUP:  apbPStrb <= '0;
      R_ACCESS: apbPStrb <= '0;
      W_SETUP:  apbPStrb <= nextStrb;
      W_ACCESS: apbPStrb <= nextStrb;
      default:  apbPStrb <= '0;
    endcase

  always_ff @(posedge ckApb) // apbPProt
    case (apbState)
      IDLE:     apbPProt <= '0;
      R_SETUP:  apbPProt <= nextProt;
      R_ACCESS: apbPProt <= nextProt;
      W_SETUP:  apbPProt <= nextProt;
      W_ACCESS: apbPProt <= nextProt;
      default:  apbPProt <= '0;
    endcase

  always_ff @(posedge ckApb) // apbState
    case (apbState)
      IDLE:     if (nextState == n_READ)       apbState <= R_SETUP;
                else if (nextState == n_WRITE) apbState <= W_SETUP;
                else                           apbState <= IDLE;
      R_SETUP:                                 apbState <= R_ACCESS;
      R_ACCESS: if (nextState == n_IDLE)       apbState <= IDLE;
                else                           apbState <= R_ACCESS;
      W_SETUP:                                 apbState <= W_ACCESS;
      W_ACCESS: if (nextState == n_IDLE)       apbState <= IDLE;
                else                           apbState <= W_ACCESS;
      default:                                 apbState <= IDLE;
    endcase

  function automatic int tryStartApbRead (input bit [APB_AW-1:0] addr, input bit [2:0] prot);
    if (apbState == IDLE && (nextState == n_NONE || nextState == n_IDLE)) begin
      nextAddr   = addr;
      nextWData  = '0;
      nextStrb   = '0;
      nextProt   = prot;
      nextState  = n_READ;
      return 0;
    end else
      return -1;
  endfunction

  function automatic int tryStartApbWrite (input bit [APB_AW-1:0] addr, input bit [APB_DW-1:0] data, input bit [APB_SW-1:0] strb, input bit [2:0] prot);
    if (apbState == IDLE && (nextState == n_NONE || nextState == n_IDLE)) begin
      nextAddr   = addr;
      nextWData  = data;
      nextStrb   = strb;
      nextProt   = prot;
      nextState  = n_WRITE;
      return 0;
    end else
      return -1;
  endfunction

  function automatic int tryFinishApbRead (output bit SlvErr, output bit [APB_DW-1:0] RData);
    if (apbState == R_ACCESS && apbPReady) begin
      nextAddr   = '0;
      nextWData  = '0;
      nextStrb   = '0;
      nextProt   = '0;
      SlvErr     = apbPSlvErr;
      RData      = apbPRData;
      nextState  = n_IDLE;
      return 0;
    end else
      return -1;
  endfunction

  function automatic int tryFinishApbWrite (output bit SlvErr);
    if (apbState == W_ACCESS && apbPReady) begin
      nextAddr   = '0;
      nextWData  = '0;
      nextStrb   = '0;
      nextProt   = '0;
      SlvErr     = apbPSlvErr;
      nextState  = n_IDLE;
      return 0;
    end else
      return -1;
  endfunction

endmodule

`resetall
