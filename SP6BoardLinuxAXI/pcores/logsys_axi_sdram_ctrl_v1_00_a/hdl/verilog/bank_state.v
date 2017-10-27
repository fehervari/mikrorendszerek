//******************************************************************************
//* SDRAM bank state module.                                                   *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 2.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module bank_state #(
   //SDRAM timing parameters.
   parameter SDRAM_T_RC_PS      = 66000,        //RAS to RAS delay in ps
   parameter SDRAM_T_RAS_MIN_PS = 42000,        //Min. row active time in ps
   
   //System clock parameters.
   parameter SYSCLK_PERIOD_PS   = 10000         //System clock period in ps
) (
   //System clock signal.
   input  wire        clk,
   
   //SDRAM address signals.
   input  wire [1:0]  sdram_bank_addr,          //SDRAM bank address
   input  wire [12:0] sdram_row_addr,           //SDRAM row address

   //Input control signals.
   input  wire        precharge_all,            //A precharge all command has been issued
   input  wire        precharge_row,            //A precharge command has been issued
   input  wire        activate_row,             //An activate row command has been issued
   
   //Output signals.
   output reg         row_active,               //A row is active in the selected bank
   output wire        row_addr_match,           //Row address match in the selected bank
   output reg         tras_done,                //Tras has been elapsed for the selected bank
   output wire        tras_all_done,            //Tras has been elapsed for all banks
   output reg         trc_done                  //Trc has been elapsed for the selected bank
);

`include "functions.vh"

//******************************************************************************
//* Register that stores the state of the SDRAM banks.                         *
//* 0: the given bank is not activated.                                        *
//* 1: a row in the given bank is activated.                                   *
//******************************************************************************
reg [3:0] bank_state;

integer i;

always @(posedge clk)
begin
   for (i = 0; i < 4; i = i + 1)
      if (precharge_all || (precharge_row && (sdram_bank_addr == i)))
         bank_state[i] <= 1'b0;
      else
         if (activate_row && (sdram_bank_addr == i))
            bank_state[i] <= 1'b1;
end

always @(*)
begin
   case (sdram_bank_addr)
      2'b00: row_active <= bank_state[0];
      2'b01: row_active <= bank_state[1];
      2'b10: row_active <= bank_state[2];
      2'b11: row_active <= bank_state[3];
   endcase
end


//******************************************************************************
//* RAM that stores the address of the activated SDRAM rows.                   *
//******************************************************************************
(* ram_style = "distributed" *)
reg [12:0] row_addr_reg [3:0];

always @(posedge clk)
begin
   if (activate_row)
      row_addr_reg[sdram_bank_addr] <= sdram_row_addr;
end

assign row_addr_match = (row_addr_reg[sdram_bank_addr] == sdram_row_addr);


//******************************************************************************
//* Bank active timers.                                                        *
//******************************************************************************
localparam RAS_TIMER_MAX = (SDRAM_T_RAS_MIN_PS + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam RAS_TIMER_LEN = log2(RAS_TIMER_MAX);

reg [RAS_TIMER_LEN-1:0] ras_tmr [3:0];

always @(posedge clk)
begin
   for (i = 0; i < 4; i = i + 1)
      if (activate_row && (sdram_bank_addr == i))
         ras_tmr[i] <= RAS_TIMER_MAX - 1;
      else
         if (ras_tmr[i] != 0)
            ras_tmr[i] <= ras_tmr[i] - 1;
end

always @(*)
begin
   case (sdram_bank_addr)
      2'b00: tras_done <= (ras_tmr[0] == 0);
      2'b01: tras_done <= (ras_tmr[1] == 0);
      2'b10: tras_done <= (ras_tmr[2] == 0);
      2'b11: tras_done <= (ras_tmr[3] == 0);
   endcase
end

assign tras_all_done = (ras_tmr[0] == 0) & (ras_tmr[1] == 0) &
                       (ras_tmr[2] == 0) & (ras_tmr[3] == 0);


//******************************************************************************
//* RAS to RAS delay timers.                                                   *
//******************************************************************************
localparam RC_TIMER_MAX = (SDRAM_T_RC_PS + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam RC_TIMER_LEN = log2(RC_TIMER_MAX);

reg [RC_TIMER_LEN-1:0] rc_tmr [3:0];

always @(posedge clk)
begin
   for (i = 0; i < 4; i = i + 1)
      if (activate_row && (sdram_bank_addr == i))
         rc_tmr[i] <= RC_TIMER_MAX - 1;
      else
         if (rc_tmr[i] != 0)
            rc_tmr[i] <= rc_tmr[i] - 1;
end

always @(*)
begin
   case (sdram_bank_addr)
      2'b00: trc_done <= (rc_tmr[0] == 0);
      2'b01: trc_done <= (rc_tmr[1] == 0);
      2'b10: trc_done <= (rc_tmr[2] == 0);
      2'b11: trc_done <= (rc_tmr[3] == 0);
   endcase
end


endmodule
