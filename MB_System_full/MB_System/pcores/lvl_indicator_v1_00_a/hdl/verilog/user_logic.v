`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

//******************************************************************************
//* Folyad�kszint jelz� perif�ria.                                             *
//*                                                                            *
//*  ------------     ----                                                     *
//* |          O-|-->|    |                                                    *
//* |          O-|-->|    | folyad�kszint                                      *
//* |          O-|-->|    |     (0-8)      ------------                        *
//* |~~~~~~~~~~O-|-->|    |/-------------\| MicroBlaze |                       *
//* |~~~~~~~~~~O-|-->|    |\-------------/| CPU        |                       *
//* |~~~~~~~~~~O-|-->|    |   AXI4-Lite    ------------                        *
//* |~~~~~~~~~~O-|-->|    |                                                    *
//* |~~~~~~~~~~O-|-->|    |------> IRQ                                         *
//*  ------------     ----                                                     *
//*    tart�ly      perif�ria                                                  *
//******************************************************************************
module user_logic #(
   //Az IPIF interf�szhez tartoz� param�terek.
   parameter C_NUM_REG                      = 3,		//Az IPIF �ltal dek�dolt 32 bites regiszterek sz�ma.
   parameter C_SLV_DWIDTH                   = 32		//Az adatbusz sz�less�ge bitekben.
   
   //Itt kell megadni a t�bbi saj�t param�tert.
) (
   //Az IPIF interf�szhez tartoz� portok. Ha a Create or Import Peripheral
   //Wizard-ban nem jel�lt�k be a mem�ria interf�szhez tartoz� Bus2IP_Addr,
   //Bus2IP_CS �s Bus2IP_RNW jelek hozz�ad�s�t, akkor ezeket innen t�r�lj�k.
   input  wire                      Bus2IP_Clk,			//�rajel.
   input  wire                      Bus2IP_Resetn,		//Akt�v alacsony reset jel.
   //input  wire [31:0]               Bus2IP_Addr,		//C�mbusz.
   //input  wire [0:0]                Bus2IP_CS,		//A perif�ria c�mtartom�ny�nak el�r�s�t jelz� jel.
   //input  wire                      Bus2IP_RNW,		//A m�velet t�pus�t (0: �r�s, 1: olvas�s) jelz� jel.
   input  wire [C_SLV_DWIDTH-1:0]   Bus2IP_Data,		//�r�si adatbusz.
   input  wire [C_SLV_DWIDTH/8-1:0] Bus2IP_BE,			//B�jt enged�lyez� jelek (csak �r�s eset�n �rv�nyesek).
   input  wire [C_NUM_REG-1:0]      Bus2IP_RdCE,		//A regiszterek olvas�s enged�lyez� jelei.
   input  wire [C_NUM_REG-1:0]      Bus2IP_WrCE,		//A regiszterek �r�s enged�lyez� jelei.
   output reg  [C_SLV_DWIDTH-1:0]   IP2Bus_Data,		//Olvas�si adatbusz.
   output wire                      IP2Bus_RdAck,		//Az olvas�si m�veletek nyugt�z� jele.
   output wire                      IP2Bus_WrAck,		//Az �r�si m�veletek nyugt�z� jele.
   output wire                      IP2Bus_Error,		//Hibajelz�s.
   
   //Itt kell megadni a t�bbi saj�t portot.
	input  wire [7:0]                sensor_in,        //Folyad�kszint �rz�kel� szenzor bemenet.
	output wire                      irq               //Megszak�t�sk�r� kimenet.
);

//******************************************************************************
//* �rajel �s reset.                                                           *
//******************************************************************************
wire clk =  Bus2IP_Clk;
wire rst = ~Bus2IP_Resetn;


//******************************************************************************
//* A szenzor bemenetre a DIP kapcsol�t k�tj�k, melyen fell�phet perg�s. Ennek *
//* elker�l�se v�gett a bemenetet 10 Hz frekvenci�val mintav�telezz�k, az �te- *
//* mez� jelet egy 23 bites sz�ml�l�val �ll�tjuk el� (4999999 - 0 => 23 bit).  *
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
//* A szenzor bemenet alapj�n a folyad�kszintet egy priorit�s enk�derrel       *
//* �ll�thatjuk el�. A legnagyobb sorsz�m� akt�v bit hat�rozza meg a           *
//* folyad�kszint �rt�k�t.                                                     *
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
//* A hibajelz�s el��ll�t�sa. �rv�nyes a szenzor bemeneten l�v� adat, ha       *
//* a legnagyobb sorsz�m� akt�v bemeneti bit alatti �sszes bit is akt�v.       *
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
//* St�tusz regiszter: BASEADDR+0x00, 32 bites, csak olvashat�                 *
//*                                                                            *
//*    31    30          4     3     2     1     0                             *
//*  -----------------------------------------------                           *
//* |ERROR|        0        |  folyad�kszint (0-8)  |                          *
//*  -----------------------------------------------                           * 
//******************************************************************************
wire [31:0] status_reg = {error, 27'd0, fluid_level};


//******************************************************************************
//* Megszak�t�s enged�lyez� reg.: BASEADDR+0x04, 32 bites, �rhat�/olvashat�    *
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
//* Megszak�t�s flag regiszter: BASEADDR+0x08, 32 bites, olvashat� �s a jelz�s *
//*                             '1' be�r�s�val t�r�lhet�                       *
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

//A tart�ly �ppen megtelt (FULL): a folyad�kszint 8 �rt�kre v�ltozott.
assign ifr_set[0] = (in7_samples == 2'b01);
//A tart�ly �ppen ki�r�lt (EMPTY): a folyad�kszint 0 �rt�kre v�ltozott.
assign ifr_set[1] = (in0_samples == 2'b01);
//Hiba t�rt�nt (ERROR): felfut� �l a hibajelz�sen.
assign ifr_set[2] = (err_samples == 2'b01);

integer i;

//A megszak�t�s flag regisztert egyetlen always blokkban �rjuk le, FOR
//ciklussal indexelve a biteket. A bitek be�ll�t�sa nagyobb priorit�s�
//az '1' be�r�s�nak hat�s�ra megt�rt�n� t�rl�sn�l.
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

//Jelezz�k a megszak�t�sk�r�st, ha van akt�v esem�ny, amely enged�lyezett is.
assign irq = |(ier & ifr);


//******************************************************************************
//* Az olvas�si adatbusz meghajt�sa. Csak akkor adhatunk ki az inakt�v 0-t�l   *
//* k�l�nb�z� �rt�ket, ha kaptunk regiszter olvas�si parancsot.                *
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
//* Az IPIF fel� men� egy�b jelek meghajt�sa.                                  *
//******************************************************************************
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_Error = 1'b0;


endmodule
