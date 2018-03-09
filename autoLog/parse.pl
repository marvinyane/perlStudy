#! /usr/bin/perl -w
use strict;
use JSON;
use Data::Dumper qw(Dumper);

open INPUT, "<$ARGV[0]" or die $!;

#my @log = grep{/^\[APP\]/} <INPUT>;

#chomp(@log);

#print Dumper(\@log);

#my @tmp = map{[split ' ']} @log;

#print Dumper(\@tmp);


#grep {
#	$hash{$$_[1]}=join ' ', @$_[2..$#$_]
#} 

my @info;

my @log = map {[split ' ']} grep{/^\[APP\]/} <INPUT>;

foreach (@log){
	my %hash;
	$hash{'textname'} = $$_[1];
	$hash{'param'} = join ' ', @$_[2..$#$_];
	$hash{'x'} = &getMark($$_[1])>>1;
	$hash{'y'} = -1;
	$hash{'timevalue'} = 0;

	push @info, \%hash;
}

# set y
&getReletion();

print &getJson();

sub getJson()
{
	my $jsonStr = "var employees = [ \n";
	foreach (@info){
		my $json = encode_json $_;
		$jsonStr .= "$json,\n";
	}
	$jsonStr .= "];";

	return $jsonStr;
}


sub getMark(){
	my @mark = split '_', shift;

	if($#mark <= 0){
		return 6;
	}

	if($mark[$#mark] eq 'REQ'){
		return 0;
	}
	elsif($mark[$#mark] eq 'RES'){
		return 1;
	}
	elsif($mark[$#mark] eq 'CFM'){
		return 2;
	}
	elsif($mark[$#mark] eq 'IND'){
		if($mark[$#mark-1] eq 'COM' || 
			$mark[$#mark-1] eq 'COMP' || 
			$mark[$#mark-1] eq 'COMPLETE')
		{
			return 4;
		}
		return 5;
	}
	return 6;
}

sub getName()
{
	my $v = shift;
	my @items = split '_', $v;

	if(&getMark($v) eq 4){
		$v = join '', @items[0..$#items-2];
	}
	else{
		$v = join '', @items[0..$#items-1];
	}

	return $v;
}

sub getReletion(){
	my $y = 0;
	for(my $i=0; $i <= $#info; $i++){
		if($info[$i]->{'y'} ne -1){
			next;
		}

		$info[$i]{'y'} = $y;
		if(&getMark($info[$i]->{'textname'}) eq 0){
			my $name =  &getName($info[$i]{'textname'});
			for(my $j=$i+1; $j <= $#info; $j++){
				my $t_name = &getName($info[$j]{'textname'});
				my $mark = &getMark($info[$j]{'textname'});
				if($t_name eq $name){
					if($mark eq 4){
						$info[$j]{'y'} = $y;
						last;
					}
					elsif($mark eq 0){
						next;
					}
					else{
						$info[$j]{'y'} = $y;
					}
				}
			}
		}

		if(&getMark($info[$i]{'textname'} eq 4)){
			my $name =  &getName($info[$i]{'textname'});
			for(my $j=$i+1; $j <= $#info; $j++){
				my $t_name = &getName($info[$j]{'textname'});
				my $mark = &getMark($info[$j]{'textname'});
				if($t_name eq $name and $mark eq 1){
					$info[$j]{'y'} = $y;
					last;
		
				}
			}
		}

		$y++;
	}
}
