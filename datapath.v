module datapath(clock, reset, sram_row_data, address, count,
				next_sram_row, dram_address, done);

input clock;
input reset;				//global reset
input [31:0] sram_row_data;	//SRAM row retireved from memory
input [31:0] address;		//IP address 
input [2:0] count;			//count signal (timing)
output [9:0] next_sram_row;	//next sram row to access
output [9:0] dram_address;	//dram address for lookup
output done;				//control flag to signal finished traversal and 
							//dram address ready (true high)

reg done = 1'b0;			//default register done to not ready (0)
reg done_in = 1'b0;			//variable for done					
reg [9:0] dram_address_in;	//variable for dram_address
reg [9:0] dram_address;		//register for dram_address
reg [9:0] next_sram_row = 10'b0;	//variable for sram row
reg [9:0] next_sram_row_in = 10'b0;	//register for sram row

reg [7:0] sum;			//sum of ones in previous rows for current level
reg [7:0] currLvlOnes;	//number of ones in current level
reg [15:0] tree_val;	//tree value of SRAM used for traversal
reg [3:0] leaf_num;		//index of leaf within tree value
reg leaf_val;			//value of leaf (0 or 1)


reg [7:0] prev_ones;    //variable for count of number of ones encounetered in current level
reg  [15:0] masked_row;   //variable for SRAM row data after mask applied
reg [4:0] row_ones;     	//number of ones in currest SRAM row before leaf bit
reg [15:0] bitMask;		//bit mask for removing unwanted ones


reg [7:0] total_ones=8'b0;    // register for total number of ones encountered
reg [7:0] total_ones_in = 8'b0; //variable for total number of ones


reg [15:0] prev_diff_in = 16'b0;	//register that saves difference of ones for level so can be
									//subtracted when traversal ends
reg [15:0] prev_diff;


reg [7:0] row_count = 8'b0;	//register that tracks number of ones in previous row so location
							//of next level in SRAM is known								
reg [7:0] row_count_in = 8'b0; //temporary variable for row_count

always@(posedge clock)
begin 
	if(reset)
	begin
		
	end
	
	if(new)
	begin 
	end
	
	//copy temporary variables into registers
	prev_diff <= prev_diff_in;
	row_count <= row_count_in;
	total_ones <= total_ones_in;
	next_sram_row <= next_sram_row_in;
	dram_address <= dram_address_in;
	done <= done_in;
end

always@(sram_row_data or count)
begin

	//split SRAM row into relevant values
	{sum[7:0], currLvlOnes[7:0], tree_val[15:0]} = sram_row_data[31:0];
	
	//save number of ones so number of rows in SRAM for next level is known
	row_count_in = currLvlOnes + row_count;
	
	//extract the index (leaf_num) for the leaf value
	casex(count) 
		3'd0 : leaf_num = address[31:28];
		3'd1 : leaf_num = address[27:24];
		3'd2 : leaf_num = address[23:20];
		3'd3 : leaf_num = address[19:16];
		3'd4 : leaf_num = address[15:12];
		3'd5 : leaf_num = address[11:8];
		3'd6 : leaf_num = address[7:4];
		3'd7 : leaf_num = address[3:0];
		default: leaf_num = address[3:0];
	endcase	
	
	
	//use leaf index to extract single bit leaf value
	casex(leaf_num) 
		4'd0 : leaf_val = tree_val[15];
		4'd1 : leaf_val = tree_val[14];
		4'd2 : leaf_val = tree_val[13];
		4'd3 : leaf_val = tree_val[12];
		4'd4 : leaf_val = tree_val[11];
		4'd5 : leaf_val = tree_val[10];
		4'd6  : leaf_val = tree_val[9];
		4'd7  : leaf_val = tree_val[8];
		4'd8  : leaf_val = tree_val[7];
		4'd9  : leaf_val = tree_val[6];
		4'd10  : leaf_val = tree_val[5];
		4'd11  : leaf_val = tree_val[4];
		4'd12  : leaf_val = tree_val[3];
		4'd13  : leaf_val = tree_val[2];
		4'd14  : leaf_val = tree_val[1];
		4'd15  : leaf_val = tree_val[0];
		default: leaf_val = tree_val[0]; 	
	endcase
	
	//$display("leaf_val: %d \n", leaf_val);

	//if one, prepare to continue traversal at next level
	if(leaf_val == 1'b1)
		begin
			//generate mask to remove unwanted 1's
			case(leaf_num)
				4'd0  : bitMask = 16'b1000000000000000;
				4'd1  : bitMask = 16'b1100000000000000;
				4'd2  : bitMask = 16'b1110000000000000;
				4'd3  : bitMask = 16'b1111000000000000;
				4'd4  : bitMask = 16'b1111100000000000;
				4'd5  : bitMask = 16'b1111110000000000;
				4'd6  : bitMask = 16'b1111111000000000;
				4'd7  : bitMask = 16'b1111111100000000;
				4'd8  : bitMask = 16'b1111111110000000;
				4'd9  : bitMask = 16'b1111111111000000;
				4'd10 : bitMask = 16'b1111111111100000;
				4'd11 : bitMask = 16'b1111111111110000;
				4'd12 : bitMask = 16'b1111111111111000;
				4'd13 : bitMask = 16'b1111111111111100;
				4'd14 : bitMask = 16'b1111111111111110;
				4'd15 : bitMask = 16'b1111111111111111;
				default : bitMask = 16'b1111111111111111;
			endcase
			
			//apply mask to remove unwanted ones
			masked_row  = (tree_val & bitMask);
			
			//REPLACE SUBTRACTION WITH MODIFIED MASKS
			
			//sum number of ones in value subtraction to remove indexed bit
				row_ones  = masked_row[15] + masked_row[14] + masked_row[13] + masked_row[12] + 
					masked_row[11] + masked_row[10] + masked_row[9] + masked_row[8] + masked_row[7] +
					masked_row[6] + masked_row[5] + masked_row[4] + masked_row[3] + masked_row[2] + 
					masked_row[1] + masked_row[0] - 1'b1;
		
			
			//calculate number of ones in level before leaf bit
			prev_ones = row_ones + sum;	
			
			//add number of ones in current level to total count
			total_ones_in = total_ones + currLvlOnes;
			
			//saves difference of total number of ones in level and number
			//of ones before leaf bit, used if next level ends traversal and
			//need to remove ones
			prev_diff_in = currLvlOnes - prev_ones -  1'b1;
			
			
			//REMOVE +1 when using actual mems
			//HERE ones just aligns with txt file
			
			
			//calculate next sram row address
			next_sram_row_in = row_count + prev_ones +1'b1;
			
			done_in = 1'b0;
		end
		
	//if leaf value is zero, conclude traversal and output DRAM row
	else if(leaf_val == 1'b0)
		begin
			//remove ones added in previous level traversal
			total_ones_in = total_ones - prev_diff;	
			
			//calculate DRAM Address using total ones and part extracted from address (leaf_num)
			dram_address_in = (total_ones_in << 2) + (leaf_num >> 2);
			
			//$display("dram_address: %d \n", dram_address);
			
			$display("offset: %d \n", leaf_num%4);
			
			done_in = 1'b1;
			
		end
	end

endmodule
