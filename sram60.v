module SRAM60 (clock, WE, WriteAddress, ReadAddress1, WriteBus, ReadBus1);?
input  clock, WE; 
input  [9:0] WriteAddress, ReadAddress1; // Change as you change size of SRAM
input  [31:0] WriteBus;
output [31:0] ReadBus1;

reg [31:0]   Register [0:1024];   // 1024 words, each 32 bit (i.e. a  4 kB 
reg [31:0] ReadBus1;

// provide one write enable line per register
reg [1024:0] WElines;
integer i;

// Write '1' into write enable line for selected register
// Note:  Memory must have registered interfaces in your design
always@(*)
#30 WElines = (WE << WriteAddress);

always@(posedge clock)
    for (i=0; i<=1024; i=i+1)
      if (WElines[i]) Register[i] <= WriteBus;
 
always@(*) 
  begin 
    #30 ReadBus1  =  Register[ReadAddress1];
  end
endmodule
