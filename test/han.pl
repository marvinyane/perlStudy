#! /usr/bin/perl -w

use strict;
use Encode;

open IN, "<$ARGV[0]" or die $!;

while(<IN>)
{
	my $line = Encode::decode("UTF-8",$_);
	print $1 if $line =~ m/(\p{Han}+)/;
}