//******************************************************************************
//* FIFO with configurable depth and word size.                                *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 1.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module fifo #(
   //Depth of the FIFO.
   parameter DEPTH            = 16,
   //Number of bits in the data words.
   parameter WIDTH            = 8,
   //The programmable full flag is set to 1 when the FIFO
   //contains at least PRG_FULL_H_TRESH data words.
   parameter PRG_FULL_H_TRESH = 12,
   //The programmable full flag is set to 0 when the FIFO
   //contains less than PRG_FULL_L_TRESH data words.
   parameter PRG_FULL_L_TRESH = 8
) (
   //Clock and reset.
   input  wire             clk,        //Clock signal
   input  wire             rstn,       //Reset signal (active-low)
   
   //Data input and output.
   input  wire [WIDTH-1:0] data_in,    //FIFO data input
   output wire [WIDTH-1:0] data_out,   //FIFO data output
   
   //Control inputs.
   input  wire             write,      //FIFO write signal
   input  wire             read,       //FIFO read signal
   
   //Status outputs.
   output reg              exists,     //FIFO is not empty
   output reg              full,       //FIFO is full
   output reg              prg_full    //Programmable FULL flag
);

`include "functions.vh"

//******************************************************************************
//* Dynamic shift register.                                                    *
//******************************************************************************
localparam CNT_LEN = log2(DEPTH - 1);
    
reg  [DEPTH-1:0]   fifo_shr [WIDTH-1:0];
reg  [CNT_LEN-1:0] read_address;
wire               fifo_shr_en = write & (~full | read);

genvar i;   

generate
   for (i = 0; i < WIDTH; i = i + 1)
   begin : shr_loop
      always @(posedge clk)
         if (fifo_shr_en)
            fifo_shr[i] <= {fifo_shr[i][DEPTH-2:0], data_in[i]};
      
      assign data_out[i] = fifo_shr[i][read_address];
   end
endgenerate


//******************************************************************************
//* Read address counter.                                                      *
//******************************************************************************
wire read_address_min = (read_address == 0);
wire read_address_max = (read_address == (DEPTH - 1));
wire read_address_inc = ~read_address_max &  write & ~read & exists;
wire read_address_dec = ~read_address_min & ~write &  read;
  
always @(posedge clk)
begin
   if (rstn == 0)
      read_address <= 0;
   else
      if (read_address_inc)
         read_address <= read_address + 1;
      else
         if (read_address_dec)
            read_address <= read_address - 1;
end 


//******************************************************************************
//* FIFO status bits.                                                          *
//******************************************************************************
//FIFO not empty status flag.
wire exists_clr = read_address_min & read & ~write;
wire exists_set = write;

always @(posedge clk)
begin
   if ((rstn == 0) || exists_clr)
      exists <= 1'b0;
   else
      if (exists_set)
         exists <= 1'b1;
end

//FIFO full ststus flag.
wire full_set = (read_address == (DEPTH - 2)) & write & ~read;
wire full_clr = ~write & read;

always @(posedge clk)
begin
   if ((rstn == 0) || full_clr)
      full <= 1'b0;
   else
      if (full_set)
         full <= 1'b1;
end

//Programmable FULL status flag.
wire prg_full_set = (read_address == (PRG_FULL_H_TRESH - 2)) &  write & ~read;
wire prg_full_clr = (read_address == (PRG_FULL_L_TRESH - 1)) & ~write &  read;

always @(posedge clk)
begin
   if ((rstn == 0) || prg_full_clr)
      prg_full <= 1'b0;
   else
      if (prg_full_set)
         prg_full <= 1'b1;
end

endmodule
