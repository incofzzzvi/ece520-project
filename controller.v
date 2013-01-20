module controller( input clock, input reset, input run, output count);

//begin counting when run is high

reg [2:0] count;	//counter used to control timing

always@(posedge clock)
begin
	if(reset)
	begin
		count <= 3'b0;
	end
	else if(start)
	begin
		//if count at 8, restart at 0
		if(count == 3'b111)
			count <= 3'b000;
		//increment count
		count <= count + 1'b1;
	end
end
	