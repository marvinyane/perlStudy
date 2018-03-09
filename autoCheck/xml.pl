#! /usr/bin/perl

use warnings;
use XML::Simple;
use Data::Dumper;

die 'one argument - xml file' if($#ARGV != 0);

my $xml = XMLin(shift @ARGV, ForceArray => 1);

#print Dumper($xml);
my @items = @{$xml->{'CmdList'}[0]->{'CMD'}};

#print $#items;

my %result;

foreach (@items){
	my $group = $_->{'group'};
	my @params = @{$_->{'Param'}};
	my %names = %{$_->{'Name'}[0]};
	my $name = $names{'content'};

	my @values;

	foreach (@params){
		my @type = @{$_->{'Type'}};
		push @values, $type[0];
	}

	$result{$name} = \@values;
}

foreach (keys %result){
	my @params = @{$result{$_}};

	print "$_ : ";
	foreach(@params){
		print "$_ ";
	}
	print "\n";

}