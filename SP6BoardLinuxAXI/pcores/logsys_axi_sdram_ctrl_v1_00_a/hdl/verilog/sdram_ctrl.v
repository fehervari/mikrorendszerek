//******************************************************************************
//* Memory controller state machine.                                           *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 2.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module sdram_ctrl #( 
   //SDRAM timing parameters.
   parameter SDRAM_T_RP_PS       = 20000,       //Wait time after PRECHARGE command in ps
   parameter SDRAM_T_RFC_PS      = 66000,       //AUTO REFRESH command period in ps
   parameter SDRAM_T_RMD_CLK     = 2,           //Wait time after mode reg. write in clocks
   parameter SDRAM_T_RCD_PS      = 20000,       //RAS to CAS delay in ps
   parameter SDRAM_T_RC_PS       = 66000,       //RAS to RAS delay in ps
   parameter SDRAM_T_RAS_MIN_PS  = 42000,       //Min. row active time in ps
   parameter SDRAM_T_RAS_MAX_PS  = 100000000,   //Max. row active time in ps
   parameter SDRAM_T_REFRESH_MS  = 64,          //Refresh period in ms
   parameter SDRAM_REFRESH_BURST = 8,           //Number of issued AUTO REFRESH commands
   parameter SDRAM_CAS_LATENCY   = 2,           //CAS latency in clocks
   
   //System clock parameters.
   parameter SYSCLK_PERIOD_PS    = 10000        //System clock period in ps
) (
   //Clock and reset.
   input  wire        clk,                      //Clock signal
   input  wire        rstn,                     //Reset signal (active-low)
   
   //Input control signals.
   input  wire        mem_write_req,            //Memory write request signal
   input  wire        mem_read_req,             //Memory read request signal
   input  wire        wr_data_valid,            //Write data valid signal
   input  wire [1:0]  sdram_bank_addr,          //SDRAM bank address
   input  wire [12:0] sdram_row_addr,           //SDRAM row address
   input  wire        iodelay_busy,             //IODELAY calibration is in progress
   
   //Output control signals.
   output wire        sdram_cke_set,            //SDRAM clock enable set signal
   output reg         sdram_init_done,          //SDRAM initialization done signal
   output wire        iodelay_cal,              //IODELAY calibration start signal
   output reg  [8:0]  sdram_cmd,                //SDRAM command
   output reg  [1:0]  sdram_addr_sel,           //SDRAM address select signal
   output wire        mem_write_ack,            //Write acknowledge signal
   output wire        mem_read_ack,             //Read acknowledge signal
   output wire        dout_buf_tri,             //Output buffer tri-state signal
   output wire        be_valid,                 //Byte enable valid signal
   output wire        be_delay_sel,             //Byte enable delay select  
   output wire        rd_data_valid             //Read data valid signal
);

`include "memctrl_defs.vh"
`include "functions.vh"

//******************************************************************************
//* SDRAM timing generator.                                                    *
//******************************************************************************
wire init_cnt_clr;
wire init_cnt_en;
wire init_wait_done;
wire refresh_burst_done;
wire cmd_timer_en;
wire precharge_cmd_done;
wire refresh_cmd_done;
wire mreg_wr_cmd_done;
wire row_act_cmd_done;
wire refresh_timer_clr;
wire sdram_refresh_req;
wire sdram_refresh_ack;

sdram_timing #(
   //SDRAM timing parameters.
   .SDRAM_T_RP_PS(SDRAM_T_RP_PS),               //Wait time after PRECHARGE command in ps
   .SDRAM_T_RFC_PS(SDRAM_T_RFC_PS),             //AUTO REFRESH command period in ps
   .SDRAM_T_RMD_CLK(SDRAM_T_RMD_CLK),           //Wait time after mode reg. write in clocks
   .SDRAM_T_RCD_PS(SDRAM_T_RCD_PS),             //RAS to CAS delay in ps
   .SDRAM_T_RC_PS(SDRAM_T_RC_PS),               //RAS to RAS delay in ps
   .SDRAM_T_RAS_MAX_PS(SDRAM_T_RAS_MAX_PS),     //Max. row active time in ps
   .SDRAM_T_REFRESH_MS(SDRAM_T_REFRESH_MS),     //Refresh period in ms
   .SDRAM_REFRESH_BURST(SDRAM_REFRESH_BURST),   //Number of issued AUTO REFRESH commands
   
   //System clock parameters.
   .SYSCLK_PERIOD_PS(SYSCLK_PERIOD_PS)          //System clock period in ps
) sdram_timing (
   //Clock and reset.
   .clk(clk),                                   //System clock signal
   .rstn(rstn),                                 //Reset signal (active-low)
   
   //Signals related to the SDRAM initialization delay counter.
   .init_cnt_clr(init_cnt_clr),                 //Counter clear signal
   .init_cnt_en(init_cnt_en),                   //Counter enable signal
   .sdram_cke_set(sdram_cke_set),               //SDRAM clock enable set signal
   .init_wait_done(init_wait_done),             //SDRAM initialization wait done signal
   .refresh_burst_done(refresh_burst_done),     //SDRAM refresh burst done signal
   
   //Signals related to the SDRAM command timing.
   .cmd_timer_en(cmd_timer_en),                 //SDRAM command timer enable signal
   .precharge_done(precharge_cmd_done),         //SDRAM precharge done signal
   .refresh_done(refresh_cmd_done),             //SDRAM auto refresh done signal
   .mreg_wr_done(mreg_wr_cmd_done),             //SDRAM mode register write done signal
   .row_act_done(row_act_cmd_done),             //SDRAM row activation done signal
   
   //Signals related to the SDRAM refresh timer.
   .refresh_timer_clr(refresh_timer_clr),       //SDRAM refresh timer clear signal
   .sdram_refresh_ack(sdram_refresh_ack),       //SDRAM refresh acknowledge signal
   .sdram_refresh_req(sdram_refresh_req)        //SDRAM refresh request signal
);


//******************************************************************************
//* SDRAM bank state.                                                          *
//******************************************************************************
wire precharge_all;
wire precharge_row;
wire activate_row;
wire row_active;
wire row_addr_match;
wire tras_done;
wire tras_all_done;
wire trc_done;

bank_state # (
   //SDRAM timing parameters.
   .SDRAM_T_RC_PS(SDRAM_T_RC_PS),               //RAS to RAS delay in ps
   .SDRAM_T_RAS_MIN_PS(SDRAM_T_RAS_MIN_PS),     //Min. row active time in ps
   
   //System clock parameters.
   .SYSCLK_PERIOD_PS(SYSCLK_PERIOD_PS)          //System clock period in ps
) bank_state (
   //System clock signal.
   .clk(clk),
   
   //SDRAM address signals.
   .sdram_bank_addr(sdram_bank_addr),           //SDRAM bank address
   .sdram_row_addr(sdram_row_addr),             //SDRAM row address

   //Input control signals.
   .precharge_all(precharge_all),               //A precharge all command has been issued
   .precharge_row(precharge_row),               //A precharge command has been issued
   .activate_row(activate_row),                 //An activate row command has been issued
   
   //Output signals.
   .row_active(row_active),                     //A row is active in the selected bank
   .row_addr_match(row_addr_match),             //Row address match in the selected bank
   .tras_done(tras_done),                       //Tras has been elapsed for the selected bank
   .tras_all_done(tras_all_done),               //Tras has been elapsed for all banks
   .trc_done(trc_done)                          //Trc has been elapsed for the selected bank
);


//******************************************************************************
//* Memory controller state machine.                                           *
//******************************************************************************
localparam SDRAM_INIT_BEGIN    = 4'd0;
localparam SDRAM_CHK_TRAS_ALL  = 4'd1;
localparam SDRAM_PRECHARGE_ALL = 4'd2;
localparam SDRAM_CHK_RFRSH_CNT = 4'd3;
localparam SDRAM_AUTO_REFRESH  = 4'd4;
localparam SDRAM_MODEREG_WRITE = 4'd5;
localparam SDRAM_CHK_CAL_DONE  = 4'd6;
localparam SDRAM_IDLE          = 4'd7;
localparam SDRAM_CHK_TRAS_ROW  = 4'd8;
localparam SDRAM_PRECHARGE_ROW = 4'd9;
localparam SDRAM_CHK_TRC_ROW   = 4'd10;
localparam SDRAM_ACTIVATE_ROW  = 4'd11;
localparam SDRAM_WRITE         = 4'd12;
localparam SDRAM_READ          = 4'd13;

reg [3:0] mem_state;

always @(posedge clk)
begin
   if (rstn == 0)
      mem_state <= SDRAM_INIT_BEGIN;
   else
      case (mem_state)
         //Wait for the initialization timer.
         SDRAM_INIT_BEGIN   : if (init_wait_done)
                                 mem_state <= SDRAM_PRECHARGE_ALL;
                              else
                                 mem_state <= SDRAM_INIT_BEGIN;
                                 
         //Check all of the Tras timers.
         SDRAM_CHK_TRAS_ALL : if (tras_all_done)
                                 mem_state <= SDRAM_PRECHARGE_ALL;
                              else
                                 mem_state <= SDRAM_CHK_TRAS_ALL;
                                 
         //A PRECHARGE ALL command has been issued.
         SDRAM_PRECHARGE_ALL: if (precharge_cmd_done)
                                 mem_state <= SDRAM_CHK_RFRSH_CNT;
                              else
                                 mem_state <= SDRAM_PRECHARGE_ALL;
                                 
         //Check the number of issued AUTO REFRESH commands.
         SDRAM_CHK_RFRSH_CNT: if (refresh_burst_done)
                                 if (sdram_init_done)
                                    mem_state <= SDRAM_CHK_CAL_DONE;
                                 else
                                    mem_state <= SDRAM_MODEREG_WRITE;
                              else
                                 mem_state <= SDRAM_AUTO_REFRESH;
                                 
         //An AUTO REFRESH command has been issued.
         SDRAM_AUTO_REFRESH : if (refresh_cmd_done)
                                 mem_state <= SDRAM_CHK_RFRSH_CNT;
                              else
                                 mem_state <= SDRAM_AUTO_REFRESH;
                                 
         //A MODE REGISTER WRITE command has been issued.
         SDRAM_MODEREG_WRITE: if (mreg_wr_cmd_done)
                                 mem_state <= SDRAM_CHK_CAL_DONE;
                              else
                                 mem_state <= SDRAM_MODEREG_WRITE;
                                 
         //Wait for the IODELAY calibration to finish.
         SDRAM_CHK_CAL_DONE : if (iodelay_busy)
                                 mem_state <= SDRAM_CHK_CAL_DONE;
                              else
                                 mem_state <= SDRAM_IDLE;
                                 
         //Wait for a memory transfer request.
         SDRAM_IDLE         : if (sdram_refresh_req)
                                 mem_state <= SDRAM_CHK_TRAS_ALL;
                              else
                                 if (mem_write_req || mem_read_req)
                                    if (row_active)
                                       if (row_addr_match)
                                          if (mem_read_req)
                                             mem_state <= SDRAM_READ;
                                          else
                                             mem_state <= SDRAM_WRITE;
                                       else
                                          mem_state <= SDRAM_CHK_TRAS_ROW;
                                    else
                                       mem_state <= SDRAM_CHK_TRC_ROW;
                                 else
                                    mem_state <= SDRAM_IDLE;
                                 
         //Check the Tras timer of the selected bank.
         SDRAM_CHK_TRAS_ROW : if (tras_done)
                                 mem_state <= SDRAM_PRECHARGE_ROW;
                              else
                                 mem_state <= SDRAM_CHK_TRAS_ROW;
                                    
         //A PRECHARGE command has been issued.
         SDRAM_PRECHARGE_ROW: if (precharge_cmd_done)
                                 mem_state <= SDRAM_CHK_TRC_ROW;
                              else
                                 mem_state <= SDRAM_PRECHARGE_ROW;
                                
         //Check the RAS to RAS delay timer.
         SDRAM_CHK_TRC_ROW  : if (trc_done)
                                 mem_state <= SDRAM_ACTIVATE_ROW;
                              else
                                 mem_state <= SDRAM_CHK_TRC_ROW;
                                 
         //An ACTIVATE ROW command has been issued.
         SDRAM_ACTIVATE_ROW : if (row_act_cmd_done)
                                 if (mem_read_req)
                                    mem_state <= SDRAM_READ;
                                 else
                                    mem_state <= SDRAM_WRITE;
                              else
                                 mem_state <= SDRAM_ACTIVATE_ROW;
                                 
         //SDRAM write transfer.
         SDRAM_WRITE        : if ((sdram_refresh_req == 0) && mem_write_req)
                                 mem_state <= SDRAM_WRITE;
                              else
                                 mem_state <= SDRAM_IDLE;
                                 
         //SDRAM read transfer.
         SDRAM_READ         : if ((sdram_refresh_req == 0) && mem_read_req)
                                 mem_state <= SDRAM_READ;
                              else
                                 mem_state <= SDRAM_IDLE;
         
         //Invalid states.
         default            : mem_state <= SDRAM_INIT_BEGIN;
      endcase
end


//******************************************************************************
//* IODELAY calibration start signal.                                          *
//******************************************************************************
assign iodelay_cal = (mem_state == SDRAM_PRECHARGE_ALL) & precharge_cmd_done;


//******************************************************************************
//* SDRAM initialization done signal.                                          *
//******************************************************************************
always @(posedge clk)
begin
   if (rstn == 0)
      sdram_init_done <= 1'b0;
   else
      if ((mem_state == SDRAM_MODEREG_WRITE) && mreg_wr_cmd_done)
         sdram_init_done <= 1'b1;
end


//******************************************************************************
//* SDRAM refresh acknowledge signal.                                          *
//******************************************************************************
assign sdram_refresh_ack = (mem_state == SDRAM_CHK_RFRSH_CNT) & refresh_burst_done;


//******************************************************************************
//* SDRAM timing generator control signals.                                    *
//******************************************************************************
//Initialization delay counter clear signal.
assign init_cnt_clr = (mem_state == SDRAM_PRECHARGE_ALL);

//Initialization delay counter enable signal.
assign init_cnt_en = (mem_state == SDRAM_INIT_BEGIN) |
                     (mem_state == SDRAM_CHK_RFRSH_CNT);

//SDRAM refresh timer clear signal.
assign refresh_timer_clr = (mem_state == SDRAM_MODEREG_WRITE);

//SDRAM command timer enable signal.
assign cmd_timer_en = (mem_state == SDRAM_PRECHARGE_ALL) |
                      (mem_state == SDRAM_AUTO_REFRESH)  |
                      (mem_state == SDRAM_MODEREG_WRITE) |
                      (mem_state == SDRAM_PRECHARGE_ROW) |
                      (mem_state == SDRAM_ACTIVATE_ROW);


//******************************************************************************
//* SDRAM bank state module control signals.                                   *
//******************************************************************************
assign precharge_all = (mem_state == SDRAM_PRECHARGE_ALL);
assign precharge_row = (mem_state == SDRAM_PRECHARGE_ROW);
assign activate_row  = (mem_state == SDRAM_CHK_TRC_ROW) & trc_done;


//******************************************************************************
//* SDRAM commands.                                                            *
//******************************************************************************
localparam CMD_SDRAM_READ = (SDRAM_CAS_LATENCY == 3) ? CMD_SDRAM_READ_CL3 : CMD_SDRAM_READ_CL2;

always @(*)
begin
   case (mem_state)
      SDRAM_INIT_BEGIN   : if (init_wait_done)
                              sdram_cmd <= CMD_SDRAM_PRECHARGE_ALL;
                           else
                              sdram_cmd <= CMD_SDRAM_DESELECT;

      SDRAM_CHK_TRAS_ALL : if (tras_all_done)
                              sdram_cmd <= CMD_SDRAM_PRECHARGE_ALL;
                           else
                              sdram_cmd <= CMD_SDRAM_DESELECT;
                              
      SDRAM_CHK_RFRSH_CNT: if (refresh_burst_done)
                              if (sdram_init_done)
                                 sdram_cmd <= CMD_SDRAM_DESELECT;
                              else
                                 sdram_cmd <= CMD_SDRAM_MODE_REG_WR;
                           else
                              sdram_cmd <= CMD_SDRAM_AUTO_REFRESH;
                              
      SDRAM_CHK_TRAS_ROW : if (tras_done)
                              sdram_cmd <= CMD_SDRAM_PRECHARGE;
                           else
                              sdram_cmd <= CMD_SDRAM_DESELECT;
                              
      SDRAM_CHK_TRC_ROW  : if (trc_done)
                              sdram_cmd <= CMD_SDRAM_ACTIVATE_ROW;
                           else
                              sdram_cmd <= CMD_SDRAM_DESELECT;
      
      SDRAM_WRITE        : if (wr_data_valid)
                              sdram_cmd <= CMD_SDRAM_WRITE;
                           else
                              sdram_cmd <= CMD_SDRAM_DESELECT;
      
      SDRAM_READ         : sdram_cmd <= CMD_SDRAM_READ;
      
      default            : sdram_cmd <= CMD_SDRAM_DESELECT;
   endcase
end


//******************************************************************************
//* Address select signals.                                                    *
//******************************************************************************                  
always @(*)
begin
   case (mem_state)
      //When the SDRAM mode register is written, its value is selected.
      SDRAM_CHK_RFRSH_CNT: if (refresh_burst_done && (sdram_init_done == 0))
                              sdram_addr_sel <= ADDR_SEL_SDRAM_MREG;
                           else
                              sdram_addr_sel <= ADDR_SEL_SDRAM_COL;
      
      //The SDRAM row address is selected when an ACTIVATE ROW command is issued.
      SDRAM_CHK_TRC_ROW  : if (trc_done)
                              sdram_addr_sel <= ADDR_SEL_SDRAM_ROW;
                           else
                              sdram_addr_sel <= ADDR_SEL_SDRAM_COL;
      
      //The SDRAM column address is selected by default.
      default            : sdram_addr_sel <= ADDR_SEL_SDRAM_COL;
   endcase
end
                       
                       
//******************************************************************************
//* Memory write and read acknowledge signals.                                 *
//******************************************************************************
assign mem_write_ack = (mem_state == SDRAM_WRITE) & wr_data_valid;
assign mem_read_ack  = (mem_state == SDRAM_READ);


//******************************************************************************
//* Output buffer tri-state signal.                                            *
//******************************************************************************
assign dout_buf_tri = ~((mem_state == SDRAM_WRITE) & wr_data_valid);


//******************************************************************************
//* Byte enable control signals.                                               *
//******************************************************************************
//Byte enable valid signal.
assign be_valid = ((mem_state == SDRAM_WRITE) & wr_data_valid) | (mem_state == SDRAM_READ);

//Byte enable delay select signal.
generate
   if (SDRAM_CAS_LATENCY == 3)
   begin
      reg be_delay_sel_reg;

      always @(posedge clk)
      begin
         be_delay_sel_reg <= (mem_state == SDRAM_READ);
      end
 
      assign be_delay_sel = (mem_state == SDRAM_READ) | be_delay_sel_reg;
   end
   else
   begin
      assign be_delay_sel = 1'b0;
   end
endgenerate


//******************************************************************************
//* Read data valid signal.                                                    *
//******************************************************************************
reg [SDRAM_CAS_LATENCY:0] rd_valid_delay;

always @(posedge clk)
begin
   rd_valid_delay <= {rd_valid_delay[SDRAM_CAS_LATENCY-1:0], (mem_state == SDRAM_READ)};
end

assign rd_data_valid = rd_valid_delay[SDRAM_CAS_LATENCY];


endmodule
