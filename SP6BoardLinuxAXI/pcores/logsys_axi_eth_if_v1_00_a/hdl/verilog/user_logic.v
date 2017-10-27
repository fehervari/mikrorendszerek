//******************************************************************************
//* Interface peripheral for the LOGSYS 10/100 Ethernet module (AXI4 ver.).    *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 1.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic #(
   //Bus protocol parameters.
   parameter C_S_AXI_ACLK_PERIOD_PS = 10000,
   parameter C_SLV_AWIDTH           = 12,
   parameter C_SLV_DWIDTH           = 32,
   parameter C_NUM_REG              = 1
) (
   //Bus protocol ports.
   input  wire                        Bus2IP_Clk,        //Clock signal.
   input  wire                        Bus2IP_Resetn,     //Reset signal (active-low).
   input  wire [C_SLV_AWIDTH-1 : 0]   Bus2IP_Addr,       //Address bus.
   input  wire [0 : 0]                Bus2IP_CS,         //Memory address range select signal.
   input  wire                        Bus2IP_RNW,        //Read/write select signal. 
   input  wire [C_SLV_DWIDTH-1 : 0]   Bus2IP_Data,       //Input data bus.
   input  wire [C_SLV_DWIDTH/8-1 : 0] Bus2IP_BE,         //Byte enable signals.
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_RdCE,       //Register read enable signals.
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_WrCE,       //Register write enable signals.
   output wire [C_SLV_DWIDTH-1 : 0]   IP2Bus_Data,       //Output data bus.
   output wire                        IP2Bus_RdAck,      //Read acknowledge signal.
   output wire                        IP2Bus_WrAck,      //Write acknowledge signal.
   output wire                        IP2Bus_Error,      //Bus error signal.
   output wire                        interrupt,         //Interrupt request signal.
   
   //ENC424J600 Ethernet controller interface signals.
   output wire                        eth_en,            //Read/write enable signal
   output wire                        eth_al,            //Address latch enable signal.
   output wire                        eth_rnw_ad8,       //Read/write select, 8th address bit.
   output wire [7:0]                  eth_ad_O,          //Multiplexed address and data bus.
   input  wire [7:0]                  eth_ad_I,
   output wire [7:0]                  eth_ad_T,
   input  wire                        eth_irq            //ENC424J600 interrupt request signal. 
);

//*****************************************************************************
//* Base 2 logarithm function.                                                *
//*****************************************************************************
function integer log2(input integer x);
   for (log2 = 0; x > 0; log2 = log2 + 1)
      x = x >> 1;
endfunction


//******************************************************************************
//* Clock, reset and address signals.                                          *
//******************************************************************************
wire        clk  = Bus2IP_Clk;
wire        rstn = Bus2IP_Resetn;
wire [11:0] addr = Bus2IP_Addr[11:0];


//******************************************************************************
//* ENC424J600 timing parameters.                                              *
//******************************************************************************
localparam T_EN_SRAM_RD_HIGH_PS = 75000;              //SRAM read EN high time.
localparam T_EN_OTHER_HIGH_PS   = 20000;              //Other operation EN high time.
localparam T_EN_SRAM_RW_LOW_PS  = 40000;              //SRAM read/write EN low time.
localparam T_EN_OTHER_LOW_PS    = 10000;              //Other operation EN low time.


//******************************************************************************
//* Indicating the SRAM access.                                                *
//******************************************************************************
localparam EGPDATA  = 9'h0080;                        //EGPDATA  reg. address: 0x7E80
localparam ERXDATA  = 9'h0082;                        //ERXDATA  reg. address: 0x7E82
localparam EUDADATA = 9'h0084;                        //EUDADATA reg. address: 0x7E84

reg  [1:0] sram_access_type;
wire       sram_access_ld;

always @(posedge clk)
begin
   if (sram_access_ld)
      case (addr[10:2])
         EGPDATA : sram_access_type <= {Bus2IP_RNW, 1'b1};
         ERXDATA : sram_access_type <= {Bus2IP_RNW, 1'b1};
         EUDADATA: sram_access_type <= {Bus2IP_RNW, 1'b1};
         default : sram_access_type <= 2'b00;
      endcase
end

wire sram_access = sram_access_type[0]; 
wire sram_read   = sram_access_type[1]; 

   
//******************************************************************************
//* Indicating the SFR address change.                                         *
//******************************************************************************
reg  [9:0] sfr_addr_reg;
wire       sfr_addr_reg_ld;
wire       sfr_addr_changed = (sfr_addr_reg[8:0] != addr[10:2]) | sfr_addr_reg[9];

always @(posedge clk)
begin
   if (rstn == 0)
      sfr_addr_reg <= 10'b10_0000_0000;
   else
      if (sfr_addr_reg_ld)
         sfr_addr_reg <= {1'b0, addr[10:2]};
end


//******************************************************************************
//* EN high time counter.                                                      *
//******************************************************************************
localparam T_EN_SRAM_RD_HIGH_CLK = (T_EN_SRAM_RD_HIGH_PS + C_S_AXI_ACLK_PERIOD_PS - 1) / C_S_AXI_ACLK_PERIOD_PS;
localparam T_EN_OTHER_HIGH_CLK   = (T_EN_OTHER_HIGH_PS   + C_S_AXI_ACLK_PERIOD_PS - 1) / C_S_AXI_ACLK_PERIOD_PS;
localparam ENH_CNT_LEN           = log2(T_EN_SRAM_RD_HIGH_CLK - 1);

wire enh_cnt_ld;
wire enh_cnt_en;
wire enh_cnt_tc;

generate
   if (T_EN_SRAM_RD_HIGH_CLK < 2)
   begin
      //No counter is required.
      assign enh_cnt_tc = 1'b1;
   end
   else
   begin
      //EN high time counter.
      reg [ENH_CNT_LEN-1:0] enh_cnt;
      
      always @(posedge clk)
      begin
         if (enh_cnt_ld)
            if (sram_read)
               enh_cnt <= T_EN_SRAM_RD_HIGH_CLK - 1;
            else
               enh_cnt <= T_EN_OTHER_HIGH_CLK - 1;
         else
            if (enh_cnt_en)
               enh_cnt <= enh_cnt - 1;
      end
      
      assign enh_cnt_tc = (enh_cnt == 0);
   end
endgenerate


//******************************************************************************
//* EN low time counter.                                                       *
//******************************************************************************
localparam T_EN_SRAM_RW_LOW_CLK = (T_EN_SRAM_RW_LOW_PS + C_S_AXI_ACLK_PERIOD_PS - 1) / C_S_AXI_ACLK_PERIOD_PS;
localparam T_EN_OTHER_LOW_CLK   = (T_EN_OTHER_LOW_PS   + C_S_AXI_ACLK_PERIOD_PS - 1) / C_S_AXI_ACLK_PERIOD_PS;
localparam ENL_CNT_LEN          = log2(T_EN_SRAM_RW_LOW_CLK - 1);

wire enl_cnt_ld;
wire enl_cnt_en;
wire enl_cnt_tc;

generate
   if (T_EN_SRAM_RW_LOW_CLK < 2)
   begin
      //No counter is required.
      assign enl_cnt_tc = 1'b1;
   end
   else
   begin
      //EN low time counter.
      reg [ENL_CNT_LEN-1:0] enl_cnt;
      
      always @(posedge clk)
      begin
         if (enl_cnt_ld)
            if (sram_access)
               enl_cnt <= T_EN_SRAM_RW_LOW_CLK - 1;
            else
               enl_cnt <= T_EN_OTHER_LOW_CLK - 1; 
         else
            if (enl_cnt_en)
               enl_cnt <= enl_cnt - 1;
      end
      
      assign enl_cnt_tc = (enl_cnt == 0);
   end
endgenerate


//******************************************************************************
//* Byte counter.                                                              *
//******************************************************************************
reg  [1:0] byte_cnt;
wire       byte_cnt_clr;
wire       byte_cnt_en;
reg  [1:0] byte_cnt_max;

always @(posedge clk)
begin
   if (byte_cnt_clr)
      byte_cnt <= 2'd0;
   else
      if (byte_cnt_en)
         byte_cnt <= byte_cnt + 2'd1;
end

always @(posedge clk)
begin
   if (byte_cnt_clr)
      byte_cnt_max <= (addr[11]) ? 2'd3 : 2'd0;
end

//Burst done signal.
wire burst_done = (byte_cnt == byte_cnt_max);


//******************************************************************************
//* Controller state machine.                                                  *
//******************************************************************************
localparam ETH_IDLE    = 4'd0;
localparam ETH_ADDR1   = 4'd1;
localparam ETH_ADDR2   = 4'd2;
localparam ETH_WRITE1  = 4'd3;
localparam ETH_WRITE2  = 4'd4;
localparam ETH_WRITE3  = 4'd5;
localparam ETH_READ1   = 4'd6;
localparam ETH_READ2   = 4'd7;
localparam ETH_READ3   = 4'd8;
localparam ETH_WR_DONE = 4'd9;
localparam ETH_RD_WAIT = 4'd10;

reg  [3:0] eth_state;
wire       rd_done;

always @(posedge clk)
begin
   if (rstn == 0)
      eth_state <= ETH_IDLE;
   else
      case (eth_state)
         //Wait for a request.
         ETH_IDLE   : if (Bus2IP_CS[0])
                         if (sfr_addr_changed)
                            eth_state <= ETH_ADDR1;
                         else
                            if (Bus2IP_RNW)
                               eth_state <= ETH_READ1;
                            else
                               eth_state <= ETH_WRITE1;
                      else
                         eth_state <= ETH_IDLE;
                         
         //Address latch write.
         ETH_ADDR1  : eth_state <= ETH_ADDR2;
         
         ETH_ADDR2  : if (Bus2IP_RNW)
                         eth_state <= ETH_READ1;
                      else
                         eth_state <= ETH_WRITE1;
         
         //Write transfer.
         ETH_WRITE1 : eth_state <= ETH_WRITE2;
         
         ETH_WRITE2 : if (enh_cnt_tc)
                         if (burst_done)
                            eth_state <= ETH_WR_DONE;
                         else
                            eth_state <= ETH_WRITE3;
                      else
                         eth_state <= ETH_WRITE2;
         
         ETH_WRITE3 : if (enl_cnt_tc)
                         eth_state <= ETH_WRITE1;
                      else
                         eth_state <= ETH_WRITE3;
                         
         //Read transfer.
         ETH_READ1  : eth_state <= ETH_READ2;
         
         ETH_READ2  : if (enh_cnt_tc)
                         if (burst_done)
                            eth_state <= ETH_RD_WAIT;
                         else
                            eth_state <= ETH_READ3;
                      else
                         eth_state <= ETH_READ2;
         
         ETH_READ3  : if (enl_cnt_tc)
                         eth_state <= ETH_READ2;
                      else
                         eth_state <= ETH_READ3;
         
         //The transfer has been completed.
         ETH_WR_DONE: eth_state <= ETH_IDLE;
         
         ETH_RD_WAIT: if (rd_done)
                         eth_state <= ETH_IDLE;
                      else 
                         eth_state <= ETH_RD_WAIT;
         
         //Invalid states.
         default    : eth_state <= ETH_IDLE;
      endcase
end


//******************************************************************************
//* Read data valid and read done signals.                                     *
//******************************************************************************
reg [1:0] rd_valid_shr;
reg [2:0] rd_done_shr;

wire rd_valid_in = (eth_state == ETH_READ2) & enh_cnt_tc;
wire rd_done_in  = rd_valid_in & burst_done;

always @(posedge clk)
begin
   rd_valid_shr <= {rd_valid_shr[0], rd_valid_in};
   rd_done_shr  <= {rd_done_shr[1:0], rd_done_in};
end

wire   rd_data_valid = rd_valid_shr[1];
assign rd_done       = rd_done_shr[2];


//******************************************************************************
//* Control signals of the address related registers.                          *
//******************************************************************************
//SRAM access indicator register load signal.
assign sram_access_ld  = (eth_state == ETH_IDLE) & Bus2IP_CS[0];

//Address register load signal.
assign sfr_addr_reg_ld = (eth_state == ETH_ADDR1);


//******************************************************************************
//* Timing generator control signals.                                          *
//******************************************************************************
//EN high time counter load signal.
assign enh_cnt_ld = (eth_state == ETH_WRITE1) | (eth_state == ETH_READ1) | 
                    (eth_state == ETH_WRITE3) | (eth_state == ETH_READ3);

//EN high time counter enable signal.
assign enh_cnt_en = (eth_state == ETH_WRITE2) | (eth_state == ETH_READ2);

//EN low time counter load signal.
assign enl_cnt_ld = (eth_state == ETH_WRITE2) | (eth_state == ETH_READ2);

//EN low time counter enable signal.
assign enl_cnt_en = (eth_state == ETH_WRITE3) | (eth_state == ETH_READ3);


//******************************************************************************
//* Byte counter control signals.                                              *
//******************************************************************************
//Byte counter clear signal.
assign byte_cnt_clr = (eth_state == ETH_IDLE) & Bus2IP_CS[0];

//Byte counter enable signal.
assign byte_cnt_en  = ((eth_state == ETH_WRITE3) | (eth_state == ETH_READ3)) & enl_cnt_tc;


//******************************************************************************
//* Driving the ENC424J600 read/write enable signal.                           *
//******************************************************************************
(* iob = "force" *)
reg eth_en_reg;

always @(posedge clk)
begin
   eth_en_reg <= (eth_state == ETH_WRITE2) | (eth_state == ETH_READ2);
end

assign eth_en = eth_en_reg;


//******************************************************************************
//* Driving the ENC424J600 address latch enable signal.                        *
//******************************************************************************
(* iob = "force" *)
reg eth_al_reg;

always @(posedge clk)
begin
   eth_al_reg <= (eth_state == ETH_ADDR1);
end

assign eth_al = eth_al_reg;


//******************************************************************************
//* Driving the ENC424J600 R/W select and AD[8] signal.                        *
//******************************************************************************
(* iob = "force" *)
reg eth_rnw_ad8_reg;

always @(posedge clk)
begin
   case (eth_state)
      ETH_ADDR1: eth_rnw_ad8_reg <= addr[10];
      ETH_ADDR2: eth_rnw_ad8_reg <= addr[10];
      ETH_READ1: eth_rnw_ad8_reg <= 1'b1;
      ETH_READ2: eth_rnw_ad8_reg <= 1'b1;
      ETH_READ3: eth_rnw_ad8_reg <= 1'b1;
      default  : eth_rnw_ad8_reg <= 1'b0;
   endcase
end

assign eth_rnw_ad8 = eth_rnw_ad8_reg;


//******************************************************************************
//* Output data register and output buffer tri-state register.                 *
//******************************************************************************
(* iob = "force" *)
reg [7:0] eth_ad_O_reg;
(* iob = "force" *)
(* equivalent_register_removal = "no" *)
reg [7:0] eth_ad_T_reg;

always @(posedge clk)
begin
   if ((eth_state == ETH_ADDR1) || (eth_state == ETH_ADDR2))
      eth_ad_O_reg <= addr[9:2];
   else
      case (byte_cnt)
         2'd0: eth_ad_O_reg <= Bus2IP_Data[7:0];
         2'd1: eth_ad_O_reg <= Bus2IP_Data[15:8];
         2'd2: eth_ad_O_reg <= Bus2IP_Data[23:16];
         2'd3: eth_ad_O_reg <= Bus2IP_Data[31:24];
      endcase
end

always @(posedge clk)
begin
   if (rstn == 0)
      eth_ad_T_reg <= 8'hff;
   else
      case (eth_state)
         ETH_ADDR1  : eth_ad_T_reg <= 8'h00;
         ETH_ADDR2  : eth_ad_T_reg <= 8'h00;
         ETH_WRITE1 : eth_ad_T_reg <= 8'h00;
         ETH_WRITE2 : eth_ad_T_reg <= 8'h00;
         ETH_WRITE3 : eth_ad_T_reg <= 8'h00;
         ETH_WR_DONE: eth_ad_T_reg <= 8'h00;
         default    : eth_ad_T_reg <= 8'hff;
      endcase
end

assign eth_ad_O = eth_ad_O_reg;
assign eth_ad_T = eth_ad_T_reg;


//******************************************************************************
//* Input data register.                                                       *
//******************************************************************************
(* iob = "force" *)
reg [7:0]  eth_ad_I_reg;
reg [31:0] rd_data_reg;
reg [1:0]  rd_data_sel;

always @(posedge clk)
begin
   eth_ad_I_reg <= eth_ad_I;
end

always @(posedge clk)
begin
   if ((rstn == 0) || rd_done)
      rd_data_reg <= 32'd0;
   else
      if (rd_data_valid)
         case (rd_data_sel)
            2'd0: rd_data_reg[7:0]   <= eth_ad_I_reg;
            2'd1: rd_data_reg[15:8]  <= eth_ad_I_reg;
            2'd2: rd_data_reg[23:16] <= eth_ad_I_reg;
            2'd3: rd_data_reg[31:24] <= eth_ad_I_reg;
         endcase
end

always @(posedge clk)
begin
   if ((rstn == 0) || rd_done)
      rd_data_sel <= 2'd0;
   else
      if (rd_data_valid)
         rd_data_sel <= rd_data_sel + 2'd1;
end


//******************************************************************************
//* Driving the AXI output signals.                                            *
//******************************************************************************
assign IP2Bus_RdAck = rd_done;
assign IP2Bus_WrAck = (eth_state == ETH_WR_DONE);
assign IP2Bus_Error = 1'b0;
assign IP2Bus_Data  = rd_data_reg;


//*****************************************************************************
//* Driving the interrupt request output.                                     *
//*****************************************************************************
reg [1:0] eth_irq_samples;

always @(posedge clk)
begin
   if (rstn == 0)
      eth_irq_samples <= 2'b11;
   else
      eth_irq_samples <= {eth_irq_samples[0], eth_irq};
end

assign interrupt = ~eth_irq_samples[1];

endmodule
