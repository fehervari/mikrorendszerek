`timescale 1ns / 1ps

module fifo
#(
	parameter WIDTH = 9
)
(
   input         clk,
   input         rst,
   input         wr,
   input         rd,
   input  [WIDTH-1:0] din,
   output [WIDTH-1:0] dout,
   output        empty,
   output        full
)/* synthesis syn_hier = "hard" */;
// Generating 16-deep SRL based shift register (no reset)
integer i;
reg [WIDTH-1:0] srl_shr[15:0];
always @ (posedge clk)
if (wr) begin
   for (i=15; i>0; i=i-1) begin
      srl_shr[i] <= srl_shr[i-1];
   end
   srl_shr[0] <= din;
end

// Data counter with the ability to count from 0 to 16
reg [4:0] srl_dcnt;
always @ (posedge clk)
if (rst)
   srl_dcnt <= 0;
else
   if (wr & ~rd)
      srl_dcnt <= srl_dcnt + 1;
   else if (~wr & rd)
      srl_dcnt <= srl_dcnt - 1;


// Read address for the SRL, 5 bit wide
reg [4:0] srl_addr;
always @ (posedge clk)
if (rst)
   srl_addr <= 5'h1F;
else
   if (wr & ~rd)
      srl_addr <= srl_addr + 1;
   else if (~wr & rd)
      srl_addr <= srl_addr - 1;

// FIFO status signals
assign empty = srl_addr[4];
assign full  = srl_dcnt[4];      

// Asyncronous data output
assign dout =srl_shr[srl_addr[3:0]];


endmodule
