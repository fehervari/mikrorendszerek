//*****************************************************************************
//* Inferface peripheral for the simple I/O devices on the LOGSYS Spartan-6   *
//* FPGA board (AXI4 version).                                                *
//*                                                                           *
//* Written by   : Tamas Raikovich                                            *
//* Version      : 1.0                                                        *
//* Last modified: 2013.04.28.                                                *
//*****************************************************************************
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic #(
   //GPIO interface parameters.
   parameter C_GPIO_ENABLE        = 1,
   parameter C_GPIO_WIDTH         = 13,
   
   //Bus protocol parameters.
   parameter C_S_AXI_ACLK_FREQ_HZ = 100000000,
   parameter C_SLV_DWIDTH         = 32,
   parameter C_NUM_REG            = 4
) (
   //Bus protocol ports.
   input  wire                        Bus2IP_Clk,        //Clock signal.
   input  wire                        Bus2IP_Resetn,     //Reset signal (active-low).
   input  wire [C_SLV_DWIDTH-1 : 0]   Bus2IP_Data,       //Input data bus.
   input  wire [C_SLV_DWIDTH/8-1 : 0] Bus2IP_BE,         //Byte enable signals.
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_RdCE,       //Register read enable signals.
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_WrCE,       //Register write enable signals.
   output reg  [C_SLV_DWIDTH-1 : 0]   IP2Bus_Data,       //Output data bus.
   output wire                        IP2Bus_RdAck,      //Read acknowledge signal.
   output wire                        IP2Bus_WrAck,      //Write acknowledge signal.
   output wire                        IP2Bus_Error,      //Bus error signal.
   output reg                         irq,               //Interrupt request signal.
   
   //Button input.
   input  wire [2:0]                  btn_in,
   
   //DIP switch output.
   output wire [7:0]                  sw_out,
   
   //GPIO interface.
   input  wire [C_GPIO_WIDTH-1 : 0]   gpio_I,            //GPIO input data.
   output wire [C_GPIO_WIDTH-1 : 0]   gpio_O,            //GPIO output data.
   output wire [C_GPIO_WIDTH-1 : 0]   gpio_T,            //GPIO direction control (0:out, 1:in).
   
   //CPLD interface ports.
   output wire                        cpld_jtagen,       //CPLD JTAG interface enable signal.
   output wire                        cpld_rstn,         //CPLD reset signal.
   output wire                        cpld_clk,          //CPLD clock signal.
   output wire                        cpld_load,         //CPLD load signal.
   output wire                        cpld_mosi,         //CPLD serial data output.
   input  wire                        cpld_miso          //CPLD serial data input.
); 

//*****************************************************************************
//* Base 2 logarithm function.                                                *
//*****************************************************************************
function integer log2(input integer x);
   for (log2 = 0; x > 0; log2 = log2 + 1)
      x = x >> 1;
endfunction


//******************************************************************************
//* Clock and reset signals.                                                   *
//******************************************************************************
wire clk  = Bus2IP_Clk;
wire rstn = Bus2IP_Resetn;

//CPLD reset signal.
(* iob = "force" *)
reg cpld_rstn_reg;

always @(posedge clk)
begin
   cpld_rstn_reg <= rstn;
end

assign cpld_rstn   = cpld_rstn_reg;
assign cpld_jtagen = 1'b0;


//******************************************************************************
//* LED register (BASE+0x00, 8 bit, RW).                                       *
//******************************************************************************
reg  [7:0] led_reg;
wire       led_reg_wr = Bus2IP_WrCE[3] & (Bus2IP_BE == 4'b0001);

always @(posedge clk)
begin
   if (rstn == 0)
      led_reg <= 8'd0;
   else
      if (led_reg_wr)
         led_reg <= Bus2IP_Data[7:0];
end


//******************************************************************************
//* DISP1 register (BASE+0x01, 8 bit, RW).                                     *
//******************************************************************************
reg  [7:0] disp1_reg;
wire       disp1_reg_wr = Bus2IP_WrCE[3] & (Bus2IP_BE == 4'b0010);

always @(posedge clk)
begin
   if (rstn == 0)
      disp1_reg <= 8'd0;
   else
      if (disp1_reg_wr)
         disp1_reg <= Bus2IP_Data[15:8];
end


//******************************************************************************
//* DISP2 register (BASE+0x02, 8 bit, RW).                                     *
//******************************************************************************
reg  [7:0] disp2_reg;
wire       disp2_reg_wr = Bus2IP_WrCE[3] & (Bus2IP_BE == 4'b0100);

always @(posedge clk)
begin
   if (rstn == 0)
      disp2_reg <= 8'd0;
   else
      if (disp2_reg_wr)
         disp2_reg <= Bus2IP_Data[23:16];
end


//******************************************************************************
//* GPIO data register (BASE+0x04, 16 bit, RW).                                *
//******************************************************************************
wire [15:0]             gpio_data_dout;
reg  [C_GPIO_WIDTH-1:0] gpio_din_curr;
reg  [C_GPIO_WIDTH-1:0] gpio_din_prev;

generate
   if (C_GPIO_ENABLE != 0)
   begin
      (* iob = "true" *)
      reg  [C_GPIO_WIDTH-1:0] gpio_O_reg;
      reg  [C_GPIO_WIDTH-1:0] gpio_dout_reg;
      wire                    gpio_dout_reg_wr = Bus2IP_WrCE[2] & (Bus2IP_BE == 4'b0011);

      always @(posedge clk)
      begin
         if (rstn == 0)
            gpio_dout_reg <= {C_GPIO_WIDTH{1'b0}};
         else
            if (gpio_dout_reg_wr)
               gpio_dout_reg <= Bus2IP_Data[C_GPIO_WIDTH-1:0];
      end

      //Driving the GPIO output signals.
      always @(posedge clk)
      begin
         gpio_O_reg <= gpio_dout_reg;
      end
      
      assign gpio_O = gpio_O_reg;

      //Sampling the GPIO input signals.
      (* iob = "true" *)
      reg [C_GPIO_WIDTH-1:0] gpio_I_reg;

      always @(posedge clk)
      begin
         gpio_I_reg    <= gpio_I;
         gpio_din_curr <= gpio_I_reg;
         gpio_din_prev <= gpio_din_curr;
      end
      
      //Driving the GPIO data register output.
      assign gpio_data_dout = {{16-C_GPIO_WIDTH{1'b0}}, gpio_din_curr};
   end
   else
   begin
      //Driving the GPIO output signals.
      assign gpio_O = {C_GPIO_WIDTH{1'b0}};
      
      //Driving the GPIO data register output.
      assign gpio_data_dout = 16'd0;
   end
endgenerate


//******************************************************************************
//* GPIO direction register (BASE+0x08, 16 bit, RW).                           *
//******************************************************************************
wire [15:0] gpio_dir_dout;
wire        gpio_changed;

generate
   if (C_GPIO_ENABLE != 0)
   begin
      (* iob = "true" *)
      reg  [C_GPIO_WIDTH-1:0] gpio_T_reg;
      reg  [C_GPIO_WIDTH-1:0] gpio_dir_reg;
      wire                    gpio_dir_reg_wr = Bus2IP_WrCE[1] & (Bus2IP_BE == 4'b0011);

      always @(posedge clk)
      begin
         if (rstn == 0)
            gpio_dir_reg <= {C_GPIO_WIDTH{1'b1}};
         else
            if (gpio_dir_reg_wr)
               gpio_dir_reg <= Bus2IP_Data[C_GPIO_WIDTH-1:0];
      end
      
      //Driving the GPIO direction register output.
      assign gpio_dir_dout = {{16-C_GPIO_WIDTH{1'b0}}, gpio_dir_reg};

      //Driving the GPIO direction control signal.
      always @(posedge clk)
      begin
         gpio_T_reg <= gpio_dir_reg;
      end
      
      assign gpio_T = gpio_T_reg;

      //Generating the GPIO interrupt flag set signal.
      assign gpio_changed = |((gpio_din_curr ^ gpio_din_prev) & gpio_dir_reg);
   end
   else
   begin
      //Driving the GPIO direction register output.
      assign gpio_dir_dout = 16'd0;
      
      //Driving the GPIO direction control signal.
      assign gpio_T = {C_GPIO_WIDTH{1'b1}};
      
      //Generating the GPIO interrupt flag set signal.
      assign gpio_changed = 1'b0;
   end
endgenerate


//******************************************************************************
//* Interrupt enable register (BASE+0x0C, 8 bit, RW).                          *
//******************************************************************************
reg  [3:0] ie_reg;
wire       ie_reg_wr   = Bus2IP_WrCE[0] & (Bus2IP_BE == 4'b0001);
wire [7:0] ie_reg_dout = {4'b0000, ie_reg};

always @(posedge clk)
begin
   if (rstn == 0)
      ie_reg <= 4'd0;
   else
      if (ie_reg_wr)
         ie_reg <= Bus2IP_Data[3:0];
end


//******************************************************************************
//* Interrupt flag register (BASE+0x0D, 8 bit, RW).                            *
//******************************************************************************
//Interrupt flag register.
reg  [3:0] if_reg;
wire [3:0] if_set;
wire       if_reg_wr   = Bus2IP_WrCE[0] & (Bus2IP_BE == 4'b0010);
wire [7:0] if_reg_dout = {4'b0000, if_reg};

integer i;

always @(posedge clk)
begin
   for (i = 0; i < 4; i = i + 1)
      if (rstn == 0)
         if_reg[i] <= 1'b0;
      else
         if (if_set[i])
            if_reg[i] <= 1'b1;
         else
            if (if_reg_wr && Bus2IP_Data[8+i])
               if_reg[i] <= 1'b0;
end

//Interrupt sources.
wire dipsw_changed;
wire navsw_changed;
wire btn_changed;

assign if_set[0] = dipsw_changed;
assign if_set[1] = navsw_changed;
assign if_set[2] = btn_changed;
assign if_set[3] = gpio_changed;

//Driving the interrupt request output.
always @(posedge clk)
begin
   if (rstn == 0)
      irq <= 1'b0;
   else
      irq <= |(ie_reg & if_reg);
end


//******************************************************************************
//* Clock divider for generating the 3200 Hz clock enable signal.              *
//******************************************************************************
localparam CLK_DIV_VALUE = C_S_AXI_ACLK_FREQ_HZ / 3200;
localparam CLK_DIV_WIDTH = log2(CLK_DIV_VALUE - 1);

reg  [CLK_DIV_WIDTH-1:0] clk_divider;
wire                     clk_divider_tc = (clk_divider == 0);

always @(posedge clk)
begin
   if ((rstn == 0) || clk_divider_tc)
      clk_divider <= CLK_DIV_VALUE - 1;
   else
      clk_divider <= clk_divider - 1;
end


//******************************************************************************
//* Generating the CPLD clock signal.                                          *
//******************************************************************************
reg cpld_clk_reg;
(* iob = "force" *)
reg cpld_clk_out_reg;

always @(posedge clk)
begin
   if (rstn == 0)
      cpld_clk_reg <= 1'b0;
   else
      if (clk_divider_tc)
         cpld_clk_reg <= ~cpld_clk_reg;
end

always @(posedge clk)
begin
   if (rstn == 0)
      cpld_clk_out_reg <= 1'b0;
   else
      cpld_clk_out_reg <= cpld_clk_reg;
end

assign cpld_clk = cpld_clk_out_reg;


//******************************************************************************
//* Generating the CPLD load signal.                                           *
//******************************************************************************
reg [3:0] cpld_clk_cnt;
reg       cpld_load_reg;
(* iob = "force" *)
reg       cpld_load_out_reg;

always @(posedge clk)
begin
   if (rstn == 0)
      cpld_clk_cnt <= 4'd0;
   else
      if (clk_divider_tc && cpld_clk_reg)
         cpld_clk_cnt <= cpld_clk_cnt + 4'd1;
end

always @(posedge clk)
begin
   if (rstn == 0)
      cpld_load_reg <= 1'b0;
   else
      cpld_load_reg <= (cpld_clk_cnt == 4'd15);
end

always @(posedge clk)
begin
   if (rstn == 0)
      cpld_load_out_reg <= 1'b0;
   else
      cpld_load_out_reg <= cpld_load_reg;
end

assign cpld_load = cpld_load_out_reg;


//******************************************************************************
//* Sampling the CPLD serial input data.                                       *
//******************************************************************************
(* iob = "force" *)
reg cpld_miso_in_reg;
reg cpld_miso_sample;

always @(posedge clk)
begin
   cpld_miso_in_reg <= cpld_miso;
end

always @(posedge clk)
begin
   if (clk_divider_tc && (cpld_clk_reg == 0))
      cpld_miso_sample <= cpld_miso_in_reg;
end


//******************************************************************************
//* Shift register.                                                            *
//******************************************************************************
reg  [15:0] shr;
wire [15:0] shr_din;
reg         disp_sel;
(* iob = "force" *)
reg         cpld_mosi_reg;

assign shr_din[7:0]  = led_reg;
assign shr_din[15:8] = (disp_sel) ? disp1_reg : disp2_reg;

always @(posedge clk)
begin
   if (rstn == 0)
      shr <= 16'd0;
   else
      if (clk_divider_tc && cpld_clk_reg)
         if (cpld_load_reg)
            shr <= shr_din;
         else
            shr <= {cpld_miso_sample, shr[15:1]};
end

always @(posedge clk)
begin
   if (rstn == 0)
      disp_sel <= 1'b0;
   else
      if (clk_divider_tc && cpld_clk_reg && cpld_load_reg)
         disp_sel <= shr[14];
end

always @(posedge clk)
begin
   cpld_mosi_reg <= shr[0];
end

assign cpld_mosi = cpld_mosi_reg;


//******************************************************************************
//* DIP switch register (BASE+0x06, 8 bit, R).                                 *
//******************************************************************************
reg [7:0] dipsw_reg;
reg [7:0] dipsw_prev;

always @(posedge clk)
begin
   if (rstn == 0)
      dipsw_reg <= 8'd0;
   else
      if (clk_divider_tc && cpld_clk_reg && cpld_load_reg)
         dipsw_reg <= shr[8:1];
end

assign sw_out = dipsw_reg;

//Sampling the value of the DIP switch register.
always @(posedge clk)
begin
   dipsw_prev <= dipsw_reg;
end

//Generating the interrupt flag set signal.
assign dipsw_changed = |(dipsw_reg ^ dipsw_prev);


//******************************************************************************
//* Navigation switch and buttons register (BASE+0x0A, 8 bit, R).              *
//******************************************************************************
(* iob = "force" *)
reg [2:0] btn_in_reg;
reg [7:0] navsw_btn_reg;
reg [7:0] navsw_btn_prev;

always @(posedge clk)
begin
   btn_in_reg <= btn_in;
end

always @(posedge clk)
begin
   if (rstn == 0)
      navsw_btn_reg <= 8'd0;
   else
      if (clk_divider_tc && cpld_clk_reg && cpld_load_reg)
         navsw_btn_reg <= {btn_in_reg, shr[13:9]};
end

//Sampling the value of the navigation switch and buttons register.
always @(posedge clk)
begin
   navsw_btn_prev <= navsw_btn_reg;
end

//Generating the interrupt flag set signals.
assign navsw_changed = |(navsw_btn_reg[4:0] ^ navsw_btn_prev[4:0]);
assign btn_changed   = |(navsw_btn_reg[7:5] ^ navsw_btn_prev[7:5]);


//******************************************************************************
//* Driving the AXI output ports.                                              *
//******************************************************************************
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_Error = 1'b0;

always @(*)
begin
   case (Bus2IP_RdCE)
      4'b1000: IP2Bus_Data <= {8'd0, disp2_reg, disp1_reg, led_reg};
      4'b0100: IP2Bus_Data <= {8'd0, dipsw_reg, gpio_data_dout};
      4'b0010: IP2Bus_Data <= {8'd0, navsw_btn_reg, gpio_dir_dout};
      4'b0001: IP2Bus_Data <= {16'd0, if_reg_dout, ie_reg_dout};
      default: IP2Bus_Data <= 32'd0;
   endcase
end

endmodule 
