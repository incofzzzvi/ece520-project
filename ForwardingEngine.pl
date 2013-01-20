#!/usr/bin/perl
use strict;
use warnings;


#variable used if no output file specified to set output
#to print to console
my $printConsole = 0;

if (@ARGV==0)
{
  # The number of command line parameters is 0,
  # so print an Usage message.
  usage();  # Call subroutine usage()
  exit();   
}
#if only 3 arguments, then assume no output file specified and print to 
#console
elsif (@ARGV==3)
{
	$printConsole=1;
}

#read in filenames from arguments
(my $dram_file,my $sram_file,my $address_file,my $output_file) = @ARGV;

#declare array to hold lines from files
my @sram_lines;
my @dram_lines;
my @address_lines;

#open files and store lines to array and open output file
openFilesToArray();

#calculate number of ones in each level
my @lvlOnes;
calcLvlOnes();

#calculate DRAM row where each level starts based on number of ones 
#in each level and last row of previous level
my @lvlStart;
calcLvlStart();

#iterate through each line in the address file
ADDRESS: foreach my $line (@address_lines) {
	
	#variable representing current level at in tree
	my $level=0;
	#current sram_line used beginning at start of level 0
	my $sram_line=$lvlStart[$level];
	#total number of ones ecnountered, used to calculate DRAM row
	my $totalOnes=0;
	#total number of previous ones, used to calculate rows to skip
	#in SRAM
	my $prevOnes=0;
	#difference between total number of ones in level and number of ones
	#before selected bit, used in calulation of DRAM row
	my $prev_diff=0;
	
	my $currLvlOnes = 0;
	my $sum = 0;
	my $tree_val = 0;
	
	#if line does not contain space then exit
	if(index($line, ' ') == -1) {exit;}
	
	#parse line into address and input port
	(my $in_port, my $address)=split(' ',$line);
	$address= hex($address);
	$in_port= hex($in_port);
	
	#printf("ADDRESS:\t %x \n", $address);
	#print("INPUT PORT:\t ",$in_port,"\n\n");
	
	#for each grouping of four bits in address, analyze
	for(my $count = 0; $count<8; $count++){
		
		#parse SRAM line into sum and tree value
		$sum = (hex($sram_lines[$sram_line]) & 0xFF000000) >> 24;
		$currLvlOnes = (hex($sram_lines[$sram_line]) & 0x00FF0000) >> 16;
		$tree_val = (hex($sram_lines[$sram_line]) & 0x0000FFFF);
		print "SRAM LINE: ".hex($sram_lines[$sram_line])."\n";
		#determine leaf number and then value at this location (0 or 1)
		my $mask = 0xF0000000 >> ($count*4);
		my $leaf_num = ($address & $mask)>>(28-$count*4);
		my $leaf_val = (($tree_val) >> (15-$leaf_num) & (0x00000001));
		
		print "LEAF NUM:\t ".$leaf_num."\n";
		print "LEAF VALUE:\t ".$leaf_val."\n";
		
		#if leaf value is 0, then have went to lowest possible level
		if($leaf_val == 0) {
			$totalOnes = $totalOnes - $prev_diff;
			print "PREV DIFF: ".$prev_diff."\n";
			print "TOT ONES: ".$totalOnes."\n";
			print "DRAM ROW: ".(int (($totalOnes*4) + ($leaf_num/4)))."  OFFSET: ".($leaf_num%4)."\n";
			my $out_port = ((hex($dram_lines[int (($totalOnes*4) + ($leaf_num/4))]) >> (24 - ($leaf_num % 4)*8)) & 0x000000FF);
			printf "OUT PORT: %X\n", $out_port;
			print "=======================================\n";
			
			if($printConsole){
				printf "%08X %X \n", $address, $out_port;
			}
			else{
				printf OUTPUT_FILE "%08X %X \n", $address, $out_port;
			}
			next ADDRESS;
		}
		#if not zero, continue analyzing
		else {
		
			$prevOnes = numOnes($tree_val,$leaf_num) + $sum ;
			print "NUM ONES: ".numOnes($tree_val,$leaf_num)."\n";
			$totalOnes+=$currLvlOnes;
			$prev_diff = $currLvlOnes - $prevOnes - 1;
			
			print "TOT ONES: ".$totalOnes."\n";
			print "PRV ONES: ".$prevOnes."\n";
			
			$sram_line = $lvlStart[++$level]+$prevOnes;
			
			print "NEXT SRAM LINE: ".$sram_line."\n";
		}
		
	}	
}

#close output file after finishing writing to it
close(OUTPUT_FILE);


#returns number of ones in number before bit number counting left to right
#numOnes(number with ones, number of bits)
sub numOnes
{
	#get arguments
	my $number = $_[0] & 0x0000FFFF;
	my $bits = $_[1];
	
	my $numOnes = 0;
	
	#for each bit, if one then increment count
	for(my $i =15; $i>(15-$bits); $i--){
		if((($number >> $i) & (0x0001)) == 1) {
			$numOnes++;
		}
	}
	
	return $numOnes;
}

sub openFilesToArray
{

	#open DRAM file and read in each line into array
	open DRAM_FILE, $dram_file or die $!;
	@dram_lines=<DRAM_FILE>;
	chomp(@dram_lines);
	close DRAM_FILE or die $!."\n".$dram_file." could not be opened";

	#open SRAM file and read in each line into array
	open SRAM_FILE, $sram_file or die $!."\n".$sram_file." could not be opened";
	@sram_lines=<SRAM_FILE>;
	chomp(@sram_lines);
	close SRAM_FILE or die $!;

	#open address input file and read in each line into array
	open ADDRESS_FILE, $address_file or die $!."\n".$address_file." could not be opened";
	@address_lines = <ADDRESS_FILE>;
	chomp(@address_lines);
	close ADDRESS_FILE or die $!;
	
	if(!$printConsole){
		#open output file in preparation to write to it
		open OUTPUT_FILE, ">".$output_file or die $!."\n".$output_file." could not be opened";
	}
}


#calculate number of ones in each level
sub calcLvlOnes
{
	my $curr_line=0;
	my $prev_line=0;

	for(my $i = 0; $i <8 ;$i++){
		if($i == 0) {
			my $sum = (hex($sram_lines[$curr_line]) & 0xFF000000) >> 24;
			my $tree_val = (hex($sram_lines[$curr_line]) & 0x0000FFFF);
			$lvlOnes[$i] = numOnes($tree_val,16) + $sum;
		}
		else{
			$curr_line = $lvlOnes[$i-1] + $prev_line;
			$prev_line = $curr_line;
			my $sum = (hex($sram_lines[$curr_line]) & 0xFF000000) >> 24;
			my $tree_val = (hex($sram_lines[$curr_line]) & 0x0000FFFF);
			$lvlOnes[$i]=numOnes($tree_val,16) + $sum;
		}
	}

}

#calculate SRAM row where each level starts based on number of ones 
#in each level and last row of previous level
sub calcLvlStart
{
	for(my $i = 0; $i <8 ;$i++){

		if($i == 0) { $lvlStart[$i] = 0; }
		elsif($i == 1) { $lvlStart[$i] = 1; }
		else {
			$lvlStart[$i] = $lvlStart[$i-1] + $lvlOnes[$i-2];
		}
	}
	
}

sub usage
{
  print "Usage: perl ForwardingEngine.pl DRAM.mem SRAM.mem input.txt output.txt\n";
}