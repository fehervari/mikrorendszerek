//******************************************************************************
//* SRAM timing generator.                                                     *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 2.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module sdram_timing #(
   //SDRAM timing parameters.
   parameter SDRAM_T_RP_PS       = 20000,       //Wait time after PRECHARGE command in ps
   parameter SDRAM_T_RFC_PS      = 66000,       //AUTO REFRESH command period in ps
   parameter SDRAM_T_RMD_CLK     = 2,           //Wait time after mode reg. write in clocks
   parameter SDRAM_T_RCD_PS      = 20000,       //RAS to CAS delay in ps
   parameter SDRAM_T_RC_PS       = 66000,       //RAS to RAS delay in ps
   parameter SDRAM_T_RAS_MAX_PS  = 100000000,   //Max. row active time in ps
   parameter SDRAM_T_REFRESH_MS  = 64,          //Refresh period in ms
   parameter SDRAM_REFRESH_BURST = 8,           //Number of issued AUTO REFRESH commands
   
   //System clock parameters.
   parameter SYSCLK_PERIOD_PS    = 10000        //System clock period in ps
) (
   ///Clock and reset.
   input  wire clk,                             //System clock signal
   input  wire rstn,                            //Reset signal (active-low)
   
   //Signals related to the SDRAM initialization delay counter.
   input  wire init_cnt_clr,                    //Counter clear signal
   input  wire init_cnt_en,                     //Counter enable signal
   output wire sdram_cke_set,                   //SDRAM clock enable set signal
   output wire init_wait_done,                  //SDRAM initialization wait done signal
   output wire refresh_burst_done,              //SDRAM refresh burst done signal
   
   //Signals related to the SDRAM command timing.
   input  wire cmd_timer_en,                    //SDRAM command timer enable signal
   output wire precharge_done,                  //SDRAM precharge done signal
   output wire refresh_done,                    //SDRAM auto refresh done signal
   output wire mreg_wr_done,                    //SDRAM mode register write done signal
   output wire row_act_done,                    //SDRAM row activation done signal
   
   //Signals related to the SDRAM refresh timer.
   input  wire refresh_timer_clr,               //SDRAM refresh timer clear signal
   input  wire sdram_refresh_ack,               //SDRAM refresh acknowledge signal
   output reg  sdram_refresh_req                //SDRAM refresh request signal
);

`include "functions.vh"

//******************************************************************************
//* SDRAM initialization delay counter.                                        *
//******************************************************************************
localparam INIT_CNT_LEN = log2(400000000 / SYSCLK_PERIOD_PS);

reg  [INIT_CNT_LEN-1:0] init_cnt;

always @(posedge clk)
begin
   if ((rstn == 0) || init_cnt_clr)
      init_cnt <= 0;
   else
      if (init_cnt_en)
         init_cnt <= init_cnt + 1;
end

//SDRAM clock enable set signal.
assign sdram_cke_set = init_cnt[INIT_CNT_LEN-3];

//SDRAM initialization wait done signal.
assign init_wait_done = init_cnt[INIT_CNT_LEN-1];

//SDRAM refresh burst done signal.
assign refresh_burst_done = (init_cnt[3:0] == SDRAM_REFRESH_BURST);


//******************************************************************************
//* SDRAM command timing.                                                      *
//******************************************************************************
localparam T_RP_CLK  = (SDRAM_T_RP_PS  + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam T_RFC_CLK = (SDRAM_T_RFC_PS + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam T_RCD_CLK = (SDRAM_T_RCD_PS + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam T_RMD_CLK = SDRAM_T_RMD_CLK;

localparam T_CMD_MAX1 = (T_RP_CLK   > T_RFC_CLK)  ? T_RP_CLK   : T_RFC_CLK;
localparam T_CMD_MAX2 = (T_RCD_CLK  > T_RMD_CLK)  ? T_RCD_CLK  : T_RMD_CLK;
localparam SHR_LENGTH = (T_CMD_MAX1 > T_CMD_MAX2) ? T_CMD_MAX1 : T_CMD_MAX2;

reg [SHR_LENGTH-1:0] cmd_timer;

always @(posedge clk)
begin
   if (cmd_timer_en == 0)
      cmd_timer <= 1;
   else
      cmd_timer <= {cmd_timer[SHR_LENGTH-2:0], 1'b0};
end

//SDRAM command done signals.
assign precharge_done = cmd_timer[T_RP_CLK-1];
assign refresh_done   = cmd_timer[T_RFC_CLK-1];
assign mreg_wr_done   = cmd_timer[T_RMD_CLK-1];
assign row_act_done   = cmd_timer[T_RCD_CLK-1];


//******************************************************************************
//* SDRAM refresh timer.                                                       *
//******************************************************************************
localparam REFRESH_PERIOD_PS  = (1000000000 / 8192) * SDRAM_T_REFRESH_MS * SDRAM_REFRESH_BURST;
localparam REFRESH_PERIOD_CLK = (REFRESH_PERIOD_PS  + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;
localparam RAS_MAX_CLK        = (SDRAM_T_RAS_MAX_PS + SYSCLK_PERIOD_PS - 1) / SYSCLK_PERIOD_PS;

localparam REFRESH_CNT_MAX    = (RAS_MAX_CLK < REFRESH_PERIOD_CLK) ? RAS_MAX_CLK : REFRESH_PERIOD_CLK;
localparam REFRESH_CNT_LEN    = log2(REFRESH_CNT_MAX - 1);

reg  [REFRESH_CNT_LEN-1:0] refresh_cnt;
wire                       refresh_cnt_tc = (refresh_cnt == 0);

always @(posedge clk)
begin
   if (refresh_timer_clr || refresh_cnt_tc)
      refresh_cnt <= REFRESH_CNT_MAX - 1;
   else
      refresh_cnt <= refresh_cnt - 1;
end

always @(posedge clk)
begin
   if (refresh_timer_clr)
      sdram_refresh_req <= 1'b0;
   else
      if (refresh_cnt_tc)
         sdram_refresh_req <= 1'b1;
      else
         if (sdram_refresh_ack)
            sdram_refresh_req <= 1'b0;
end


endmodule
