`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

//******************************************************************************
//* Folyadékszint jelzõ periféria.                                             *
//*                                                                            *
//*  ------------     ----                                                     *
//* |          O-|-->|    |                                                    *
//* |          O-|-->|    | folyadékszint                                      *
//* |          O-|-->|    |     (0-8)      ------------                        *
//* |~~~~~~~~~~O-|-->|    |/-------------\| MicroBlaze |                       *
//* |~~~~~~~~~~O-|-->|    |\-------------/| CPU        |                       *
//* |~~~~~~~~~~O-|-->|    |   AXI4-Lite    ------------                        *
//* |~~~~~~~~~~O-|-->|    |                                                    *
//* |~~~~~~~~~~O-|-->|    |------> IRQ                                         *
//*  ------------     ----                                                     *
//*    tartály      periféria                                                  *
//******************************************************************************
module user_logic #(
   //Az IPIF interfészhez tartozó paraméterek.
   parameter C_NUM_REG                      = 3,		//Az IPIF által dekódolt 32 bites regiszterek száma.
   parameter C_SLV_DWIDTH                   = 32		//Az adatbusz szélessége bitekben.
   
   //Itt kell megadni a többi saját paramétert.
) (
   //Az IPIF interfészhez tartozó portok. Ha a Create or Import Peripheral
   //Wizard-ban nem jelöltük be a memória interfészhez tartozó Bus2IP_Addr,
   //Bus2IP_CS és Bus2IP_RNW jelek hozzáadását, akkor ezeket innen töröljük.
   input  wire                      Bus2IP_Clk,			//Órajel.
   input  wire                      Bus2IP_Resetn,		//Aktív alacsony reset jel.
   //input  wire [31:0]               Bus2IP_Addr,		//Címbusz.
   //input  wire [0:0]                Bus2IP_CS,		//A periféria címtartományának elérését jelzõ jel.
   //input  wire                      Bus2IP_RNW,		//A mûvelet típusát (0: írás, 1: olvasás) jelzõ jel.
   input  wire [C_SLV_DWIDTH-1:0]   Bus2IP_Data,		//Írási adatbusz.
   input  wire [C_SLV_DWIDTH/8-1:0] Bus2IP_BE,			//Bájt engedélyezõ jelek (csak írás esetén érvényesek).
   input  wire [C_NUM_REG-1:0]      Bus2IP_RdCE,		//A regiszterek olvasás engedélyezõ jelei.
   input  wire [C_NUM_REG-1:0]      Bus2IP_WrCE,		//A regiszterek írás engedélyezõ jelei.
   output reg  [C_SLV_DWIDTH-1:0]   IP2Bus_Data,		//Olvasási adatbusz.
   output wire                      IP2Bus_RdAck,		//Az olvasási mûveletek nyugtázó jele.
   output wire                      IP2Bus_WrAck,		//Az írási mûveletek nyugtázó jele.
   output wire                      IP2Bus_Error,		//Hibajelzés.
   
   //Itt kell megadni a többi saját portot.
	input  wire [7:0]                sensor_in,        //Folyadékszint érzékelõ szenzor bemenet.
	output wire                      irq               //Megszakításkérõ kimenet.
);

//******************************************************************************
//* Órajel és reset.                                                           *
//******************************************************************************
wire clk =  Bus2IP_Clk;
wire rst = ~Bus2IP_Resetn;


//******************************************************************************
//* A szenzor bemenetre a DIP kapcsolót kötjük, melyen felléphet pergés. Ennek *
//* elkerülése végett a bemenetet 10 Hz frekvenciával mintavételezzük, az üte- *
//* mezõ jelet egy 23 bites számlálóval állítjuk elõ (4999999 - 0 => 23 bit).  *
//******************************************************************************
reg  [22:0] clk_div;
wire        clk_div_tc = (clk_div == 23'd0);

always @(posedge clk)
begin
	if (rst || clk_div_tc)
		clk_div <= 23'd4999999;
	else
		clk_div <= clk_div - 23'd1;
end

reg [7:0] sensor_reg;

always @(posedge clk)
begin
	if (rst)
		sensor_reg <= 8'd0;
	else
		if (clk_div_tc)
			sensor_reg <= sensor_in;
end


//******************************************************************************
//* A szenzor bemenet alapján a folyadékszintet egy prioritás enkóderrel       *
//* állíthatjuk elõ. A legnagyobb sorszámú aktív bit határozza meg a           *
//* folyadékszint értékét.                                                     *
//******************************************************************************
reg [3:0] fluid_level;

always @(posedge clk)
begin
	if (rst)
		fluid_level <= 4'd0;
	else
		casex (sensor_reg)
			8'b1xxx_xxxx: fluid_level <= 4'd8;
			8'b01xx_xxxx: fluid_level <= 4'd7;
			8'b001x_xxxx: fluid_level <= 4'd6;
			8'b0001_xxxx: fluid_level <= 4'd5;
			8'b0000_1xxx: fluid_level <= 4'd4;
			8'b0000_01xx: fluid_level <= 4'd3;
			8'b0000_001x: fluid_level <= 4'd2;
			8'b0000_0001: fluid_level <= 4'd1;
			8'b0000_0000: fluid_level <= 4'd0;
		endcase
end


//******************************************************************************
//* A hibajelzés elõállítása. Érvényes a szenzor bemeneten lévõ adat, ha       *
//* a legnagyobb sorszámú aktív bemeneti bit alatti összes bit is aktív.       *
//******************************************************************************
reg error;

always @(posedge clk)
begin
	if (rst)
		error <= 1'b0;
	else
		case (sensor_reg)
			8'b1111_1111: error <= 1'b0;
			8'b0111_1111: error <= 1'b0;
			8'b0011_1111: error <= 1'b0;
			8'b0001_1111: error <= 1'b0;
			8'b0000_1111: error <= 1'b0;
			8'b0000_0111: error <= 1'b0;
			8'b0000_0011: error <= 1'b0;
			8'b0000_0001: error <= 1'b0;
			8'b0000_0000: error <= 1'b0;
			default     : error <= 1'b1;
		endcase
end


//******************************************************************************
//* Státusz regiszter: BASEADDR+0x00, 32 bites, csak olvasható                 *
//*                                                                            *
//*    31    30          4     3     2     1     0                             *
//*  -----------------------------------------------                           *
//* |ERROR|        0        |  folyadékszint (0-8)  |                          *
//*  -----------------------------------------------                           * 
//******************************************************************************
wire [31:0] status_reg = {error, 27'd0, fluid_level};


//******************************************************************************
//* Megszakítás engedélyezõ reg.: BASEADDR+0x04, 32 bites, írható/olvasható    *
//*                                                                            *
//*    31                      3     2     1     0                             *
//*  -----------------------------------------------                           *
//* |  x     x     x     x    x   |ERROR|EMPTY| FULL|                          *
//*  -----------------------------------------------                           *
//******************************************************************************
reg [2:0] ier;

always @(posedge clk)
begin
	if (rst)
		ier <= 3'b000;
	else
		if (Bus2IP_WrCE[1] && (Bus2IP_BE == 4'b1111))
			ier <= Bus2IP_Data[2:0];
end

//******************************************************************************
//* Megszakítás flag regiszter: BASEADDR+0x08, 32 bites, olvasható és a jelzés *
//*                             '1' beírásával törölhetõ                       *
//*                                                                            *
//*    31                      3     2     1     0                             *
//*  -----------------------------------------------                           *
//* |  x     x     x     x    x   |ERROR|EMPTY| FULL|                          *
//*  -----------------------------------------------                           *
//******************************************************************************
reg [1:0] in7_samples;
reg [1:0] in0_samples;
reg [1:0] err_samples;

always @(posedge clk)
begin
	if (rst)
	begin
		in7_samples <= 2'b11;
		in0_samples <= 2'b11;
		err_samples <= 2'b11;
	end
	else
	begin
		in7_samples <= {in7_samples[0], (fluid_level == 4'd8)};
		in0_samples <= {in0_samples[0], (fluid_level == 4'd0)};
		err_samples <= {err_samples[0], error};
	end
end

reg  [2:0] ifr;
wire [2:0] ifr_set;

//A tartály éppen megtelt (FULL): a folyadékszint 8 értékre változott.
assign ifr_set[0] = (in7_samples == 2'b01);
//A tartály éppen kiürült (EMPTY): a folyadékszint 0 értékre változott.
assign ifr_set[1] = (in0_samples == 2'b01);
//Hiba történt (ERROR): felfutó él a hibajelzésen.
assign ifr_set[2] = (err_samples == 2'b01);

integer i;

//A megszakítás flag regisztert egyetlen always blokkban írjuk le, FOR
//ciklussal indexelve a biteket. A bitek beállítása nagyobb prioritású
//az '1' beírásának hatására megtörténõ törlésnél.
always @(posedge clk)
begin
	for (i = 0; i < 3; i = i + 1)
		if (rst)
			ifr[i] <= 1'b0;
		else
			if (ifr_set[i])
				ifr[i] <= 1'b1;
			else
				if (Bus2IP_WrCE[0] && (Bus2IP_BE == 4'b1111) && Bus2IP_Data[i])
					ifr[i] <= 1'b0;
end

//Jelezzük a megszakításkérést, ha van aktív esemény, amely engedélyezett is.
assign irq = |(ier & ifr);


//******************************************************************************
//* Az olvasási adatbusz meghajtása. Csak akkor adhatunk ki az inaktív 0-tól   *
//* különbözõ értéket, ha kaptunk regiszter olvasási parancsot.                *
//******************************************************************************
always @(*)
begin
	case (Bus2IP_RdCE)
		3'b100 : IP2Bus_Data <= status_reg;
		3'b010 : IP2Bus_Data <= {29'd0, ier};
		3'b001 : IP2Bus_Data <= {29'd0, ifr};
		default: IP2Bus_Data <= 32'd0;
	endcase
end


//******************************************************************************
//* Az IPIF felé menõ egyéb jelek meghajtása.                                  *
//******************************************************************************
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_Error = 1'b0;


endmodule
