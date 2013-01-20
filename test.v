module test_fixture;	
	reg clock = 0;
	reg reset = 1;				//global reset
	reg [31:0] sram_row_data;	//SRAM row retireved from memory
	reg [31:0] address;			//IP address 
	reg [2:0] count;			//count signal

	wire	[9:0] next_sram_row;
	wire	[9:0] dram_address;
	wire	done;

	reg [9:0] WriteAddressDRAM;
	reg [9:0] WriteAddressSRAM;
	reg [9:0] ReadAddressDRAM;
	reg [9:0] ReadAddressSRAM;
	reg [31:0] WriteBusDRAM;
	reg [31:0] WriteBusSRAM;
	
	wire [31:0] ReadBusDRAM;
	wire [31:0] ReadBusSRAM;
	
	reg [31:0] SRAM_data[1024:0];
	reg [31:0] DRAM_data[1024:0];
	reg [31:0] addresses[1499:0];
	
	reg WE = 1'b1;
	
	integer i;
	integer j;
	
	integer ret_val;
	integer input_addresses; 
	
	reg [12:0] input_port;
	initial	//following block executed only once
	  begin
	  
		input_addresses = $fopen("rout_input_final.mem","r");
		
		$readmemh("sram_final.mem",SRAM_data);
		$readmemh("dram_final.mem",DRAM_data);

		
		for(i=0; i<1025;i=i+1)
		begin
			#12
			WriteAddressDRAM = i;
			WriteBusDRAM = DRAM_data[i];
			
			WriteAddressSRAM = i;
			WriteBusSRAM = SRAM_data[i];
		end
		#10 WE = 1'b0;
		ReadAddressSRAM = 10'b0;
		
		for(j=0; j<1500; j=j+1)
		begin
			ret_val = $fscanf(input_addresses,"%X %X", input_port,address);
			$display("ADDRESS :  %X\n", address );
			for (i=0; i<8; i=i+1)
			begin 
				//ReadAddressSRAM = next_sram_row;
				$display("next_sram_row :  %d\n", next_sram_row );
				sram_row_data = SRAM_data[next_sram_row];
				$display("sram_row_data :  %X\n", sram_row_data );
				count = i;
				#12
				$display("DONE:  %d\n", done);
				if(done==1'b1)
				begin
					ReadAddressDRAM = dram_address;
					#32
					$display("DRAM ROW: %X  \n", DRAM_data[dram_address]);
					//make i more than 8 so loop exits and next address fetched
					i=8;
				end	
			end
			if(ret_val == -1) $finish;
		end	
		/*
		#12 address = 32'hD091BB5B;
			ReadAddressSRAM = 10'b0;
			#.5
			sram_row_data = ReadBusSRAM;
			count = 3'b0;
		#10 count=3'd1;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
		#10 count=3'd2;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
		#10 count=3'd3;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
		#10 count=3'd4;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
		#10 count=3'd5;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
		#10 count=3'd6;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);
			if(done == 1'b1)
			begin
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			end
		#10 count=3'd7;
			ReadAddressSRAM = next_sram_row;
			#.5
			sram_row_data = ReadBusSRAM;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);	
		#10 //count=3'd8;
			//sram_row_data = 32'h0010FFFF;
			$display("next_sram_row: %d \t dram_address: %d \t done: %d \n", next_sram_row, dram_address, done);		
		*/
		
		#100 $finish;		//finished with simulation
  	end
	always #5 clock = ~clock;	// 10ns clock

	// instantiate modules 
	datapath 	u1(  .clock(clock), .sram_row_data(sram_row_data), .address(address), 
					.reset(reset), .count(count), .next_sram_row(next_sram_row), 
					.dram_address(dram_address), .done(done));
					
	SRAM60		u2(.clock(clock), .WE(WE),.ReadAddress1(ReadAddressDRAM), .WriteAddress(WriteAddressDRAM),.WriteBus(WriteBusDRAM),
					.ReadBus1(ReadBusDRAM));
	
	SRAM		u3(.clock(clock), .WE(WE), .ReadAddress1(ReadAddressSRAM),.WriteAddress(WriteAddressSRAM),.WriteBus(WriteBusSRAM),
					.ReadBus1(ReadBusSRAM));
				
endmodule  /*test_fixture*/