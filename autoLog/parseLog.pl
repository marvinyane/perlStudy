#! /usr/bin/perl
use warnings;
use strict;
use Storable qw(dclone);
use JSON;

die $#ARGV unless $#ARGV == 1;

open INPUT, "<$ARGV[0]" or die $!;
open OUTPUT, ">$ARGV[1]" or die $!;

my @info= ();
my $paramStr = "";
my $key;
my $time;
my $starttime;

my @log = grep{/^\[APP\]/} <>;
print $#log;
while(<INPUT>){
	if(/\[APP\]:\s*(\w+)\s(\d+)\s*$/){
		if(defined $key){
			my %tmp;
			$tmp{'textname'} = $key;
			$tmp{'param'} = $paramStr;
			$tmp{'x'} = &getMark($key)>>1;
			$tmp{'y'} = -1;
			$tmp{'timevalue'} = $time;
			$paramStr = "";
			push( @info, \%tmp);
		}

		$key = $1;

		unless(defined $starttime){
			$starttime = $2;
		}

		$time = $2 - $starttime;
	}
	elsif(/\[APP\]:\s\[Param\]\s*(.*?)\s*$/){
		$paramStr .= "$1\n";
	}
	elsif(/\[APP\]/){
		print $_;
	}
}

if(defined $key){
	my %tmp;
	$tmp{'textname'} = $key;
	$tmp{'param'} = $paramStr;
	$tmp{'x'} = &getMark($key)>>1;
	$tmp{'y'} = -1;
	$tmp{'timevalue'} = $time;

	push( @info, \%tmp);
}

sub getMark(){
	my $total_name = shift;
	my $tmp_name = substr($total_name, length($total_name)-4, 4);
	if( $tmp_name eq '_REQ' ){
		return 0;
	}
	if( $tmp_name eq '_RES'){
		return 1;
	}
	elsif($tmp_name eq '_CFM'){
		return 2;
	}
	elsif($tmp_name eq '_IND'){
		my $comp = substr($total_name, length($total_name)-8, 4);
		if($comp eq '_COM'){
			return 4;
		}
		$comp = substr($total_name, length($total_name)-9, 5);
		if($comp eq '_COMP'){
			return 4;
		}
		$comp = substr($total_name, length($total_name)-13, 9);
		if($comp eq '_COMPLETE'){
			return 4;
		}
		return 5;
	}
	else{
		print "what? $tmp_name";
		return 6;
	}
}

sub parseRelation(){
	my $y = 0;
	my $start = 0;
	for($start = 0; $start <= $#info; $start++){
		my %hash = %{$info[$start]};
		if($hash{'y'} ne -1){
			next;
		}
		$y ++;
		my $mark = &getMark($hash{'textname'});
		my $name = $hash{'textname'};

		if($mark == 0){
			my $name_len = length($hash{'textname'}) - 4;
			my $name = substr($hash{'textname'}, 0, $name_len);
			$hash{'y'} = $y; 
			for(my $i = $start+1; $i <= $#info; $i++){
				my %t_h = %{$info[$i]};
				my $t_m = &getMark($t_h{'textname'});

				if(length($t_h{'textname'}) > $name_len && 
					$name eq substr($t_h{'textname'}, 0, $name_len))
				{
					if($t_m eq 0 ){
						my $t_len = length($t_h{'textname'}) - $name_len;
						print "$t_h{'textname'} ############# $t_len \n";
						if($t_len eq 4){
							last;
						}
						else{
							next;
						}
					}
					elsif($t_m eq 2){
						unless(length($t_h{'textname'}) - $name_len eq 4){
							next;
						}
					}
					elsif($t_m eq 1){
						next;
					}

					$t_h{'y'} = $y;
					$info[$i] = \%t_h;

					if($t_m eq 4){
						last;
					}
				}
			}
		}

		elsif($mark == 5 )
		{
			my $name_len = length($hash{'textname'}) - 4;
			my $name = substr($hash{'textname'}, 0, $name_len);
			$hash{'y'} = $y; 
			for(my $i = $start+1; $i <= $#info; $i++){
				my %t_h = %{$info[$i]};
				my $t_m = &getMark($t_h{'textname'});

				if(length($t_h{'textname'}) > $name_len && 
					$name eq substr($t_h{'textname'}, 0, $name_len) &&
					$t_m == 1)
				{

					$t_h{'y'} = $y;
					$info[$i] = \%t_h;
					last;
				}
			}

		}
		else{
			$hash{'y'} = $y;
		}

		$info[$start] = \%hash;
	}
}

&parseRelation();

my $jsonStr = "var employees = [ \n";
foreach (@info){
	my %h = %{$_};
	my $p_y = $h{'y'};
	my $json = encode_json \%h;
	$jsonStr .= "$json,\n";
}
$jsonStr .= "];";

print OUTPUT $jsonStr;

close INPUT;
close OUTPUT;